class_name HintManager
extends Node

## Mission 7: satu hint sekaligus, 5 s, sekali per run, reset saat restart.

signal hint_shown(id: StringName, text: String)
signal hint_hidden(id: StringName)

const SHOW_TIME := 5.0
const BASE_HINT_DELAY := 3.0
const DEFAULT_NEEDS: NeedsConfig = preload("res://src/data/configs/needs_config.tres")
const HINT_PATHS: Array[String] = [
	"res://src/data/hints/base_place.tres",
	"res://src/data/hints/gather.tres",
	"res://src/data/hints/dusk.tres",
	"res://src/data/hints/need_low.tres",
	"res://src/data/hints/repair.tres",
	"res://src/data/hints/campfire_cold.tres",
	"res://src/data/hints/crafting.tres",
	"res://src/data/hints/fence.tres",
	"res://src/data/hints/neutral_hit.tres",
	"res://src/data/hints/hunger_sprint_lock.tres",
]

@export var label: Label
@export var clock: Node
@export var settings: SettingsService

var _definitions: Dictionary = {}
var _queue: Array[StringName] = []
var _shown: Dictionary = {}
var _current: StringName = &""
var _timer: float = 0.0
var _base_timer: float = 0.0
var _base_checked: bool = false
var _was_night: bool = false
var _cold_fire_checked: bool = false
## Teks bebas (OpeningSequence) ikut antrean hint yang sama supaya tidak tumpang tindih.
var _texts: Dictionary = {}
var _durations: Dictionary = {}
## Antrean prioritas: prompt pembuka selalu didahulukan dari hint gameplay.
var _priority: Array[StringName] = []


func _ready() -> void:
	_load_definitions()
	_bind()
	_wire()
	_ensure_label()


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	if _timer > 0.0:
		_timer = maxf(_timer - delta, 0.0)
		if _timer <= 0.0:
			_hide_current()
	_tick_base_hint(delta)
	_tick_night()
	_tick_cold_fire()
	if _current == &"" and has_pending():
		_pump()


func trigger(id: StringName) -> void:
	if not is_enabled() or _shown.has(id) or _current == id or _queue.has(id):
		return
	if not _definitions.has(id):
		return
	_queue.append(id)
	if _current == &"":
		_pump()


## Tampilkan teks bebas di saluran hint yang sama (satu hint pada satu waktu).
## `priority` = true (default) menaruhnya di antrean prioritas, sehingga hint
## gameplay yang masuk di tengah urutan tidak bisa memotong prompt pembuka.
func show_text(id: StringName, text: String, duration: float = SHOW_TIME, priority: bool = true) -> void:
	if not is_enabled() or _current == id:
		return
	_texts[id] = text
	_durations[id] = maxf(duration, 0.1)
	var bucket := _priority if priority else _queue
	if not bucket.has(id):
		bucket.append(id)
	if _current == &"":
		_pump()


## True bila masih ada hint (prioritas maupun gameplay) yang menunggu.
func has_pending() -> bool:
	return not _priority.is_empty() or not _queue.is_empty()


## Tutup hint yang tampil sekarang lalu lanjut ke antrean berikutnya.
func skip_current() -> void:
	if _current == &"":
		return
	_hide_current()
	if _current == &"" and has_pending():
		_pump()


func reset() -> void:
	_shown.clear()
	_queue.clear()
	_priority.clear()
	_texts.clear()
	_durations.clear()
	_current = &""
	_timer = 0.0
	_base_timer = 0.0
	_base_checked = false
	_cold_fire_checked = false
	if label != null:
		label.text = ""
		label.visible = false


func is_enabled() -> bool:
	if settings == null:
		settings = SettingsService.find_service(self)
	return settings == null or settings.are_hints_enabled()


func is_showing() -> bool:
	return _current != &""


func get_current() -> StringName:
	return _current


## Jumlah hint yang menunggu (prioritas + gameplay).
func get_queue_size() -> int:
	return _priority.size() + _queue.size()


func has_shown(id: StringName) -> bool:
	return _shown.has(id)


func get_text(id: StringName) -> String:
	if _texts.has(id):
		return String(_texts[id])
	return "" if not _definitions.has(id) else String(_definitions[id])


# --- Internal ---------------------------------------------------------------

func _ensure_label() -> void:
	if label != null:
		return
	var layer := CanvasLayer.new()
	layer.name = "HintLayer"
	layer.layer = 5
	add_child(layer)
	label = Label.new()
	label.name = "HintLabel"
	label.visible = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.14, 0.09, 0.05, 0.95))
	label.add_theme_constant_override("outline_size", 3)
	var tex_path := "res://assets/textures/ui/02_panel/panel_walnut_stitched.png"
	if ResourceLoader.exists(tex_path):
		var box := StyleBoxTexture.new()
		box.texture = load(tex_path) as Texture2D
		box.texture_margin_left = 20.0
		box.texture_margin_top = 20.0
		box.texture_margin_right = 20.0
		box.texture_margin_bottom = 20.0
		box.content_margin_left = 20.0
		box.content_margin_top = 12.0
		box.content_margin_right = 20.0
		box.content_margin_bottom = 12.0
		label.add_theme_stylebox_override("normal", box)
	label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.offset_top = 182.0
	layer.add_child(label)


func _load_definitions() -> void:
	for path in HINT_PATHS:
		var definition := load(path) as HintDefinition
		if definition == null:
			continue
		_definitions[definition.id] = definition.text


func _bind() -> void:
	if settings == null:
		settings = SettingsService.find_service(self)
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")


func _wire() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group(&"player")
	if player != null:
		var interactor := player.get_node_or_null("InteractorComponent") as InteractorComponent
		if interactor != null:
			interactor.target_changed.connect(_on_target_changed)
		var needs := player.get_node_or_null("NeedsComponent") as NeedsComponent
		if needs != null:
			needs.tier_changed.connect(_on_tier_changed)
			needs.value_changed.connect(_on_need_value_changed)
		var combat := player.get_node_or_null("CombatComponent") as CombatComponent
		if combat != null:
			combat.hit_dealt.connect(_on_hit_dealt)
	for node in tree.get_nodes_in_group(&"camp_structure"):
		if node.has_signal(&"damaged"):
			node.damaged.connect(_on_structure_damaged)


func _on_target_changed(target: Interactable) -> void:
	if target != null:
		trigger(&"gather")


## Mission 9: Hunger <= 30 memblokir sprint dan memperlambat regen HP.
func _on_need_value_changed(need: int, value: float) -> void:
	if need != NeedsComponent.Need.HUNGER:
		return
	if value <= DEFAULT_NEEDS.hunger_sprint_lock_threshold:
		trigger(&"hunger_sprint_lock")


func _on_tier_changed(_need: int, tier: int) -> void:
	if tier == NeedsComponent.Tier.LOW:
		trigger(&"need_low")


func _on_hit_dealt(target: Node, _damage: float) -> void:
	var fauna := target as FaunaBase
	if fauna != null and fauna.temperament == FaunaBase.Temperament.NEUTRAL:
		trigger(&"neutral_hit")


func _on_structure_damaged(_amount: float, _source: Node) -> void:
	trigger(&"repair")


func _tick_base_hint(delta: float) -> void:
	if _base_checked:
		return
	if CampAnchor.find_anchor(self) != null:
		_base_checked = true
		return
	_base_timer += delta
	if _base_timer >= BASE_HINT_DELAY:
		_base_checked = true
		trigger(&"base_place")


## Mission 9: api unggun baru dibangun COLD, jadi hint muncul begitu ada api
## dingin (dengan atau tanpa bahan bakar), bukan hanya setelah api padam.
func _tick_cold_fire() -> void:
	if _cold_fire_checked:
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(&"camp_structure"):
		var fire := node as Campfire
		if fire == null or not is_instance_valid(fire):
			continue
		if not fire.is_cold():
			continue
		_cold_fire_checked = true
		trigger(&"campfire_cold")
		return


func _tick_night() -> void:
	if clock == null or not clock.has_method(&"is_night"):
		return
	var night: bool = clock.is_night()
	if night and not _was_night:
		var day: int = clock.get_current_day() if clock.has_method(&"get_current_day") else 1
		if day <= 1:
			trigger(&"dusk")
		_was_night = true
	elif not night:
		_was_night = false


func _pump() -> void:
	if not has_pending() or not is_enabled():
		return
	_current = _priority.pop_front() if not _priority.is_empty() else _queue.pop_front()
	_shown[_current] = true
	_timer = float(_durations.get(_current, SHOW_TIME))
	if label != null:
		label.text = get_text(_current)
		label.visible = true
	hint_shown.emit(_current, get_text(_current))


func _hide_current() -> void:
	if _current == &"":
		return
	var id := _current
	_current = &""
	if label != null:
		label.text = ""
		label.visible = false
	hint_hidden.emit(id)

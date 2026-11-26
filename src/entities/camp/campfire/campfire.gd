class_name Campfire
extends CampStructure

## Api unggun: bahan bakar, cahaya, refuel, dan bonus rest.
##
## Bahan bakar dihitung dalam detik game: `day_drain`/`night_drain` dikali
## `DayNightManager.get_time_scale()` (0 saat final dawn membekukan fuel).
## Clock bisa di-inject lewat `clock` untuk tes.
##
## Menyala = fuel > 0 dan tidak COLD. Mission 9: bangunan baru menaruh dasar api
## (COLD) dengan bahan bakar tersimpan; api dinyalakan minigame gesek batu.
## Saat bahan bakar habis, api menjadi ember (cahaya 80 px) dan `fuel_depleted`
## dipancarkan; struktur tetap berdiri sampai dihancurkan.
##
## Bonus rest: pemain dalam `rest_radius` mendapat override idle regen
## `&"campfire"` sebesar `rest_regen`, dicek tiap `rest_check_interval`.

signal fuel_changed(seconds: float)
signal lit_changed(is_lit: bool)
signal fuel_depleted

signal interaction_requested(station: Node, interactor: Node)

const STATION_GROUP := &"crafting_station"
const STATION_TYPE := RecipeDefinition.Station.CAMPFIRE
const PROMPT := "E: Api Unggun"
const PLAYER_GROUP := &"player"
const NEEDS_NAME := "NeedsComponent"
const REST_SOURCE := &"campfire"
## Siang hari api tetap terlihat redup; malam penuh.
const DAY_LIGHT_ENERGY := 0.12
const NIGHT_LIGHT_ENERGY := 1.0

## Tuning. Null berarti memakai CampfireConfig() bawaan.
@export var config: CampfireConfig
## Ember Snuff (malam 5-7): serangan fisik musuh juga memakan bahan bakar.
@export var ember_snuff_config: EmberSnuffConfig = preload("res://src/data/configs/fauna/ember_snuff_config.tres")
## Opsional; default autoload DayNightManager.
@export var clock: Node

var _fuel: float = 0.0
## D3: api mati (fuel 0) tetap COLD setelah diisi bahan bakar sampai
## dinyalakan dengan minigame gesek batu. Mission 9: bangunan baru juga COLD.
var _cold: bool = false
## Mission 9: pernah menyala? Ember hanya muncul setelah api pernah menyala.
var has_been_lit: bool = false
var _rest_timer: float = 0.0
var _rest_players: Array[Node] = []
var _light: PointLight2D
var _light_texture: Texture2D
## Faktor fade halus cahaya api (0 = padam, 1 = menyala penuh).
var _light_fade: float = 0.0


func _enter_tree() -> void:
	super()
	add_to_group(STATION_GROUP)


func _ready() -> void:
	super()
	_ensure_config()
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	_fuel = clampf(config.initial_fuel_seconds, 0.0, config.max_fuel)
	_cold = not config.start_lit
	has_been_lit = config.start_lit and _fuel > 0.0
	var link := StationInteractable.new()
	link.name = "StationInteractable"
	link.station = self
	add_child(link)
	_ensure_light()
	_light_fade = 1.0 if get_light_radius() > 0.0 else 0.0
	_refresh_light()
	VisualSlot.attach(self, &"campfire", [get_node_or_null("Visual"), get_node_or_null("Flame")], null, CampfireVisual.new())


func _process(delta: float) -> void:
	tick(delta)
	# Tint dunia berubah selama senja/fajar; energi cahaya ikut meredup.
	_refresh_light()


func _exit_tree() -> void:
	for player in _rest_players:
		_clear_rest(player)
	_rest_players.clear()


# --- Stasiun crafting -------------------------------------------------------

## `station_type` dibaca CraftingComponent lewat properti dinamis.
var station_type: int = STATION_TYPE


func get_interaction_prompt() -> String:
	return PROMPT


func request_station_panel(interactor: Node) -> void:
	interaction_requested.emit(self, interactor)


func is_station_active() -> bool:
	return is_lit()


# --- State ------------------------------------------------------------------

func is_lit() -> bool:
	return not _cold and _fuel > 0.0


func is_cold() -> bool:
	return _cold


## Perlu minigame: sudah ada bahan bakar tetapi api masih mati.
func needs_ignition() -> bool:
	return _cold and _fuel > 0.0


func can_ignite() -> bool:
	return needs_ignition() and (config == null or config.manual_ignition_enabled)


## Nyalakan api yang COLD (bahan bakar sudah ada).
func ignite() -> bool:
	if not can_ignite():
		return false
	_cold = false
	has_been_lit = true
	_refresh_light()
	lit_changed.emit(true)
	return true


## Alasan blokir untuk minigame gesek batu.
func get_ignite_block_reason(interactor: Node) -> String:
	if not needs_ignition():
		return ""
	var inventory := _inventory_of(interactor)
	if inventory == null or not inventory.has_item(ItemCatalog.STONE, 1):
		return "Butuh Batu"
	return ""


## Dipanggil CampfireRefuel saat api COLD dengan bahan bakar.
func request_ignition(interactor: Node) -> bool:
	var starter := _fire_starter_of(interactor)
	if starter == null:
		return false
	return starter.start(self)


func get_fuel() -> float:
	return _fuel


func get_max_fuel() -> float:
	return config.max_fuel if config != null else 600.0


## Mission 9: belum pernah menyala = `unlit_light_radius` (0 = gelap).
func get_light_radius() -> float:
	if is_lit():
		return config.lit_light_radius
	if not has_been_lit:
		return config.unlit_light_radius
	return config.ember_light_radius


## Radius Dazzled (getter saja; efek musuh menyusul).
func get_dazzle_radius() -> float:
	return config.dazzle_radius


func get_refuel_hold_time() -> float:
	return config.refuel_hold_time


## PointLight2D milik api (dipakai tes dan visual).
func get_light() -> PointLight2D:
	return _light


func is_full() -> bool:
	return _fuel >= config.full_threshold


## Set bahan bakar langsung (tes dan save nanti). Dibatasi 0..max_fuel.
func set_fuel(value: float) -> void:
	_ensure_config()
	_set_fuel(value)


## Kurangi bahan bakar (Ember Snuff). Tidak pernah menambah.
func remove_fuel(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_ensure_config()
	_set_fuel(_fuel - seconds)


## Ember Snuff: serangan fisik dari fauna saat malam hari >= first_day
## juga memakan bahan bakar.
func take_damage(amount: float, source: Node) -> void:
	if _ember_snuff_applies(source):
		remove_fuel(ember_snuff_config.fuel_loss)
	super.take_damage(amount, source)


func _ember_snuff_applies(source: Node) -> bool:
	if ember_snuff_config == null or source == null:
		return false
	if not _fuel > 0.0:
		return false
	if not source.is_in_group(&"fauna"):
		return false
	if not _is_night():
		return false
	return _day() >= ember_snuff_config.first_day


func _day() -> int:
	if clock == null or not clock.has_method(&"get_current_day"):
		return 1
	return int(clock.get_current_day())


# --- Tick -------------------------------------------------------------------

## Satu tick game. `_process` hanya memanggil ini supaya tes deterministik.
func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	var time_scale := _time_scale()
	if is_lit():
		if time_scale > 0.0:
			var rate := config.night_drain if _is_night() else config.day_drain
			_set_fuel(_fuel - rate * time_scale * delta)
	_tick_light_fade(delta * maxf(time_scale, 0.0))
	_update_rest(delta)


# --- Refuel -----------------------------------------------------------------

func can_refuel(interactor: Node) -> bool:
	return get_refuel_block_reason(interactor).is_empty()


func get_refuel_block_reason(interactor: Node) -> String:
	if is_full():
		return "Bahan bakar penuh"
	var inventory := _inventory_of(interactor)
	if inventory == null:
		return "Butuh 2 Kayu"
	if not inventory.has_item(ItemCatalog.WOOD, config.refuel_wood_cost):
		return "Butuh 2 Kayu"
	return ""


## Isi ulang: 2 kayu -> +180 s, dibatasi max_fuel. False bila tidak bisa.
func refuel(interactor: Node) -> bool:
	if not can_refuel(interactor):
		return false
	var inventory := _inventory_of(interactor)
	if inventory == null:
		return false
	if not inventory.remove_item(ItemCatalog.WOOD, config.refuel_wood_cost):
		return false
	_set_fuel(_fuel + config.refuel_seconds)
	return true


# --- Internal ---------------------------------------------------------------

func _ensure_config() -> void:
	if config == null:
		config = CampfireConfig.new()


func _set_fuel(value: float) -> void:
	var clamped := clampf(value, 0.0, config.max_fuel)
	var was_lit := is_lit()
	if is_equal_approx(clamped, _fuel):
		return
	_fuel = clamped
	if _fuel <= 0.0:
		_cold = true
	fuel_changed.emit(_fuel)
	_refresh_light()
	var now_lit := is_lit()
	if now_lit:
		has_been_lit = true
	if was_lit and not now_lit:
		lit_changed.emit(false)
		fuel_depleted.emit()
	elif not was_lit and now_lit:
		lit_changed.emit(true)


func _time_scale() -> float:
	if clock == null or not clock.has_method("get_time_scale"):
		return 1.0
	return clock.get_time_scale()


func _is_night() -> bool:
	if clock == null or not clock.has_method("is_night"):
		return false
	return clock.is_night()


func _inventory_of(interactor: Node) -> InventoryComponent:
	if interactor == null or not interactor.has_method(&"get_inventory"):
		return null
	return interactor.get_inventory() as InventoryComponent


func _fire_starter_of(interactor: Node) -> FireStarterController:
	if interactor == null:
		return null
	var direct := interactor.get_node_or_null("FireStarterController") as FireStarterController
	if direct != null:
		return direct
	var parent := interactor.get_parent()
	if parent != null:
		return parent.get_node_or_null("FireStarterController") as FireStarterController
	return null


# --- Rest bonus -------------------------------------------------------------

func _update_rest(delta: float) -> void:
	if config == null:
		return
	_rest_timer += delta
	if _rest_timer < config.rest_check_interval:
		return
	_rest_timer = 0.0
	_refresh_rest()


func _refresh_rest() -> void:
	var tree := get_tree()
	if tree == null:
		return

	var active: Array[Node] = []
	if is_lit():
		for node in tree.get_nodes_in_group(PLAYER_GROUP):
			var entity := node as Node2D
			if entity == null:
				continue
			if global_position.distance_to(entity.global_position) > config.rest_radius:
				continue
			if _apply_rest(node):
				active.append(node)

	for player in _rest_players:
		if not is_instance_valid(player):
			continue
		if not active.has(player):
			_clear_rest(player)
	_rest_players = active


## Parameter sengaja tidak bertipe: pemain bisa sudah freed saat campfire masih
## memegang referensinya, dan cast bertipe akan error sebelum bisa dicek.
func _apply_rest(player) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var needs := player.get_node_or_null(NEEDS_NAME) as NeedsComponent
	if needs == null:
		return false
	needs.set_idle_regen_override(REST_SOURCE, config.rest_regen)
	return true


func _clear_rest(player) -> void:
	if player == null or not is_instance_valid(player):
		return
	var needs := player.get_node_or_null(NEEDS_NAME) as NeedsComponent
	if needs != null:
		needs.clear_idle_regen_override(REST_SOURCE)


# --- Light ------------------------------------------------------------------

func _ensure_light() -> void:
	if _light != null:
		return
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.0)])

	_light_texture = GradientTexture2D.new()
	_light_texture.gradient = gradient
	_light_texture.fill = GradientTexture2D.FILL_RADIAL
	_light_texture.fill_from = Vector2(0.5, 0.5)
	_light_texture.fill_to = Vector2(1.0, 0.5)
	_light_texture.width = 256
	_light_texture.height = 256

	var art := Assets.ui_texture(&"light_campfire")
	if art != null:
		_light_texture = art

	_light = PointLight2D.new()
	_light.name = "Light"
	_light.texture = _light_texture
	_light.color = Color(1.0, 0.72, 0.4, 1.0)
	_light.energy = 1.0
	# Jangkau SunSweepOverlay (layer 2) agar blend_mul senja tidak meredupkan cahaya api.
	_light.range_layer_max = SunSweepOverlay.LAYER
	add_child(_light)


## Energi cahaya target berdasarkan kegelapan dunia 0..1 (0 siang, 0.5 sore, 1 malam).
func compute_light_energy(darkness: float) -> float:
	_ensure_config()
	var d := clampf(darkness, 0.0, 1.0)
	if d <= 0.5:
		return lerpf(config.light_energy_day, config.light_energy_dusk, d * 2.0)
	return lerpf(config.light_energy_dusk, config.light_energy_night, (d - 0.5) * 2.0)


func _tick_light_fade(game_delta: float) -> void:
	_ensure_config()
	var target := 1.0 if get_light_radius() > 0.0 else 0.0
	if config.light_fade_seconds <= 0.0:
		_light_fade = target
	elif game_delta > 0.0:
		_light_fade = move_toward(_light_fade, target, game_delta / config.light_fade_seconds)
	_refresh_light()


func _refresh_light() -> void:
	if _light == null or _light_texture == null:
		return
	var radius := get_light_radius()
	var effective_radius := radius if radius > 0.0 else (config.lit_light_radius if config != null else 240.0)
	var width := maxf(float(_light_texture.get_width()), 1.0)
	_light.texture_scale = (effective_radius * 2.0) / width
	var active := radius > 0.0 or _light_fade > 0.001
	_light.visible = active
	_light.energy = compute_light_energy(_world_darkness()) * _light_fade if active else 0.0


## 0 siang terang, 1 malam; dibaca dari tint CanvasModulate DayNightVisual.
func _world_darkness() -> float:
	var tree := get_tree()
	if tree == null:
		return 0.0
	var visual := tree.get_first_node_in_group(&"day_night_visual")
	if visual != null and visual.has_method(&"get_world_darkness"):
		return clampf(float(visual.call(&"get_world_darkness")), 0.0, 1.0)
	return 0.0

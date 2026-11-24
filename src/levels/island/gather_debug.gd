extends Node

## Debug khusus island (default OFF); tidak dipasang di practice1 supaya tidak
## bertabrakan dengan NeedsDebug.
##
## F2: aktifkan debug dan beri Stone Axe + Stone Pickaxe (equip).
## F3: teleport ke tengah zona berikutnya.
## F4: lompat ke pagi berikutnya lewat DayNightManager.skip_time.
## Y: lompat ke awal periode jam berikutnya (Pagi 06:00 / Siang 10:00 /
## Sore 15:00 / Malam 18:00) memakai GameClockFormat + skip_time.
##
## Tombol dibaca sebagai action Input Map `debug_island_*` yang didaftarkan
## `InputSetup` (F2/F3/F4), jadi tidak ada pencocokan raw keycode.

const PLAYER_GROUP := &"player"
const INVENTORY_NAME := "InventoryComponent"
const HINT_OFF := "F2: island debug (tools · zona · waktu · kit · fauna · senjata)"
const HINT_ON := "ISLAND DEBUG ON\nF2 off · F3 zona · F4 pagi · F5 kit · F6 boar · F7 rusa\nF8 malam · F9 heal · F10 senjata · F11 mati · F12 rescue · Y periode"
const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")
const DEER_SCENE: PackedScene = preload("res://src/entities/fauna/island_deer/island_deer.tscn")
const SPAWN_DISTANCE := 250.0
const WEAPON_CYCLE: Array[ItemDefinition] = [
	null,
	preload("res://src/data/items/wooden_spear.tres"),
	preload("res://src/data/items/stone_spear.tres"),
	preload("res://src/data/items/bone_spear.tres"),
]
## Kit uji crafting (item, jumlah). Diberikan lewat add_or_drop supaya perilaku
## overflow sama dengan gameplay normal.
const KIT: Array = [
	[ItemCatalog.WOOD, 30],
	[ItemCatalog.STONE, 20],
	[ItemCatalog.FIBER, 20],
	[ItemCatalog.BAMBOO, 10],
	[ItemCatalog.BONE, 10],
	[ItemCatalog.HIDE, 10],
	[ItemCatalog.RAW_MEAT, 6],
	[ItemCatalog.BERRY, 6],
]
const ZONES: Array[int] = [
	IslandZones.Zone.CAMP,
	IslandZones.Zone.SOUTH_BEACH,
	IslandZones.Zone.EAST_BEACH,
	IslandZones.Zone.WEST_CLIFFS,
	IslandZones.Zone.RIVER,
	IslandZones.Zone.FOREST,
]

## Opsional; default autoload DayNightManager.
@export var clock: Node

var _enabled: bool = false
var _zone_index: int = 0
var _weapon_index: int = 0
var _label: Label
var _fauna_labels_enabled: bool = false
var _fauna_labels: Dictionary = {}

const FAUNA_GROUP := &"fauna"
const TEMPERAMENT_NAMES: Array[String] = ["PASSIVE", "NEUTRAL", "HOSTILE"]
const BOAR_STATE_NAMES: Array[String] = [
	"WANDER", "CHASE", "BITE", "DASH_TELEGRAPH", "DASH", "RECOVER", "FLEE"
]


func _ready() -> void:
	InputSetup.ensure_actions()
	_build_hint()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_TOGGLE):
		_toggle()
		return
	if Input.is_action_just_pressed(InputSetup.DEBUG_FAUNA_LABELS):
		set_fauna_labels_enabled(not _fauna_labels_enabled)
	if _fauna_labels_enabled:
		refresh_fauna_labels()
	if not _enabled:
		return
	if Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_ZONE):
		_cycle_zone()
	elif Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_MORNING):
		_skip_to_morning()
	elif Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_KIT):
		_grant_kit()
	elif Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_BOAR):
		_spawn_fauna(BOAR_SCENE, true)
	elif Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_DEER):
		_spawn_fauna(DEER_SCENE, false)
	elif Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_NIGHT):
		_skip_to_night()
	elif Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_HEAL):
		_heal_player()
	elif Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_WEAPON):
		_cycle_weapon()
	elif Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_KILL):
		_kill_player()
	elif Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_RESCUE):
		_jump_to_rescue()
	elif Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_PERIOD):
		_jump_to_next_period()
	elif Input.is_action_just_pressed(InputSetup.DEBUG_RAID):
		_trigger_raid()


func is_debug_enabled() -> bool:
	return _enabled


func is_fauna_labels_enabled() -> bool:
	return _fauna_labels_enabled


func get_fauna_label_count() -> int:
	return _fauna_labels.size()


## Label temperament/state di atas tiap fauna (Insert). Debug-only.
func set_fauna_labels_enabled(value: bool) -> void:
	_fauna_labels_enabled = value
	if value:
		refresh_fauna_labels()
		return
	for key in _fauna_labels.keys():
		var label: Label = _fauna_labels[key]
		if is_instance_valid(label):
			label.queue_free()
	_fauna_labels.clear()


func refresh_fauna_labels() -> void:
	if not _fauna_labels_enabled:
		return
	var host: Node = get_parent()
	if host == null:
		host = self
	var seen := {}
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(FAUNA_GROUP):
		var fauna := node as FaunaBase
		if fauna == null or not is_instance_valid(fauna):
			continue
		var id := fauna.get_instance_id()
		seen[id] = true
		var label: Label = _fauna_labels.get(id)
		if label == null or not is_instance_valid(label):
			label = Label.new()
			label.add_theme_font_size_override("font_size", 10)
			label.z_index = 20
			host.add_child(label)
			_fauna_labels[id] = label
		label.global_position = fauna.global_position + Vector2(-46.0, -48.0)
		label.text = _fauna_label_text(fauna)
	for id in _fauna_labels.keys():
		if seen.has(id):
			continue
		var stale: Label = _fauna_labels[id]
		if is_instance_valid(stale):
			stale.queue_free()
		_fauna_labels.erase(id)


func _fauna_label_text(fauna: FaunaBase) -> String:
	var temperament := fauna.get_temperament()
	var temperament_name: String = TEMPERAMENT_NAMES[clampi(temperament, 0, TEMPERAMENT_NAMES.size() - 1)]
	if fauna.forced_hostile:
		temperament_name += "(forced)"
	var state_name := "-"
	var raid_tag := ""
	if fauna is WildBoar:
		var boar := fauna as WildBoar
		var state_value: int = boar.get_state()
		state_name = BOAR_STATE_NAMES[clampi(state_value, 0, BOAR_STATE_NAMES.size() - 1)]
		raid_tag = " | RAIDER" if boar.is_raider else " | normal"
	return "%s | %s | provoked=%s%s" % [temperament_name, state_name, "yes" if fauna.is_provoked() else "no", raid_tag]


## Mission 9 (debug island): picu raid sekarang lewat RaidDirector.
func _trigger_raid() -> int:
	var tree := get_tree()
	if tree == null:
		return 0
	var director := tree.get_first_node_in_group(RaidDirector.GROUP) as RaidDirector
	if director == null:
		return 0
	var count := director.trigger_raid_now()
	refresh_fauna_labels()
	return count


func _build_hint() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 21
	add_child(layer)

	_label = Label.new()
	_label.position = Vector2(16.0, 214.0)
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55, 1.0))
	_label.text = HINT_OFF
	layer.add_child(_label)


func _toggle() -> void:
	_enabled = not _enabled
	if _enabled:
		_grant_tools()
	if _label != null:
		_label.text = HINT_ON if _enabled else HINT_OFF


func _grant_tools() -> void:
	var inventory := _inventory()
	if inventory == null:
		push_warning("GatherDebug: InventoryComponent tidak ditemukan; tools tidak diberikan.")
		return
	inventory.equip(ItemCatalog.STONE_AXE)
	inventory.equip(ItemCatalog.STONE_PICKAXE)


func _cycle_zone() -> void:
	var player := _resolve_player()
	if player == null:
		push_warning("GatherDebug: Player tidak ditemukan; teleport dilewati.")
		return
	var zone: int = ZONES[_zone_index % ZONES.size()]
	_zone_index += 1
	var center := WorldRules.zone_center(zone)
	if center == Vector2.INF:
		push_warning("GatherDebug: zona %s tidak punya titik teleport; dilewati." % IslandZones.zone_name(zone))
		return
	player.global_position = center
	print("GatherDebug: teleport ke zona %s" % IslandZones.zone_name(zone))


func _skip_to_morning() -> void:
	var manager := clock
	if manager == null:
		manager = get_node_or_null("/root/DayNightManager")
	if manager == null:
		push_warning("GatherDebug: DayNightManager tidak ditemukan; skip dilewati.")
		return

	var seconds: float = manager.get_remaining_seconds()
	if manager.is_day():
		seconds += manager.get_night_duration()
	manager.skip_time(seconds)
	print("GatherDebug: lompat %.1f detik ke pagi berikutnya" % seconds)


## Mission 12: lompat ke awal periode jam berikutnya (Pagi 06:00, Siang 10:00,
## Sore 15:00, Malam 18:00). Berhenti tepat di jam target: kalau target ada di
## fase ini, skip persis detiknya; kalau tidak, habiskan fase ini dulu lalu
## hitung lagi di fase berikutnya (kecepatan jam berbeda per fase).
func _jump_to_next_period() -> void:
	var manager := clock
	if manager == null:
		manager = get_node_or_null("/root/DayNightManager")
	if manager == null or not manager.has_method(&"get_clock_hour"):
		push_warning("GatherDebug: jam dunia nyata tidak tersedia; lompat dilewati.")
		return

	var format: ClockFormatConfig = manager.get_clock_format()
	var target := GameClockFormat.next_period_start_hour(manager.get_clock_hour(), format)
	for step in 6:
		var hour: float = manager.get_clock_hour()
		if GameClockFormat.hours_between(hour, target) < 0.02 or GameClockFormat.hours_between(hour, target) > 23.98:
			break
		var seconds: float = GameClockFormat.seconds_until_hour(
			target, manager.is_day(), manager.get_phase_progress(), manager.get_phase_duration(), format
		)
		var remaining: float = manager.get_remaining_seconds()
		manager.skip_time(remaining if seconds >= remaining - 0.001 else seconds)
	print("GatherDebug: jam sekarang %s (target %s)" % [
		manager.get_clock_text(), GameClockFormat.text(target, format == null or format.use_24h, 1 if format == null else format.minute_step)
	])


func _spawn_fauna(scene: PackedScene, hostile: bool) -> void:
	var player := _resolve_player() as Node2D
	if player == null:
		push_warning("GatherDebug: Player tidak ditemukan; spawn dilewati.")
		return
	var fauna := scene.instantiate() as FaunaBase
	if fauna == null:
		return
	var tree := get_tree()
	(tree.current_scene if tree != null and tree.current_scene != null else self).add_child(fauna)
	var facing := Vector2.DOWN
	if "facing_direction" in player:
		facing = player.facing_direction
	fauna.global_position = player.global_position + facing.normalized() * SPAWN_DISTANCE
	if hostile:
		fauna.forced_hostile = true
		fauna.set_temperament(FaunaBase.Temperament.HOSTILE)
	print("GatherDebug: spawn %s." % fauna.name)


func _skip_to_night() -> void:
	var manager := clock
	if manager == null:
		manager = get_node_or_null("/root/DayNightManager")
	if manager == null or manager.is_night():
		return
	manager.skip_time(manager.get_remaining_seconds())
	print("GatherDebug: lompat ke awal malam")


func _heal_player() -> void:
	var player := _resolve_player()
	if player == null:
		return
	var stats := player.get_node_or_null("StatsComponent") as StatsComponent
	if stats != null:
		stats.set_hp(stats.get_max_hp())
	var needs := player.get_node_or_null("NeedsComponent") as NeedsComponent
	if needs != null:
		needs.set_value(NeedsComponent.Need.HUNGER, needs.get_config().max_value)
		needs.set_value(NeedsComponent.Need.THIRST, needs.get_config().max_value)
		needs.restore_fatigue_capacity(needs.get_config().max_value)
	print("GatherDebug: HP dan needs dipulihkan")


func _cycle_weapon() -> void:
	var inventory := _inventory()
	if inventory == null:
		return
	_weapon_index = (_weapon_index + 1) % WEAPON_CYCLE.size()
	var item := WEAPON_CYCLE[_weapon_index]
	if item == null:
		inventory.unequip(ItemDefinition.EquipmentSlot.WEAPON)
		print("GatherDebug: senjata dilepas")
		return
	inventory.add_or_drop(item, 1)
	inventory.equip(item)
	print("GatherDebug: senjata %s" % item.display_name)


## F11: HP 0 supaya DeathController/DeathScreen teruji tanpa menunggu boar.
func _kill_player() -> void:
	var player := _resolve_player()
	if player == null:
		return
	var stats := player.get_node_or_null("StatsComponent") as StatsComponent
	if stats == null:
		return
	stats.get_max_hp()
	stats.set_hp(0.0)
	print("GatherDebug: pemain dimatikan")


## F12: lompat fase sampai rescue (fajar Hari 7) menyala.
func _jump_to_rescue() -> void:
	var manager := clock
	if manager == null:
		manager = get_node_or_null("/root/DayNightManager")
	if manager == null:
		return
	var guard := 0
	while not manager.rescue_triggered and guard < 40:
		manager.skip_time(manager.get_remaining_seconds() + 0.01)
		guard += 1
	print("GatherDebug: lompat ke rescue (hari %d)" % manager.get_current_day())


func _grant_kit() -> void:
	var inventory := _inventory()
	if inventory == null:
		push_warning("GatherDebug: InventoryComponent tidak ditemukan; kit tidak diberikan.")
		return
	for entry: Array in KIT:
		inventory.add_or_drop(entry[0], entry[1])
	print("GatherDebug: kit bahan diberikan (%d jenis)." % KIT.size())


func _resolve_player() -> Node:
	return get_tree().get_first_node_in_group(PLAYER_GROUP)


func _inventory() -> InventoryComponent:
	var player := _resolve_player()
	if player == null:
		return null
	return player.get_node_or_null(INVENTORY_NAME) as InventoryComponent

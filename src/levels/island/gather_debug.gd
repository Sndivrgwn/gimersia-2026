extends Node

## Debug khusus island (default OFF); tidak dipasang di practice1 supaya tidak
## bertabrakan dengan NeedsDebug.
##
## F2: aktifkan debug dan beri Stone Axe + Stone Pickaxe (equip).
## F3: teleport ke tengah zona berikutnya.
## F4: lompat ke pagi berikutnya lewat DayNightManager.skip_time.
##
## Tombol dibaca sebagai action Input Map `debug_island_*` yang didaftarkan
## `InputSetup` (F2/F3/F4), jadi tidak ada pencocokan raw keycode.

const PLAYER_GROUP := &"player"
const INVENTORY_NAME := "InventoryComponent"
const HINT_OFF := "F2: island debug (tools · teleport zona · lompat pagi · kit bahan)"
const HINT_ON := "ISLAND DEBUG ON\nF2 off · F3 zona berikutnya · F4 pagi berikutnya · F5 kit bahan"
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
var _label: Label


func _ready() -> void:
	InputSetup.ensure_actions()
	_build_hint()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_TOGGLE):
		_toggle()
		return
	if not _enabled:
		return
	if Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_ZONE):
		_cycle_zone()
	elif Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_MORNING):
		_skip_to_morning()
	elif Input.is_action_just_pressed(InputSetup.DEBUG_ISLAND_KIT):
		_grant_kit()


func is_debug_enabled() -> bool:
	return _enabled


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
	player.global_position = IslandZones.zone_center(zone)
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

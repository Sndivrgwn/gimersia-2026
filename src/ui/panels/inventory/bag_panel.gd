extends CanvasLayer

## Panel tas interaktif (Step 2B): 12 slot tas + kolom equipment.
##
## Bukan HUD: panel ini menerima mouse dan memanggil `move_slot()` /
## `use_slot()`. Ia tidak menyimpan state gameplay dan tidak mem-pause game:
## DayNightManager, drain Needs, dan gerakan pemain tetap berjalan.
##
## Semua isi dibaca dari InventoryComponent; refresh hanya terjadi lewat sinyal
## `slot_changed`, `equipment_changed`, dan `inventory_changed`.

const PLAYER_GROUP := &"player"
const INVENTORY_NAME := "InventoryComponent"
const TOGGLE_ACTION := &"inventory_toggle"
## Esc hanya menutup panel; tidak membukanya.
const CLOSE_ACTION := &"ui_cancel"
const SLOT_SCENE: PackedScene = preload("res://src/ui/panels/inventory/bag_slot.tscn")
const DEFAULT_BAG_SIZE := 12
const DEFAULT_HOTBAR_SIZE := 5
const EMPTY_TEXT := "-"
## TOOL adalah set kepemilikan, jadi kolomnya menampilkan alat yang dimiliki.
const TOOL_ITEMS: Array[ItemDefinition] = [
	ItemCatalog.STONE_AXE,
	ItemCatalog.STONE_PICKAXE,
]

## Opsional; bila kosong dicari lewat grup "player" -> InventoryComponent.
@export var inventory: InventoryComponent
## Buka panel saat scene mulai (default: tersembunyi).
@export var open_on_start: bool = false

@onready var _root: Control = $Root
@onready var _tabs: TabContainer = $Root/Frame/Margin/VBox/Tabs
@onready var _grid: GridContainer = $Root/Frame/Margin/VBox/Tabs/Tas/HBox/Grid
@onready var _weapon_value: Label = $Root/Frame/Margin/VBox/Tabs/Tas/HBox/Equipment/Weapon/Value
@onready var _tool_value: Label = $Root/Frame/Margin/VBox/Tabs/Tas/HBox/Equipment/Tool/Value
@onready var _armor_value: Label = $Root/Frame/Margin/VBox/Tabs/Tas/HBox/Equipment/Armor/Value

var _slots: Array[BagSlot] = []


func _ready() -> void:
	InputSetup.ensure_actions()
	# Tab harus dipakai untuk toggle, bukan navigasi fokus UI.
	_tabs.get_tab_bar().focus_mode = Control.FOCUS_NONE

	if inventory == null:
		inventory = _find_inventory()
	_build_slots()

	if inventory == null:
		push_warning("BagPanel: InventoryComponent tidak ditemukan.")
	else:
		_connect_inventory()

	refresh()
	_apply_visible(open_on_start)


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed(CLOSE_ACTION):
		_apply_visible(false)
		get_viewport().set_input_as_handled()
		return

	if not event.is_action_pressed(TOGGLE_ACTION):
		return
	toggle_panel()
	get_viewport().set_input_as_handled()


# --- API panel --------------------------------------------------------------

func is_open() -> bool:
	return _root.visible


func toggle_panel() -> void:
	_apply_visible(not is_open())


func get_slots() -> Array[BagSlot]:
	return _slots


# --- Teks equipment (dipakai tes) -------------------------------------------

func get_weapon_text() -> String:
	return _weapon_value.text


func get_tool_text() -> String:
	return _tool_value.text


func get_armor_text() -> String:
	return _armor_value.text


# --- Internal ---------------------------------------------------------------

func _apply_visible(value: bool) -> void:
	_root.visible = value


func _build_slots() -> void:
	if _grid == null:
		return

	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_slots.clear()

	var capacity := DEFAULT_BAG_SIZE
	var hotbar := DEFAULT_HOTBAR_SIZE
	if inventory != null:
		capacity = inventory.get_capacity()
		hotbar = inventory.get_hotbar_size()

	for index in capacity:
		var slot := SLOT_SCENE.instantiate() as BagSlot
		slot.slot_index = index
		slot.hotbar_number = (index + 1) if index < hotbar else 0
		slot.inventory = inventory
		_grid.add_child(slot)
		_slots.append(slot)


func _connect_inventory() -> void:
	if not inventory.slot_changed.is_connected(_on_slot_changed):
		inventory.slot_changed.connect(_on_slot_changed)
	if not inventory.equipment_changed.is_connected(_on_equipment_changed):
		inventory.equipment_changed.connect(_on_equipment_changed)
	if not inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.connect(_on_inventory_changed)


func refresh() -> void:
	for slot in _slots:
		slot.refresh()
	_refresh_equipment()


func _refresh_equipment() -> void:
	if _weapon_value == null:
		return
	_weapon_value.text = _equipped_text(ItemDefinition.EquipmentSlot.WEAPON)
	_armor_value.text = _equipped_text(ItemDefinition.EquipmentSlot.ARMOR)
	_tool_value.text = _owned_tools_text()


func _equipped_text(slot: int) -> String:
	if inventory == null:
		return EMPTY_TEXT
	var item := inventory.get_equipped(slot)
	return EMPTY_TEXT if item == null else item.display_name


func _owned_tools_text() -> String:
	if inventory == null:
		return EMPTY_TEXT

	var owned := PackedStringArray()
	for item in TOOL_ITEMS:
		if inventory.has_tool(item):
			owned.append(item.display_name)
	return ", ".join(owned) if not owned.is_empty() else EMPTY_TEXT


func _on_slot_changed(index: int) -> void:
	if index < 0 or index >= _slots.size():
		return
	_slots[index].refresh()


func _on_equipment_changed(_slot: int) -> void:
	_refresh_equipment()


func _on_inventory_changed() -> void:
	refresh()


func _find_inventory() -> InventoryComponent:
	var tree := get_tree()
	if tree == null:
		return null
	var candidate := tree.get_first_node_in_group(PLAYER_GROUP)
	if candidate == null:
		return null
	return candidate.get_node_or_null(INVENTORY_NAME) as InventoryComponent

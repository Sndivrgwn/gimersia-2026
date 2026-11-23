class_name HotbarSelectionComponent
extends Node

## Mission 10 Phase 3: hotbar 1-5 memilih item yang DIBAWA, bukan memakainya.
## Aksi use_held (klik kanan / F) memakai item terpilih bila consumable.

signal selected_changed(index: int, stack: ItemStack)

const SIZE := 5
const INVENTORY_NAME := "InventoryComponent"

@export var inventory: InventoryComponent
var selected_index: int = 0


func _ready() -> void:
	InputSetup.ensure_actions()
	if inventory == null:
		inventory = get_parent().get_node_or_null(INVENTORY_NAME) as InventoryComponent


func _process(delta: float) -> void:
	tick(delta)


func tick(_delta: float) -> void:
	if inventory == null or _ui_blocked():
		return
	for index in SIZE:
		if Input.is_action_just_pressed(InputSetup.HOTBAR_ACTIONS[index]):
			select(index)
			return
	if Input.is_action_just_pressed(InputSetup.HOTBAR_NEXT):
		select(_wrap(selected_index + 1))
	elif Input.is_action_just_pressed(InputSetup.HOTBAR_PREV):
		select(_wrap(selected_index - 1))
	elif Input.is_action_just_pressed(InputSetup.USE_HELD):
		use_held()


func select(index: int) -> void:
	if inventory == null:
		return
	var next := clampi(index, 0, SIZE - 1)
	if next == selected_index:
		return
	selected_index = next
	selected_changed.emit(selected_index, get_held_stack())


func get_held_stack() -> ItemStack:
	if inventory == null:
		return null
	return inventory.get_slot(selected_index)


func get_held_item() -> ItemDefinition:
	var stack := get_held_stack()
	return null if stack == null else stack.item


## True bila item terpilih benar-benar dipakai (consumable).
func use_held() -> bool:
	var item := get_held_item()
	if item == null or item.category != ItemDefinition.Category.CONSUMABLE:
		return false
	return inventory.use_slot(selected_index)


## Guard UI bersama: panel terbuka, kursor di UI, atau game beku.
func _ui_blocked() -> bool:
	if UiBackStack.has_open(self):
		return true
	var viewport := get_viewport()
	if viewport != null and viewport.gui_get_hovered_control() != null:
		return true
	var tree := get_tree()
	return tree != null and tree.paused


func _wrap(index: int) -> int:
	return ((index % SIZE) + SIZE) % SIZE

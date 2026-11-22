class_name EmergencySuitcase
extends Interactable

## Koper darurat di dekat wreckage. Sekali pakai: memberi herbal bandage,
## boiled water, dan Catatan Kokpit, lalu menolak interaksi berikutnya.

signal looted

const HOLD_TIME := 1.0
const PROMPT := "Tahan E: Buka Koper Darurat"
const LOOTED_REASON := "Sudah dikosongkan"

const ITEM_HERBAL_BANDAGE := preload("res://src/data/items/herbal_bandage.tres")
const ITEM_BOILED_WATER := preload("res://src/data/items/boiled_water.tres")
const ITEM_COCKPIT_NOTES := preload("res://src/data/items/cockpit_notes.tres")

var _looted: bool = false
var _visual_slot: VisualSlot

@onready var _visual: Polygon2D = get_node_or_null("Visual") as Polygon2D


func _on_looted_visual() -> void:
	if _visual_slot != null:
		_visual_slot.set_state(&"open")
@onready var _label: Label = get_node_or_null("Label") as Label


func _ready() -> void:
	_visual_slot = VisualSlot.attach(self, &"emergency_suitcase", [get_node_or_null("Visual")])
	if not looted.is_connected(_on_looted_visual):
		looted.connect(_on_looted_visual)


func get_prompt(_interactor: Node) -> String:
	return PROMPT


func get_hold_time(_interactor: Node) -> float:
	return HOLD_TIME


func can_interact(_interactor: Node) -> bool:
	return not _looted


func get_block_reason(_interactor: Node) -> String:
	if _looted:
		return LOOTED_REASON
	return ""


func interact(interactor: Node) -> void:
	if _looted:
		return
	var inventory := _inventory_of(interactor)
	if inventory == null:
		return

	inventory.add_or_drop(ITEM_HERBAL_BANDAGE, 1)
	inventory.add_or_drop(ITEM_BOILED_WATER, 1)
	inventory.add_or_drop(ITEM_COCKPIT_NOTES, 1)

	_looted = true
	if _label != null:
		_label.text = "Kosong"
	if _visual != null:
		_visual.color = Color(0.35, 0.33, 0.3, 1.0)
	looted.emit()


func is_looted() -> bool:
	return _looted


func _inventory_of(interactor: Node) -> InventoryComponent:
	if interactor == null or not interactor.has_method(&"get_inventory"):
		return null
	return interactor.get_inventory() as InventoryComponent

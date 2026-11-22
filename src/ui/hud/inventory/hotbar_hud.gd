extends CanvasLayer

## Read-only hotbar HUD: 5 slot pertama InventoryComponent.
##
## HUD hanya membaca slot dan mendengar `slot_changed`; tidak menyimpan atau
## mengubah item dan tidak menangani input. Tombol 1-5 diproses
## InventoryComponent, bukan HUD.

const PLAYER_GROUP := &"player"
const INVENTORY_NAME := "InventoryComponent"
const SLOT_COUNT := 5
const SLOT_PATHS: Array[String] = [
	"Root/Panel/Margin/HBox/Slot1",
	"Root/Panel/Margin/HBox/Slot2",
	"Root/Panel/Margin/HBox/Slot3",
	"Root/Panel/Margin/HBox/Slot4",
	"Root/Panel/Margin/HBox/Slot5",
]

## Opsional; bila kosong dicari lewat grup "player" -> InventoryComponent.
@export var inventory: InventoryComponent

var _keys: Array[Label] = []
var _names: Array[Label] = []
var _counts: Array[Label] = []
var _icons: Array[TextureRect] = []


func _ready() -> void:
	_collect_slots()

	if inventory == null:
		inventory = _find_inventory()
	if inventory == null:
		push_warning("HotbarHUD: InventoryComponent tidak ditemukan.")
		return

	if not inventory.slot_changed.is_connected(_on_slot_changed):
		inventory.slot_changed.connect(_on_slot_changed)
	refresh()


func refresh() -> void:
	for index in _keys.size():
		_refresh_slot(index)


func _collect_slots() -> void:
	for path in SLOT_PATHS:
		var slot := get_node_or_null(path)
		if slot == null:
			push_warning("HotbarHUD: slot '%s' tidak ditemukan." % path)
			continue
		_keys.append(slot.get_node_or_null("Key") as Label)
		_names.append(slot.get_node_or_null("Name") as Label)
		_counts.append(slot.get_node_or_null("Count") as Label)
		_icons.append(slot.get_node_or_null("Icon") as TextureRect)


func _refresh_slot(index: int) -> void:
	if inventory == null or index < 0 or index >= _keys.size():
		return

	_keys[index].text = "%d" % (index + 1)

	var item := inventory.get_slot_item(index)
	var count := inventory.get_slot_count(index)
	if item == null or count <= 0:
		_names[index].text = "-"
		_counts[index].text = ""
		_icons[index].visible = false
		return

	_names[index].text = item.display_name
	_counts[index].text = "x%d" % count
	var icon := item.get_icon()
	_icons[index].visible = icon != null
	if icon != null:
		_icons[index].texture = icon


func _on_slot_changed(index: int) -> void:
	_refresh_slot(index)


func _find_inventory() -> InventoryComponent:
	var tree := get_tree()
	if tree == null:
		return null
	var candidate := tree.get_first_node_in_group(PLAYER_GROUP)
	if candidate == null:
		return null
	return candidate.get_node_or_null(INVENTORY_NAME) as InventoryComponent

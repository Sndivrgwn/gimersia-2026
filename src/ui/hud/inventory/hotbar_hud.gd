extends CanvasLayer

const UiMotion := preload("res://src/ui/fx/ui_motion.gd")

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
@export var selection: HotbarSelectionComponent

var _keys: Array[Label] = []
var _names: Array[Label] = []
var _counts: Array[Label] = []
var _icons: Array[TextureRect] = []
var _held_label: Label
var _selected_index: int = 0


func _ready() -> void:
	_collect_slots()

	if inventory == null:
		inventory = _find_inventory()
	if inventory == null:
		push_warning("HotbarHUD: InventoryComponent tidak ditemukan.")
		return

	if not inventory.slot_changed.is_connected(_on_slot_changed):
		inventory.slot_changed.connect(_on_slot_changed)
	if selection == null and inventory.get_parent() != null:
		selection = inventory.get_parent().get_node_or_null("HotbarSelectionComponent") as HotbarSelectionComponent
	if selection != null and not selection.selected_changed.is_connected(_on_selection_changed):
		selection.selected_changed.connect(_on_selection_changed)
	refresh()


func refresh() -> void:
	for index in _keys.size():
		_refresh_slot(index)
	_refresh_selection()


## Mission 10 Phase 3: sorot slot terpilih + label nama/jumlah item di atas.
func _refresh_selection() -> void:
	if selection == null and inventory != null:
		set_selection(inventory.get_parent().get_node_or_null("HotbarSelectionComponent") as HotbarSelectionComponent)
	if _held_label == null:
		_build_held_label()
	for index in _icons.size():
		var selected := selection != null and selection.selected_index == index
		_icons[index].modulate = Color(1, 1, 1, 1) if selected else Color(1, 1, 1, 0.55)
	var text := ""
	if selection != null:
		var stack := selection.get_held_stack()
		if stack != null and stack.item != null:
			text = "%s x%d" % [stack.item.display_name, stack.count]
	if _held_label != null:
		_held_label.text = text
		_held_label.visible = not text.is_empty()
		_selected_index = selection.selected_index if selection != null else 0


func set_selection(value: HotbarSelectionComponent) -> void:
	if value == null:
		return
	selection = value
	if not selection.selected_changed.is_connected(_on_selection_changed):
		selection.selected_changed.connect(_on_selection_changed)
	_refresh_selection()


func _on_selection_changed(_index: int, _stack: ItemStack) -> void:
	_refresh_selection()


func get_held_label_text() -> String:
	return "" if _held_label == null else _held_label.text


func get_selected_index() -> int:
	return _selected_index


func _build_held_label() -> void:
	_held_label = Label.new()
	_held_label.name = "HeldLabel"
	_held_label.add_theme_font_size_override("font_size", 10)
	_held_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7, 1.0))
	_held_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_held_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_held_label.offset_top = -16.0
	_held_label.offset_bottom = -2.0
	_held_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_held_label)


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
	if index < 0 or index >= SLOT_PATHS.size():
		return
	UiMotion.pop(get_node_or_null(SLOT_PATHS[index]) as Control)


func _find_inventory() -> InventoryComponent:
	var tree := get_tree()
	if tree == null:
		return null
	var candidate := tree.get_first_node_in_group(PLAYER_GROUP)
	if candidate == null:
		return null
	return candidate.get_node_or_null(INVENTORY_NAME) as InventoryComponent

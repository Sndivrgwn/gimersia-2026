class_name BagSlot
extends PanelContainer

## Satu kotak slot tas di BagPanel.
##
## Slot ini tidak menyimpan state: semua data dibaca dari InventoryComponent.
## Satu-satunya aksi ke gameplay adalah `move_slot()` (drag-drop) dan
## `use_slot()` (klik kanan). Slot peralatan tidak memakai node ini, jadi
## Weapon/Tool/Armor tidak bisa di-drag dan tidak menerima drop.

const DRAG_TYPE := &"bag_slot"
const TOOLTIP_SCENE: PackedScene = preload("res://src/ui/panels/inventory/item_tooltip.tscn")

## Indeks slot tas (0..bag_size-1).
@export var slot_index: int = 0
## Nomor tombol hotbar (1-5); 0 berarti bukan slot hotbar.
@export var hotbar_number: int = 0

## Gaya panel saat kursor di atas slot (diatur di bag_slot.tscn).
@export var hover_style: StyleBox

## Diisi BagPanel saat build; null berarti slot belum terikat.
var inventory: InventoryComponent

var _normal_style: StyleBox

@onready var _key: Label = $VBox/Top/Key
@onready var _count: Label = $VBox/Top/Count
@onready var _icon: TextureRect = $VBox/Icon
@onready var _dummy: Label = $VBox/DummyIcon


func _ready() -> void:
	# Gaya slot (9-slice normal/hover) diatur di bag_slot.tscn.
	_normal_style = get_theme_stylebox(&"panel")
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	_key.text = str(hotbar_number) if hotbar_number > 0 else ""
	refresh()


func _set_hover(hovered: bool) -> void:
	if hover_style == null or _normal_style == null:
		return
	add_theme_stylebox_override(&"panel", hover_style if hovered else _normal_style)


## Tampilkan isi slot sesuai state InventoryComponent saat ini.
func refresh() -> void:
	var item := get_item()
	var count := get_count()
	var empty := item == null or count <= 0

	_count.text = "" if empty else "x%d" % count
	var icon: Texture2D = null if empty else item.get_icon()
	_icon.texture = icon
	_icon.visible = icon != null
	# Nama item tidak lagi tampil di slot; ikon dummy huruf + tooltip.
	_dummy.visible = not empty and icon == null
	_dummy.text = "" if empty or icon != null else item.display_name.left(1).to_upper()
	tooltip_text = "" if empty else describe_item(item)


## Slot di luar kapasitas inventory tidak punya isi.
func is_available() -> bool:
	return inventory != null and slot_index < inventory.get_capacity()


func get_item() -> ItemDefinition:
	if not is_available():
		return null
	return inventory.get_slot_item(slot_index)


func get_count() -> int:
	if not is_available():
		return 0
	return inventory.get_slot_count(slot_index)


# --- Teks (dipakai tes) -----------------------------------------------------

func get_key_text() -> String:
	return _key.text


## Nama item hanya ada di tooltip; slot tidak menampilkan teks deskripsi.
func get_label_text() -> String:
	return ""


func get_count_text() -> String:
	return _count.text


# --- Tooltip ----------------------------------------------------------------

## Tooltip kustom: Godot hanya menampilkannya bila `tooltip_text` tidak kosong
## (diatur di refresh()). Isinya dibangun dari item di slot ini.
func _make_custom_tooltip(_for_text: String) -> Object:
	var item := get_item()
	if item == null:
		return null
	var tip := TOOLTIP_SCENE.instantiate() as ItemTooltip
	tip.show_item(item, get_count())
	return tip


## Nama, deskripsi, lalu satu baris ringkasan efek dari ItemDefinition.
static func describe_item(item: ItemDefinition) -> String:
	if item == null:
		return ""

	var lines := PackedStringArray()
	lines.append(item.display_name)
	if not item.description.is_empty():
		lines.append(item.description)

	var effect := describe_effect(item)
	if not effect.is_empty():
		lines.append(effect)
	return "\n".join(lines)


## Ringkasan efek satu baris: konsumsi, senjata, atau armor.
static func describe_effect(item: ItemDefinition) -> String:
	return ", ".join(effect_parts(item))


## Potongan efek terpisah (dipakai tooltip, satu potongan per baris).
static func effect_parts(item: ItemDefinition) -> PackedStringArray:
	return ItemTooltip.effect_parts(item)


# --- Drag & drop ------------------------------------------------------------

func _get_drag_data(_at_position: Vector2) -> Variant:
	var item := get_item()
	var count := get_count()
	if not is_available() or item == null or count <= 0:
		return null

	_show_drag_preview(item, count)
	return {
		"type": DRAG_TYPE,
		"index": slot_index,
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not is_available() or typeof(data) != TYPE_DICTIONARY:
		return false
	if data.get("type") != DRAG_TYPE:
		return false

	var source := int(data.get("index", -1))
	if source < 0 or source == slot_index:
		return false
	return source < inventory.get_capacity()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(Vector2.ZERO, data):
		return
	inventory.move_slot(int(data.get("index", -1)), slot_index)


## Pratinjau kecil yang mengikuti kursor saat drag.
func _show_drag_preview(item: ItemDefinition, count: int) -> void:
	if not is_visible_in_tree():
		return

	var preview := PanelContainer.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.custom_minimum_size = Vector2(120.0, 30.0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.968627, 0.945098, 0.898039, 1.0)
	style.border_color = Color(0.243137, 0.152941, 0.101961, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8.0)
	preview.add_theme_stylebox_override(&"panel", style)

	var label := Label.new()
	label.text = "%s x%d" % [item.display_name, count]
	label.add_theme_font_size_override(&"font_size", 12)
	label.add_theme_color_override(&"font_color", Color(0.243137, 0.152941, 0.101961, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(label)

	set_drag_preview(preview)


# --- Mouse ------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed:
		return
	# Shift + klik kiri = pecah tumpukan ke slot kosong pertama (Fase 4A).
	if mouse.button_index == MOUSE_BUTTON_LEFT and mouse.shift_pressed:
		accept_event()
		if inventory != null:
			inventory.split_slot(slot_index)
		return
	if mouse.button_index != MOUSE_BUTTON_RIGHT:
		return

	# Klik kanan = pakai item. Telan event supaya tidak sampai ke gameplay.
	accept_event()
	if is_available():
		inventory.use_slot(slot_index)

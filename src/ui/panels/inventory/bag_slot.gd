class_name BagSlot
extends PanelContainer

## Satu kotak slot tas di BagPanel.
##
## Slot ini tidak menyimpan state: semua data dibaca dari InventoryComponent.
## Satu-satunya aksi ke gameplay adalah `move_slot()` (drag-drop) dan
## `use_slot()` (klik kanan). Slot peralatan tidak memakai node ini, jadi
## Weapon/Tool/Armor tidak bisa di-drag dan tidak menerima drop.

const DRAG_TYPE := &"bag_slot"

## Indeks slot tas (0..bag_size-1).
@export var slot_index: int = 0
## Nomor tombol hotbar (1-5); 0 berarti bukan slot hotbar.
@export var hotbar_number: int = 0

## Diisi BagPanel saat build; null berarti slot belum terikat.
var inventory: InventoryComponent

@onready var _key: Label = $VBox/Top/Key
@onready var _count: Label = $VBox/Top/Count
@onready var _icon: TextureRect = $VBox/Icon
@onready var _name: Label = $VBox/Name


func _ready() -> void:
	_key.text = str(hotbar_number) if hotbar_number > 0 else ""
	refresh()


## Tampilkan isi slot sesuai state InventoryComponent saat ini.
func refresh() -> void:
	var item := get_item()
	var count := get_count()
	var empty := item == null or count <= 0

	_name.text = "" if empty else item.display_name
	_count.text = "" if empty else "x%d" % count
	var icon: Texture2D = null if empty else item.get_icon()
	_icon.texture = icon
	_icon.visible = icon != null
	tooltip_text = "" if empty else describe_item(item)


func get_item() -> ItemDefinition:
	if inventory == null:
		return null
	return inventory.get_slot_item(slot_index)


func get_count() -> int:
	if inventory == null:
		return 0
	return inventory.get_slot_count(slot_index)


# --- Teks (dipakai tes) -----------------------------------------------------

func get_key_text() -> String:
	return _key.text


func get_label_text() -> String:
	return _name.text


func get_count_text() -> String:
	return _count.text


# --- Tooltip ----------------------------------------------------------------

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
	if item == null:
		return ""

	var parts := PackedStringArray()
	var effect := item.consume_effect
	if effect != null:
		_add_amount(parts, "Hunger", effect.hunger)
		_add_amount(parts, "Thirst", effect.thirst)
		_add_amount(parts, "Fatigue", effect.fatigue)
		_add_amount(parts, "HP", effect.hp)
		if effect.regen_hp_per_second > 0.0:
			parts.append(
				"Regen +%.1f HP/dtk selama %d dtk"
				% [effect.regen_hp_per_second, int(roundf(effect.regen_duration))]
			)

	if item.weapon_damage > 0.0:
		parts.append("Damage %.0f, jangkauan %.0f px" % [item.weapon_damage, item.weapon_range])
	if item.armor_damage_reduction > 0.0:
		parts.append("-%.0f%% damage diterima" % (item.armor_damage_reduction * 100.0))
	if item.armor_max_hp_bonus > 0.0:
		parts.append("+%.0f max HP" % item.armor_max_hp_bonus)

	return ", ".join(parts)


static func _add_amount(parts: PackedStringArray, label: String, amount: float) -> void:
	if is_zero_approx(amount):
		return
	var sign_text := "+" if amount > 0.0 else ""
	parts.append("%s %s%.0f" % [label, sign_text, amount])


# --- Drag & drop ------------------------------------------------------------

func _get_drag_data(_at_position: Vector2) -> Variant:
	var item := get_item()
	var count := get_count()
	if inventory == null or item == null or count <= 0:
		return null

	_show_drag_preview(item, count)
	return {
		"type": DRAG_TYPE,
		"index": slot_index,
	}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if inventory == null or typeof(data) != TYPE_DICTIONARY:
		return false
	if data.get("type") != DRAG_TYPE:
		return false

	var source := int(data.get("index", -1))
	if source < 0 or source == slot_index:
		return false
	return source < inventory.get_capacity() and slot_index < inventory.get_capacity()


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
	preview.custom_minimum_size = Vector2(120.0, 28.0)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.1, 0.9)
	style.border_color = Color(0.85, 0.78, 0.55, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	preview.add_theme_stylebox_override(&"panel", style)

	var label := Label.new()
	label.text = "%s x%d" % [item.display_name, count]
	label.add_theme_font_size_override(&"font_size", 12)
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
	if inventory != null:
		inventory.use_slot(slot_index)

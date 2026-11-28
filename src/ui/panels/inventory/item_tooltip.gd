class_name ItemTooltip
extends PanelContainer

## Tooltip item (dipakai BagSlot dan CraftingRow lewat `_make_custom_tooltip`).
##
## Tampilan (ukuran, font, warna, gaya panel) diatur di item_tooltip.tscn.
## Script ini mengisi ikon, nama, kategori/status, berat, deskripsi, dan efek stat.

const EFFECT_FONT: FontFile = preload("res://assets/fonts/nunito/Nunito-Bold.ttf")

@onready var _icon: TextureRect = $VBox/Header/IconBox/Icon
@onready var _dummy_icon: Label = $VBox/Header/IconBox/DummyIcon
@onready var _name: Label = $VBox/Header/TitleCol/TopRow/Name
@onready var _count: Label = $VBox/Header/TitleCol/TopRow/Count
@onready var _category: Label = $VBox/Header/TitleCol/MetaRow/Category
@onready var _weight: Label = $VBox/Header/TitleCol/MetaRow/Weight
@onready var _divider: ColorRect = $VBox/Divider
@onready var _desc: Label = $VBox/Desc
@onready var _effects: VBoxContainer = $VBox/Effects

var _item: ItemDefinition
var _amount: int = 0


## Panggil sebelum node masuk tree. `amount` <= 0 menyembunyikan jumlah.
func show_item(item: ItemDefinition, amount: int = 0) -> void:
	_item = item
	_amount = amount
	if is_node_ready():
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if _item == null:
		return

	_name.text = _item.display_name
	_count.text = "x %d" % _amount if _amount > 0 else ""
	_count.visible = _amount > 0

	_category.text = category_label(_item.category)
	_weight.text = "%.1f kg" % _item.get_weight()

	var tex := _item.get_icon()
	_icon.texture = tex
	_icon.visible = tex != null
	_dummy_icon.visible = tex == null
	_dummy_icon.text = _item.display_name.left(1).to_upper() if tex == null else ""

	_desc.text = _item.description
	_desc.visible = not _item.description.is_empty()

	for child in _effects.get_children():
		_effects.remove_child(child)
		child.free()

	for part in effect_parts(_item):
		var line := Label.new()
		line.text = part
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(232, 0)
		line.add_theme_font_override(&"font", EFFECT_FONT)
		line.add_theme_font_size_override(&"font_size", 13)
		line.add_theme_color_override(&"font_color", _effect_color(part))
		_effects.add_child(line)
	_effects.visible = _effects.get_child_count() > 0
	_divider.visible = _desc.visible or _effects.visible


static func category_label(category: int) -> String:
	match category:
		ItemDefinition.Category.RESOURCE:
			return "Bahan Baku"
		ItemDefinition.Category.CONSUMABLE:
			return "Konsumsi"
		ItemDefinition.Category.WEAPON:
			return "Senjata"
		ItemDefinition.Category.TOOL:
			return "Alat"
		ItemDefinition.Category.ARMOR:
			return "Pelindung"
		ItemDefinition.Category.SPECIAL:
			return "Khusus"
		_:
			return ""


## Hijau untuk efek positif, merah untuk negatif, netral untuk sisanya.
func _effect_color(part: String) -> Color:
	if part.contains(" -") and not part.begins_with("-"):
		return Color(0.98, 0.56, 0.46)
	if part.contains(" +") or part.begins_with("+") or part.begins_with("-") or part.begins_with("Damage "):
		return Color(0.62, 0.89, 0.52)
	return Color(0.969, 0.945, 0.898)


## Potongan efek terpisah (dipakai tooltip dan BagSlot, satu potongan per baris).
static func effect_parts(item: ItemDefinition) -> PackedStringArray:
	var parts := PackedStringArray()
	if item == null:
		return parts
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

	return parts


static func _add_amount(parts: PackedStringArray, label: String, amount: float) -> void:
	if is_zero_approx(amount):
		return
	var sign_text := "+" if amount > 0.0 else ""
	parts.append("%s %s%.0f" % [label, sign_text, amount])

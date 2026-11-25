class_name ItemTooltip
extends PanelContainer

## Tooltip item (dipakai BagSlot dan CraftingRow lewat `_make_custom_tooltip`).
##
## Tampilan (ukuran, font, warna, gaya panel) diatur di item_tooltip.tscn, jadi
## bisa diubah lewat editor. Script ini hanya mengisi data dari ItemDefinition.

@onready var _icon: TextureRect = $Margin/VBox/Header/Icon
@onready var _name: Label = $Margin/VBox/Header/Name
@onready var _count: Label = $Margin/VBox/Header/Count
@onready var _desc: Label = $Margin/VBox/Desc
@onready var _effects: VBoxContainer = $Margin/VBox/Effects

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
	_count.text = "x%d" % _amount if _amount > 0 else ""
	_count.visible = _amount > 0

	_icon.texture = _item.icon
	_icon.visible = _icon.texture != null

	_desc.text = _item.description
	_desc.visible = not _item.description.is_empty()

	for child in _effects.get_children():
		_effects.remove_child(child)
		child.free()

	for part in BagSlot.effect_parts(_item):
		var line := Label.new()
		line.text = part
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(200, 0)
		line.theme_type_variation = &"TooltipEffectLabel"
		line.add_theme_font_size_override(&"font_size", 14)
		line.add_theme_color_override(&"font_color", _effect_color(part))
		_effects.add_child(line)
	_effects.visible = _effects.get_child_count() > 0


## Hijau untuk efek positif, merah untuk negatif, netral untuk sisanya.
func _effect_color(part: String) -> Color:
	if part.contains(" -") and not part.begins_with("-"):
		return Color(0.95, 0.55, 0.45)
	if part.contains(" +") or part.begins_with("+") or part.begins_with("-"):
		return Color(0.60, 0.85, 0.50)
	return Color(0.9686, 0.9451, 0.898)

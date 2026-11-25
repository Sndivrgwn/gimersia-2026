class_name IngredientChip
extends VBoxContainer

## Satu kolom bahan di kartu resep: ikon kecil + lencana "punya/butuh".
## Tampilan (ukuran, font, gaya lencana) diatur di ingredient_chip.tscn dan
## theme; script ini hanya mengisi data dan memilih varian hijau/merah.

const CHIP_GOOD := &"ChipGood"
const CHIP_BAD := &"ChipBad"

@onready var _icon: TextureRect = $Icon
@onready var _chip: PanelContainer = $Chip
@onready var _label: Label = $Chip/Label


func clear() -> void:
	_label.text = ""
	_chip.visible = false
	_icon.texture = null
	_icon.visible = false


## Format "punya/butuh" tanpa nama bahan: tes membaca akhiran "3/3".
func show_amount(item: ItemDefinition, have: int, need: int) -> void:
	var missing := have < need
	_label.text = "%d/%d" % [have, need]
	_chip.visible = true
	_chip.theme_type_variation = CHIP_BAD if missing else CHIP_GOOD
	_icon.texture = item.icon
	_icon.visible = _icon.texture != null


func get_text() -> String:
	return _label.text

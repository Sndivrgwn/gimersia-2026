class_name MenuKit
extends RefCounted

## Pembangun UI bersama untuk menu yang dibuat lewat kode.
## Semua visual memakai tekstur dari assets/textures/ui lewat ui_theme_tex.tres,
## tanpa ColorRect / StyleBoxFlat / shader.

const THEME: Theme = preload("res://src/ui/theme/ui_theme_tex.tres")
const BACKDROP: Texture2D = preload("res://assets/textures/ui/01_palette/palette_backdrop.png")


## Lapisan peredup layar penuh (tekstur palette_backdrop, diatur lewat alpha).
static func dim(alpha: float = 0.55) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = "Dim"
	rect.texture = BACKDROP
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	rect.modulate.a = alpha
	return rect


## Root Control layar penuh yang membawa theme.
static func root(parent: Node, alpha: float = 0.55) -> Control:
	var ctrl := Control.new()
	ctrl.name = "Root"
	ctrl.theme = THEME
	ctrl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(ctrl)
	ctrl.add_child(dim(alpha))
	return ctrl


## Kartu di tengah layar. Mengembalikan kolom isi (VBoxContainer).
static func card(parent: Control, min_size: Vector2, variation: StringName = &"PanelCard") -> VBoxContainer:
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Card"
	panel.theme_type_variation = variation
	panel.custom_minimum_size = min_size
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 14)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(column)
	return column


static func title(parent: Control, text: String, variation: StringName = &"CardTitleLabel") -> Label:
	var label := Label.new()
	label.name = "Title"
	label.text = text
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


static func body(parent: Control, text: String = "") -> Label:
	var label := Label.new()
	label.name = "Detail"
	label.text = text
	label.theme_type_variation = &"BodyLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


static func button(parent: Control, text: String, variation: StringName = &"SecondaryButton") -> Button:
	var btn := Button.new()
	btn.text = text
	btn.theme_type_variation = variation
	btn.custom_minimum_size = Vector2(0, 64)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(btn)
	return btn

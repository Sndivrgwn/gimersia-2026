class_name BaseHUD
extends CanvasLayer

## Hint lokasi base (read-only). Tersembunyi setelah base ditentukan.

const HINT := "Pasang Camp"
const PREVIEW_OFFER := "Pasang Camp · Esc: Batal"

@export var anchor: CampAnchor
@export var placement: BasePlacementController

var _panel: PanelContainer
var _label: Label
var _text: String = ""


func _ready() -> void:
	layer = 10
	_build()
	refresh()


func _process(_delta: float) -> void:
	refresh()


func get_text() -> String:
	return _text


func is_showing() -> bool:
	return _panel != null and _panel.visible


## Petunjuk base hanyalah teks HUD, bukan panel modal: jangan blokir menu Jeda.
func blocks_pause() -> bool:
	return false


func refresh() -> void:
	if anchor == null:
		anchor = CampAnchor.find_anchor(self)
	if placement == null:
		placement = _find_placement()
	var founded := anchor != null and anchor.is_founded()
	var preview := placement != null and placement.is_preview_active()
	if founded and not preview:
		_set_text("")
		return
	if preview:
		var reason := String(placement.get_result().get("reason", ""))
		_set_text("%s\n%s" % [reason, PREVIEW_OFFER] if not reason.is_empty() else PREVIEW_OFFER)
		return
	_set_text(HINT)


func _find_placement() -> BasePlacementController:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(BasePlacementController.GROUP) as BasePlacementController


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.name = "BasePanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.offset_left = -372.0
	_panel.offset_right = -20.0
	_panel.offset_top = 138.0
	_panel.offset_bottom = 198.0
	_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(hbox)

	var key_badge := PanelContainer.new()
	key_badge.custom_minimum_size = Vector2(40.0, 40.0)
	key_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	key_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_badge.add_theme_stylebox_override("panel", _key_style())
	hbox.add_child(key_badge)

	var key_label := Label.new()
	key_label.text = "B"
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key_label.add_theme_font_size_override("font_size", 17)
	key_label.add_theme_color_override("font_color", Color(0.2, 0.12, 0.07, 1.0))
	key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_badge.add_child(key_label)

	_label = Label.new()
	_label.name = "Hint"
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(240.0, 0.0)
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.92, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.14, 0.09, 0.05, 0.95))
	_label.add_theme_constant_override("outline_size", 3)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(_label)


func _panel_style() -> StyleBox:
	var tex_path := "res://assets/textures/ui/02_panel/panel_walnut_stitched.png"
	if ResourceLoader.exists(tex_path):
		var tex := load(tex_path) as Texture2D
		if tex != null:
			var box := StyleBoxTexture.new()
			box.texture = tex
			box.texture_margin_left = 24.0
			box.texture_margin_top = 24.0
			box.texture_margin_right = 24.0
			box.texture_margin_bottom = 24.0
			box.content_margin_left = 22.0
			box.content_margin_top = 16.0
			box.content_margin_right = 22.0
			box.content_margin_bottom = 16.0
			return box
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.11, 0.08, 0.88)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.78, 0.55, 0.5)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12.0)
	return style


func _key_style() -> StyleBox:
	var tex_path := "res://assets/textures/ui/05_slot/slot_item.png"
	if ResourceLoader.exists(tex_path):
		var tex := load(tex_path) as Texture2D
		if tex != null:
			var box := StyleBoxTexture.new()
			box.texture = tex
			box.texture_margin_left = 14.0
			box.texture_margin_top = 14.0
			box.texture_margin_right = 14.0
			box.texture_margin_bottom = 14.0
			box.content_margin_left = 10.0
			box.content_margin_top = 6.0
			box.content_margin_right = 10.0
			box.content_margin_bottom = 6.0
			return box
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.93, 0.86, 1.0)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(4.0)
	return style


func _set_text(value: String) -> void:
	_text = value
	if _label == null:
		return
	_label.text = value
	if _panel != null:
		_panel.visible = not value.is_empty()

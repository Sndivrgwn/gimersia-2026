class_name UiSkin
extends RefCounted

## Tema UI dari aset. Tanpa art, `theme()` mengembalikan null dan `apply()`
## tidak mengubah apa pun (tampilan lama tetap sama persis).

const BACKGROUND_NAME := "SkinBackground"
const LOGO_NAME := "SkinLogo"

static var _theme: Theme
static var _built: bool = false


## Buang tema (dipakai setelah Assets.reload_assets()).
static func reset() -> void:
	_built = false
	_theme = null


## True bila ada setidaknya satu bagian tema yang berasal dari art.
static func has_skin() -> bool:
	return theme() != null


static func theme() -> Theme:
	if not _built:
		_built = true
		_theme = _build()
	return _theme


## Pasang tema ke satu root Control; tanpa art tidak melakukan apa pun.
static func apply(root: Control) -> void:
	if root == null:
		return
	var skin := theme()
	if skin == null:
		return
	root.theme = skin


## Pasang ke semua root UI di bawah node scene (HUD CanvasLayer memakai
## Control anak pertamanya). Idempotent dan aman tanpa art.
static func apply_all(node: Node) -> void:
	if node == null:
		return
	if node is CanvasLayer:
		for child in node.get_children():
			if child is Control:
				apply(child as Control)
				return
		return
	if node is Control:
		apply(node as Control)
		return
	for child in node.get_children():
		if child is Control or child is CanvasLayer:
			apply_all(child)


## Latar layar penuh di belakang root Control; null bila art tidak ada.
static func add_background(root: Control, key: StringName) -> TextureRect:
	var texture := Assets.ui_texture(key)
	if texture == null or root == null:
		return null
	var rect := TextureRect.new()
	rect.name = BACKGROUND_NAME
	rect.texture = texture
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.move_child(rect, 0)
	return rect


## Varian untuk layar CanvasLayer (DeathScreen, GameOverScreen, EndgameHUD).
static func add_canvas_background(layer: CanvasLayer, key: StringName) -> Control:
	var texture := Assets.ui_texture(key)
	if texture == null or layer == null:
		return null
	var holder := Control.new()
	holder.name = BACKGROUND_NAME
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(holder)
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.move_child(holder, 0)
	return holder


## Logo di tengah atas menu; null bila art tidak ada.
static func add_logo(root: Control) -> TextureRect:
	var texture := Assets.ui_texture(&"ui_logo")
	if texture == null or root == null:
		return null
	var rect := TextureRect.new()
	rect.name = LOGO_NAME
	rect.texture = texture
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rect)
	rect.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	rect.position = Vector2(-240.0, 24.0)
	rect.size = Vector2(480.0, 160.0)
	return rect


# --- Internal ---------------------------------------------------------------

static func _build() -> Theme:
	var any := false
	var skin := Theme.new()

	var main_font := Assets.font(&"ui_font_main")
	if main_font != null:
		skin.default_font = main_font
		any = true
	var bold_font := Assets.font(&"ui_font_bold")
	if bold_font != null:
		skin.set_font(&"font", &"BoldLabel", bold_font)
		any = true

	any = _add_panel_style(skin, &"ui_panel", &"PanelContainer") or any
	any = _add_panel_style(skin, &"ui_panel", &"Panel") or any
	any = _add_button_style(skin, &"ui_button_normal", &"normal") or any
	any = _add_button_style(skin, &"ui_button_hover", &"hover") or any
	any = _add_button_style(skin, &"ui_button_pressed", &"pressed") or any
	any = _add_button_style(skin, &"ui_button_disabled", &"disabled") or any

	var bar_bg := _stylebox(&"ui_bar_bg")
	if bar_bg != null:
		skin.set_stylebox(&"background", &"ProgressBar", bar_bg)
		any = true

	# Isi bar per kebutuhan disimpan dengan nama sendiri supaya HUD bisa memilih
	# tanpa mengganggu override StyleBoxFlat yang sudah ada.
	for slug in ["hunger", "thirst", "fatigue", "hp"]:
		var fill := _stylebox(StringName("ui_bar_fill_" + slug))
		if fill != null:
			skin.set_stylebox(StringName("fill_" + slug), &"ProgressBar", fill)
			any = true

	return skin if any else null


static func _add_panel_style(skin: Theme, key: StringName, type_name: StringName) -> bool:
	var style := _stylebox(key)
	if style == null:
		return false
	skin.set_stylebox(&"panel", type_name, style)
	return true


static func _add_button_style(skin: Theme, key: StringName, state: StringName) -> bool:
	var style := _stylebox(key)
	if style == null:
		return false
	skin.set_stylebox(state, &"Button", style)
	return true


static func _stylebox(key: StringName) -> StyleBoxTexture:
	var texture := Assets.ui_texture(key)
	if texture == null:
		return null
	var box := StyleBoxTexture.new()
	box.texture = texture
	var slot := Assets.registry().get_slot(key)
	if slot != null:
		var margins := slot.nine_slice
		box.texture_margin_left = margins.x
		box.texture_margin_top = margins.y
		box.texture_margin_right = margins.z
		box.texture_margin_bottom = margins.w
		if margins != Vector4.ZERO:
			box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
			box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return box

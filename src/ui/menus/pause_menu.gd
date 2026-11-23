class_name PauseMenu
extends CanvasLayer

## Mission 7: pause dengan guard. Panel sendiri boleh _unhandled_input untuk toggle.

signal resumed
signal settings_requested
signal help_requested
signal main_menu_requested

@export var clock: Node
## Node yang menahan pause saat sedang tampil (HUD/panel).
var blockers: Array[Node] = []

const TITLE_TEXT := "JEDA"
const HINT_TEXT := "Esc atau P untuk lanjut"
const PANEL_SIZE := Vector2(320.0, 260.0)
const PANEL_COLOR := Color(0.10, 0.12, 0.10, 0.96)
const DIM_COLOR := Color(0.0, 0.0, 0.0, 0.55)

var _previous_scale: float = 1.0
var _paused_by_menu: bool = false
var _panel: Control
var _settings_panel: Node
var _help_panel: Node


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	InputSetup.ensure_actions()
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	if _panel == null:
		_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputSetup.PAUSE_TOGGLE):
		toggle()
		get_viewport().set_input_as_handled()
		return
	if is_open() and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


# --- UI (Mission 9: menu jeda yang benar-benar terlihat) --------------------

## Dibangun runtime supaya PauseMenu tetap boleh dipasang sebagai CanvasLayer
## kosong di scene (island.tscn) dan tidak butuh aset biner.
func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = DIM_COLOR
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = PANEL_SIZE
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = Color(0.85, 0.78, 0.5, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16.0)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	_panel = panel

	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = TITLE_TEXT
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)

	_add_button(box, "Lanjutkan", Callable(self, &"close"))
	_add_button(box, "Pengaturan", Callable(self, &"_open_settings"))
	_add_button(box, "Bantuan", Callable(self, &"_open_help"))
	_add_button(box, "Menu Utama", Callable(self, &"request_main_menu"))

	var hint := Label.new()
	hint.text = HINT_TEXT
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.75, 0.78, 0.72, 1.0))
	box.add_child(hint)


func _add_button(parent: Node, text: String, handler: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 14)
	button.pressed.connect(handler)
	parent.add_child(button)
	return button


func get_panel() -> Control:
	return _panel


func _open_settings() -> void:
	settings_requested.emit()
	if _settings_panel == null or not is_instance_valid(_settings_panel):
		_settings_panel = get_node_or_null("SettingsPanel")
	if _settings_panel != null and _settings_panel.has_method(&"open"):
		_settings_panel.open()


func _open_help() -> void:
	help_requested.emit()
	if _help_panel == null or not is_instance_valid(_help_panel):
		_help_panel = get_node_or_null("HelpPanel")
	if _help_panel != null and _help_panel.has_method(&"open"):
		_help_panel.open()


func _close_sub_panels() -> void:
	for node in [_settings_panel, _help_panel]:
		if node != null and is_instance_valid(node) and node.has_method(&"close"):
			node.close()


func can_open() -> bool:
	if _paused_by_menu:
		return true
	for node in blockers:
		if _is_blocking(node):
			return false
	return true


func _is_blocking(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.has_method(&"is_showing") and node.is_showing():
		return true
	if node.has_method(&"is_open") and node.is_open():
		return true
	return false


## Mission 9: beku lewat FreezeController bila scene memasangnya; kalau tidak,
## jalur lama (paused + skala 0) tetap dipakai.
func _freezer() -> FreezeController:
	return FreezeController.find_controller(self)


func open() -> bool:
	if _paused_by_menu or not can_open():
		return false
	_paused_by_menu = true
	var freezer := _freezer()
	if freezer != null:
		freezer.request(FreezeController.REASON_PAUSE)
		_previous_scale = freezer.get_previous_time_scale()
	else:
		_previous_scale = 1.0
		if clock != null and clock.has_method(&"get_time_scale"):
			_previous_scale = clock.get_time_scale()
		get_tree().paused = true
		if clock != null and clock.has_method(&"set_time_scale"):
			clock.set_time_scale(0.0)
	visible = true
	return true


func close() -> void:
	if not _paused_by_menu:
		visible = false
		return
	_paused_by_menu = false
	var freezer := _freezer()
	if freezer != null:
		freezer.release(FreezeController.REASON_PAUSE)
	else:
		get_tree().paused = false
		if clock != null and clock.has_method(&"set_time_scale"):
			clock.set_time_scale(_previous_scale)
	_close_sub_panels()
	visible = false
	resumed.emit()


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func is_open() -> bool:
	return _paused_by_menu


func get_previous_time_scale() -> float:
	return _previous_scale


func request_settings() -> void:
	settings_requested.emit()


func request_help() -> void:
	help_requested.emit()


func request_main_menu() -> void:
	close()
	main_menu_requested.emit()

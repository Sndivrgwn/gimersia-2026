class_name SettingsPanel
extends Control

## Mission 7: panel pengaturan yang dipakai PauseMenu dan MainMenu.

signal closed

const LABEL_INTENSITY := "Intensitas efek"
const LABEL_SHAKE := "Guncangan layar"
const LABEL_HINTS := "Tampilkan petunjuk"
const LABEL_FULLSCREEN := "Layar penuh"

var service: SettingsService
var _slider: HSlider
var _shake: CheckBox
var _hints: CheckBox
var _fullscreen: CheckBox
var _building: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	if has_node("Ui"):
		_bind_scene_ui()
	else:
		_build()


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


const UiMotion := preload("res://src/ui/fx/ui_motion.gd")

var _is_open: bool = false


func setup(p_service: SettingsService) -> void:
	service = p_service
	refresh()


func open() -> void:
	_is_open = true
	UiMotion.pop_in(self)
	refresh()
	if _slider != null:
		_slider.grab_focus()


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	closed.emit()
	UiMotion.pop_out(self)


func is_open() -> bool:
	return _is_open


func refresh() -> void:
	if not _building:
		return
	if service == null:
		service = SettingsService.find_service(self)
	if service == null:
		return
	if _slider != null:
		_slider.value = service.get_juice_intensity()
	if _shake != null:
		_shake.button_pressed = service.is_screenshake_enabled()
	if _hints != null:
		_hints.button_pressed = service.are_hints_enabled()
	if _fullscreen != null:
		_fullscreen.button_pressed = service.is_fullscreen()


func get_slider() -> HSlider:
	return _slider


func get_screenshake_toggle() -> CheckBox:
	return _shake


func get_hints_toggle() -> CheckBox:
	return _hints


func get_fullscreen_toggle() -> CheckBox:
	return _fullscreen


func _bind_scene_ui() -> void:
	_building = true
	var ui := get_node("Ui")
	_slider = ui.get_node_or_null("%Slider") as HSlider
	_shake = ui.get_node_or_null("%ShakeCheck") as CheckBox
	_hints = ui.get_node_or_null("%HintsCheck") as CheckBox
	_fullscreen = ui.get_node_or_null("%FullscreenCheck") as CheckBox
	if _fullscreen == null:
		_fullscreen = ui.get_node_or_null("%Fullscreen") as CheckBox
	var back := ui.get_node_or_null("%BackButton") as Button
	if _slider != null:
		_slider.min_value = SettingsService.JUICE_MIN
		_slider.max_value = SettingsService.JUICE_MAX
		_slider.value_changed.connect(_on_intensity_changed)
	if _shake != null:
		_shake.toggled.connect(_on_shake_toggled)
	if _hints != null:
		_hints.toggled.connect(_on_hints_toggled)
	if _fullscreen != null:
		_fullscreen.toggled.connect(_on_fullscreen_toggled)
	if back != null:
		back.pressed.connect(close)


func _build() -> void:
	_building = true
	var panel := PanelContainer.new()
	panel.name = "Card"
	panel.custom_minimum_size = Vector2(360.0, 0.0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.10, 0.96)
	style.border_color = Color(0.85, 0.78, 0.5, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16.0)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var box := VBoxContainer.new()
	box.name = "Rows"
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Pengaturan"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)

	var intensity_label := Label.new()
	intensity_label.text = LABEL_INTENSITY
	box.add_child(intensity_label)
	_slider = HSlider.new()
	_slider.min_value = SettingsService.JUICE_MIN
	_slider.max_value = SettingsService.JUICE_MAX
	_slider.step = 0.1
	_slider.value = SettingsService.DEFAULTS[&"juice_intensity"]
	_slider.value_changed.connect(_on_intensity_changed)
	box.add_child(_slider)

	_shake = CheckBox.new()
	_shake.text = LABEL_SHAKE
	_shake.button_pressed = true
	_shake.toggled.connect(_on_shake_toggled)
	box.add_child(_shake)

	_hints = CheckBox.new()
	_hints.text = LABEL_HINTS
	_hints.button_pressed = true
	_hints.toggled.connect(_on_hints_toggled)
	box.add_child(_hints)

	_fullscreen = CheckBox.new()
	_fullscreen.name = "Fullscreen"
	_fullscreen.text = LABEL_FULLSCREEN
	_fullscreen.button_pressed = false
	_fullscreen.toggled.connect(_on_fullscreen_toggled)
	box.add_child(_fullscreen)

	var back := Button.new()
	back.text = "Kembali"
	back.pressed.connect(close)
	box.add_child(back)


func _on_intensity_changed(value: float) -> void:
	if service != null:
		service.set_value(&"juice_intensity", value)


func _on_shake_toggled(pressed: bool) -> void:
	if service != null:
		service.set_value(&"screenshake_enabled", pressed)


func _on_hints_toggled(pressed: bool) -> void:
	if service != null:
		service.set_value(&"hints_enabled", pressed)


func _on_fullscreen_toggled(pressed: bool) -> void:
	if service != null:
		service.set_value(&"fullscreen", pressed)

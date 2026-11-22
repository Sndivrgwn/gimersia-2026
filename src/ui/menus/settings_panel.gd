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
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()


func setup(p_service: SettingsService) -> void:
	service = p_service
	refresh()


func open() -> void:
	visible = true
	refresh()


func close() -> void:
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func refresh() -> void:
	if not _building:
		return
	if service == null:
		service = SettingsService.find_service(self)
	if service == null:
		return
	_slider.value = service.get_juice_intensity()
	_shake.button_pressed = service.is_screenshake_enabled()
	_hints.button_pressed = service.are_hints_enabled()
	_fullscreen.button_pressed = service.is_fullscreen()


func get_slider() -> HSlider:
	return _slider


func get_screenshake_toggle() -> CheckBox:
	return _shake


func get_hints_toggle() -> CheckBox:
	return _hints


func get_fullscreen_toggle() -> CheckBox:
	return _fullscreen


func _build() -> void:
	_building = true
	var box := VBoxContainer.new()
	box.name = "Rows"
	add_child(box)

	var title := Label.new()
	title.text = "Pengaturan"
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

class_name SettingsService
extends Node

## Mission 7: pengaturan pemain (bukan autoload). Disimpan di user://settings.cfg.

signal changed(key: StringName, value: Variant)

const GROUP := &"settings_service"
const SAVE_PATH := "user://settings.cfg"
const SECTION := "settings"
const JUICE_MIN := 0.0
const JUICE_MAX := 1.5
const DEFAULTS := {
	&"juice_intensity": 1.0,
	&"screenshake_enabled": true,
	&"hints_enabled": true,
	&"fullscreen": false,
}

var _values: Dictionary = DEFAULTS.duplicate()


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	load_settings()
	apply_display()


static func find_service(node: Node) -> SettingsService:
	if node == null or not node.is_inside_tree():
		return null
	return node.get_tree().get_first_node_in_group(GROUP) as SettingsService


func get_value(key: StringName) -> Variant:
	if _values.has(key):
		return _values[key]
	return DEFAULTS.get(key)


func set_value(key: StringName, value: Variant) -> void:
	if not DEFAULTS.has(key):
		return
	var sanitized: Variant = value
	if key == &"juice_intensity":
		sanitized = clampf(float(value), JUICE_MIN, JUICE_MAX)
	if _values.get(key) == sanitized:
		return
	_values[key] = sanitized
	if key == &"fullscreen":
		apply_display()
	changed.emit(key, sanitized)
	save_settings()


func get_juice_intensity() -> float:
	return float(get_value(&"juice_intensity"))


func is_screenshake_enabled() -> bool:
	return bool(get_value(&"screenshake_enabled"))


func are_hints_enabled() -> bool:
	return bool(get_value(&"hints_enabled"))


func is_fullscreen() -> bool:
	return bool(get_value(&"fullscreen"))


## Mode jendela hanya diubah di runtime; file project.godot tidak disentuh.
func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if is_fullscreen() else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func reset_defaults() -> void:
	for key in DEFAULTS:
		set_value(key, DEFAULTS[key])


func save_settings() -> void:
	var file := ConfigFile.new()
	for key in _values:
		file.set_value(SECTION, String(key), _values[key])
	file.save(SAVE_PATH)


## Toleran: file hilang, rusak, atau nilai aneh -> kembali ke default.
func load_settings() -> void:
	_values = DEFAULTS.duplicate()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	# File jelas rusak: jangan sampai ConfigFile melempar error ke log.
	var raw := FileAccess.get_file_as_string(SAVE_PATH)
	if raw.is_empty() or not raw.contains("["):
		return
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return
	for key in DEFAULTS:
		if not file.has_section_key(SECTION, String(key)):
			continue
		var value: Variant = file.get_value(SECTION, String(key))
		if key == &"juice_intensity":
			if value is float or value is int:
				_values[key] = clampf(float(value), JUICE_MIN, JUICE_MAX)
		elif value is bool:
			_values[key] = value

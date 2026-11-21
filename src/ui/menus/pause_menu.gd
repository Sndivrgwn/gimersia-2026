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

var _previous_scale: float = 1.0
var _paused_by_menu: bool = false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	InputSetup.ensure_actions()
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputSetup.PAUSE_TOGGLE):
		toggle()
		get_viewport().set_input_as_handled()


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


func open() -> bool:
	if _paused_by_menu or not can_open():
		return false
	_paused_by_menu = true
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
	get_tree().paused = false
	if clock != null and clock.has_method(&"set_time_scale"):
		clock.set_time_scale(_previous_scale)
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

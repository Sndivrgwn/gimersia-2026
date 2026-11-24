class_name TentVisual
extends VisualDriver

## Driver animasi tenda: state sleeping sebentar setelah tidur selesai.

const SLEEP_SHOW_TIME := 1.0

var _sleep_remaining: float = 0.0


func bind() -> void:
	if owner_node == null:
		return
	if owner_node.has_signal(&"sleep_completed") and not owner_node.sleep_completed.is_connected(_on_sleep_completed):
		owner_node.sleep_completed.connect(_on_sleep_completed)


func step(delta: float) -> void:
	_sleep_remaining = maxf(_sleep_remaining - delta, 0.0)
	push(VisualStateMap.tent_state(_sleep_remaining > 0.0))


func is_sleeping_visual() -> bool:
	return _sleep_remaining > 0.0


func _on_sleep_completed() -> void:
	_sleep_remaining = SLEEP_SHOW_TIME

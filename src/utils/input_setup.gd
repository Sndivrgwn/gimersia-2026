class_name InputSetup
extends RefCounted

## Mendaftarkan action Input Map yang dipakai modul player.
## Idempotent: aman dipanggil dari banyak scene dan tidak menduplikasi event.
## Memakai physical_keycode agar tetap sama di layout keyboard berbeda.

const MOVE_LEFT := &"move_left"
const MOVE_RIGHT := &"move_right"
const MOVE_UP := &"move_up"
const MOVE_DOWN := &"move_down"
const SPRINT := &"sprint"


static func ensure_actions() -> void:
	_ensure_action(MOVE_LEFT)
	_ensure_key(MOVE_LEFT, KEY_A)
	_ensure_key(MOVE_LEFT, KEY_LEFT)

	_ensure_action(MOVE_RIGHT)
	_ensure_key(MOVE_RIGHT, KEY_D)
	_ensure_key(MOVE_RIGHT, KEY_RIGHT)

	_ensure_action(MOVE_UP)
	_ensure_key(MOVE_UP, KEY_W)
	_ensure_key(MOVE_UP, KEY_UP)

	_ensure_action(MOVE_DOWN)
	_ensure_key(MOVE_DOWN, KEY_S)
	_ensure_key(MOVE_DOWN, KEY_DOWN)

	_ensure_action(SPRINT)
	_ensure_key(SPRINT, KEY_SHIFT)


static func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)


static func _ensure_key(action: StringName, key: Key) -> void:
	if _has_physical_key(action, key):
		return

	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)


static func _has_physical_key(action: StringName, key: Key) -> bool:
	for event in InputMap.action_get_events(action):
		var key_event := event as InputEventKey
		if key_event != null and key_event.physical_keycode == key:
			return true
	return false

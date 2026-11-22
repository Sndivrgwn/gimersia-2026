extends Node

## Mission 9 polish: 3 prompt pembuka, memakai saluran yang sama dengan
## HintManager (satu hint pada satu waktu, jadi tidak mungkin tumpang tindih).
## Sekali per sesi aplikasi; bisa dilewati dengan menekan gerak/serang.

const STEPS: Array[Dictionary] = [
	{"text": "Kamu terdampar. WASD untuk bergerak, Shift untuk sprint.", "time": 4.5},
	{"text": "Dekati pohon atau ranting, lalu tahan E untuk mengumpulkan.", "time": 5.0},
	{"text": "Tekan Tab untuk tas dan crafting, P untuk jeda.", "time": 5.0},
]

## Sekali per proses aplikasi; tidak ikut tersimpan ke settings.
static var _played: bool = false

var _manager: HintManager
var _index: int = 0
var _running: bool = false


func _ready() -> void:
	_start.call_deferred()


func is_running() -> bool:
	return _running


## Dipakai tes untuk mengulang urutan.
static func reset_played() -> void:
	_played = false


func _start() -> void:
	if _played:
		return
	_played = true
	_manager = _find_manager()
	if _manager == null or not _manager.is_enabled():
		return
	_manager.hint_hidden.connect(_on_hint_hidden)
	_running = true
	_show(0)


func _process(_delta: float) -> void:
	if not _running or _manager == null:
		return
	if _skip_pressed():
		_manager.skip_current()


func _show(index: int) -> void:
	if not _running:
		return
	_index = index
	if index >= STEPS.size():
		_running = false
		return
	_manager.show_text(_id(index), String(STEPS[index]["text"]), float(STEPS[index]["time"]))


func _on_hint_hidden(id: StringName) -> void:
	if not _running or id != _id(_index):
		return
	_show(_index + 1)


func _id(index: int) -> StringName:
	return StringName("opening_%d" % index)


func _skip_pressed() -> bool:
	for action in InputSetup.MOVE_ACTIONS:
		if Input.is_action_just_pressed(action):
			return true
	return Input.is_action_just_pressed(InputSetup.ATTACK_SPACE)


func _find_manager() -> HintManager:
	var parent := get_parent()
	if parent != null:
		var sibling := parent.get_node_or_null("HintManager") as HintManager
		if sibling != null:
			return sibling
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("HintManager", true, false) as HintManager

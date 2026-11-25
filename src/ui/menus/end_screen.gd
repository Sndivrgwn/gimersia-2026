class_name EndScreen
extends CanvasLayer

## Basis layar akhir (Kamu Tewas / Game Over).
## - Hanya satu layar akhir yang tampil (yang lain disembunyikan).
## - Ikut memblokir jeda lewat group "pause_blockers".
## - Enter/Space ditahan sesaat setelah layar muncul, supaya tombol tidak
##   tertekan tanpa sengaja oleh serangan (Space) yang sedang ditekan berulang.

const GROUP := &"end_screens"
const BLOCKER_GROUP := &"pause_blockers"
const INPUT_GUARD_MSEC := 400

@onready var _panel: Control = %Panel

var _guard_until_msec: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
	add_to_group(BLOCKER_GROUP)
	hide_screen()


func _input(event: InputEvent) -> void:
	if not is_showing() or Time.get_ticks_msec() >= _guard_until_msec:
		return
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_select"):
		get_viewport().set_input_as_handled()


func hide_screen() -> void:
	_panel.visible = false


func is_showing() -> bool:
	return _panel.visible


## Tampilkan layar ini, sembunyikan layar akhir lain, dan fokuskan tombol utama.
## Fokus selalu diambil ulang, jadi tidak pernah tertinggal di tombol yang disembunyikan.
func _present(focus_target: Button) -> void:
	for node in get_tree().get_nodes_in_group(GROUP):
		if node != self and node.has_method(&"hide_screen"):
			node.hide_screen()
	_guard_until_msec = Time.get_ticks_msec() + INPUT_GUARD_MSEC
	_panel.visible = true
	focus_target.grab_focus()

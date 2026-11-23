class_name HelpPanel
extends Control

## Mission 7: daftar kontrol statis. Tidak mem-pause.

signal toggled_open(is_open: bool)

const HELP_LINES: Array[String] = [
	"PEMAIN",
	"WASD - bergerak",
	"Shift - sprint",
	"Ctrl - jongkok",
	"E (tahan) - kumpulkan / gunakan",
	"R (tahan) - perbaiki struktur",
	"B - tentukan lokasi base",
	"1-5 - hotbar",
	"Space / klik kiri - serang",
	"",
	"PANEL & MENU",
	"Tab / I - panel tas: Tas | Crafting | Profisiensi",
	"P - pause (Lanjutkan, Pengaturan, Bantuan, Menu Utama)",
	"H - bantuan ini",
	"Esc - tutup panel yang terbuka",
	"",
	"DEBUG PULAU (island)",
	"F2 - mode debug on/off",
	"F3 - zona berikutnya, F4 - pagi, F5 - kit bahan",
	"F6 - babi, F7 - rusa, F8 - malam, F9 - heal",
	"F10 - siklus senjata, F11 - mati, F12 - rescue",
	"J - raid sekarang, Insert - label fauna",
]

var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	InputSetup.ensure_actions()
	_label = Label.new()
	_label.name = "HelpText"
	_label.text = "\n".join(HELP_LINES)
	add_child(_label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputSetup.HELP_TOGGLE):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	visible = not visible
	toggled_open.emit(visible)


func open() -> void:
	visible = true
	toggled_open.emit(true)


func close() -> void:
	visible = false
	toggled_open.emit(false)


func is_open() -> bool:
	return visible


func get_text() -> String:
	return "" if _label == null else _label.text

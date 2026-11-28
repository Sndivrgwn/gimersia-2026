class_name HelpPanel
extends Control

## Daftar kontrol statis. Seluruh node UI didefinisikan di help_panel_ui.tscn + controls_content.tscn;
## skrip ini hanya menangani logika buka/tutup, input, dan fokus.

signal toggled_open(is_open: bool)

const UI_SCENE := preload("res://src/ui/menus/help_panel_ui.tscn")

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
	"Tab / I - panel tas: Tas | Crafting",
	"P - pause (Lanjutkan, Pengaturan, Bantuan, Menu Utama)",
	"Esc - tutup panel yang terbuka",
]

var _label: Label
var _back_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	InputSetup.ensure_actions()
	if not has_node("Ui"):
		var ui := UI_SCENE.instantiate()
		ui.name = "Ui"
		add_child(ui)
	_bind_scene_ui()


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func open() -> void:
	if visible:
		return
	visible = true
	UiBackStack.register(self)
	toggled_open.emit(true)
	if _back_button != null:
		_back_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	UiBackStack.unregister(self)
	toggled_open.emit(false)


func is_open() -> bool:
	return visible


func get_text() -> String:
	return "\n".join(HELP_LINES) if _label == null else _label.text


func _bind_scene_ui() -> void:
	var ui := get_node("Ui")
	_label = ui.get_node_or_null("%HelpText") as Label
	if _label != null:
		_label.text = "\n".join(HELP_LINES)
	var back := ui.get_node_or_null("%BackButton") as Button
	_back_button = back
	if back != null and not back.pressed.is_connected(close):
		back.pressed.connect(close)

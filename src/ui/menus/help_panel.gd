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
	"Tab / I - panel tas: Tas | Crafting",
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
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	InputSetup.ensure_actions()
	if has_node("Ui"):
		_bind_scene_ui()
	else:
		_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(InputSetup.HELP_TOGGLE):
		if not is_open():
			if (get_tree() != null and get_tree().paused) or UiBackStack.has_open(self):
				return
		toggle()
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


func close() -> void:
	if not visible:
		return
	visible = false
	UiBackStack.unregister(self)
	toggled_open.emit(false)


func is_open() -> bool:
	return visible


func get_text() -> String:
	return "" if _label == null else _label.text


func _bind_scene_ui() -> void:
	var ui := get_node("Ui")
	_label = ui.get_node_or_null("%HelpText") as Label
	if _label != null:
		_label.text = "\n".join(HELP_LINES)
	var back := ui.get_node_or_null("%BackButton") as Button
	if back != null:
		back.pressed.connect(close)


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "Card"
	panel.custom_minimum_size = Vector2(460.0, 0.0)
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
	box.name = "Box"
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := Label.new()
	title.text = "Kontrol & Bantuan"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)

	_label = Label.new()
	_label.name = "HelpText"
	_label.text = "\n".join(HELP_LINES)
	_label.add_theme_font_size_override("font_size", 13)
	box.add_child(_label)

	var back := Button.new()
	back.text = "Kembali"
	back.pressed.connect(close)
	box.add_child(back)

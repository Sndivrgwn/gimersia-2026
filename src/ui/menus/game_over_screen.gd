class_name GameOverScreen
extends CanvasLayer

## Layar Game Over permanen setelah seluruh kesempatan respawn habis.
## process_mode ALWAYS supaya tetap aktif saat gameplay di-pause.

signal restart_requested
signal main_menu_requested

const TITLE := "Kalah"
const DETAIL := "Tidak ada kesempatan respawn tersisa."
const UiMotion := preload("res://src/ui/fx/ui_motion.gd")

var _panel: Control
var _title: Label
var _detail: Label
var _restart_button: Button
var _menu_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_bind_scene_ui()
	UiSkin.apply_all(self)
	UiSkin.add_canvas_background(self, &"ui_bg_game_over")
	hide_screen()


# --- API --------------------------------------------------------------------

func show_screen() -> void:
	visible = true
	if _panel != null:
		UiMotion.pop_in(_panel)
	_refresh_detail()
	if _restart_button != null:
		_restart_button.grab_focus()


func show_game_over() -> void:
	show_screen()


## Teks detail lengkap (dipakai tes).
func get_detail_text() -> String:
	return "" if _detail == null else _detail.text


## Fase 5: ringkasan run dari DailyRunStats.
func _refresh_detail() -> void:
	if _detail != null:
		_detail.text = DETAIL + RunSummary.block_for(self)


func hide_screen() -> void:
	if _panel != null:
		UiMotion.pop_out(_panel, func() -> void:
			visible = false
		)
	else:
		visible = false


func is_showing() -> bool:
	return visible and _panel != null and _panel.visible


# --- Internal ---------------------------------------------------------------

func _bind_scene_ui() -> void:
	_panel = get_node_or_null("Panel") as Control
	_title = get_node_or_null("%Title") as Label
	_detail = get_node_or_null("%Detail") as Label
	_restart_button = get_node_or_null("%RestartButton") as Button
	_menu_button = get_node_or_null("%MenuButton") as Button
	if _restart_button != null and not _restart_button.pressed.is_connected(_on_restart_pressed):
		_restart_button.pressed.connect(_on_restart_pressed)
	if _menu_button != null and not _menu_button.pressed.is_connected(_on_menu_pressed):
		_menu_button.pressed.connect(_on_menu_pressed)


func _on_restart_pressed() -> void:
	restart_requested.emit()


func _on_menu_pressed() -> void:
	main_menu_requested.emit()

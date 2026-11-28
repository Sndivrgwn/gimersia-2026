class_name DeathScreen
extends CanvasLayer

## Layar "Kamu Tewas" / Game Over. Hanya UI: tidak mengubah state gameplay.
## process_mode ALWAYS supaya tetap terlihat walau SceneTree di-pause nanti.

signal respawn_requested
signal main_menu_requested

const TITLE_DEATH := "Tewas"
const TITLE_GAME_OVER := "Kalah"
const HINT_DEATH := "Sisa Kesempatan Respawn: %d / 3"
const HINT_GAME_OVER := "Tidak ada kesempatan respawn tersisa."
const UiMotion := preload("res://src/ui/fx/ui_motion.gd")

var _panel: Control
var _title: Label
var _detail: Label
var _respawn_button: Button
var _menu_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_bind_scene_ui()
	UiSkin.apply_all(self)
	UiSkin.add_canvas_background(self, &"ui_bg_death")
	hide_screen()


# --- API --------------------------------------------------------------------

func show_death(respawns_remaining: int) -> void:
	_title.text = TITLE_DEATH
	_detail.text = HINT_DEATH % maxi(respawns_remaining, 0) + _death_time_line() + _summary_block()
	_respawn_button.visible = true
	visible = true
	UiMotion.pop_in(_panel)
	_respawn_button.grab_focus()


func show_game_over() -> void:
	_title.text = TITLE_GAME_OVER
	_detail.text = HINT_GAME_OVER + _summary_block()
	_respawn_button.visible = false
	visible = true
	UiMotion.pop_in(_panel)
	_menu_button.grab_focus()


## Teks detail lengkap (dipakai tes).
func get_detail_text() -> String:
	return "" if _detail == null else _detail.text


## Fase 5: ringkasan run dari DailyRunStats (kosong bila statistik tidak ada).
func _summary_block() -> String:
	return RunSummary.block_for(self)


## Mission 12: "Tewas pada Hari 3 pukul 22:14" bila jam tersedia.
func _death_time_line() -> String:
	var clock := get_node_or_null("/root/DayNightManager")
	if clock == null or not clock.has_method(&"get_clock_text"):
		return ""
	return "\nTewas pada Hari %d pukul %s" % [int(clock.get_current_day()), clock.get_clock_text()]


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
	_respawn_button = get_node_or_null("%RespawnButton") as Button
	_menu_button = get_node_or_null("%MenuButton") as Button
	if _respawn_button != null and not _respawn_button.pressed.is_connected(_on_respawn_pressed):
		_respawn_button.pressed.connect(_on_respawn_pressed)
	if _menu_button != null and not _menu_button.pressed.is_connected(_on_menu_pressed):
		_menu_button.pressed.connect(_on_menu_pressed)


func _on_respawn_pressed() -> void:
	respawn_requested.emit()


func _on_menu_pressed() -> void:
	main_menu_requested.emit()

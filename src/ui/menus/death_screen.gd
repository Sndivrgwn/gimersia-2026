class_name DeathScreen
extends CanvasLayer

## Layar "Kamu Tewas" / Game Over. Hanya UI: tidak mengubah state gameplay.
## process_mode ALWAYS supaya tetap terlihat walau SceneTree di-pause nanti.

signal respawn_requested
signal main_menu_requested

const TITLE_DEATH := "Kamu Tewas"
const TITLE_GAME_OVER := "Game Over"
const HINT_DEATH := "Sisa Kesempatan Respawn: %d / 3"
const HINT_GAME_OVER := "Tidak ada kesempatan respawn tersisa."

var _panel: Control
var _title: Label
var _detail: Label
var _respawn_button: Button
var _menu_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	if has_node("Panel"):
		_bind_scene_ui()
	else:
		_build()
	UiSkin.apply_all(self)
	UiSkin.add_canvas_background(self, &"ui_bg_death")
	hide_screen()


# --- API --------------------------------------------------------------------

func show_death(respawns_remaining: int) -> void:
	_title.text = TITLE_DEATH
	_detail.text = HINT_DEATH % maxi(respawns_remaining, 0) + _death_time_line() + _summary_block()
	_respawn_button.visible = true
	_panel.visible = true
	visible = true


func show_game_over() -> void:
	_title.text = TITLE_GAME_OVER
	_detail.text = HINT_GAME_OVER + _summary_block()
	_respawn_button.visible = false
	_panel.visible = true
	visible = true


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
	visible = false
	if _panel != null:
		_panel.visible = false


func is_showing() -> bool:
	return visible and _panel != null and _panel.visible


# --- Internal ---------------------------------------------------------------

func _bind_scene_ui() -> void:
	_panel = get_node("Panel") as Control
	_title = get_node("%Title") as Label
	_detail = get_node("%Detail") as Label
	_respawn_button = get_node("%RespawnButton") as Button
	_menu_button = get_node("%MenuButton") as Button
	if _respawn_button != null and not _respawn_button.pressed.is_connected(_on_respawn_pressed):
		_respawn_button.pressed.connect(_on_respawn_pressed)
	if _menu_button != null and not _menu_button.pressed.is_connected(_on_menu_pressed):
		_menu_button.pressed.connect(_on_menu_pressed)

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-230, -150)
	_panel.custom_minimum_size = Vector2(460, 300)
	add_child(_panel)

	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)

	_title = Label.new()
	_title.name = "Title"
	_title.text = TITLE_DEATH
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 26)
	column.add_child(_title)

	_detail = Label.new()
	_detail.name = "Detail"
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 14)
	column.add_child(_detail)

	_respawn_button = Button.new()
	_respawn_button.name = "RespawnButton"
	_respawn_button.text = "Respawn"
	_respawn_button.pressed.connect(_on_respawn_pressed)
	column.add_child(_respawn_button)

	_menu_button = Button.new()
	_menu_button.name = "MenuButton"
	_menu_button.text = "Menu Utama"
	_menu_button.pressed.connect(_on_menu_pressed)
	column.add_child(_menu_button)


func _on_respawn_pressed() -> void:
	respawn_requested.emit()


func _on_menu_pressed() -> void:
	main_menu_requested.emit()

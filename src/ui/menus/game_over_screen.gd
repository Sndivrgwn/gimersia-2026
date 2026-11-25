class_name GameOverScreen
extends CanvasLayer

## Layar Game Over permanen setelah seluruh kesempatan respawn habis.
## process_mode ALWAYS supaya tetap aktif saat gameplay di-pause.

signal restart_requested
signal main_menu_requested

const TITLE := "KALAH"
const DETAIL := "Tidak ada kesempatan respawn tersisa."

var _panel: Control
var _title: Label
var _detail: Label
var _restart_button: Button
var _menu_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	if has_node("Panel"):
		_bind_scene_ui()
	else:
		_build()
	UiSkin.apply_all(self)
	UiSkin.add_canvas_background(self, &"ui_bg_game_over")
	hide_screen()


# --- API --------------------------------------------------------------------

func show_screen() -> void:
	visible = true
	if _panel != null:
		_panel.visible = true
	_refresh_detail()


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
	_restart_button = get_node("%RestartButton") as Button
	_menu_button = get_node("%MenuButton") as Button
	if _restart_button != null and not _restart_button.pressed.is_connected(_on_restart_pressed):
		_restart_button.pressed.connect(_on_restart_pressed)
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
	_title.text = TITLE
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 26)
	column.add_child(_title)

	_detail = Label.new()
	_detail.name = "Detail"
	_detail.text = DETAIL
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.add_theme_font_size_override("font_size", 14)
	column.add_child(_detail)

	_restart_button = Button.new()
	_restart_button.name = "RestartButton"
	_restart_button.text = "Mulai Baru"
	_restart_button.pressed.connect(_on_restart_pressed)
	column.add_child(_restart_button)

	_menu_button = Button.new()
	_menu_button.name = "MenuButton"
	_menu_button.text = "Menu Utama"
	_menu_button.pressed.connect(_on_menu_pressed)
	column.add_child(_menu_button)


func _on_restart_pressed() -> void:
	restart_requested.emit()


func _on_menu_pressed() -> void:
	main_menu_requested.emit()

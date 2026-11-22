class_name GameOverScreen
extends CanvasLayer

## Layar Game Over permanen setelah seluruh kesempatan respawn habis.
## process_mode ALWAYS supaya tetap aktif saat gameplay di-pause.

signal restart_requested
signal main_menu_requested

const TITLE := "Game Over"
const DETAIL := "Tidak ada kesempatan respawn tersisa."

var _panel: PanelContainer
var _title: Label
var _detail: Label
var _restart_button: Button
var _menu_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_build()
	hide_screen()
	UiSkin.apply_all(self)
	UiSkin.add_canvas_background(self, &"ui_bg_game_over")


# --- API --------------------------------------------------------------------

func show_screen() -> void:
	if _panel != null:
		_panel.visible = true


func show_game_over() -> void:
	show_screen()


func hide_screen() -> void:
	if _panel != null:
		_panel.visible = false


func is_showing() -> bool:
	return _panel != null and _panel.visible


# --- Internal ---------------------------------------------------------------

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.position = Vector2(-170, -110)
	_panel.custom_minimum_size = Vector2(340, 220)
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

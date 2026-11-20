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

var _panel: PanelContainer
var _title: Label
var _detail: Label
var _respawn_button: Button
var _menu_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	_build()
	hide_screen()


# --- API --------------------------------------------------------------------

func show_death(respawns_remaining: int) -> void:
	_title.text = TITLE_DEATH
	_detail.text = HINT_DEATH % maxi(respawns_remaining, 0)
	_respawn_button.visible = true
	_panel.visible = true


func show_game_over() -> void:
	_title.text = TITLE_GAME_OVER
	_detail.text = HINT_GAME_OVER
	_respawn_button.visible = false
	_panel.visible = true


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
	_title.text = TITLE_DEATH
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 26)
	column.add_child(_title)

	_detail = Label.new()
	_detail.name = "Detail"
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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

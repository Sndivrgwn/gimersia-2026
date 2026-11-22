extends Control

## Menu Utama placeholder. Scene ini BUKAN main scene (project tetap memakai
## practice1.tscn); dibuka dari DeathScreen / RunController.
##
## "Mulai Baru": DayNightManager.restart() lalu pindah ke island.tscn.
## "Keluar": menutup aplikasi.

const GAME_SCENE := "res://src/levels/island/island.tscn"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_ensure_settings_ui()
	UiSkin.apply(self)
	UiSkin.add_background(self, &"ui_bg_main_menu")
	UiSkin.add_logo(self)


## Mission 7: panel pengaturan dipakai ulang di menu utama.
func _ensure_settings_ui() -> void:
	var service := get_node_or_null("SettingsService") as SettingsService
	if service == null:
		service = SettingsService.new()
		service.name = "SettingsService"
		add_child(service)
	var panel := get_node_or_null("SettingsPanel") as SettingsPanel
	if panel == null:
		panel = SettingsPanel.new()
		panel.name = "SettingsPanel"
		add_child(panel)
	panel.setup(service)
	if find_child("SettingsButton", true, false) != null:
		return
	var button := Button.new()
	button.name = "SettingsButton"
	button.text = "Pengaturan"
	button.pressed.connect(panel.open)
	add_child(button)


# --- Internal ---------------------------------------------------------------

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color(0.09, 0.12, 0.16, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var column := VBoxContainer.new()
	column.position = Vector2(470, 260)
	column.custom_minimum_size = Vector2(212, 180)
	column.add_theme_constant_override("separation", 14)
	add_child(column)

	var title := Label.new()
	title.text = "GIMERSIA 2026"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Bertahan 7 hari sampai kapal penyelamat datang."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.custom_minimum_size = Vector2(212, 40)
	subtitle.add_theme_font_size_override("font_size", 12)
	column.add_child(subtitle)

	var start_button := Button.new()
	start_button.name = "StartButton"
	start_button.text = "Mulai Baru"
	start_button.pressed.connect(_start_game)
	column.add_child(start_button)

	var quit_button := Button.new()
	quit_button.name = "QuitButton"
	quit_button.text = "Keluar"
	quit_button.pressed.connect(_quit)
	column.add_child(quit_button)


func _start_game() -> void:
	var clock := get_node_or_null("/root/DayNightManager")
	if clock != null and clock.has_method(&"restart"):
		clock.restart()
	get_tree().change_scene_to_file(GAME_SCENE)


func _quit() -> void:
	get_tree().quit()

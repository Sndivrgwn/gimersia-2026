class_name EndgameHUD
extends CanvasLayer

## HUD endgame: banner Hari 7 / rescue, panah ke Beacon, dan panel Victory.
## Read-only: semua state datang dari EndgameController.

signal restart_requested
signal main_menu_requested

const ARROW_FORMAT := "%s  Beacon %d px"
const VICTORY_TITLE := "SELAMAT!"
const VICTORY_DETAIL := "Suar darurat menyala. Kapal penyelamat menemukanmu."

var _banner: Label
var _arrow: Label
var _victory_panel: PanelContainer
## Mission 12: baris "Diselamatkan Hari N pukul HH:MM".
var _victory_detail: Label
var _restart_button: Button
var _menu_button: Button
var _controller: EndgameController
var _banner_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	_build()
	UiSkin.apply_all(self)
	UiSkin.add_canvas_background(self, &"ui_bg_victory")
	_controller = get_tree().get_first_node_in_group(&"endgame_controller") as EndgameController
	if _controller != null:
		_controller.banner_shown.connect(_on_banner_shown)
		_controller.rescue_ready.connect(_on_rescue_ready)
		_controller.victory.connect(_on_victory)


func _process(delta: float) -> void:
	_tick_banner(delta)
	_tick_arrow()


# --- API --------------------------------------------------------------------

func get_banner_text() -> String:
	return _banner.text if _banner != null else ""


func is_victory_visible() -> bool:
	return _victory_panel != null and _victory_panel.visible


## Teks panel Victory lengkap (dipakai tes).
func get_victory_text() -> String:
	return "" if _victory_detail == null else _victory_detail.text


# --- Internal ---------------------------------------------------------------

func _build() -> void:
	_banner = Label.new()
	_banner.name = "Banner"
	_banner.position = Vector2(0, 44)
	_banner.size = Vector2(1152, 40)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 16)
	_banner.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55, 1.0))
	_banner.visible = false
	add_child(_banner)

	_arrow = Label.new()
	_arrow.name = "Arrow"
	_arrow.position = Vector2(0, 620)
	_arrow.size = Vector2(1152, 24)
	_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arrow.add_theme_font_size_override("font_size", 15)
	_arrow.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0, 1.0))
	_arrow.visible = false
	add_child(_arrow)

	_victory_panel = PanelContainer.new()
	_victory_panel.name = "Victory"
	_victory_panel.position = Vector2(370, 220)
	_victory_panel.custom_minimum_size = Vector2(420, 300)
	_victory_panel.visible = false
	add_child(_victory_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_victory_panel.add_child(column)

	var title := Label.new()
	title.text = VICTORY_TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)

	var detail := Label.new()
	detail.text = VICTORY_DETAIL
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(320, 40)
	column.add_child(detail)
	_victory_detail = detail

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


func _on_banner_shown(text: String) -> void:
	_banner.text = text
	_banner.visible = true
	_banner_timer = 12.0


func _on_rescue_ready() -> void:
	_arrow.visible = true


func _on_victory() -> void:
	_victory_panel.visible = true
	if _victory_detail != null:
		# Fase 5: ringkasan run ikut ditampilkan di panel Victory.
		_victory_detail.text = VICTORY_DETAIL + _rescue_time_line() + RunSummary.block_for(self)


## Mission 12: "Diselamatkan Hari 7 pukul 06:00" bila jam tersedia.
func _rescue_time_line() -> String:
	var clock := get_node_or_null("/root/DayNightManager")
	if clock == null or not clock.has_method(&"get_clock_text"):
		return ""
	return "\nDiselamatkan Hari %d pukul %s" % [int(clock.get_current_day()), clock.get_clock_text()]


func _tick_banner(delta: float) -> void:
	if not _banner.visible:
		return
	_banner_timer -= delta
	if _banner_timer <= 0.0:
		_banner.visible = false


func _tick_arrow() -> void:
	if _controller == null or not _controller.is_rescue_active():
		_arrow.visible = false
		return
	_arrow.visible = true
	var direction := _controller.get_beacon_direction()
	var glyph := "↑"
	if direction != Vector2.ZERO:
		var angle := direction.angle()
		if angle >= -PI / 4.0 and angle < PI / 4.0:
			glyph = "→"
		elif angle >= PI / 4.0 and angle < 3.0 * PI / 4.0:
			glyph = "↓"
		elif angle >= -3.0 * PI / 4.0 and angle < -PI / 4.0:
			glyph = "↑"
		else:
			glyph = "←"
	_arrow.text = ARROW_FORMAT % [glyph, int(round(_controller.get_beacon_distance()))]

class_name EndgameHUD
extends CanvasLayer

## HUD endgame: banner Hari 7 / rescue, panah ke Beacon, dan panel Victory.
## Read-only: semua state datang dari EndgameController.

signal restart_requested
signal main_menu_requested

const ARROW_FORMAT := "%s  Beacon %d px"
const VICTORY_TITLE := "Kapal penyelamat menemukanmu"
const VICTORY_DETAIL := "Suar darurat menyala. Kapal penyelamat menemukanmu."
const UiMotion := preload("res://src/ui/fx/ui_motion.gd")

var _banner: Label
var _arrow: Label
var _victory_panel: PanelContainer
## Mission 12: baris "Diselamatkan Hari N pukul HH:MM".
var _victory_detail: Label
var _restart_button: Button
var _menu_button: Button
var _controller: EndgameController
var _banner_timer: float = 0.0
var _banner_text: String = ""
var _victory_visible: bool = false
var _victory_text: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	_bind_scene_ui()
	UiSkin.apply_all(self)
	UiSkin.add_canvas_background(self, &"ui_bg_victory")
	_controller = get_tree().get_first_node_in_group(&"endgame_controller") as EndgameController
	if _controller != null:
		_controller.banner_shown.connect(_on_banner_shown)
		_controller.rescue_ready.connect(_on_rescue_ready)
		_controller.victory.connect(_on_victory)


func _bind_scene_ui() -> void:
	_banner = get_node_or_null("%Banner") as Label
	_arrow = get_node_or_null("%Arrow") as Label
	_victory_panel = get_node_or_null("%Victory") as PanelContainer
	_victory_detail = get_node_or_null("%VictoryDetail") as Label
	_restart_button = get_node_or_null("%RestartButton") as Button
	_menu_button = get_node_or_null("%MenuButton") as Button
	if _restart_button != null and not _restart_button.pressed.is_connected(_on_restart_pressed):
		_restart_button.pressed.connect(_on_restart_pressed)
	if _menu_button != null and not _menu_button.pressed.is_connected(_on_menu_pressed):
		_menu_button.pressed.connect(_on_menu_pressed)


func _process(delta: float) -> void:
	_tick_banner(delta)
	_tick_arrow()


# --- API --------------------------------------------------------------------

func get_banner_text() -> String:
	return _banner.text if _banner != null else _banner_text


func is_victory_visible() -> bool:
	return _victory_panel.visible if _victory_panel != null else _victory_visible


## Teks panel Victory lengkap (dipakai tes).
func get_victory_text() -> String:
	return _victory_text if _victory_detail == null else _victory_detail.text


# --- Internal ---------------------------------------------------------------


func _on_restart_pressed() -> void:
	restart_requested.emit()


func _on_menu_pressed() -> void:
	main_menu_requested.emit()


func _on_banner_shown(text: String) -> void:
	_banner_text = text
	if _banner != null:
		_banner.text = text
		_banner.visible = true
	_banner_timer = 12.0


func _on_rescue_ready() -> void:
	if _arrow != null:
		_arrow.visible = true


func _on_victory() -> void:
	_victory_visible = true
	UiMotion.pop_in(_victory_panel)
	var summary := RunSummary.block_for(self)
	var rescue_line := _rescue_time_line()
	_victory_text = VICTORY_DETAIL + rescue_line + summary
	if _victory_detail != null:
		# Fase 5: ringkasan run ikut ditampilkan di panel Victory.
		_victory_detail.text = _victory_text
		_victory_detail.visible = not rescue_line.is_empty() or not summary.is_empty()
	if _restart_button != null:
		_restart_button.grab_focus()


## Mission 12: "Diselamatkan Hari 7 pukul 06:00" bila jam tersedia.
func _rescue_time_line() -> String:
	var clock := get_node_or_null("/root/DayNightManager")
	if clock == null or not clock.has_method(&"get_clock_text"):
		return ""
	return "\nDiselamatkan Hari %d pukul %s" % [int(clock.get_current_day()), clock.get_clock_text()]


func _tick_banner(delta: float) -> void:
	if _banner == null or not _banner.visible:
		return
	_banner_timer -= delta
	if _banner_timer <= 0.0:
		_banner.visible = false


func _tick_arrow() -> void:
	if _arrow == null:
		return
	if _controller == null or not _controller.is_rescue_active():
		_arrow.visible = false
		return
	_arrow.visible = true
	var direction := _controller.get_beacon_direction()
	_arrow.text = ARROW_FORMAT % [Dir4.glyph(direction), int(round(_controller.get_beacon_distance()))]

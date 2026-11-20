class_name EndgameHUD
extends CanvasLayer

## HUD endgame: banner Hari 7 / rescue, panah ke Beacon, dan panel Victory.
## Read-only: semua state datang dari EndgameController.

const ARROW_FORMAT := "%s  Beacon %d px"
const VICTORY_TITLE := "SELAMAT!"
const VICTORY_DETAIL := "Suar darurat menyala. Kapal penyelamat menemukanmu."

var _banner: Label
var _arrow: Label
var _victory_panel: PanelContainer
var _controller: EndgameController
var _banner_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	_build()
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
	_victory_panel.position = Vector2(400, 260)
	_victory_panel.custom_minimum_size = Vector2(352, 140)
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


func _on_banner_shown(text: String) -> void:
	_banner.text = text
	_banner.visible = true
	_banner_timer = 12.0


func _on_rescue_ready() -> void:
	_arrow.visible = true


func _on_victory() -> void:
	_victory_panel.visible = true


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

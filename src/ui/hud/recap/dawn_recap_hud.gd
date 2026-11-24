extends CanvasLayer

## Fase 1B: panel rekap saat fajar ("Hari 2 selesai: 12 resource, 2 babi, base
## utuh"). Non-blocking: TIDAK mem-pause game dan tidak mendaftar ke UiBackStack
## supaya kontrol pemain tetap jalan. Menutup sendiri setelah
## `DawnRecapConfig.panel_seconds`, dengan Esc, atau lewat `close()`. Muncul dan
## hilang dengan fade `DawnRecapConfig.fade_seconds`.

const CONFIG_PATH := "res://src/data/configs/dawn_recap_config.tres"
const STATS_NAME := "DailyRunStats"
const BIND_RETRY := 0.5

@export var config: DawnRecapConfig
@export var stats: Node

var _panel: PanelContainer
var _title: Label
var _body: Label
var _timer: float = 0.0
var _showing: bool = false
var _bind_timer: float = 0.0
var _fade_tween: Tween


func _ready() -> void:
	layer = 13
	process_mode = Node.PROCESS_MODE_ALWAYS
	_showing = false
	if config == null:
		config = load(CONFIG_PATH) as DawnRecapConfig
	_build()
	_bind()


func _process(delta: float) -> void:
	if not _showing:
		if stats == null:
			_bind_timer -= delta
			if _bind_timer <= 0.0:
				_bind_timer = BIND_RETRY
				_bind()
		return
	_timer -= delta
	if _timer <= 0.0:
		close()


func _unhandled_input(event: InputEvent) -> void:
	if not _showing:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


# --- API --------------------------------------------------------------------

func show_summary(summary: Dictionary) -> void:
	if _panel == null:
		return
	_title.text = "Hari %d selesai" % int(summary.get("day", 1))
	_body.text = format_summary(summary)
	_panel.visible = true
	_showing = true
	_timer = config.panel_seconds if config != null else 6.0
	_fade_in()


func close() -> void:
	if not _showing and _panel != null and not _panel.visible:
		return
	_showing = false
	_timer = 0.0
	_fade_out()


func is_open() -> bool:
	return _showing


func get_title_text() -> String:
	return "" if _title == null else _title.text


func get_body_text() -> String:
	return "" if _body == null else _body.text


## Teks ringkasan; statis supaya bisa diuji tanpa scene.
static func format_summary(summary: Dictionary) -> String:
	var resources := int(summary.get("resources", 0))
	var boar := int(summary.get("kills_boar", 0))
	var destroyed := int(summary.get("structures_destroyed", 0))
	var intact := bool(summary.get("base_intact", true))
	var base_text := "base utuh"
	if not intact:
		base_text = "base rusak" if destroyed == 0 else "base rusak (%d hancur)" % destroyed
	return "%d resource · %d babi · %s" % [resources, boar, base_text]


# --- Internal ---------------------------------------------------------------

func _fade_seconds() -> float:
	return 0.0 if config == null else maxf(config.fade_seconds, 0.0)


func _fade_in() -> void:
	if _panel == null:
		return
	_kill_fade()
	var fade := _fade_seconds()
	if fade <= 0.0:
		_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
		return
	_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_fade_tween = create_tween()
	_fade_tween.tween_property(_panel, "modulate:a", 1.0, fade)


func _fade_out() -> void:
	if _panel == null:
		return
	_kill_fade()
	var fade := _fade_seconds()
	if fade <= 0.0:
		_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
		_panel.visible = false
		return
	_fade_tween = create_tween()
	_fade_tween.tween_property(_panel, "modulate:a", 0.0, fade)
	_fade_tween.tween_callback(_hide_panel)


func _hide_panel() -> void:
	if _panel == null:
		return
	_panel.visible = false
	_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _kill_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func _bind() -> void:
	if stats == null:
		var tree := get_tree()
		var scene := tree.current_scene if tree != null else null
		if scene != null:
			stats = scene.find_child(STATS_NAME, true, false)
	if stats == null:
		return
	if stats.has_signal(&"day_summary") and not stats.day_summary.is_connected(show_summary):
		stats.day_summary.connect(show_summary)


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.name = "RecapPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -200.0
	_panel.offset_right = 200.0
	_panel.offset_top = 88.0
	_panel.offset_bottom = 162.0
	_panel.add_theme_stylebox_override("panel", _panel_style())
	_panel.visible = false
	root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)

	_title = Label.new()
	_title.name = "Title"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 19)
	_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.6, 1.0))
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_title)

	_body = Label.new()
	_body.name = "Body"
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("font_size", 14)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_body)

	var hint := Label.new()
	hint.name = "Hint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.76, 0.78, 0.8, 1.0))
	hint.text = "Esc untuk menutup"
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(hint)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.1, 0.86)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.78, 0.55, 0.5)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

class_name WorldDebugOverlay
extends Node2D

## Overlay debug dunia (Mission 13 blok H). Default OFF; toggle dengan action
## `debug_world_overlay` (O). Menggambar sel kamera saja, jadi biayanya kecil.
##
## Bekerja di mode FORMULA (warna zona via WorldRules.zone_at, tanpa
## reachability) maupun AUTHORED (tambah sel blocked + sel tak terjangkau).

const TOGGLE_ACTION := InputSetup.DEBUG_WORLD_OVERLAY
const PANEL_NAME := &"WorldOverlayPanel"
const LAYER_NAME := &"OverlayLayer"
const REFRESH_SECONDS := 0.25
const CAMERA_MOVE_PX := 64.0
const MAX_MESSAGES := 8

@export var config: WorldConfig = preload("res://src/data/configs/world/world_config.tres")

var _enabled: bool = false
var _timer: float = 0.0
var _last_camera := Vector2.INF
var _counts := {"errors": 0, "warnings": 0}
var _messages: Array[String] = []
var _panel: Label
var _layer: CanvasLayer
var _reachable := PackedByteArray()
var _reachable_source_id: StringName = &""
## Validasi dijalankan sekali per sumber: validasi penuh (flood fill + plan)
## terlalu mahal untuk diulang tiap 0.25 s saat kamera bergerak.
var _validation_source_id: StringName = &""


func _ready() -> void:
	InputSetup.ensure_actions()
	_layer = CanvasLayer.new()
	_layer.name = String(LAYER_NAME)
	_layer.visible = false
	add_child(_layer)
	_panel = Label.new()
	_panel.name = String(PANEL_NAME)
	_panel.position = Vector2(16.0, 16.0)
	_panel.add_theme_color_override("font_color", Color(0.95, 0.95, 0.85, 1.0))
	_panel.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_panel.add_theme_constant_override("shadow_offset_x", 1)
	_panel.add_theme_constant_override("shadow_offset_y", 1)
	_layer.add_child(_panel)
	visible = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(TOGGLE_ACTION):
		toggle()
	if not _enabled:
		return
	_timer += delta
	var camera_position := _camera_position()
	if _timer >= REFRESH_SECONDS or camera_position.distance_to(_last_camera) > CAMERA_MOVE_PX:
		refresh_now()


# --- API --------------------------------------------------------------------

func is_enabled() -> bool:
	return _enabled


func toggle() -> void:
	set_enabled(not _enabled)


func set_enabled(value: bool) -> void:
	_enabled = value
	visible = _enabled
	if _layer != null:
		_layer.visible = _enabled
	_last_camera = Vector2.INF
	if _enabled:
		refresh_now()


## Hitung ulang panel + reachability lalu minta gambar ulang.
func refresh_now() -> void:
	_timer = 0.0
	_last_camera = _camera_position()
	_refresh_counts()
	_refresh_panel()
	queue_redraw()


func get_counts() -> Dictionary:
	return _counts.duplicate()


func get_panel_text() -> String:
	return _panel.text if _panel != null else ""


func is_formula_mode() -> bool:
	return WorldRules.get_source() is FormulaWorld


# --- Internal ---------------------------------------------------------------

func _refresh_counts() -> void:
	var source := WorldRules.get_source()
	if _validation_source_id == source.id():
		return
	_validation_source_id = source.id()
	_counts = {"errors": 0, "warnings": 0}
	_messages.clear()
	_reachable = PackedByteArray()
	_reachable_source_id = source.id()
	if source is AuthoredWorldSource:
		var config_value := config if config != null else WorldConfig.new()
		var results := WorldValidator.validate(source, config_value)
		for entry in results:
			if String(entry["severity"]) == "ERROR":
				_counts["errors"] = int(_counts["errors"]) + 1
			else:
				_counts["warnings"] = int(_counts["warnings"]) + 1
			if _messages.size() < MAX_MESSAGES:
				_messages.append("%s: %s" % [String(entry["code"]), String(entry["message"])])
		var start := source.poi(WorldSource.POI_PLAYER_START)
		if start != Vector2.INF:
			_reachable = WorldValidator.flood_fill(source.grid, start)


func _refresh_panel() -> void:
	if _panel == null:
		return
	var mode := "AUTHORED" if WorldRules.get_source() is AuthoredWorldSource else "FORMULA"
	var lines := PackedStringArray()
	lines.append("World: %s | mode: %s | E:%d W:%d | O: toggle" % [
		String(WorldRules.id()), mode, int(_counts["errors"]), int(_counts["warnings"])
	])
	if _messages.is_empty():
		lines.append("Tidak ada masalah.")
	else:
		for message in _messages:
			lines.append("- %s" % message)
	_panel.text = "\n".join(lines)


func _draw() -> void:
	if not _enabled:
		return
	var step := float((config if config != null else WorldConfig.new()).overlay_cell_px)
	step = maxf(step, 8.0)
	var view := _camera_rect()
	var authored := WorldRules.get_source() is AuthoredWorldSource
	var col_from := int(floor(view.position.x / step)) - 1
	var col_to := int(ceil(view.end.x / step)) + 1
	var row_from := int(floor(view.position.y / step)) - 1
	var row_to := int(ceil(view.end.y / step)) + 1
	for row in range(row_from, row_to + 1):
		for col in range(col_from, col_to + 1):
			var cell := Rect2(Vector2(col, row) * step, Vector2(step, step))
			var center := cell.position + Vector2(step, step) * 0.5
			var zone := WorldRules.zone_at(center)
			var tint := WorldZoneType.color(zone)
			tint.a = 0.22
			draw_rect(cell, tint, true)
			if not WorldRules.is_walkable(center):
				draw_rect(cell, Color(0.05, 0.05, 0.05, 0.35), true)
			elif authored and not _reachable.is_empty():
				var index := ZoneGrid.cell_index(WorldRules.get_source().grid, center)
				if index >= 0 and index < _reachable.size() and int(_reachable[index]) == 0:
					draw_rect(cell, Color(0.8, 0.1, 0.1, 0.35), true)

	for poi_name in [
		WorldSource.POI_PLAYER_START, WorldSource.POI_PLANE_WRECKAGE,
		WorldSource.POI_EMERGENCY_SUITCASE, WorldSource.POI_SIGNAL_BEACON,
	]:
		var point := WorldRules.poi(poi_name)
		if point == Vector2.INF:
			continue
		draw_circle(point, 9.0, Color(0.95, 0.85, 0.3, 0.85))
		_draw_label(point + Vector2(10.0, -10.0), String(poi_name))
	for point in WorldRules.night_spawn_points():
		draw_circle(point, 5.0, Color(0.55, 0.35, 0.95, 0.9))
	for point in WorldRules.water_access_points():
		draw_circle(point, 6.0, Color(0.3, 0.7, 0.95, 0.9))
		_draw_label(point + Vector2(8.0, 12.0), "air")


func _draw_label(position_value: Vector2, text: String) -> void:
	draw_string(
		ThemeDB.fallback_font,
		position_value,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		12,
		Color(0.97, 0.97, 0.9, 0.9)
	)


func _camera_rect() -> Rect2:
	var viewport := get_viewport()
	if viewport == null:
		return Rect2(Vector2.ZERO, Vector2(1152.0, 648.0))
	var canvas := viewport.get_canvas_transform()
	return canvas.affine_inverse() * viewport.get_visible_rect()


func _camera_position() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2.ZERO
	var camera := viewport.get_camera_2d()
	if camera == null:
		return Vector2.ZERO
	return camera.global_position

class_name FireStarterHUD
extends CanvasLayer

## Read-only HUD minigame gesek batu: bar dengan zona, marker, dan status.

const WIDTH := 260.0
const HEIGHT := 14.0
const TEXT_IDLE := ""
const TEXT_MISS := "Meleset"
const TEXT_GOOD := "Percikan!"
const TEXT_PERFECT := "Percikan!"
const TEXT_SUCCESS := "Api menyala!"
const TEXT_FAIL := "Gagal, batu aus"

@export var controller: FireStarterController

var _status: Label
var _bar: ColorRect
var _good: ColorRect
var _perfect: ColorRect
var _marker: ColorRect
var _text: String = ""


func _ready() -> void:
	layer = 23
	_build()
	refresh()


func _process(_delta: float) -> void:
	refresh()


func get_status_text() -> String:
	return _text


func is_showing() -> bool:
	return _status != null and _status.visible


func refresh() -> void:
	if controller == null:
		controller = _find_controller()
	if controller == null:
		_set_text(TEXT_IDLE, false)
		return
	var active := controller.is_active()
	var result_visible := controller.state == FireStarterController.State.RESULT
	var showing := active or result_visible
	_set_text(_resolve_text(), showing)
	if showing:
		_marker.position = Vector2(WIDTH * controller.get_marker() - 1.0, -3.0)
	_set_marker_visible(showing)


func _resolve_text() -> String:
	if controller == null:
		return TEXT_IDLE
	if controller.state == FireStarterController.State.RESULT:
		return TEXT_SUCCESS if controller.get_last_success() else TEXT_FAIL
	if not controller.is_active():
		return TEXT_IDLE
	match controller.get_last_quality():
		FireStarterController.Quality.PERFECT:
			return TEXT_PERFECT
		FireStarterController.Quality.GOOD:
			return TEXT_GOOD
		_:
			return TEXT_MISS if controller.get_strikes() > 0 else ""
	return TEXT_IDLE


func _find_controller() -> FireStarterController:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(FireStarterController.GROUP) as FireStarterController


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.position = Vector2(16.0, 64.0)
	add_child(root)

	_bar = ColorRect.new()
	_bar.name = "Bar"
	_bar.color = Color(0.15, 0.15, 0.15, 0.7)
	_bar.size = Vector2(WIDTH, HEIGHT)
	_bar.position = Vector2.ZERO
	root.add_child(_bar)

	var config := controller.config if controller != null else FireStarterConfig.new()
	_good = ColorRect.new()
	_good.name = "GoodZone"
	_good.color = Color(0.9, 0.8, 0.3, 0.55)
	_good.size = Vector2(WIDTH * config.good_zone, HEIGHT)
	_good.position = Vector2(WIDTH * (0.5 - config.good_zone * 0.5), 0.0)
	root.add_child(_good)

	_perfect = ColorRect.new()
	_perfect.name = "PerfectZone"
	_perfect.color = Color(0.3, 0.95, 0.4, 0.8)
	_perfect.size = Vector2(WIDTH * config.perfect_zone, HEIGHT)
	_perfect.position = Vector2(WIDTH * (0.5 - config.perfect_zone * 0.5), 0.0)
	root.add_child(_perfect)

	_marker = ColorRect.new()
	_marker.name = "Marker"
	_marker.color = Color(1.0, 1.0, 1.0, 1.0)
	_marker.size = Vector2(3.0, HEIGHT + 6.0)
	root.add_child(_marker)

	_status = Label.new()
	_status.name = "Status"
	_status.add_theme_font_size_override("font_size", 12)
	_status.position = Vector2(0.0, HEIGHT + 6.0)
	root.add_child(_status)


func _set_text(value: String, visible_value: bool) -> void:
	_text = value
	if _status != null:
		_status.text = value
		_status.visible = visible_value


func _set_marker_visible(value: bool) -> void:
	if _marker != null:
		_marker.visible = value
	if _bar != null:
		_bar.visible = value
	if _good != null:
		_good.visible = value
	if _perfect != null:
		_perfect.visible = value

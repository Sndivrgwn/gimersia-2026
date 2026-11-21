class_name NightBanner
extends Control

## Mission 7: banner malam/fajar 4 s.

const SHOW_TIME := 4.0
const EMBER_SNUFF_DAY := 5
const DAY7 := 7

@export var clock: Node
@export var endgame: Node

var _timer: float = 0.0
var _text: String = ""
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_label = Label.new()
	_label.name = "BannerLabel"
	add_child(_label)
	_connect()


func _connect() -> void:
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	if clock == null:
		return
	if clock.has_signal(&"night_started") and not clock.night_started.is_connected(_on_night_started):
		clock.night_started.connect(_on_night_started)
	if clock.has_signal(&"day_started") and not clock.day_started.is_connected(_on_day_started):
		clock.day_started.connect(_on_day_started)


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if _timer <= 0.0:
		return
	_timer = maxf(_timer - delta, 0.0)
	if _timer <= 0.0:
		visible = false


func _on_night_started(day: int) -> void:
	show_night(day)


func _on_day_started(day: int) -> void:
	if _should_skip_dawn():
		return
	show_dawn(day)


func show_night(day: int) -> void:
	var suffix := " - Ember Snuff aktif" if day >= EMBER_SNUFF_DAY else ""
	_show("Malam %d dimulai%s" % [day, suffix])


func show_dawn(day: int) -> void:
	if day > DAY7:
		return
	_show("Fajar hari %d - kamu selamat dari malam %d" % [day, day - 1])


func _should_skip_dawn() -> bool:
	if endgame == null:
		endgame = get_tree().get_first_node_in_group(&"endgame_controller") if get_tree() != null else null
	if endgame == null:
		return false
	if endgame.has_method(&"is_rescue_active") and endgame.is_rescue_active():
		return true
	return false


func _show(text: String) -> void:
	_text = text
	if _label != null:
		_label.text = text
	visible = true
	_timer = SHOW_TIME


func get_text() -> String:
	return _text


func is_showing() -> bool:
	return visible and _timer > 0.0

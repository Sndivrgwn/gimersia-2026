class_name RespawnRecapHUD
extends Control

## Mission 7: toast 8 s setelah respawn berisi debuff kematian.

const SHOW_TIME := 8.0
const PROF_NAMES: Array[String] = ["Kekuatan", "Kecepatan", "Penguasaan", "Kelincahan"]

var _timer: float = 0.0
var _text: String = ""
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_label = Label.new()
	_label.name = "RecapLabel"
	add_child(_label)


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if _timer <= 0.0:
		return
	_timer = maxf(_timer - delta, 0.0)
	if _timer <= 0.0:
		visible = false


func show_recap(changes: Array) -> void:
	_text = format_recap(changes)
	if _label != null:
		_label.text = _text
	visible = true
	_timer = SHOW_TIME


func format_recap(changes: Array) -> String:
	if changes.is_empty():
		return "Tidak ada debuff"
	var parts: Array[String] = []
	for entry in changes:
		var prof := int(entry.get("prof", -1))
		var prof_name := "Proficiency" if prof < 0 or prof >= PROF_NAMES.size() else PROF_NAMES[prof]
		parts.append("%s Lv %d -> %d" % [prof_name, int(entry.get("from_level", 0)), int(entry.get("to_level", 0))])
	return "Debuff kematian: " + ", ".join(parts)


func get_text() -> String:
	return _text


func is_showing() -> bool:
	return visible and _timer > 0.0

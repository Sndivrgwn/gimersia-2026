class_name ProficiencyHUD
extends Control

## Mission 7: baris proficiency memerah 3 s saat debuff kematian.

const FLASH_TIME := 3.0
const PROF_NAMES: Array[String] = ["Kekuatan", "Kecepatan", "Penguasaan", "Kelincahan"]

var _flash: Dictionary = {}
var _labels: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if delta <= 0.0 or _flash.is_empty():
		return
	for prof in _flash.keys():
		_flash[prof] = maxf(_flash[prof] - delta, 0.0)
		var label := _labels.get(prof) as Label
		if label == null:
			continue
		if _flash[prof] <= 0.0:
			label.modulate = Color.WHITE
			_flash.erase(prof)
		else:
			label.modulate = Color(1.0, 0.3, 0.3, 1.0)


func flash_rows(changes: Array) -> void:
	for entry in changes:
		var prof: int = int(entry.get("prof", -1))
		if prof < 0:
			continue
		_flash[prof] = FLASH_TIME
		var label := _labels.get(prof) as Label
		if label != null:
			label.modulate = Color(1.0, 0.3, 0.3, 1.0)


func is_row_flashing(prof: int) -> bool:
	return _flash.has(prof) and float(_flash[prof]) > 0.0


func get_row_text(prof: int) -> String:
	var label := _labels.get(prof) as Label
	return "" if label == null else label.text


func set_row_text(prof: int, text: String) -> void:
	var label := _labels.get(prof) as Label
	if label != null:
		label.text = text


func _build() -> void:
	var box := VBoxContainer.new()
	box.name = "Rows"
	add_child(box)
	for prof in PROF_NAMES.size():
		var label := Label.new()
		label.text = PROF_NAMES[prof]
		box.add_child(label)
		_labels[prof] = label

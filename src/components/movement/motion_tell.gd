class_name MotionTell
extends Node2D

## Mission 9 fase 4: tell visual mode gerak pemain (jongkok / mengarungi sungai).
## Label dibuat runtime (tanpa aset biner, tanpa state art baru) supaya pemain
## tahu kenapa geraknya lambat. Hanya MEMBACA state Player, tidak menulis apa pun.

const SNEAK_TEXT := "JONGKOK"
const WADING_TEXT := "AIR"
const SNEAK_COLOR := Color(0.72, 0.92, 1.0, 0.95)
const WADING_COLOR := Color(0.45, 0.72, 1.0, 0.95)
const TELL_OFFSET := Vector2(-30.0, -46.0)
const FONT_SIZE := 10

@export var player: Player

var _label: Label


func _ready() -> void:
	if player == null:
		player = get_parent() as Player
	_label = Label.new()
	_label.name = "Tell"
	_label.position = TELL_OFFSET
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	add_child(_label)
	tick()


func _process(_delta: float) -> void:
	tick()


## Satu langkah baca state; dipanggil _process dan tes.
func tick() -> void:
	if _label == null:
		return
	var text := ""
	var tint := SNEAK_COLOR
	if player != null and is_instance_valid(player):
		if player.is_sneaking():
			text = SNEAK_TEXT
		if player.is_wading():
			text = WADING_TEXT if text.is_empty() else "%s + %s" % [SNEAK_TEXT, WADING_TEXT]
			tint = WADING_COLOR
	_label.text = text
	_label.add_theme_color_override("font_color", tint)
	_label.visible = not text.is_empty()


func get_text() -> String:
	return _label.text if _label != null else ""


func is_showing() -> bool:
	return _label != null and _label.visible

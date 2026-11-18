extends Node

## Practice-only debug keys: paksa Hunger/Thirst/Fatigue ke batas tier supaya
## efeknya langsung terlihat di StatsHUD. Default mati; F1 menyalakannya.
## Tidak dipakai di level produksi (sama seperti SafeZone).

const PLAYER_GROUP := &"player"
const NEEDS_NAME := "NeedsComponent"
const LOW_VALUE := 25.0
const FULL_VALUE := 100.0
const NEED_NAMES: Array[String] = ["Hunger", "Thirst", "Fatigue"]
const HINT_TEXT := """NEEDS DEBUG ON
X hunger · C thirst · V fatigue   (100 -> 25 -> 0 -> 100)
B refill all · F1 toggle off"""

var _needs: NeedsComponent
var _hint: Label
var _enabled: bool = false


func _ready() -> void:
	var player := get_tree().get_first_node_in_group(PLAYER_GROUP)
	if player != null:
		_needs = player.get_node_or_null(NEEDS_NAME) as NeedsComponent
	if _needs == null:
		push_warning("NeedsDebug: NeedsComponent tidak ditemukan; debug keys nonaktif.")
		return
	_build_hint()


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	if key_event.physical_keycode == KEY_F1:
		if _hint == null:
			return
		_enabled = not _enabled
		_hint.visible = _enabled
		get_viewport().set_input_as_handled()
		return

	if not _enabled or _needs == null:
		return

	match key_event.physical_keycode:
		KEY_X:
			_cycle(NeedsComponent.Need.HUNGER)
		KEY_C:
			_cycle(NeedsComponent.Need.THIRST)
		KEY_V:
			_cycle(NeedsComponent.Need.FATIGUE)
		KEY_B:
			_refill()


func _build_hint() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	_hint = Label.new()
	_hint.position = Vector2(16.0, 186.0)
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55, 1.0))
	_hint.text = HINT_TEXT
	_hint.visible = false
	layer.add_child(_hint)


## 100 -> 25 (LOW) -> 0 (ZERO) -> 100.
func _cycle(need: int) -> void:
	var value := _needs.get_value(need)
	var next := FULL_VALUE
	if value > LOW_VALUE:
		next = LOW_VALUE
	elif value > 0.0:
		next = 0.0

	_needs.set_value(need, next)
	print("NeedsDebug: %s = %d" % [NEED_NAMES[need], int(next)])


func _refill() -> void:
	for need in NEED_NAMES.size():
		_needs.set_value(need, FULL_VALUE)
	print("NeedsDebug: semua needs = 100")

extends Node

## Mission 9 polish: kamera terasa hidup tanpa mengubah gameplay.
## - look-ahead kecil ke arah gerak (follow_offset PhantomCamera2D)
## - zoom sedikit lebih jauh saat malam
## Hanya menulis properti kamera; posisi pemain/hitbox tidak berubah.

const PLAYER_GROUP := &"player"

@export var look_ahead_px: float = 11.0
@export var follow_speed: float = 3.2
@export var day_zoom: float = 3.0
@export var night_zoom: float = 2.75
@export var zoom_time: float = 1.4

var _pcam: Node
var _player: CharacterBody2D
var _offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	_pcam = _find_pcam()
	_player = get_tree().get_first_node_in_group(PLAYER_GROUP) as CharacterBody2D
	var clock := get_node_or_null("/root/DayNightManager")
	var is_night := false
	if clock != null:
		if clock.has_signal(&"night_started"):
			clock.connect(&"night_started", _on_night_started)
		if clock.has_signal(&"day_started"):
			clock.connect(&"day_started", _on_day_started)
		if clock.has_method(&"is_night"):
			is_night = bool(clock.call(&"is_night"))
	_apply_zoom(night_zoom if is_night else day_zoom)


func _process(delta: float) -> void:
	if _pcam == null or _player == null:
		return
	var velocity := _player.velocity
	var target := Vector2.ZERO if velocity.length() <= 1.0 else velocity.normalized() * look_ahead_px
	_offset = _offset.lerp(target, clampf(delta * follow_speed, 0.0, 1.0))
	_pcam.set(&"follow_offset", _offset)


## Dipakai tes: offset look-ahead saat ini.
func get_offset() -> Vector2:
	return _offset


func _on_night_started(_day: int) -> void:
	_apply_zoom(night_zoom)


func _on_day_started(_day: int) -> void:
	_apply_zoom(day_zoom)


func _apply_zoom(value: float) -> void:
	if _pcam == null:
		return
	var target := Vector2(value, value)
	if DisplayServer.get_name() == "headless":
		_pcam.set(&"zoom", target)
		return
	var tween := create_tween()
	tween.tween_property(_pcam, "zoom", target, zoom_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _find_pcam() -> Node:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("PhantomCamera2D", true, false)

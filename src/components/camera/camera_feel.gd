extends Node

## Mission 9 polish / Fase 3A: kamera terasa hidup tanpa mengubah gameplay.
## - look-ahead kecil ke arah gerak (follow_offset PhantomCamera2D)
## - zoom sedikit lebih jauh saat malam
## - batas kamera di tepi pulau (Camera2D limit) supaya tidak ada area kosong
##
## Fase 3A: semua angka (look-ahead, follow speed, zoom, margin limit) dibaca
## dari `camera_feel_config.tres`. Setengah sisi pulau dibaca dari
## `IslandLayoutConfig.half_size` milik IslandBuilder, bukan angka baru.
## Hanya menulis properti kamera; posisi pemain/hitbox tidak berubah.

const PLAYER_GROUP := &"player"
const CONFIG_PATH := "res://src/data/configs/camera_feel_config.tres"
const BUILDER_NAME := "IslandBuilder"
const CAMERA_NAME := "Camera2D"
const DEFAULT_HALF_SIZE := 2400.0

@export var config: CameraFeelConfig
## Opsional; default ditemukan lewat nama node (dipakai tes juga).
@export var pcam: Node
@export var camera: Camera2D
@export var player: CharacterBody2D

var _offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	if config == null:
		config = load(CONFIG_PATH) as CameraFeelConfig
	_resolve_nodes()
	var clock := get_node_or_null("/root/DayNightManager")
	var is_night := false
	if clock != null:
		if clock.has_signal(&"night_started"):
			clock.connect(&"night_started", _on_night_started)
		if clock.has_signal(&"day_started"):
			clock.connect(&"day_started", _on_day_started)
		if clock.has_method(&"is_night"):
			is_night = bool(clock.call(&"is_night"))
	apply_limits()
	_apply_zoom(night_zoom() if is_night else day_zoom())


func _process(delta: float) -> void:
	tick(delta)


## Langkah kamera; publik supaya tes bisa menggerakkannya deterministik.
func tick(delta: float) -> void:
	_resolve_nodes()
	if pcam == null or player == null:
		return
	var velocity := player.velocity
	var target := Vector2.ZERO if velocity.length() <= 1.0 else velocity.normalized() * look_ahead_px()
	_offset = _offset.lerp(target, clampf(delta * follow_speed(), 0.0, 1.0))
	pcam.set(&"follow_offset", _offset)


## Dipakai tes: offset look-ahead saat ini.
func get_offset() -> Vector2:
	return _offset


# --- Angka dari config ------------------------------------------------------

func look_ahead_px() -> float:
	return 11.0 if config == null else config.look_ahead_px


func follow_speed() -> float:
	return 3.2 if config == null else config.follow_speed


func day_zoom() -> float:
	return 3.0 if config == null else config.day_zoom


func night_zoom() -> float:
	return 2.75 if config == null else config.night_zoom


func zoom_time() -> float:
	return 1.4 if config == null else config.zoom_time


func limit_margin() -> float:
	return 0.0 if config == null else config.camera_limit_margin


# --- Batas pulau ------------------------------------------------------------

## Pasang limit Camera2D di tepi pulau. `half_size` < 0 berarti baca dari
## IslandBuilder (fallback 2400 px).
func apply_limits(half_size: float = -1.0) -> void:
	if camera == null or not is_instance_valid(camera):
		camera = _find_camera()
	if camera == null:
		return
	var half := half_size
	if half < 0.0:
		half = get_world_half_size()
	var inner := maxf(half - limit_margin(), 1.0)
	camera.limit_left = int(-inner)
	camera.limit_right = int(inner)
	camera.limit_top = int(-inner)
	camera.limit_bottom = int(inner)


func get_world_half_size() -> float:
	var scene := get_tree().current_scene if get_tree() != null else null
	if scene != null:
		var builder := scene.find_child(BUILDER_NAME, true, false) as IslandBuilder
		if builder != null and builder.layout != null:
			return builder.layout.half_size
	return DEFAULT_HALF_SIZE


func get_limits() -> Dictionary:
	if camera == null:
		return {}
	return {
		"left": camera.limit_left,
		"right": camera.limit_right,
		"top": camera.limit_top,
		"bottom": camera.limit_bottom,
	}


# --- Internal ---------------------------------------------------------------

func _resolve_nodes() -> void:
	if pcam == null or not is_instance_valid(pcam):
		pcam = _find_pcam()
	if player == null or not is_instance_valid(player):
		var tree := get_tree()
		player = tree.get_first_node_in_group(PLAYER_GROUP) as CharacterBody2D if tree != null else null


func _find_pcam() -> Node:
	var scene := get_tree().current_scene if get_tree() != null else null
	if scene == null:
		return null
	var found := scene.find_child("PhantomCamera2D", true, false)
	if found != null:
		return found
	if camera != null:
		return camera.find_child("PhantomCamera2D", true, false)
	return null


func _find_camera() -> Camera2D:
	var scene := get_tree().current_scene if get_tree() != null else null
	if scene != null:
		var found := scene.find_child(CAMERA_NAME, true, false) as Camera2D
		if found != null:
			return found
	if pcam != null:
		var ancestor := pcam.get_parent()
		while ancestor != null:
			if ancestor is Camera2D:
				return ancestor as Camera2D
			ancestor = ancestor.get_parent()
	return null


func _on_night_started(_day: int) -> void:
	_apply_zoom(night_zoom())


func _on_day_started(_day: int) -> void:
	_apply_zoom(day_zoom())


func _apply_zoom(value: float) -> void:
	if pcam == null:
		return
	var target := Vector2(value, value)
	if DisplayServer.get_name() == "headless":
		pcam.set(&"zoom", target)
		return
	var tween := create_tween()
	tween.tween_property(pcam, "zoom", target, zoom_time()).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

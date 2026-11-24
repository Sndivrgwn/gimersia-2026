extends GutTest

## Fase 3: kamera look-ahead + limit pulau (3A) dan telegraph babi (3B).

const CAMERA_FEEL_SCRIPT := preload("res://src/components/camera/camera_feel.gd")
const CAMERA_CONFIG: CameraFeelConfig = preload("res://src/data/configs/camera_feel_config.tres")
const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")


class StubPcam extends Node:
	var follow_offset := Vector2.ZERO
	var zoom := Vector2(3.0, 3.0)


var _telegraph_started: int = 0
var _telegraph_ended: int = 0
var _telegraph_seconds: float = 0.0


# --- 3A: kamera -------------------------------------------------------------

func test_camera_config_values() -> void:
	assert_almost_eq(CAMERA_CONFIG.look_ahead_px, 11.0, 0.01, "look-ahead dari config")
	assert_almost_eq(CAMERA_CONFIG.follow_speed, 3.2, 0.01)
	assert_almost_eq(CAMERA_CONFIG.day_zoom, 3.0, 0.01)
	assert_almost_eq(CAMERA_CONFIG.night_zoom, 2.75, 0.01)
	assert_almost_eq(CAMERA_CONFIG.camera_limit_margin, 0.0, 0.01)


func test_camera_look_ahead_follows_velocity() -> void:
	var player := CharacterBody2D.new()
	add_child_autofree(player)
	var pcam := StubPcam.new()
	add_child_autofree(pcam)
	var feel := CAMERA_FEEL_SCRIPT.new()
	feel.config = CAMERA_CONFIG
	feel.player = player
	feel.pcam = pcam
	add_child_autofree(feel)

	player.velocity = Vector2(100.0, 0.0)
	feel.tick(0.1)
	var offset: Vector2 = feel.get_offset()
	assert_gt(offset.x, 0.0, "kamera bergeser ke arah gerak")
	assert_lt(offset.x, CAMERA_CONFIG.look_ahead_px + 0.01, "tidak melewati look-ahead")
	assert_almost_eq(pcam.follow_offset.x, offset.x, 0.01, "offset diteruskan ke kamera")

	player.velocity = Vector2.ZERO
	for index in 20:
		feel.tick(0.2)
	assert_almost_eq(feel.get_offset().length(), 0.0, 0.05, "berhenti: offset kembali ke nol")


func test_camera_limits_follow_island_edge() -> void:
	var camera := Camera2D.new()
	add_child_autofree(camera)
	var feel := CAMERA_FEEL_SCRIPT.new()
	feel.camera = camera
	add_child_autofree(feel)

	feel.apply_limits(2400.0)
	var limits: Dictionary = feel.get_limits()
	assert_eq(int(limits["left"]), -2400, "batas kiri = tepi pulau")
	assert_eq(int(limits["right"]), 2400)
	assert_eq(int(limits["top"]), -2400)
	assert_eq(int(limits["bottom"]), 2400)

	var config := CameraFeelConfig.new()
	config.camera_limit_margin = 100.0
	feel.config = config
	feel.apply_limits(2400.0)
	assert_eq(camera.limit_right, 2300, "margin menarik batas ke dalam")


# --- 3B: telegraph babi -----------------------------------------------------

func test_boar_telegraph_signals_and_visuals() -> void:
	var boar := BOAR_SCENE.instantiate() as WildBoar
	add_child_autofree(boar)
	boar.ensure_ready()
	boar.telegraph_started.connect(_on_telegraph_started)
	boar.telegraph_ended.connect(_on_telegraph_ended)

	var boar_config := boar.config_boar()
	boar.call(&"_begin_telegraph", Vector2(150.0, 0.0), boar_config)

	assert_eq(_telegraph_started, 1, "telegraph_started dipancarkan (hook suara)")
	assert_almost_eq(_telegraph_seconds, boar_config.dash_telegraph, 0.001)
	assert_true(boar.is_telegraph_active())
	var line := boar.get_telegraph_line()
	assert_not_null(line, "garis merah ada")
	assert_not_null(boar.get_telegraph_ring(), "cincin zona bahaya ada")
	assert_gt(line.width, 0.0)
	var width_start := line.width

	boar.call(&"_tick_telegraph", boar_config.dash_telegraph * 0.6, boar_config)
	assert_gt(line.width, width_start, "garis makin tebal menjelang dash")

	boar.call(&"_tick_telegraph", boar_config.dash_telegraph, boar_config)
	assert_false(boar.is_telegraph_active(), "telegraph selesai saat dash mulai")
	assert_eq(_telegraph_ended, 1, "telegraph_ended sekali")
	assert_null(boar.get_telegraph_line(), "visual dibersihkan")
	assert_null(boar.get_telegraph_ring())


func _on_telegraph_started(_target: Vector2, seconds: float) -> void:
	_telegraph_started += 1
	_telegraph_seconds = seconds


func _on_telegraph_ended() -> void:
	_telegraph_ended += 1

extends GutTest

## Mission 9 Phase 1.6: massa babi dengan body fisika sungguhan.
## (A) pemain menabrak babi diam tidak menembus/mendorong, (B) pemain menjauh
## tidak menyeret babi, (C) babi yang mengejar berhenti di jarak kontak,
## (D) knockback pemain diperkecil knockback_resistance.

const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const DELTA := 1.0 / 60.0
const PLAYER_RADIUS := 12.0
const BOAR_RADIUS := 12.0


## Clock netral: tanpa ini boar membaca autoload DayNightManager dan bisa
## mendadak HOSTILE saat suite sudah berjalan lama (malam).
class StubClock extends Node:
	func is_night() -> bool:
		return false

	func get_current_day() -> int:
		return 1

	func get_time_scale() -> float:
		return 1.0


var _clock: StubClock


func before_each() -> void:
	_clock = StubClock.new()
	add_child_autofree(_clock)


func _spawn_player(position: Vector2) -> Player:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.global_position = position
	player.set_physics_process(false)
	return player


func _spawn_boar(position: Vector2, player: Player) -> WildBoar:
	var boar := BOAR_SCENE.instantiate() as WildBoar
	boar.player = player
	boar.clock = _clock
	add_child_autofree(boar)
	boar.global_position = position
	boar.ensure_ready()
	boar.set_physics_process(false)
	boar._wander_pause = 9999.0
	return boar


func _walk(body: CharacterBody2D, frames: int) -> void:
	for index in frames:
		body.move_and_slide()
		await get_tree().physics_frame


func _tick(boar: WildBoar, frames: int) -> void:
	for index in frames:
		boar.tick(DELTA)
		await get_tree().physics_frame


# --- (A) pemain menabrak babi diam -----------------------------------------

func test_a_player_walking_into_a_still_boar_does_not_overlap_it() -> void:
	var player := _spawn_player(Vector2.ZERO)
	var boar := _spawn_boar(Vector2(60.0, 0.0), player)
	await get_tree().physics_frame
	var boar_start := boar.global_position
	player.velocity = Vector2.RIGHT * 240.0
	await _walk(player, 120)
	assert_lt(boar.global_position.distance_to(boar_start), 1.0, "babi diam tidak bergeser")
	var gap := player.global_position.distance_to(boar.global_position)
	assert_gte(gap, PLAYER_RADIUS + BOAR_RADIUS - 2.0, "tidak menembus lebih dari 2 px")


# --- (B) pemain menjauh tidak menyeret babi --------------------------------

func test_b_player_walking_away_does_not_drag_the_boar() -> void:
	var player := _spawn_player(Vector2.ZERO)
	var boar := _spawn_boar(Vector2(60.0, 0.0), player)
	await get_tree().physics_frame
	player.velocity = Vector2.RIGHT * 240.0
	await _walk(player, 60)
	var boar_pressed := boar.global_position
	player.velocity = Vector2.LEFT * 240.0
	await _walk(player, 60)
	assert_lt(boar.global_position.distance_to(boar_pressed), 1.0, "menjauh tidak menyeret babi")


# --- (C) babi mengejar berhenti di jarak kontak ----------------------------

func test_c_chasing_boar_stops_at_contact_distance() -> void:
	var player := _spawn_player(Vector2.ZERO)
	var boar := _spawn_boar(Vector2(220.0, 0.0), player)
	boar.forced_hostile = true
	await get_tree().physics_frame
	var player_start := player.global_position
	await _tick(boar, 240)
	var contact := boar.get_contact_distance_to_player()
	var samples: Array[float] = []
	for index in 60:
		boar.tick(DELTA)
		await get_tree().physics_frame
		samples.append(boar.global_position.distance_to(player.global_position))
	var low := samples[0]
	var high := samples[0]
	for value in samples:
		low = minf(low, value)
		high = maxf(high, value)
	assert_almost_eq(low, contact, 3.0)
	assert_lte(high - low, 3.0, "jarak stabil +-3 px selama 1 s")
	assert_lt(player.global_position.distance_to(player_start), 1.0, "pemain tidak didorong")


# --- (D) knockback diperkecil resistensi -----------------------------------

func test_d_melee_knockback_is_scaled_by_knockback_resistance() -> void:
	# Jauh dari origin: body dari tes sebelumnya yang masih menunggu queue_free
	# tidak boleh menumpuk dengan boar tes ini.
	var player := _spawn_player(Vector2(1400.0, 1000.0))
	var boar := _spawn_boar(Vector2(1000.0, 1000.0), player)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var start := boar.global_position
	boar.apply_knockback(Vector2.RIGHT, 40.0, 0.1)
	await _tick(boar, 6)
	var moved := boar.global_position.x - start.x
	assert_almost_eq(moved, 40.0 * 0.35, 1.0)


## Mission 10 Phase 4 (R4): rusa kini badan padat dan menerima knockback 0.6
## lewat BodyProfile, bukan lagi menembus pemain dengan knockback penuh.
func test_d2_deer_blocks_and_takes_reduced_knockback() -> void:
	var deer := FaunaConfig.new()
	assert_eq(deer.knockback_resistance, 1.0)
	var deer_config := DeerConfig.new()
	assert_true(deer_config.blocks_player, "rusa memblokir pemain")
	assert_almost_eq(deer_config.knockback_resistance, 0.6, 0.01)
	var boar := BoarConfig.new()
	assert_true(boar.blocks_player, "babi memblokir pemain")


# --- Tidak tersangkut & tidak menumpuk -------------------------------------

func test_player_pinned_between_boar_and_wall_can_slide_out() -> void:
	var player := _spawn_player(Vector2.ZERO)
	var wall := StaticBody2D.new()
	wall.collision_layer = PhysicsLayers.WORLD
	wall.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20.0, 400.0)
	shape.shape = box
	wall.add_child(shape)
	add_child_autofree(wall)
	wall.global_position = Vector2(34.0, 0.0)
	var boar := _spawn_boar(Vector2(-34.0, 0.0), player)
	boar.forced_hostile = true
	await get_tree().physics_frame
	for index in 60:
		boar.tick(DELTA)
		await get_tree().physics_frame
	var start_y := player.global_position.y
	player.velocity = Vector2.DOWN * 160.0
	await _walk(player, 60)
	assert_gt(player.global_position.y - start_y, 20.0, "pemain bisa keluar dari jepitan")


func test_two_boars_do_not_stack_on_one_point() -> void:
	var player := _spawn_player(Vector2(40.0, 0.0))
	var front := _spawn_boar(Vector2(160.0, 0.0), player)
	front.forced_hostile = true
	var chaser := _spawn_boar(Vector2(280.0, 0.0), player)
	chaser.forced_hostile = true
	await get_tree().physics_frame
	var closest := 9999.0
	for index in 180:
		chaser.tick(DELTA)
		front.tick(DELTA)
		await get_tree().physics_frame
		closest = minf(closest, chaser.global_position.distance_to(front.global_position))
	assert_gte(closest, BOAR_RADIUS * 2.0 - 2.0, "dua babi tidak saling menumpuk")


func test_player_layer_and_mask_include_the_fauna_body_bit() -> void:
	var player := _spawn_player(Vector2.ZERO)
	await get_tree().physics_frame
	assert_eq(player.collision_layer & PhysicsLayers.PLAYER_BODY, PhysicsLayers.PLAYER_BODY)
	assert_eq(player.collision_mask & PhysicsLayers.FAUNA_BODY, PhysicsLayers.FAUNA_BODY)
	var boar := _spawn_boar(Vector2(40.0, 0.0), player)
	assert_eq(boar.collision_layer, PhysicsLayers.FAUNA_BODY)
	assert_eq(boar.collision_mask & PhysicsLayers.PLAYER_BODY, PhysicsLayers.PLAYER_BODY)
	assert_eq(boar.collision_mask & PhysicsLayers.FENCE_LAYER, PhysicsLayers.FENCE_LAYER)

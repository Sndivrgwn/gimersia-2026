extends GutTest

## Mission 10 Phase 4: matriks fisika dengan CharacterBody2D sungguhan.
## Babi sudah punya matriks penuh di test_boar_mass.gd; file ini menguji rusa
## (A kontak, B lepas, D knockback, E jepitan, F anti-tumpuk) plus jarak
## kontak dan pemisah badan.

const DEER_SCENE: PackedScene = preload("res://src/entities/fauna/island_deer/island_deer.tscn")
const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const DELTA := 1.0 / 60.0
const PLAYER_RADIUS := 12.0
const DEER_RADIUS := 10.0


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


func _spawn_deer(position: Vector2, player: Player) -> IslandDeer:
	var deer := DEER_SCENE.instantiate() as IslandDeer
	deer.player = player
	deer.clock = _clock
	add_child_autofree(deer)
	deer.global_position = position
	deer.ensure_ready()
	deer.set_physics_process(false)
	deer._wander_pause = 9999.0
	return deer


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
	for _index in frames:
		body.move_and_slide()
		await get_tree().physics_frame


func _tick(fauna: FaunaBase, frames: int) -> void:
	for _index in frames:
		fauna.tick(DELTA)
		await get_tree().physics_frame


func test_deer_is_solid_and_blocks_the_player() -> void:
	var player := _spawn_player(Vector2.ZERO)
	var deer := _spawn_deer(Vector2(60.0, 0.0), player)
	await get_tree().physics_frame
	assert_eq(deer.collision_layer, PhysicsLayers.FAUNA_BODY, "rusa ada di layer badan fauna")
	assert_eq(deer.collision_mask & PhysicsLayers.PLAYER_BODY, PhysicsLayers.PLAYER_BODY)
	assert_true(deer._deer_config().blocks_player)


# --- (A) pemain menabrak rusa diam -----------------------------------------

func test_a_player_walking_into_a_still_deer_does_not_move_or_overlap_it() -> void:
	var player := _spawn_player(Vector2.ZERO)
	var deer := _spawn_deer(Vector2(60.0, 0.0), player)
	await get_tree().physics_frame
	var start := deer.global_position
	player.velocity = Vector2.RIGHT * 240.0
	await _walk(player, 120)
	assert_lt(deer.global_position.distance_to(start), 1.0, "rusa diam tidak bergeser")
	var gap := player.global_position.distance_to(deer.global_position)
	assert_gte(gap, PLAYER_RADIUS + DEER_RADIUS - 2.0, "tidak menembus lebih dari max_overlap_px")


# --- (B) pemain menjauh tidak menyeret rusa --------------------------------

func test_b_player_walking_away_does_not_drag_the_deer() -> void:
	var player := _spawn_player(Vector2.ZERO)
	var deer := _spawn_deer(Vector2(60.0, 0.0), player)
	await get_tree().physics_frame
	player.velocity = Vector2.RIGHT * 240.0
	await _walk(player, 60)
	var pressed := deer.global_position
	player.velocity = Vector2.LEFT * 240.0
	await _walk(player, 60)
	assert_lt(deer.global_position.distance_to(pressed), 1.0, "menjauh tidak menyeret rusa")


# --- (C) jarak kontak stabil -----------------------------------------------

func test_c_deer_contact_gap_is_stable_and_never_stacks() -> void:
	# Rusa tidak punya state mengejar; jarak kontak dijaga oleh badan padat +
	# pemisah. Dua rusa yang bertumpuk harus berpisah dan stabil.
	var player := _spawn_player(Vector2(1000.0, 1000.0))
	var first := _spawn_deer(Vector2(40.0, 0.0), player)
	var second := _spawn_deer(Vector2(52.0, 0.0), player)
	await get_tree().physics_frame
	await _tick(first, 60)
	var samples: Array[float] = []
	for _index in 60:
		first.tick(DELTA)
		second.tick(DELTA)
		await get_tree().physics_frame
		samples.append(first.global_position.distance_to(second.global_position))
	var low := samples[0]
	var high := samples[0]
	for value in samples:
		low = minf(low, value)
		high = maxf(high, value)
	assert_gte(low, DEER_RADIUS * 2.0 - 2.0, "dua rusa tidak menumpuk")
	assert_lte(high - low, 3.0, "jarak stabil +-3 px selama 1 s")


# --- (D) knockback memakai pengali profil ----------------------------------

func test_d_deer_knockback_uses_the_profile_multiplier() -> void:
	var player := _spawn_player(Vector2(1400.0, 1000.0))
	var deer := _spawn_deer(Vector2(1000.0, 1000.0), player)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var start := deer.global_position
	deer.apply_knockback(Vector2.RIGHT, 40.0, 0.1)
	await _tick(deer, 6)
	var moved := deer.global_position.x - start.x
	assert_almost_eq(moved, 40.0 * 0.6, 1.0, "rusa menerima 60% knockback")


func test_d2_boar_knockback_uses_the_profile_multiplier() -> void:
	var player := _spawn_player(Vector2(1400.0, 1200.0))
	var boar := _spawn_boar(Vector2(1000.0, 1200.0), player)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var start := boar.global_position
	boar.apply_knockback(Vector2.RIGHT, 40.0, 0.1)
	await _tick(boar, 6)
	var moved := boar.global_position.x - start.x
	assert_almost_eq(moved, 40.0 * 0.35, 1.0, "babi menerima 35% knockback")


# --- (E) pemain terjepit bisa keluar ---------------------------------------

func test_e_player_pinned_between_deer_and_wall_can_slide_out() -> void:
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
	var deer := _spawn_deer(Vector2(-34.0, 0.0), player)
	await get_tree().physics_frame
	for _index in 60:
		deer.tick(DELTA)
		await get_tree().physics_frame
	var start_y := player.global_position.y
	player.velocity = Vector2.DOWN * 160.0
	await _walk(player, 60)
	assert_gt(player.global_position.y - start_y, 20.0, "pemain bisa keluar dari jepitan")


# --- (F) dua rusa tidak menumpuk -------------------------------------------

func test_f_two_deer_never_stack_on_one_point() -> void:
	var player := _spawn_player(Vector2(1000.0, 1200.0))
	var first := _spawn_deer(Vector2(160.0, 1200.0), player)
	var second := _spawn_deer(Vector2(170.0, 1200.0), player)
	await get_tree().physics_frame
	# Beri waktu pemisah badan menyelesaikan tumpukan awal (10 px).
	for _index in 120:
		first.tick(DELTA)
		second.tick(DELTA)
		await get_tree().physics_frame
	var closest := 9999.0
	for _index in 60:
		first.tick(DELTA)
		second.tick(DELTA)
		await get_tree().physics_frame
		closest = minf(closest, first.global_position.distance_to(second.global_position))
	assert_gte(closest, DEER_RADIUS * 2.0 - 2.0, "dua rusa tidak saling menumpuk")

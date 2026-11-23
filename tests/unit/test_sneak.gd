extends GutTest

## Mission 9 fase 4: jongkok (sneak) — lebih lambat, lebih samar, tanpa sprint.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")

var player: Player


func before_each() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.set_physics_process(false)
	player.global_position = Vector2(1000.0, 1000.0)


func after_each() -> void:
	for action in [&"move_right", &"move_left", &"sneak"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)


func test_sneak_slows_and_blocks_sprint() -> void:
	player.set_sneaking(true)
	assert_true(player.is_sneaking())
	assert_true(player.is_sprint_blocked())
	assert_has(player.get_sprint_blocks(), &"sneak")
	assert_almost_eq(player.get_move_speed_multiplier(), 0.55, 0.001)


func test_sneak_reduces_detection() -> void:
	assert_eq(player.get_stealth_multiplier(), 1.0, "berdiri biasa = deteksi penuh")
	player.set_sneaking(true)
	assert_almost_eq(player.get_stealth_multiplier(), 0.6, 0.001)


func test_release_sneak_restores_everything() -> void:
	player.set_sneaking(true)
	player.set_sneaking(false)
	assert_false(player.is_sneaking())
	assert_false(player.is_sprint_blocked())
	assert_almost_eq(player.get_move_speed_multiplier(), 1.0, 0.001)
	assert_eq(player.get_stealth_multiplier(), 1.0)


func test_sneak_stops_an_active_sprint() -> void:
	player._set_sprinting(true)
	player.set_sneaking(true)
	assert_false(player.is_sprinting(), "sprint berhenti saat jongkok")


func test_sneak_config_is_used() -> void:
	var config := SneakConfig.new()
	config.speed_multiplier = 0.3
	config.detection_multiplier = 0.4
	config.blocks_sprint = false
	player.sneak_config = config
	player.set_sneaking(true)
	assert_almost_eq(player.get_move_speed_multiplier(), 0.3, 0.001)
	assert_almost_eq(player.get_stealth_multiplier(), 0.4, 0.001)
	assert_false(player.is_sprint_blocked(), "config boleh mematikan blokir sprint")


## Mission 9 fase 4: bukti nyata bahwa jongkok lebih lambat, bukan hanya angka
## multiplier. Dua lapis: velocity yang dipakai Player, dan jarak tempuh nyata
## selama frame fisika dengan input sungguhan ditekan.
func test_sneak_velocity_is_slower_than_walking() -> void:
	Input.action_press(&"move_right")
	player._physics_process(0.016)
	var walk_speed := player.velocity.length()
	Input.action_press(&"sneak")
	player._physics_process(0.016)
	var sneak_speed := player.velocity.length()
	Input.action_release(&"move_right")
	Input.action_release(&"sneak")
	assert_gt(walk_speed, 0.0, "input kanan harus menggerakkan pemain")
	assert_lt(sneak_speed, walk_speed, "velocity jongkok lebih kecil")
	assert_almost_eq(sneak_speed, walk_speed * 0.55, 0.5)


func test_player_really_moves_slower_while_sneaking() -> void:
	var walk_distance: float = await _distance_while_moving(8, false)
	var sneak_distance: float = await _distance_while_moving(8, true)
	assert_gt(walk_distance, 1.0, "berjalan harus benar-benar berpindah")
	assert_gt(sneak_distance, 0.0, "jongkok tetap bergerak")
	assert_lt(sneak_distance, walk_distance, "jarak jongkok lebih pendek")
	assert_almost_eq(sneak_distance / walk_distance, 0.55, 0.08, "rasio jarak = 0.55")


## Jalankan pemain dengan input nyata selama `frames` frame fisika.
func _distance_while_moving(frames: int, sneaking: bool) -> float:
	player.global_position = Vector2(1200.0, 1200.0)
	player.set_physics_process(true)
	Input.action_press(&"move_right")
	if sneaking:
		Input.action_press(&"sneak")
	await get_tree().physics_frame
	var start := player.global_position
	for index in frames:
		await get_tree().physics_frame
	var distance := player.global_position.distance_to(start)
	Input.action_release(&"move_right")
	if sneaking:
		Input.action_release(&"sneak")
	player.set_physics_process(false)
	return distance


func test_tell_shows_sneak_text() -> void:
	var tell := player.get_node("MotionTell") as MotionTell
	tell.tick()
	assert_false(tell.is_showing(), "berdiri biasa tanpa tell")
	player.set_sneaking(true)
	tell.tick()
	assert_true(tell.is_showing())
	assert_eq(tell.get_text(), MotionTell.SNEAK_TEXT)
	player.set_sneaking(false)
	tell.tick()
	assert_false(tell.is_showing(), "tell hilang setelah jongkok dilepas")


func test_default_config_comes_from_tres() -> void:
	assert_not_null(player.sneak_config, "SneakConfig default harus dari .tres")
	assert_almost_eq(player.sneak_config.speed_multiplier, 0.55, 0.001)
	assert_almost_eq(player.sneak_config.detection_multiplier, 0.6, 0.001)

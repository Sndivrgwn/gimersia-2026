extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")


func test_knockback_moves_distance_over_duration() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.set_physics_process(false)
	player.global_position = Vector2.ZERO
	player.apply_knockback(Vector2.RIGHT, 60.0, 0.2)
	assert_true(player.is_knocked_back())
	# 60 px / 0.2 s = 300 px/s.
	assert_almost_eq(player.get_knockback_velocity().x, 300.0, 0.5)
	assert_eq(player.get_knockback_velocity().y, 0.0)

	await _step(player, 0.2)
	assert_false(player.is_knocked_back())
	assert_eq(player.get_knockback_velocity(), Vector2.ZERO)
	# 60 px / 0.2 s, delta eksplisit -> perpindahan nyata 60 px.
	assert_almost_eq(player.global_position.x, 60.0, 0.5)
	assert_almost_eq(player.global_position.y, 0.0, 0.01)


func test_knockback_multiplier_is_a_hook() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	assert_eq(player.knockback_multiplier, 1.0)


func test_knockback_does_not_pass_the_coast() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.set_physics_process(false)
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(40.0, 400.0)
	shape.shape = rectangle
	wall.add_child(shape)
	add_child_autofree(wall)
	wall.global_position = Vector2(30.0, 0.0)

	player.global_position = Vector2.ZERO
	player.apply_knockback(Vector2.RIGHT, 200.0, 0.2)
	await _step(player, 0.2)
	assert_lt(player.global_position.x, 30.0, "dinding menahan knockback")
	assert_false(player.is_knocked_back())


func _step(player: Player, seconds: float) -> void:
	var delta := 0.02
	var frames := maxi(int(round(seconds / delta)), 1)
	for index in frames:
		player._physics_process(delta)
	await get_tree().process_frame

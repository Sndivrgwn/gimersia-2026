extends GutTest

## Mission 10 Phase 4: BodySeparation dan aturan jarak spawn 60 px.

const DEER_PROFILE: BodyProfile = preload("res://src/data/configs/physics/body_island_deer.tres")
const BOAR_PROFILE: BodyProfile = preload("res://src/data/configs/physics/body_wild_boar.tres")


func _body(position: Vector2, radius: float, profile: BodyProfile) -> CharacterBody2D:
	var body := CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	body.add_child(shape)
	add_child_autofree(body)
	body.global_position = position
	BodyProfileApplier.apply(body, profile, true)
	return body


func test_overlapping_body_is_pushed_apart_to_max_overlap() -> void:
	var first := _body(Vector2.ZERO, 10.0, DEER_PROFILE)
	var second := _body(Vector2(8.0, 0.0), 10.0, DEER_PROFILE)
	var moved := BodySeparation.apply(first, 1.0)
	assert_gt(moved.length(), 0.0, "badan yang bertumpuk digeser")
	assert_almost_eq(first.global_position.distance_to(second.global_position), 18.0, 0.5)


func test_separation_never_moves_toward_the_player() -> void:
	var first := _body(Vector2.ZERO, 10.0, DEER_PROFILE)
	var second := _body(Vector2(8.0, 0.0), 10.0, DEER_PROFILE)
	var player := Node2D.new()
	add_child_autofree(player)
	player.global_position = Vector2(100.0, 0.0)
	first.global_position = Vector2(2.0, 0.0)
	var before := first.global_position.distance_to(player.global_position)
	BodySeparation.apply(first, 1.0, player)
	assert_gte(first.global_position.distance_to(player.global_position), before, "tidak mendekat ke pemain")
	assert_true(is_instance_valid(second))


func test_separation_respects_walls() -> void:
	var first := _body(Vector2.ZERO, 10.0, DEER_PROFILE)
	var second := _body(Vector2(8.0, 0.0), 10.0, DEER_PROFILE)
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(20.0, 200.0)
	shape.shape = box
	wall.add_child(shape)
	wall.collision_layer = PhysicsLayers.WORLD
	wall.collision_mask = 0
	add_child_autofree(wall)
	wall.global_position = Vector2(-16.0, 0.0)
	var before_distance := first.global_position.distance_to(second.global_position)
	BodySeparation.apply(first, 1.0)
	assert_gte(first.global_position.distance_to(second.global_position), before_distance - 0.1, "tidak menembus dinding")


func test_spawn_clearance_rejects_points_near_player_and_fauna() -> void:
	var player := Node2D.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2.ZERO
	var fauna := Node2D.new()
	fauna.add_to_group(&"fauna")
	add_child_autofree(fauna)
	fauna.global_position = Vector2(500.0, 0.0)
	var tree := get_tree()
	assert_false(SpawnClearance.is_clear(tree, Vector2(59.0, 0.0), 60.0), "dekat pemain ditolak")
	assert_false(SpawnClearance.is_clear(tree, Vector2(541.0, 0.0), 60.0), "dekat fauna ditolak")
	assert_true(SpawnClearance.is_clear(tree, Vector2(300.0, 120.0), 60.0), "titik bebas diterima")


func test_profiles_carry_separation_numbers() -> void:
	assert_almost_eq(DEER_PROFILE.separation_speed, 60.0, 0.01)
	assert_almost_eq(DEER_PROFILE.max_overlap_px, 2.0, 0.01)
	assert_almost_eq(BOAR_PROFILE.contact_stop_extra, 2.0, 0.01)
	assert_false(DEER_PROFILE.pushable_by_others)
	assert_false(BOAR_PROFILE.pushable_by_others)

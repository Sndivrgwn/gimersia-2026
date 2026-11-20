extends GutTest

class StubPlayer extends Node2D:
	pass


const DEER_SCENE: PackedScene = preload("res://src/entities/fauna/island_deer/island_deer.tscn")


func _setup() -> Array:
	var player := StubPlayer.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2.ZERO
	var deer := DEER_SCENE.instantiate() as IslandDeer
	add_child_autofree(deer)
	deer.player = player
	deer.global_position = Vector2(100.0, 0.0)
	deer.ensure_ready()
	return [deer, player]


func test_deer_is_always_passive() -> void:
	var setup := _setup()
	var deer := setup[0] as IslandDeer
	assert_eq(deer.get_temperament(), FaunaBase.Temperament.PASSIVE)
	assert_eq(deer.get_health().get_max_hp(), 40.0)
	assert_false(deer.can_be_auto_targeted())


func test_deer_flees_when_player_is_close() -> void:
	var setup := _setup()
	var deer := setup[0] as IslandDeer
	deer.tick(0.1)
	assert_true(deer.is_fleeing())
	assert_eq(deer.get_state(), IslandDeer.State.FLEE)
	var before := deer.global_position.x
	deer.tick(0.5)
	assert_gt(deer.global_position.x, before, "kabur menjauh dari pemain")


func test_deer_flees_after_being_hit() -> void:
	var setup := _setup()
	var deer := setup[0] as IslandDeer
	deer.global_position = Vector2(400.0, 0.0)
	deer.get_health().take_damage(5.0, null)
	deer.tick(0.1)
	assert_true(deer.is_fleeing())

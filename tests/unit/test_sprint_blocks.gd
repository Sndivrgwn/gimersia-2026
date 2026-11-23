extends GutTest

## Mission 9 Phase 3.3: blokir sprint aditif dengan banyak sumber.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")

var player: Player


func before_each() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.set_physics_process(false)


func test_single_source_blocks_sprint() -> void:
	assert_false(player.is_sprint_blocked())
	player.add_sprint_block(&"hunger")
	assert_true(player.is_sprint_blocked())
	player.remove_sprint_block(&"hunger")
	assert_false(player.is_sprint_blocked())


func test_multiple_sources_need_each_removal() -> void:
	player.add_sprint_block(&"hunger")
	player.add_sprint_block(&"sneak")
	assert_eq(player.get_sprint_blocks().size(), 2)
	player.remove_sprint_block(&"hunger")
	assert_true(player.is_sprint_blocked(), "sneak masih memblokir")
	player.remove_sprint_block(&"sneak")
	assert_false(player.is_sprint_blocked())


func test_removing_unknown_source_is_safe() -> void:
	player.remove_sprint_block(&"tidak_ada")
	assert_false(player.is_sprint_blocked())


func test_block_stops_an_active_sprint() -> void:
	player._set_sprinting(true)
	assert_true(player.is_sprinting())
	player.add_sprint_block(&"hunger")
	assert_false(player.is_sprinting(), "sprint langsung berhenti saat diblokir")


func test_duplicate_source_is_idempotent() -> void:
	player.add_sprint_block(&"hunger")
	player.add_sprint_block(&"hunger")
	assert_eq(player.get_sprint_blocks().size(), 1)

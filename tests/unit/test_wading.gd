extends GutTest

## Mission 9 fase 4: mengarungi sungai memperlambat pemain dan memblokir sprint.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const RIVER_POINT := Vector2(-950.0, 200.0)
const FOREST_POINT := Vector2(500.0, 300.0)

var player: Player
var wading: WadingComponent


func before_each() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.set_physics_process(false)
	wading = player.get_node("WadingComponent") as WadingComponent
	wading.set_physics_process(false)
	player.global_position = FOREST_POINT


func test_player_scene_has_wading_component() -> void:
	assert_not_null(wading, "player.tscn harus punya WadingComponent")
	assert_same(wading.player, player, "komponen mengikat parent-nya sendiri")


func test_river_zone_slows_player() -> void:
	player.global_position = RIVER_POINT
	wading.tick()
	assert_true(wading.is_in_water())
	assert_true(player.is_wading())
	assert_true(player.is_sprint_blocked(), "sprint diblokir di air")
	assert_almost_eq(player.get_move_speed_multiplier(), 0.55, 0.001)


func test_leaving_river_restores_speed() -> void:
	player.global_position = RIVER_POINT
	wading.tick()
	player.global_position = FOREST_POINT
	wading.tick()
	assert_false(player.is_wading())
	assert_false(player.is_sprint_blocked())
	assert_almost_eq(player.get_move_speed_multiplier(), 1.0, 0.001)


func test_camp_is_not_water() -> void:
	player.global_position = Vector2.ZERO
	wading.tick()
	assert_false(wading.is_in_water())


func test_sneak_and_water_stack() -> void:
	player.global_position = RIVER_POINT
	wading.tick()
	player.set_sneaking(true)
	assert_almost_eq(player.get_move_speed_multiplier(), 0.55 * 0.55, 0.001)
	assert_eq(player.get_sprint_blocks().size(), 2)


func test_wading_config_can_allow_sprint() -> void:
	var config := WadingConfig.new()
	config.blocks_sprint = false
	config.speed_multiplier = 0.8
	player.wading_config = config
	player.global_position = RIVER_POINT
	wading.tick()
	assert_false(player.is_sprint_blocked())
	assert_almost_eq(player.get_move_speed_multiplier(), 0.8, 0.001)


func test_tell_shows_water_text() -> void:
	var tell := player.get_node("MotionTell") as MotionTell
	tell.tick()
	assert_false(tell.is_showing(), "di darat tanpa tell")
	player.global_position = RIVER_POINT
	wading.tick()
	tell.tick()
	assert_true(tell.is_showing())
	assert_eq(tell.get_text(), MotionTell.WADING_TEXT)


func test_tell_shows_both_modes() -> void:
	var tell := player.get_node("MotionTell") as MotionTell
	player.global_position = RIVER_POINT
	wading.tick()
	player.set_sneaking(true)
	tell.tick()
	assert_eq(tell.get_text(), "%s + %s" % [MotionTell.SNEAK_TEXT, MotionTell.WADING_TEXT])


func test_default_config_comes_from_tres() -> void:
	assert_not_null(player.wading_config)
	assert_almost_eq(player.wading_config.speed_multiplier, 0.55, 0.001)

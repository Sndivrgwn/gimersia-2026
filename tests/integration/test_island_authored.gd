extends GutTest

## BLOCK G (Mission 13): island sungguhan dengan config AUTHORED di kode.

const ISLAND_SCENE := preload("res://src/levels/island/island.tscn")
const CLOCK_SCENE := preload("res://src/core/managers/day_night_manager.tscn")
const SAMPLE_PATH := "res://src/levels/worlds/sample_island/world.tscn"

var island: Node2D
var player: CharacterBody2D
var controller: WorldController
var _created_clock: bool = false


func before_each() -> void:
	WorldRules.reset()
	var clock := get_node_or_null("/root/DayNightManager")
	if clock == null:
		clock = CLOCK_SCENE.instantiate()
		clock.name = "DayNightManager"
		get_tree().root.add_child(clock)
		_created_clock = true
	if clock.has_method(&"restart"):
		clock.restart()

	island = ISLAND_SCENE.instantiate()
	controller = island.get_node("WorldController") as WorldController
	var config := WorldConfig.new()
	config.mode = WorldConfig.Mode.AUTHORED
	config.authored_scene_path = SAMPLE_PATH
	controller.config = config
	add_child_autofree(island)
	player = island.get_node("Player") as CharacterBody2D

	for index in 120:
		await get_tree().physics_frame


func after_each() -> void:
	if _created_clock:
		var clock := get_node_or_null("/root/DayNightManager")
		if clock != null:
			clock.get_parent().remove_child(clock)
			clock.queue_free()
		_created_clock = false
	WorldRules.reset()


func test_island_boots_in_authored_mode() -> void:
	assert_true(WorldRules.get_source() is AuthoredWorldSource, "sumber AUTHORED aktif")
	assert_eq(controller.get_source_id(), &"authored")
	assert_eq(player.global_position, WorldRules.poi(WorldSource.POI_PLAYER_START), "pemain di PlayerStart")
	var ground := island.get_node("Ground") as Node2D
	assert_false(ground.visible, "tanah rumus disembunyikan")
	var marker_count := 0
	var holder := controller.get_node_or_null("World")
	assert_not_null(holder)
	for child in holder.get_children():
		if child is Marker2D and child.is_in_group(&"night_spawn_point"):
			marker_count += 1
	assert_eq(marker_count, 16)


func test_wading_slows_inside_river_polygon() -> void:
	var wading := player.get_node("WadingComponent") as WadingComponent
	var river_point: Vector2 = WorldRules.water_access_points()[0]
	player.global_position = river_point
	wading.tick()
	assert_true(wading.is_in_water(), "titik WaterAccess ada di zona sungai")
	assert_true(player.is_wading())
	assert_lt(player.get_move_speed_multiplier(), 1.0, "kecepatan turun di air")

	var dry_point := WorldRules.poi(WorldSource.POI_PLAYER_START)
	player.global_position = dry_point
	wading.tick()
	assert_false(wading.is_in_water())
	assert_almost_eq(player.get_move_speed_multiplier(), 1.0, 0.001)


func test_base_placement_accepts_ground_and_rejects_water() -> void:
	var anchor := island.get_node("CampAnchor") as CampAnchor
	assert_not_null(anchor)
	var on_ground: Dictionary = anchor.evaluate(Vector2(250.0, -250.0))
	assert_true(bool(on_ground["valid"]), "tanah hutan harus valid: %s" % str(on_ground))

	var water: Dictionary = anchor.evaluate(WorldRules.water_access_points()[0])
	assert_false(bool(water["valid"]), "sungai harus ditolak")
	assert_eq(String(water["reason"]), BaseSiteRules.REASON_RIVER)

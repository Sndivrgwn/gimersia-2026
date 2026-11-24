extends GutTest

## BLOCK G (Mission 13): jalur AUTHORED WorldController.

const SAMPLE_PATH := "res://src/levels/worlds/sample_island/world.tscn"

var root: Node2D
var ground: Node2D
var coast: StaticBody2D
var river_edges: Node2D
var wreckage: Node2D
var suitcase: Node2D
var beacon: Node2D
var player: Node2D


func before_each() -> void:
	WorldRules.reset()
	root = Node2D.new()
	add_child_autofree(root)
	ground = Node2D.new()
	ground.name = "Ground"
	root.add_child(ground)
	coast = StaticBody2D.new()
	coast.name = "Coastline"
	coast.collision_layer = 1
	coast.collision_mask = 1
	root.add_child(coast)
	river_edges = Node2D.new()
	river_edges.name = "RiverEdges"
	root.add_child(river_edges)
	wreckage = Node2D.new()
	wreckage.name = "Wreckage"
	wreckage.position = Vector2(0.0, -185.0)
	root.add_child(wreckage)
	suitcase = Node2D.new()
	suitcase.name = "Suitcase"
	suitcase.position = Vector2(-48.0, 40.0)
	root.add_child(suitcase)
	beacon = Node2D.new()
	beacon.name = "Beacon"
	beacon.position = Vector2(0.0, 2100.0)
	root.add_child(beacon)
	player = Node2D.new()
	player.name = "Player"
	player.position = Vector2(500.0, 500.0)
	root.add_child(player)


func after_each() -> void:
	WorldRules.reset()


func _config(path: String = SAMPLE_PATH) -> WorldConfig:
	var config := WorldConfig.new()
	config.mode = WorldConfig.Mode.AUTHORED
	config.authored_scene_path = path
	return config


func _add_controller(config: WorldConfig) -> WorldController:
	var controller := WorldController.new()
	controller.config = config
	root.add_child(controller)
	return controller


func test_authored_installs_source_world_and_player_start() -> void:
	var controller := _add_controller(_config())
	assert_true(WorldRules.get_source() is AuthoredWorldSource)
	assert_eq(controller.get_source_id(), &"authored")
	assert_eq(WorldRules.id(), &"authored")
	var holder := controller.get_node_or_null("World") as Node2D
	assert_not_null(holder, "holder World harus dibuat")
	assert_not_null(holder.get_child(0) as AuthoredWorld)
	assert_eq(player.global_position, Vector2(0.0, 64.0), "pemain dipindah ke PlayerStart")
	assert_not_null(controller.get_authored_root())


func test_authored_disables_formula_world() -> void:
	_add_controller(_config())
	assert_false(ground.visible, "polygon tanah rumus disembunyikan")
	assert_eq(ground.process_mode, Node.PROCESS_MODE_DISABLED)
	assert_false(river_edges.visible)
	assert_eq(coast.collision_layer, 0, "collision rumus dimatikan")
	assert_eq(coast.collision_mask, 0)
	assert_true(ground.is_in_group(&"formula_world"))
	assert_true(coast.is_in_group(&"formula_world"))
	assert_true(river_edges.is_in_group(&"formula_world"))


func test_authored_moves_pois_to_markers() -> void:
	var controller := _add_controller(_config())
	wreckage.position = Vector2(40.0, 40.0)
	suitcase.position = Vector2(-100.0, 100.0)
	beacon.position = Vector2(1.0, 2.0)
	controller.apply_pois()
	assert_eq(wreckage.position, Vector2(0.0, -185.0))
	assert_eq(suitcase.position, Vector2(-48.0, 40.0))
	assert_eq(beacon.position, Vector2(0.0, 2100.0))


func test_authored_spawns_markers_and_river_edges() -> void:
	var controller := _add_controller(_config())
	var holder := controller.get_node("World")
	var markers: Array[Marker2D] = []
	var edges := 0
	for child in holder.get_children():
		if child is Marker2D and child.is_in_group(&"night_spawn_point"):
			markers.append(child as Marker2D)
		elif child is RiverEdge:
			edges += 1
	assert_eq(markers.size(), 16, "16 marker spawn dari provider")
	assert_eq(edges, 6, "6 RiverEdge di WaterAccess")
	var points := WorldRules.night_spawn_points()
	for index in markers.size():
		assert_eq(markers[index].position, points[index])


func test_world_ready_reports_authored() -> void:
	var seen: Array = []
	var controller := WorldController.new()
	controller.config = _config()
	controller.world_ready.connect(func(source_id: StringName) -> void: seen.append(source_id))
	root.add_child(controller)
	assert_eq(seen, [&"authored"])


func test_missing_scene_falls_back_to_formula() -> void:
	var controller := _add_controller(_config("res://src/levels/worlds/tidak_ada/world.tscn"))
	_assert_reported_failure()
	assert_true(WorldRules.get_source() is FormulaWorld)
	assert_eq(controller.get_source_id(), &"formula")
	assert_true(ground.visible, "dunia rumus tetap terlihat saat fallback")


func test_invalid_contract_falls_back_to_formula() -> void:
	var controller := _add_controller(_config("res://src/levels/island/island.tscn"))
	_assert_reported_failure()
	assert_true(WorldRules.get_source() is FormulaWorld, "root bukan AuthoredWorld -> fallback")
	assert_eq(controller.get_source_id(), &"formula")


## Kegagalan AUTHORED sengaja memanggil push_error (dan load() ikut menulis
## error mesin); tandai sudah ditangani supaya GUT tidak menghitungnya ganda.
func _assert_reported_failure() -> void:
	var errors := get_errors()
	assert_gte(errors.size(), 1, "kegagalan AUTHORED harus dilaporkan")
	for error in errors:
		error.handled = true


func test_exit_tree_resets_source() -> void:
	var controller := _add_controller(_config())
	assert_true(WorldRules.get_source() is AuthoredWorldSource)
	root.remove_child(controller)
	controller.free()
	assert_null(WorldRules.source, "_exit_tree mengosongkan sumber")

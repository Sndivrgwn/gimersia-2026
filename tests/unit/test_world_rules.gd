extends GutTest

## BLOCK F (Mission 13): WorldSource / FormulaWorld / WorldRules / WorldController.
## Golden perilaku lama ada di test_world_golden.gd dan tidak diubah blok ini.

const WORLD_CONFIG_PATH := "res://src/data/configs/world/world_config.tres"
const POINT_SEED := 424242
const POINT_COUNT := 3000


## Sumber palsu: satu-satunya yang punya resource plan (dipakai menguji hook).
class FakePlanSource extends WorldSource:
	func id() -> StringName:
		return &"fake_plan"

	func has_resource_plan() -> bool:
		return true

	func resource_plan(_layout: IslandLayoutConfig, _seed_value: int) -> Array:
		return [{
			"kind": IslandBuilder.KIND_RESOURCE,
			"definition": null,
			"position": Vector2(12.0, -34.0),
			"zone": 0,
			"last_respawn_day": 0,
		}]


func before_each() -> void:
	WorldRules.reset()


func after_each() -> void:
	WorldRules.reset()


# --- WorldRules -------------------------------------------------------------

func test_default_source_is_formula_world() -> void:
	assert_null(WorldRules.source, "statis mulai kosong")
	var world := WorldRules.get_source()
	assert_true(world is FormulaWorld)
	assert_eq(WorldRules.id(), &"formula")
	assert_same(WorldRules.get_source(), world, "sumber yang sama dipakai ulang")


func test_set_source_and_reset() -> void:
	var custom := WorldSource.new()
	WorldRules.set_source(custom)
	assert_same(WorldRules.get_source(), custom)
	assert_eq(WorldRules.id(), &"world_source")
	WorldRules.reset()
	assert_null(WorldRules.source)
	assert_true(WorldRules.get_source() is FormulaWorld, "reset lalu lazily membuat FormulaWorld")


# --- FormulaWorld vs matematika lama ---------------------------------------

func test_formula_world_equals_old_math_for_3000_points() -> void:
	var formula := FormulaWorld.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = POINT_SEED
	var mismatches := 0
	for index in POINT_COUNT:
		var point := Vector2(rng.randf_range(-2600.0, 2600.0), rng.randf_range(-2600.0, 2600.0))
		var legacy: int = IslandZones._formula_zone_at(point)
		if legacy != formula.zone_at(point):
			mismatches += 1
		elif legacy != WorldRules.zone_at(point):
			mismatches += 1
		elif legacy != IslandZones.zone_at(point):
			mismatches += 1
	assert_eq(mismatches, 0, "FormulaWorld/WorldRules/IslandZones harus sama dengan matematika lama")


func test_bounds_and_walkable_match_old_square() -> void:
	var formula := FormulaWorld.new()
	assert_eq(formula.bounds(), Rect2(-2400.0, -2400.0, 4800.0, 4800.0))
	assert_true(formula.is_walkable(Vector2(2400.0, 2400.0)), "tepi kotak masih di dalam")
	assert_false(formula.is_walkable(Vector2(2400.5, 0.0)))
	assert_almost_eq(formula.distance_to_coast(Vector2.ZERO), 2400.0, 0.001)
	assert_almost_eq(formula.distance_to_coast(Vector2(2200.0, 0.0)), 200.0, 0.001)
	assert_almost_eq(formula.distance_to_coast(Vector2(2500.0, 0.0)), -100.0, 0.001)


func test_river_distance_matches_legacy_geometry() -> void:
	var formula := FormulaWorld.new()
	for point in [
		Vector2(-950.0, 0.0), Vector2(-1200.0, 0.0), Vector2(-700.0, 300.0),
		Vector2(-950.0, 1600.0), Vector2(-1050.0, -1400.0), Vector2(0.0, 500.0),
		Vector2(-1049.0, 1399.0), Vector2(-851.0, -1399.0),
	]:
		assert_almost_eq(
			formula.distance_to_zone(point, IslandZones.Zone.RIVER),
			_legacy_river_distance(point),
			0.0001,
			"jarak sungai %s" % str(point)
		)
		assert_almost_eq(
			BaseSiteRules.distance_to_river(point),
			_legacy_river_distance(point),
			0.0001,
			"BaseSiteRules lewat provider %s" % str(point)
		)


func test_poi_getters_equal_legacy_constants() -> void:
	var formula := FormulaWorld.new()
	assert_eq(formula.poi(WorldSource.POI_PLAYER_START), Vector2(0.0, 64.0))
	assert_eq(formula.poi(WorldSource.POI_PLAYER_START), IslandBuilder.KEEP_OUT_POINTS[0])
	assert_eq(formula.poi(WorldSource.POI_PLANE_WRECKAGE), IslandBuilder.KEEP_OUT_POINTS[1])
	assert_eq(formula.poi(WorldSource.POI_EMERGENCY_SUITCASE), IslandBuilder.KEEP_OUT_POINTS[2])
	assert_eq(formula.poi(WorldSource.POI_SIGNAL_BEACON), IslandZones.BEACON_POSITION)
	assert_eq(formula.poi(&"tidak_ada"), Vector2.INF)
	assert_eq(WorldRules.poi(WorldSource.POI_SIGNAL_BEACON), Vector2(0.0, 2100.0))
	assert_eq(WorldRules.poi(&"tidak_ada"), Vector2.INF)


func test_zone_centers_match_island_zones_and_outside_is_inf() -> void:
	var formula := FormulaWorld.new()
	for zone in [
		IslandZones.Zone.CAMP,
		IslandZones.Zone.SOUTH_BEACH,
		IslandZones.Zone.EAST_BEACH,
		IslandZones.Zone.WEST_CLIFFS,
		IslandZones.Zone.RIVER,
		IslandZones.Zone.FOREST,
	]:
		assert_eq(formula.zone_center(zone), IslandZones.zone_center(zone), "zona %d" % zone)
		assert_eq(WorldRules.zone_center(zone), IslandZones.zone_center(zone), "zona %d" % zone)
	assert_eq(formula.zone_center(IslandZones.Zone.OUTSIDE), Vector2.INF)
	assert_eq(WorldRules.zone_center(-5), Vector2.INF)


func test_formula_world_has_no_resource_plan() -> void:
	assert_false(FormulaWorld.new().has_resource_plan())
	assert_eq(FormulaWorld.new().resource_plan(IslandBuilder.LAYOUT_DEFAULT, 1), [])
	assert_true(FormulaWorld.new().night_spawn_points().is_empty())
	assert_true(FormulaWorld.new().water_access_points().is_empty())


# --- IslandBuilder hook -----------------------------------------------------

func test_builder_plan_unchanged_when_source_has_no_plan() -> void:
	WorldRules.reset()
	var builder := IslandBuilder.new()
	builder.layout = IslandBuilder.LAYOUT_DEFAULT
	builder.auto_build = false
	add_child_autofree(builder)
	var before := builder.plan()
	WorldRules.set_source(FormulaWorld.new())
	var after := builder.plan()
	assert_eq(after.size(), before.size())
	var differences := 0
	for index in mini(before.size(), after.size()):
		if before[index]["position"] != after[index]["position"]:
			differences += 1
	assert_eq(differences, 0, "hook tidak boleh mengubah plan FORMULA")


func test_builder_plan_uses_provider_plan_when_available() -> void:
	WorldRules.set_source(FakePlanSource.new())
	var builder := IslandBuilder.new()
	builder.auto_build = false
	add_child_autofree(builder)
	var entries := builder.plan()
	assert_eq(entries.size(), 1)
	assert_eq(entries[0]["position"], Vector2(12.0, -34.0))


# --- WorldController --------------------------------------------------------

func test_controller_installs_formula_source_and_resets_on_exit() -> void:
	WorldRules.reset()
	var controller := WorldController.new()
	var seen: Array = []
	controller.world_ready.connect(func(source_id: StringName) -> void: seen.append(source_id))
	add_child(controller)
	assert_true(WorldRules.get_source() is FormulaWorld)
	assert_eq(controller.get_source_id(), &"formula")
	assert_eq(seen, [&"formula"], "world_ready membawa id sumber")
	remove_child(controller)
	controller.free()
	assert_null(WorldRules.source, "_exit_tree mengosongkan sumber")


func test_controller_falls_back_to_formula_when_authored_scene_is_missing() -> void:
	var config := WorldConfig.new()
	config.mode = WorldConfig.Mode.AUTHORED
	config.authored_scene_path = "res://src/levels/worlds/tidak_ada/world.tscn"
	var controller := WorldController.new()
	controller.config = config
	add_child(controller)
	var errors := get_errors()
	assert_gte(errors.size(), 1, "scene AUTHORED hilang harus dilaporkan")
	for error in errors:
		error.handled = true
	assert_true(WorldRules.get_source() is FormulaWorld, "scene hilang -> fallback FORMULA")
	assert_eq(controller.get_source_id(), &"formula")
	remove_child(controller)
	controller.free()


func test_apply_pois_moves_only_when_provider_value_differs() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	var wreckage := Node2D.new()
	wreckage.name = "Wreckage"
	wreckage.position = FormulaWorld.PLANE_WRECKAGE
	root.add_child(wreckage)
	var suitcase := Node2D.new()
	suitcase.name = "Suitcase"
	suitcase.position = FormulaWorld.EMERGENCY_SUITCASE
	root.add_child(suitcase)
	var beacon := Node2D.new()
	beacon.name = "Beacon"
	beacon.position = FormulaWorld.SIGNAL_BEACON
	root.add_child(beacon)

	var controller := WorldController.new()
	root.add_child(controller)
	assert_eq(wreckage.position, FormulaWorld.PLANE_WRECKAGE, "no-op di posisi rumus")
	assert_eq(suitcase.position, FormulaWorld.EMERGENCY_SUITCASE, "no-op di posisi rumus")
	assert_eq(beacon.position, FormulaWorld.SIGNAL_BEACON, "no-op di posisi rumus")

	wreckage.position = Vector2(40.0, 40.0)
	suitcase.position = Vector2(-100.0, 100.0)
	beacon.position = Vector2(1.0, 2.0)
	controller.apply_pois()
	assert_eq(wreckage.position, FormulaWorld.PLANE_WRECKAGE)
	assert_eq(suitcase.position, FormulaWorld.EMERGENCY_SUITCASE)
	assert_eq(beacon.position, FormulaWorld.SIGNAL_BEACON)


# --- WorldConfig ------------------------------------------------------------

func test_world_config_defaults() -> void:
	var config: WorldConfig = load(WORLD_CONFIG_PATH)
	assert_not_null(config, "%s harus ada (tools/generate_world_config.gd)" % WORLD_CONFIG_PATH)
	if config == null:
		return
	assert_eq(config.mode, WorldConfig.Mode.FORMULA)
	assert_eq(config.authored_scene_path, "res://src/levels/worlds/sample_island/world.tscn")
	assert_true(config.fallback_to_formula)
	assert_almost_eq(config.cell_size, 32.0, 0.001)
	assert_eq(config.min_spawn_points, 8)
	assert_almost_eq(config.min_spawn_distance, 1100.0, 0.001)
	assert_almost_eq(config.min_corridor_width, 96.0, 0.001)
	assert_almost_eq(config.base_clearance_extra, 50.0, 0.001)
	assert_almost_eq(config.reachability_required_ratio, 0.98, 0.0001)
	assert_almost_eq(config.warn_node_ratio, 0.5, 0.0001)
	assert_eq(config.polygon_vertex_limit, 2000)
	assert_almost_eq(config.min_forest_area, 1000000.0, 0.001)
	assert_eq(config.overlay_cell_px, 64)


# --- Helper -----------------------------------------------------------------

## Rumus lama BaseSiteRules.distance_to_river, ditulis ulang di tes supaya
## perbandingan tidak tautologis.
func _legacy_river_distance(point: Vector2) -> float:
	var dx := 0.0
	if point.x < -1050.0:
		dx = -1050.0 - point.x
	elif point.x > -850.0:
		dx = point.x + 850.0
	var dy := 0.0
	if point.y < -1400.0:
		dy = -1400.0 - point.y
	elif point.y > 1400.0:
		dy = point.y - 1400.0
	return sqrt(dx * dx + dy * dy)

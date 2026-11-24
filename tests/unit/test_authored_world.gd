extends GutTest

## BLOCK G (Mission 13): AuthoredWorld + AuthoredWorldSource + ZoneGrid raster.

const Fixture = preload("res://tests/helpers/authored_world_fixture.gd")
const SAMPLE_PATH := "res://src/levels/worlds/sample_island/world.tscn"
const TEMPLATE_PATH := "res://src/levels/worlds/_template/world.tscn"

var _fixture
var _world: AuthoredWorld
var _source: AuthoredWorldSource


func before_each() -> void:
	_fixture = Fixture.new()
	_world = _fixture.make_world()
	add_child_autofree(_world)
	_source = _world.make_source(32.0)


func after_each() -> void:
	_world = null
	_source = null
	_fixture = null


# --- Kontrak scene ----------------------------------------------------------

func test_contract_has_no_warnings() -> void:
	assert_true(_world.configuration_warnings().is_empty(), str(_world.configuration_warnings()))
	assert_eq(_world.outline_points().size(), 4)
	assert_eq(_world.marker_position(&"PlayerStart"), Vector2(0.0, 64.0))


func test_contract_warns_for_missing_children_and_markers() -> void:
	var broken := AuthoredWorld.new()
	add_child_autofree(broken)
	var warnings := broken.configuration_warnings()
	assert_true(warnings.size() >= 5, "semua anak wajib dilaporkan hilang")
	assert_eq(broken.outline_points().size(), 0, "tanpa outline tidak ada polygon")


# --- Sumber dunia -----------------------------------------------------------

func test_zone_lookup_at_probe_points() -> void:
	assert_eq(_source.zone_at(Vector2.ZERO), WorldZoneType.Zone.CAMP)
	assert_eq(_source.zone_at(Vector2(1000.0, 0.0)), WorldZoneType.Zone.EAST_BEACH)
	assert_eq(_source.zone_at(Vector2(-950.0, 400.0)), WorldZoneType.Zone.RIVER)
	assert_eq(_source.zone_at(Vector2(500.0, -300.0)), WorldZoneType.Zone.FOREST)
	assert_eq(_source.zone_at(Vector2(5000.0, 0.0)), WorldZoneType.Zone.OUTSIDE)
	assert_false(_source.is_walkable(Vector2(5000.0, 0.0)))
	assert_true(_source.is_walkable(Vector2(-950.0, 400.0)), "sungai bisa dilewati")
	assert_false(_source.is_buildable(Vector2(-950.0, 400.0)), "sungai tidak bisa dibangun")
	assert_true(_source.is_buildable(Vector2(200.0, 200.0)))
	assert_false(_source.is_walkable(Fixture.LAKE_CENTER), "danau penghalang solid")
	assert_false(_source.is_walkable(Fixture.ROCK_CENTER), "formasi batu penghalang solid")


func test_pois_and_points() -> void:
	assert_eq(_source.poi(WorldSource.POI_PLAYER_START), Vector2(0.0, 64.0))
	assert_eq(_source.poi(WorldSource.POI_PLANE_WRECKAGE), Vector2(0.0, -185.0))
	assert_eq(_source.poi(WorldSource.POI_EMERGENCY_SUITCASE), Vector2(-48.0, 40.0))
	assert_eq(_source.poi(WorldSource.POI_SIGNAL_BEACON), Vector2(0.0, 900.0))
	assert_eq(_source.poi(&"tidak_ada"), Vector2.INF)
	assert_eq(_source.night_spawn_points().size(), 8)
	assert_eq(_source.water_access_points().size(), 2)
	assert_eq(_source.bounds(), Rect2(-1200.0, -1200.0, 2400.0, 2400.0))


func test_zone_center_is_inside_its_zone() -> void:
	for zone in [WorldZoneType.Zone.CAMP, WorldZoneType.Zone.FOREST, WorldZoneType.Zone.RIVER, WorldZoneType.Zone.EAST_BEACH]:
		var center := _source.zone_center(zone)
		assert_ne(center, Vector2.INF, "zona %d punya pusat" % zone)
		assert_eq(_source.zone_at(center), zone, "pusat zona %d" % zone)
	assert_eq(_source.zone_center(WorldZoneType.Zone.OUTSIDE), Vector2.INF)


func test_distance_helpers_follow_polygons() -> void:
	assert_almost_eq(_source.distance_to_coast(Vector2.ZERO), 1200.0, 0.5)
	assert_eq(_source.distance_to_coast(Vector2(5000.0, 0.0)), 0.0, "di luar pulau = 0")
	assert_eq(_source.distance_to_zone(Vector2(-950.0, 400.0), WorldZoneType.Zone.RIVER), 0.0)
	assert_almost_eq(_source.distance_to_zone(Vector2(-700.0, 400.0), WorldZoneType.Zone.RIVER), 150.0, 0.5)
	assert_eq(_source.distance_to_zone(Vector2.ZERO, WorldZoneType.Zone.OUTSIDE), INF)


# --- Rencana resource -------------------------------------------------------

func test_resource_plan_counts_determinism_and_rules() -> void:
	assert_true(_source.has_resource_plan())
	var layout := IslandLayoutConfig.new()
	var plan := _source.resource_plan(layout, 4242)
	var requested := 6 + 4 + 30
	var shortfalls: Dictionary = _source.get_shortfalls()
	var missing := 0
	for key in shortfalls:
		missing += int(shortfalls[key])
	assert_eq(plan.size(), requested - missing, "hasil + shortfall = permintaan")
	assert_gt(plan.size(), 0)
	assert_true(shortfalls.has("TinyPatch"), "area sempit harus melapor shortfall")
	assert_gt(int(shortfalls["TinyPatch"]), 0)

	var second := _world.make_source(32.0).resource_plan(layout, 4242)
	assert_eq(second.size(), plan.size(), "seed sama -> jumlah sama")
	var differences := 0
	for index in plan.size():
		if plan[index]["position"] != second[index]["position"]:
			differences += 1
		if plan[index]["definition"].id != second[index]["definition"].id:
			differences += 1
	assert_eq(differences, 0, "seed sama -> urutan dan posisi sama")

	var other := _world.make_source(32.0).resource_plan(layout, 99)
	assert_ne(other[0]["position"], plan[0]["position"], "seed berbeda -> posisi berbeda")

	for entry in plan:
		var point: Vector2 = entry["position"]
		assert_true(_source.is_walkable(point), "resource di sel walkable: %s" % str(point))
		assert_false(_source.is_inside_blocked(point), "resource tidak di area terlarang: %s" % str(point))
		assert_gte(point.distance_to(_source.poi(WorldSource.POI_PLAYER_START)), layout.keep_out_radius - 0.01)
		assert_gte(point.distance_to(_source.poi(WorldSource.POI_PLANE_WRECKAGE)), layout.keep_out_radius - 0.01)
		assert_gte(point.distance_to(_source.poi(WorldSource.POI_EMERGENCY_SUITCASE)), layout.keep_out_radius - 0.01)
		assert_gte(point.distance_to(_source.poi(WorldSource.POI_SIGNAL_BEACON)), layout.beacon_keep_out - 0.01)

	var closest := INF
	for i in plan.size():
		for j in range(i + 1, plan.size()):
			closest = minf(closest, (plan[i]["position"] as Vector2).distance_to(plan[j]["position"]))
	assert_gte(closest, layout.min_spacing - 0.01, "jarak minimum antar node")


func test_source_without_areas_has_no_plan() -> void:
	var data := {
		"outline": _fixture.rect(-500.0, -500.0, 500.0, 500.0),
		"zone_areas": [],
		"markers": {},
		"manual_nodes": [],
		"resource_areas": [],
		"night_points": PackedVector2Array(),
		"water_points": PackedVector2Array(),
		"cell_size": 32.0,
	}
	var source := AuthoredWorldSource.new()
	source.setup(data)
	assert_eq(source.outline.size(), 4, "outline fixture harus 4 titik")
	assert_false(source.has_resource_plan())
	assert_eq(source.resource_plan(IslandLayoutConfig.new(), 1), [])
	assert_eq(source.zone_at(Vector2.ZERO), WorldZoneType.Zone.FOREST, "isi outline default hutan")


# --- Collision --------------------------------------------------------------

func test_build_collision_creates_outline_and_blocked_shapes() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	_world.build_collision(root)

	var coast := root.get_node_or_null("CoastCollision") as StaticBody2D
	assert_not_null(coast, "CoastCollision harus ada")
	assert_eq(coast.collision_layer, 1, "layer sama dengan coast wall island.tscn")
	assert_eq(coast.collision_mask, 1)
	assert_eq(coast.get_child_count(), 1)
	var outline_shape := coast.get_child(0) as CollisionPolygon2D
	assert_eq(outline_shape.build_mode, CollisionPolygon2D.BUILD_SEGMENTS)
	assert_eq(outline_shape.polygon.size(), 4)

	var blocked := root.get_node_or_null("BlockedCollision") as StaticBody2D
	assert_not_null(blocked, "BlockedCollision harus ada")
	assert_eq(blocked.collision_layer, 1)
	assert_eq(blocked.get_child_count(), 2, "danau + formasi batu")
	for child in blocked.get_children():
		var shape := child as CollisionPolygon2D
		assert_not_null(shape)
		assert_eq(shape.build_mode, CollisionPolygon2D.BUILD_SOLIDS)


func test_physics_body_cannot_cross_outline_or_enter_blocked_area() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	var world: AuthoredWorld = _fixture.make_world()
	root.add_child(world)
	world.build_collision(root)
	await get_tree().physics_frame

	var body := CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	body.add_child(shape)
	root.add_child(body)

	body.global_position = Vector2(1100.0, 0.0)
	body.velocity = Vector2(600.0, 0.0)
	for index in 20:
		body.move_and_slide()
		await get_tree().physics_frame
	assert_lt(body.global_position.x, 1200.0, "tidak boleh menembus tepi outline")
	assert_gt(body.global_position.x, 1050.0, "harus bergerak mendekati tepi")

	body.global_position = Fixture.LAKE_CENTER + Vector2(0.0, 300.0)
	body.velocity = Vector2(0.0, -400.0)
	for index in 20:
		body.move_and_slide()
		await get_tree().physics_frame
	assert_gt(body.global_position.distance_to(Fixture.LAKE_CENTER), Fixture.LAKE_RADIUS - 20.0,
		"tidak boleh masuk danau (penghalang solid)")


# --- Scene hasil generator --------------------------------------------------

func test_generated_template_loads_without_warnings() -> void:
	var packed := load(TEMPLATE_PATH) as PackedScene
	assert_not_null(packed, "%s harus ada (tools/generate_sample_world.gd)" % TEMPLATE_PATH)
	if packed == null:
		return
	var template := packed.instantiate() as AuthoredWorld
	assert_not_null(template, "root template harus AuthoredWorld")
	assert_true(template.configuration_warnings().is_empty(), str(template.configuration_warnings()))
	assert_eq(template.zone_areas().size(), 3)
	assert_eq(template.resource_areas().size(), 1)
	assert_eq(template.marker_position(&"SignalBeacon"), Vector2(0.0, 700.0))
	var source := template.make_source(32.0)
	assert_eq(source.zone_at(Vector2.ZERO), WorldZoneType.Zone.CAMP)
	assert_true(source.has_resource_plan())
	template.free()


func test_generated_sample_loads_and_builds_grid_fast() -> void:
	var packed := load(SAMPLE_PATH) as PackedScene
	assert_not_null(packed, "%s harus ada (tools/generate_sample_world.gd)" % SAMPLE_PATH)
	if packed == null:
		return
	var sample := packed.instantiate() as AuthoredWorld
	assert_not_null(sample)
	assert_true(sample.configuration_warnings().is_empty(), str(sample.configuration_warnings()))
	assert_eq(sample.outline_points().size(), 24, "outline tidak beraturan 24 titik")
	assert_eq(sample.zone_areas().size(), 9)
	assert_eq(sample.resource_areas().size(), 5)

	var start := Time.get_ticks_msec()
	var source := sample.make_source(32.0)
	var elapsed_ms := Time.get_ticks_msec() - start
	assert_lt(float(elapsed_ms), 1500.0, "grid sample 32 px harus < 1.5 s (aktual %d ms)" % elapsed_ms)
	assert_eq(source.zone_at(Vector2.ZERO), WorldZoneType.Zone.CAMP)
	assert_eq(source.zone_at(Vector2(0.0, 2000.0)), WorldZoneType.Zone.SOUTH_BEACH)
	assert_eq(source.zone_at(Vector2(2000.0, 0.0)), WorldZoneType.Zone.EAST_BEACH)
	assert_eq(source.zone_at(Vector2(-2000.0, 0.0)), WorldZoneType.Zone.WEST_CLIFFS)
	assert_eq(source.night_spawn_points().size(), 16)
	assert_eq(source.water_access_points().size(), 6)
	assert_eq(source.poi(WorldSource.POI_SIGNAL_BEACON), Vector2(0.0, 2100.0))
	for point in source.night_spawn_points():
		assert_true(source.is_walkable(point), "spawn malam di darat: %s" % str(point))
		assert_gte(point.distance_to(source.poi(WorldSource.POI_PLAYER_START)), 1100.0)

	var layout := IslandLayoutConfig.new()
	var plan := source.resource_plan(layout, 424242)
	assert_gt(plan.size(), 100, "sample harus punya banyak resource")
	sample.free()

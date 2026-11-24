extends GutTest

## BLOCK G (Mission 13): WorldZoneType + ZoneGrid.

var SQUARE := PackedVector2Array([
	Vector2(-1000.0, -1000.0), Vector2(1000.0, -1000.0), Vector2(1000.0, 1000.0), Vector2(-1000.0, 1000.0),
])


func test_zone_type_matches_island_zones_exactly() -> void:
	var names := ["CAMP", "SOUTH_BEACH", "EAST_BEACH", "WEST_CLIFFS", "RIVER", "FOREST", "OUTSIDE"]
	assert_eq(WorldZoneType.Zone.size(), IslandZones.Zone.size(), "jumlah zona harus sama")
	for index in names.size():
		assert_eq(int(WorldZoneType.Zone[names[index]]), int(IslandZones.Zone[names[index]]), names[index])
		assert_eq(int(WorldZoneType.Zone[names[index]]), index, "urutan nilai %s" % names[index])


func test_zone_type_helpers() -> void:
	assert_eq(WorldZoneType.label_id(WorldZoneType.Zone.SOUTH_BEACH), "Pantai Selatan")
	assert_eq(WorldZoneType.label_id(WorldZoneType.Zone.OUTSIDE), "Luar Pulau")
	assert_false(WorldZoneType.default_buildable(WorldZoneType.Zone.RIVER))
	assert_false(WorldZoneType.default_buildable(WorldZoneType.Zone.OUTSIDE))
	for zone in [
		WorldZoneType.Zone.CAMP, WorldZoneType.Zone.SOUTH_BEACH, WorldZoneType.Zone.EAST_BEACH,
		WorldZoneType.Zone.WEST_CLIFFS, WorldZoneType.Zone.FOREST,
	]:
		assert_true(WorldZoneType.default_buildable(zone))
		assert_gt(WorldZoneType.color(zone).a, 0.0, "warna zona punya alpha dasar")


func test_grid_marks_outside_cells() -> void:
	var grid := ZoneGrid.build(SQUARE, [], 100.0)
	assert_eq(int(grid["cols"]), 20)
	assert_eq(int(grid["rows"]), 20)
	assert_eq(ZoneGrid.lookup(grid, Vector2.ZERO)["zone"], WorldZoneType.Zone.FOREST)
	assert_true(ZoneGrid.lookup(grid, Vector2.ZERO)["walk"])
	assert_true(ZoneGrid.lookup(grid, Vector2.ZERO)["build"])
	var outside := ZoneGrid.lookup(grid, Vector2(5000.0, 5000.0))
	assert_eq(int(outside["zone"]), WorldZoneType.Zone.OUTSIDE)
	assert_false(bool(outside["walk"]))
	assert_false(bool(outside["build"]))
	assert_eq(ZoneGrid.cell_index(grid, Vector2(-5000.0, 0.0)), -1)


func test_grid_priority_and_ties() -> void:
	var low := {"polygon": _rect(-800.0, -800.0, 800.0, 800.0), "zone": WorldZoneType.Zone.CAMP, "priority": 0, "order": 0}
	var high := {"polygon": _rect(-800.0, -800.0, 800.0, 800.0), "zone": WorldZoneType.Zone.EAST_BEACH, "priority": 10, "order": 0}
	var grid := ZoneGrid.build(SQUARE, [high, low], 100.0)
	assert_eq(int(ZoneGrid.lookup(grid, Vector2.ZERO)["zone"]), WorldZoneType.Zone.EAST_BEACH, "prioritas tinggi menang")

	var first := {"polygon": _rect(-800.0, -800.0, 800.0, 800.0), "zone": WorldZoneType.Zone.CAMP, "priority": 0, "order": 0}
	var last := {"polygon": _rect(-800.0, -800.0, 800.0, 800.0), "zone": WorldZoneType.Zone.WEST_CLIFFS, "priority": 0, "order": 1}
	var tied := ZoneGrid.build(SQUARE, [first, last], 100.0)
	assert_eq(int(ZoneGrid.lookup(tied, Vector2.ZERO)["zone"]), WorldZoneType.Zone.WEST_CLIFFS, "seri: sibling akhir menang")


func test_walk_false_sticks() -> void:
	var blocked := {"polygon": _rect(-800.0, -800.0, 800.0, 800.0), "zone": WorldZoneType.Zone.FOREST, "priority": 0, "order": 0, "walkable": false}
	var open_later := {"polygon": _rect(-800.0, -800.0, 800.0, 800.0), "zone": WorldZoneType.Zone.CAMP, "priority": 10, "order": 1, "walkable": true}
	var grid := ZoneGrid.build(SQUARE, [blocked, open_later], 100.0)
	var cell := ZoneGrid.lookup(grid, Vector2.ZERO)
	assert_eq(int(cell["zone"]), WorldZoneType.Zone.CAMP, "zona penulis terakhir")
	assert_false(bool(cell["walk"]), "walk=false tidak bisa dinaikkan lagi")


func test_build_rules() -> void:
	var river := _rect(-800.0, -800.0, 800.0, 800.0)
	var default_rule := ZoneGrid.build(SQUARE, [
		{"polygon": river, "zone": WorldZoneType.Zone.RIVER, "priority": 0, "order": 0},
	], 100.0)
	assert_false(bool(ZoneGrid.lookup(default_rule, Vector2.ZERO)["build"]), "RIVER default tidak bisa dibangun")

	var allowed := ZoneGrid.build(SQUARE, [
		{"polygon": river, "zone": WorldZoneType.Zone.RIVER, "priority": 0, "order": 0, "build_rule": 1},
	], 100.0)
	assert_true(bool(ZoneGrid.lookup(allowed, Vector2.ZERO)["build"]), "ALLOW menimpa default")

	var forbidden := ZoneGrid.build(SQUARE, [
		{"polygon": river, "zone": WorldZoneType.Zone.FOREST, "priority": 0, "order": 0, "build_rule": 2},
	], 100.0)
	assert_false(bool(ZoneGrid.lookup(forbidden, Vector2.ZERO)["build"]), "FORBID mematikan build di FOREST")


func test_areas_never_touch_cells_outside_outline() -> void:
	var everywhere := {"polygon": _rect(-5000.0, -5000.0, 5000.0, 5000.0), "zone": WorldZoneType.Zone.CAMP, "priority": 0, "order": 0}
	var grid := ZoneGrid.build(SQUARE, [everywhere], 100.0)
	assert_eq(int(ZoneGrid.lookup(grid, Vector2(4000.0, 4000.0))["zone"]), WorldZoneType.Zone.OUTSIDE)
	assert_false(bool(ZoneGrid.lookup(grid, Vector2(4000.0, 4000.0))["walk"]))


func test_distance_helpers() -> void:
	assert_almost_eq(ZoneGrid.distance_to_segments(SQUARE, Vector2.ZERO), 1000.0, 0.01)
	assert_almost_eq(ZoneGrid.distance_to_segments(SQUARE, Vector2(1200.0, 0.0)), 200.0, 0.01)
	assert_almost_eq(ZoneGrid.distance_to_segments(SQUARE, Vector2(-1000.0, -1000.0)), 0.0, 0.01)
	assert_eq(ZoneGrid.distance_to_segments(PackedVector2Array(), Vector2.ZERO), INF)
	SQUARE = _rect(-1000.0, -1000.0, 1000.0, 1000.0)
	var bounds := ZoneGrid.polygon_bounds(SQUARE)
	assert_eq(bounds, Rect2(-1000.0, -1000.0, 2000.0, 2000.0))


func _rect(x_from: float, y_from: float, x_to: float, y_to: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(x_from, y_from), Vector2(x_to, y_from), Vector2(x_to, y_to), Vector2(x_from, y_to),
	])

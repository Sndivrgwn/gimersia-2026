extends RefCounted

## Dunia AUTHORED bersih (tanpa masalah) dalam bentuk data AuthoredWorldSource,
## supaya tes validator bisa memutasi satu hal per kode. cell_size 64.

const CELL := 64.0
const HALF := 1500.0
const CAMP_RADIUS := 800.0
const LAKE_CENTER := Vector2(700.0, -900.0)
const LAKE_RADIUS := 220.0
const ROCK_CENTER := Vector2(-1300.0, -1000.0)
const ROCK_RADIUS := 180.0

const DEF_TWIG: ResourceNodeDefinition = preload("res://src/data/gathering/twig.tres")
const DEF_SMALL_TREE: ResourceNodeDefinition = preload("res://src/data/gathering/small_tree.tres")
const DEF_TREE: ResourceNodeDefinition = preload("res://src/data/gathering/tree.tres")
const DEF_SMALL_ROCK: ResourceNodeDefinition = preload("res://src/data/gathering/small_rock.tres")
const DEF_BIG_ROCK: ResourceNodeDefinition = preload("res://src/data/gathering/big_rock.tres")
const DEF_FIBER_BUSH: ResourceNodeDefinition = preload("res://src/data/gathering/fiber_bush.tres")
const DEF_BERRY_BUSH: ResourceNodeDefinition = preload("res://src/data/gathering/berry_bush.tres")
const DEF_COCONUT_PALM: ResourceNodeDefinition = preload("res://src/data/gathering/coconut_palm.tres")
const DEF_BAMBOO: ResourceNodeDefinition = preload("res://src/data/gathering/bamboo_clump.tres")


func clean_data() -> Dictionary:
	var outline := rect(-HALF, -HALF, HALF, HALF)
	var camp := circle(Vector2.ZERO, CAMP_RADIUS, 48)
	var river := rect(-1100.0, -HALF, -900.0, HALF)
	var night := PackedVector2Array()
	for angle_degrees in [0, 30, 60, 90, 120, 240, 300, 330]:
		var angle := deg_to_rad(float(angle_degrees))
		night.append(Vector2(cos(angle), sin(angle)) * 1350.0)
	return {
		"outline": outline,
		"zone_areas": [
			_zone_data("IslandOutline", outline, WorldZoneType.Zone.FOREST, -100, true, 0, true),
			_zone_data("Forest", outline, WorldZoneType.Zone.FOREST, -50, true, 0, false),
			_zone_data("Camp", camp, WorldZoneType.Zone.CAMP, 10, true, 0, false),
			_zone_data("River", river, WorldZoneType.Zone.RIVER, 20, true, 0, false),
			_zone_data("Lake", circle(LAKE_CENTER, LAKE_RADIUS, 16), WorldZoneType.Zone.RIVER, 50, false, 2, false),
			_zone_data("Rock", regular_polygon(ROCK_CENTER, ROCK_RADIUS, 6, 0.3), WorldZoneType.Zone.FOREST, 50, false, 2, false),
		],
		"markers": {
			WorldSource.POI_PLAYER_START: Vector2(0.0, 64.0),
			WorldSource.POI_PLANE_WRECKAGE: Vector2(0.0, -185.0),
			WorldSource.POI_EMERGENCY_SUITCASE: Vector2(-48.0, 40.0),
			WorldSource.POI_SIGNAL_BEACON: Vector2(0.0, 1200.0),
		},
		"manual_nodes": [],
		"manual_resources": [],
		"resource_areas": [
			_resource_data("CampGather", camp, 70.0, [
				[DEF_TWIG, 10], [DEF_SMALL_ROCK, 8], [DEF_FIBER_BUSH, 5],
				[DEF_BERRY_BUSH, 4], [DEF_SMALL_TREE, 6],
			]),
			_resource_data("ForestGather", outline, 70.0, [
				[DEF_TREE, 30], [DEF_FIBER_BUSH, 24], [DEF_BERRY_BUSH, 18],
			]),
			_resource_data("WestRocks", rect(-HALF, -1000.0, -1200.0, 1000.0), 70.0, [
				[DEF_SMALL_ROCK, 14], [DEF_BIG_ROCK, 8],
			]),
			_resource_data("RiverBamboo", river, 70.0, [[DEF_BAMBOO, 14]]),
			_resource_data("SouthCoconuts", rect(-HALF, 1200.0, HALF, HALF), 70.0, [[DEF_COCONUT_PALM, 12]]),
		],
		"night_points": night,
		"water_points": PackedVector2Array([Vector2(-1000.0, 0.0), Vector2(-1000.0, 400.0)]),
		"cell_size": CELL,
	}


func make_source(data: Dictionary) -> AuthoredWorldSource:
	var source := AuthoredWorldSource.new()
	source.setup(data)
	return source


func clean_source() -> AuthoredWorldSource:
	return make_source(clean_data())


func rect(x_from: float, y_from: float, x_to: float, y_to: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(x_from, y_from), Vector2(x_to, y_from), Vector2(x_to, y_to), Vector2(x_from, y_to),
	])


func circle(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func regular_polygon(center: Vector2, radius: float, sides: int, angle_offset: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in sides:
		var angle := angle_offset + TAU * float(index) / float(sides)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _zone_data(
	node_name: String,
	polygon: PackedVector2Array,
	zone: int,
	priority: int,
	walkable: bool,
	build_rule: int,
	is_outline: bool
) -> Dictionary:
	return {
		"name": node_name,
		"polygon": polygon,
		"zone": zone,
		"priority": priority,
		"order": 0,
		"walkable": walkable,
		"build_rule": build_rule,
		"is_outline": is_outline,
	}


func _resource_data(node_name: String, polygon: PackedVector2Array, spacing: float, pairs: Array) -> Dictionary:
	var entries: Array = []
	for pair in pairs:
		var entry := ResourceSpawnEntry.new()
		entry.definition = pair[0]
		entry.count = int(pair[1])
		entries.append(entry)
	return {
		"name": node_name,
		"polygon": polygon,
		"entries": entries,
		"min_spacing": spacing,
		"enabled": true,
	}

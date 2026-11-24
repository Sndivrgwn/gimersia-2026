extends RefCounted

## Dunia AUTHORED kecil yang dibangun di kode (tanpa file scene) untuk tes.
## Bentuk: pulau persegi 2400 px, camp radius 400, sungai strip, danau + batu
## sebagai penghalang solid.

const OUTLINE_HALF := 1200.0
const CAMP_RADIUS := 400.0
const LAKE_CENTER := Vector2(700.0, -700.0)
const LAKE_RADIUS := 200.0
const ROCK_CENTER := Vector2(-600.0, 600.0)
const ROCK_RADIUS := 180.0

const DEF_TWIG: ResourceNodeDefinition = preload("res://src/data/gathering/twig.tres")
const DEF_BERRY: ResourceNodeDefinition = preload("res://src/data/gathering/berry_bush.tres")
const DEF_BAMBOO: ResourceNodeDefinition = preload("res://src/data/gathering/bamboo_clump.tres")


func make_world() -> AuthoredWorld:
	var world := AuthoredWorld.new()
	world.name = "FixtureWorld"
	world.world_name = "fixture"
	world.layout_seed = 2026

	var zones := _container(world, "Zones")
	var markers := _container(world, "Markers")
	_container(world, "Visual")
	_container(world, "Decor")
	var resources := _container(world, "Resources")

	var outline := rect(-OUTLINE_HALF, -OUTLINE_HALF, OUTLINE_HALF, OUTLINE_HALF)
	var camp := circle(Vector2.ZERO, CAMP_RADIUS, 24)
	var river := rect(-1050.0, -1200.0, -850.0, 1200.0)

	_zone(zones, "IslandOutline", outline, WorldZoneType.Zone.FOREST, -100, true, 0, true)
	_zone(zones, "Forest", outline, WorldZoneType.Zone.FOREST, -50, true, 0, false)
	_zone(zones, "EastBeach", rect(900.0, -1200.0, 1200.0, 1200.0), WorldZoneType.Zone.EAST_BEACH, 0, true, 0, false)
	_zone(zones, "Camp", camp, WorldZoneType.Zone.CAMP, 10, true, 0, false)
	_zone(zones, "River", river, WorldZoneType.Zone.RIVER, 20, true, 0, false)
	_zone(zones, "Lake", circle(LAKE_CENTER, LAKE_RADIUS, 16), WorldZoneType.Zone.RIVER, 50, false, 2, false)
	_zone(zones, "RockFormation", regular_polygon(ROCK_CENTER, ROCK_RADIUS, 6, 0.3), WorldZoneType.Zone.FOREST, 50, false, 2, false)

	_marker(markers, "PlayerStart", Vector2(0.0, 64.0))
	_marker(markers, "PlaneWreckage", Vector2(0.0, -185.0))
	_marker(markers, "EmergencySuitcase", Vector2(-48.0, 40.0))
	_marker(markers, "SignalBeacon", Vector2(0.0, 900.0))
	var night := _container(markers, "NightSpawns")
	for index in 8:
		# Offset 0.35 rad menghindari formasi batu di (-600, 600) dan danau.
		var angle := TAU * float(index) / 8.0 + 0.35
		_marker(night, "NightSpawn%d" % (index + 1), Vector2(cos(angle), sin(angle)) * 850.0)
	var water := _container(markers, "WaterAccess")
	_marker(water, "WaterAccess1", Vector2(-950.0, -400.0))
	_marker(water, "WaterAccess2", Vector2(-950.0, 400.0))

	_resource_area(resources, "CampTwigs", camp, [_entry(DEF_TWIG, 6)], 70.0)
	_resource_area(resources, "RiverBamboo", river, [_entry(DEF_BAMBOO, 4)], 70.0)
	# Area sempit dengan jarak besar: pasti shortfall.
	_resource_area(resources, "TinyPatch", rect(300.0, 300.0, 400.0, 400.0), [_entry(DEF_BERRY, 30)], 200.0)
	return world


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


func _container(parent: Node, node_name: String) -> Node2D:
	var node := Node2D.new()
	node.name = node_name
	parent.add_child(node)
	return node


func _zone(
	parent: Node,
	node_name: String,
	polygon: PackedVector2Array,
	zone: int,
	priority: int,
	walkable: bool,
	build_rule: int,
	is_outline: bool
) -> ZoneArea:
	var area := ZoneArea.new()
	area.name = node_name
	area.polygon = polygon
	area.zone = zone
	area.priority = priority
	area.walkable = walkable
	area.build_rule = build_rule
	area.is_island_outline = is_outline
	parent.add_child(area)
	return area


func _marker(parent: Node, node_name: String, position_value: Vector2) -> Marker2D:
	var marker := Marker2D.new()
	marker.name = node_name
	marker.position = position_value
	parent.add_child(marker)
	return marker


func _resource_area(
	parent: Node,
	node_name: String,
	polygon: PackedVector2Array,
	entries: Array,
	spacing: float
) -> ResourceArea:
	var area := ResourceArea.new()
	area.name = node_name
	area.polygon = polygon
	area.min_spacing = spacing
	for entry in entries:
		area.entries.append(entry)
	parent.add_child(area)
	return area


func _entry(definition: ResourceNodeDefinition, count: int) -> ResourceSpawnEntry:
	var entry := ResourceSpawnEntry.new()
	entry.definition = definition
	entry.count = count
	return entry

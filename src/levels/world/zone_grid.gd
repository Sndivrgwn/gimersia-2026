@tool
class_name ZoneGrid
extends RefCounted

## Rasterisasi polygon dunia AUTHORED ke grid sel. Murni statis supaya bisa
## dipakai skrip @tool dan tes tanpa SceneTree.
##
## Sel hanya "playable" bila pusat sel ada di dalam outline; sel lain OUTSIDE
## dengan walk/build 0. Area diterapkan menaik menurut (priority, order), jadi
## penulis terakhir menang; walk=false tidak pernah bisa dinaikkan lagi.

const OUTSIDE := WorldZoneType.Zone.OUTSIDE


## areas: Array Dictionary {polygon, zone, priority, order, walkable, build_rule}.
## build_rule: 0 = DEFAULT, 1 = ALLOW, 2 = FORBID (samakan dengan ZoneArea).
static func build(outline: PackedVector2Array, areas: Array, cell_size: float) -> Dictionary:
	var cell := maxf(cell_size, 1.0)
	var bounds := polygon_bounds(outline)
	var cols := maxi(1, int(ceil(bounds.size.x / cell)))
	var rows := maxi(1, int(ceil(bounds.size.y / cell)))
	var total := cols * rows
	var zone := PackedByteArray()
	var walk := PackedByteArray()
	var build_rule := PackedByteArray()
	zone.resize(total)
	walk.resize(total)
	build_rule.resize(total)
	zone.fill(OUTSIDE)
	walk.fill(0)
	build_rule.fill(0)

	var inside := PackedByteArray()
	inside.resize(total)
	inside.fill(0)
	for row in rows:
		for col in cols:
			var center := bounds.position + Vector2((col + 0.5) * cell, (row + 0.5) * cell)
			if not Geometry2D.is_point_in_polygon(center, outline):
				continue
			var index := row * cols + col
			inside[index] = 1
			zone[index] = WorldZoneType.Zone.FOREST
			walk[index] = 1
			build_rule[index] = 1 if WorldZoneType.default_buildable(WorldZoneType.Zone.FOREST) else 0

	var ordered := areas.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var priority_a := int(a.get("priority", 0))
		var priority_b := int(b.get("priority", 0))
		if priority_a != priority_b:
			return priority_a < priority_b
		return int(a.get("order", 0)) < int(b.get("order", 0))
	)
	for area in ordered:
		var polygon: PackedVector2Array = area.get("polygon", PackedVector2Array())
		if polygon.size() < 3:
			continue
		var area_bounds := polygon_bounds(polygon)
		var col_from := maxi(0, int(floor((area_bounds.position.x - bounds.position.x) / cell)))
		var col_to := mini(cols - 1, int(floor((area_bounds.end.x - bounds.position.x) / cell)))
		var row_from := maxi(0, int(floor((area_bounds.position.y - bounds.position.y) / cell)))
		var row_to := mini(rows - 1, int(floor((area_bounds.end.y - bounds.position.y) / cell)))
		for row in range(row_from, row_to + 1):
			for col in range(col_from, col_to + 1):
				var index := row * cols + col
				if inside[index] == 0:
					continue
				var center := bounds.position + Vector2((col + 0.5) * cell, (row + 0.5) * cell)
				if not Geometry2D.is_point_in_polygon(center, polygon):
					continue
				var area_zone := int(area.get("zone", WorldZoneType.Zone.FOREST))
				zone[index] = area_zone
				if not bool(area.get("walkable", true)):
					walk[index] = 0
				build_rule[index] = _build_value(int(area.get("build_rule", 0)), area_zone)

	return {
		"cell": cell,
		"origin": bounds.position,
		"cols": cols,
		"rows": rows,
		"zone": zone,
		"walk": walk,
		"build": build_rule,
	}


## Hasil lookup satu titik: {zone, walk, build}. Di luar grid = OUTSIDE/0/0.
static func lookup(grid: Dictionary, position: Vector2) -> Dictionary:
	if grid.is_empty():
		return {"zone": OUTSIDE, "walk": false, "build": false}
	var index := cell_index(grid, position)
	if index < 0:
		return {"zone": OUTSIDE, "walk": false, "build": false}
	var zone: PackedByteArray = grid["zone"]
	var walk: PackedByteArray = grid["walk"]
	var build_rule: PackedByteArray = grid["build"]
	return {
		"zone": int(zone[index]),
		"walk": int(walk[index]) == 1,
		"build": int(build_rule[index]) == 1,
	}


## Indeks sel untuk posisi; -1 bila di luar grid.
static func cell_index(grid: Dictionary, position: Vector2) -> int:
	if grid.is_empty():
		return -1
	var cell := float(grid["cell"])
	var origin: Vector2 = grid["origin"]
	var col := int(floor((position.x - origin.x) / cell))
	var row := int(floor((position.y - origin.y) / cell))
	var cols := int(grid["cols"])
	var rows := int(grid["rows"])
	if col < 0 or row < 0 or col >= cols or row >= rows:
		return -1
	return row * cols + col


static func polygon_bounds(polygon: PackedVector2Array) -> Rect2:
	if polygon.is_empty():
		return Rect2()
	var min_point := polygon[0]
	var max_point := polygon[0]
	for point in polygon:
		min_point = Vector2(minf(min_point.x, point.x), minf(min_point.y, point.y))
		max_point = Vector2(maxf(max_point.x, point.x), maxf(max_point.y, point.y))
	return Rect2(min_point, max_point - min_point)


## Jarak titik ke tepi polygon (polygon dianggap tertutup).
static func distance_to_segments(polygon: PackedVector2Array, position: Vector2) -> float:
	if polygon.size() < 2:
		return INF
	var best := INF
	var count := polygon.size()
	for index in count:
		var a := polygon[index]
		var b := polygon[(index + 1) % count]
		var closest := Geometry2D.get_closest_point_to_segment(position, a, b)
		best = minf(best, position.distance_to(closest))
	return best


static func _build_value(rule: int, zone: int) -> int:
	match rule:
		1:
			return 1
		2:
			return 0
		_:
			return 1 if WorldZoneType.default_buildable(zone) else 0

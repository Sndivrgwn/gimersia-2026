class_name AuthoredWorldSource
extends WorldSource

## Sumber dunia AUTHORED: grid zona + polygon asli + marker + rencana resource.
## Datanya diisi AuthoredWorld.make_source() lewat setup() (dictionary polos),
## supaya kelas ini tidak bergantung pada scene.

const POI_NAMES: Array[StringName] = [
	WorldSource.POI_PLAYER_START,
	WorldSource.POI_PLANE_WRECKAGE,
	WorldSource.POI_EMERGENCY_SUITCASE,
	WorldSource.POI_SIGNAL_BEACON,
]

var cell_size: float = 32.0
var outline := PackedVector2Array()
var markers: Dictionary = {}
var grid: Dictionary = {}
## zone -> Array[PackedVector2Array] (polygon global area zona itu).
var polygons_by_zone: Dictionary = {}
var resource_areas: Array = []
## Metadata area zona asli (polygon, zone, priority, order, walkable, build_rule,
## is_outline, name) untuk validator.
var zone_areas: Array = []
var outline_count: int = 0
var manual_nodes: Array[Vector2] = []
## Node resource manual: {definition: StringName, position: Vector2}.
var manual_resources: Array = []
var night_points := PackedVector2Array()
var water_points := PackedVector2Array()

var _shortfalls: Dictionary = {}
var _blocked_polygons: Array = []


## data keys: outline, zone_areas, markers, manual_nodes, resource_areas,
## night_points, water_points, cell_size.
func setup(data: Dictionary) -> void:
	outline = PackedVector2Array(data.get("outline", PackedVector2Array()))
	var marker_data = data.get("markers", {})
	markers = marker_data if marker_data is Dictionary else {}
	manual_nodes.clear()
	for point in data.get("manual_nodes", []):
		manual_nodes.append(point)
	manual_resources = data.get("manual_resources", [])
	resource_areas = data.get("resource_areas", [])
	night_points = PackedVector2Array(data.get("night_points", PackedVector2Array()))
	water_points = PackedVector2Array(data.get("water_points", PackedVector2Array()))
	cell_size = maxf(float(data.get("cell_size", 32.0)), 1.0)
	zone_areas = data.get("zone_areas", [])

	polygons_by_zone.clear()
	_blocked_polygons.clear()
	outline_count = 0
	for area in zone_areas:
		if bool(area.get("is_outline", false)):
			outline_count += 1
		var polygon: PackedVector2Array = area.get("polygon", PackedVector2Array())
		if polygon.size() < 3:
			continue
		var zone := int(area.get("zone", WorldZoneType.Zone.FOREST))
		if not polygons_by_zone.has(zone):
			polygons_by_zone[zone] = []
		(polygons_by_zone[zone] as Array).append(polygon)
		if not bool(area.get("walkable", true)):
			_blocked_polygons.append(polygon)
	if outline_count == 0 and outline.size() >= 3:
		outline_count = 1
	# Sel di dalam outline tanpa area eksplisit adalah hutan.
	if not polygons_by_zone.has(WorldZoneType.Zone.FOREST):
		polygons_by_zone[WorldZoneType.Zone.FOREST] = []
	(polygons_by_zone[WorldZoneType.Zone.FOREST] as Array).append(outline)

	grid = ZoneGrid.build(outline, zone_areas, cell_size)


func id() -> StringName:
	return &"authored"


func zone_at(position: Vector2) -> int:
	return int(ZoneGrid.lookup(grid, position)["zone"])


func is_walkable(position: Vector2) -> bool:
	return bool(ZoneGrid.lookup(grid, position)["walk"])


func is_buildable(position: Vector2) -> bool:
	var cell := ZoneGrid.lookup(grid, position)
	return bool(cell["walk"]) and bool(cell["build"])


func bounds() -> Rect2:
	return ZoneGrid.polygon_bounds(outline)


## 0 di luar pulau (sama seperti aturan lama: tepi = tidak bisa dibangun).
func distance_to_coast(position: Vector2) -> float:
	if not Geometry2D.is_point_in_polygon(position, outline):
		return 0.0
	return ZoneGrid.distance_to_segments(outline, position)


func distance_to_zone(position: Vector2, zone: int) -> float:
	if zone_at(position) == zone:
		return 0.0
	var polygons: Array = polygons_by_zone.get(zone, [])
	var best := INF
	for polygon in polygons:
		best = minf(best, ZoneGrid.distance_to_segments(polygon, position))
	return best


func poi(name: StringName) -> Vector2:
	return markers.get(name, Vector2.INF)


func night_spawn_points() -> PackedVector2Array:
	return night_points


func water_access_points() -> PackedVector2Array:
	return water_points


## Titik tengah polygon terbesar milik zona itu (rata-rata vertex).
func zone_center(zone: int) -> Vector2:
	if zone == WorldZoneType.Zone.OUTSIDE:
		return Vector2.INF
	var polygons: Array = polygons_by_zone.get(zone, [])
	var best: PackedVector2Array = PackedVector2Array()
	var best_area := -1.0
	for polygon in polygons:
		var area := absf(_polygon_area(polygon))
		if area > best_area:
			best_area = area
			best = polygon
	if best.is_empty():
		return Vector2.INF
	var sum := Vector2.ZERO
	for point in best:
		sum += point
	var center := sum / float(best.size())
	if zone_at(center) == zone:
		return center
	# Centroid polygon bisa jatuh di zona lain (mis. outline hutan yang
	# mengelilingi camp): pilih sel zona itu yang terdekat.
	return _nearest_cell_center(zone, center)


func _nearest_cell_center(zone: int, near: Vector2) -> Vector2:
	if grid.is_empty():
		return Vector2.INF
	var cell := float(grid["cell"])
	var origin: Vector2 = grid["origin"]
	var cols := int(grid["cols"])
	var rows := int(grid["rows"])
	var zones: PackedByteArray = grid["zone"]
	var best_point := Vector2.INF
	var best_distance := INF
	for row in rows:
		for col in cols:
			if int(zones[row * cols + col]) != zone:
				continue
			var center := origin + Vector2((col + 0.5) * cell, (row + 0.5) * cell)
			var distance := center.distance_squared_to(near)
			if distance < best_distance:
				best_distance = distance
				best_point = center
	return best_point


func has_resource_plan() -> bool:
	for area in resource_areas:
		if not bool(area.get("enabled", true)):
			continue
		for entry in area.get("entries", []):
			if entry != null and entry.definition != null and int(entry.count) > 0:
				return true
	return false


## Sebar deterministik per area (diurutkan nama node). Seed = seed_value xor
## hash(nama area); maksimal 200 percobaan per node.
func resource_plan(layout: IslandLayoutConfig, seed_value: int) -> Array:
	var result: Array = []
	_shortfalls.clear()
	var placed: Array[Vector2] = []
	placed.append_array(manual_nodes)

	var areas: Array = []
	for area in resource_areas:
		if not bool(area.get("enabled", true)):
			continue
		var entries: Array = area.get("entries", [])
		if entries.is_empty():
			continue
		areas.append(area)
	areas.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("name", "")) < String(b.get("name", ""))
	)

	for area in areas:
		var name := String(area.get("name", ""))
		var polygon: PackedVector2Array = area.get("polygon", PackedVector2Array())
		if polygon.size() < 3:
			continue
		var entries: Array = area.get("entries", [])
		var spacing := float(area.get("min_spacing", layout.min_spacing))
		var area_bounds := ZoneGrid.polygon_bounds(polygon)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value ^ hash(name)
		var requested := 0
		var placed_here := 0
		for entry in entries:
			if entry == null or entry.definition == null:
				continue
			var count := int(entry.count)
			requested += count
			for index in count:
				var point := Vector2.INF
				for attempt in 200:
					var candidate := Vector2(
						rng.randf_range(area_bounds.position.x, area_bounds.end.x),
						rng.randf_range(area_bounds.position.y, area_bounds.end.y)
					)
					if not Geometry2D.is_point_in_polygon(candidate, polygon):
						continue
					if not is_walkable(candidate):
						continue
					if _inside_blocked(candidate):
						continue
					if not _clear_of_pois(candidate, layout):
						continue
					if not _clear_of_nodes(candidate, placed, spacing):
						continue
					point = candidate
					break
				if point == Vector2.INF:
					continue
				placed.append(point)
				placed_here += 1
				result.append({
					"definition": entry.definition,
					"position": point,
					"last_respawn_day": entry.last_respawn_day,
				})
		if placed_here < requested:
			_shortfalls[name] = requested - placed_here

	return result


## Area -> jumlah node yang gagal ditempatkan (permintaan - hasil).
func get_shortfalls() -> Dictionary:
	return _shortfalls.duplicate()


func is_inside_blocked(position: Vector2) -> bool:
	return _inside_blocked(position)


func _inside_blocked(position: Vector2) -> bool:
	for polygon in _blocked_polygons:
		if Geometry2D.is_point_in_polygon(position, polygon):
			return true
	return false


func _clear_of_pois(position: Vector2, layout: IslandLayoutConfig) -> bool:
	for poi_name in POI_NAMES:
		var target := poi(poi_name)
		if target == Vector2.INF:
			continue
		var radius := layout.beacon_keep_out if poi_name == WorldSource.POI_SIGNAL_BEACON else layout.keep_out_radius
		if position.distance_to(target) < radius:
			return false
	return true


func _clear_of_nodes(position: Vector2, placed: Array[Vector2], spacing: float) -> bool:
	for other in placed:
		if position.distance_to(other) < spacing:
			return false
	return true


func _polygon_area(polygon: PackedVector2Array) -> float:
	var total := 0.0
	var count := polygon.size()
	for index in count:
		var a := polygon[index]
		var b := polygon[(index + 1) % count]
		total += a.x * b.y - b.x * a.y
	return total * 0.5

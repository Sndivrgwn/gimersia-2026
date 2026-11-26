class_name WorldValidator
extends RefCounted

## Validator dunia AUTHORED (Mission 13 blok H). Murni statis: tidak menyentuh
## scene, jadi bisa dipakai editor (_get_configuration_warnings), CLI, dan tes.
##
## Semua kode stabil. Flood fill iteratif (PackedInt32Array), tanpa rekursi.

const CODES := {
	"W001": {"severity": "ERROR", "message_id": "Outline pulau hilang, kurang dari 3 titik, atau memotong dirinya sendiri.", "fix_id": "Perbaiki polygon ZoneArea outline."},
	"W002": {"severity": "ERROR", "message_id": "Ada lebih dari satu ZoneArea outline.", "fix_id": "Sisakan tepat satu area dengan is_island_outline."},
	"W003": {"severity": "ERROR", "message_id": "Marker wajib belum ada.", "fix_id": "Tambahkan marker di Markers."},
	"W004": {"severity": "ERROR", "message_id": "Marker wajib di luar pulau atau tidak walkable.", "fix_id": "Pindahkan marker ke tanah yang bisa dilewati."},
	"W005": {"severity": "ERROR", "message_id": "Jumlah night spawn kurang dari minimum.", "fix_id": "Tambah Marker2D di NightSpawns."},
	"W006": {"severity": "ERROR", "message_id": "Night spawn berada di sel yang tidak walkable.", "fix_id": "Pindahkan night spawn ke tanah walkable."},
	"W007": {"severity": "WARN", "message_id": "Night spawn terlalu dekat dengan PlayerStart.", "fix_id": "Jauhkan night spawn dari titik spawn pemain."},
	"W008": {"severity": "ERROR", "message_id": "Titik/area tidak terjangkau dari PlayerStart.", "fix_id": "Buka koridor atau pindahkan titiknya."},
	"W009": {"severity": "ERROR", "message_id": "Tidak ada tanah datar yang bisa dibangun di dekat PlayerStart.", "fix_id": "Longgarkan area walkable+buildable di sekitar start."},
	"W010": {"severity": "ERROR", "message_id": "Sumber resource wajib (atau akses air) tidak ada.", "fix_id": "Tambah entry ResourceArea / marker WaterAccess."},
	"W011": {"severity": "WARN", "message_id": "Jumlah resource terjangkau jauh di bawah angka FORMULA.", "fix_id": "Tambah area atau jumlah entry."},
	"W012": {"severity": "WARN", "message_id": "Koridor terlalu sempit setelah erosi: hewan tidak bisa lewat.", "fix_id": "Lebarkan koridor minimal min_corridor_width."},
	"W013": {"severity": "WARN", "message_id": "ZoneArea berbeda zona saling menimpa dengan prioritas sama.", "fix_id": "Ubah priority salah satu area."},
	"W014": {"severity": "WARN", "message_id": "Polygon melebihi batas jumlah vertex.", "fix_id": "Sederhanakan polygon."},
	"W015": {"severity": "WARN", "message_id": "ResourceArea tidak bisa menempatkan semua node.", "fix_id": "Perbesar area atau kecilkan count."},
	"W016": {"severity": "WARN", "message_id": "Area FOREST terjangkau terlalu kecil untuk fauna.", "fix_id": "Perluas hutan yang bisa dilewati."},
	"W017": {"severity": "WARN", "message_id": "Resource manual berada di area terlarang atau di luar pulau.", "fix_id": "Pindahkan node resource manual."},
}

const REQUIRED_MARKERS: Array[StringName] = [
	WorldSource.POI_PLAYER_START,
	WorldSource.POI_PLANE_WRECKAGE,
	WorldSource.POI_EMERGENCY_SUITCASE,
	WorldSource.POI_SIGNAL_BEACON,
]
const REQUIRED_REACHABLE: Array[StringName] = [
	WorldSource.POI_PLANE_WRECKAGE,
	WorldSource.POI_EMERGENCY_SUITCASE,
	WorldSource.POI_SIGNAL_BEACON,
]
## Kategori resource wajib: nama -> daftar definition id.
const RESOURCE_GROUPS := {
	"kayu": ["twig", "tree", "small_tree"],
	"batu": ["small_rock", "big_rock"],
	"fiber": ["fiber_bush"],
	"berry": ["berry_bush"],
	"bambu": ["bamboo_clump"],
}
const OPTIONAL_GROUPS := {
	"kelapa": ["coconut_palm"],
}


static func validate(source: AuthoredWorldSource, cfg: WorldConfig, ctx: Dictionary = {}) -> Array:
	var results: Array = []
	if source == null or cfg == null:
		return results
	var layout: IslandLayoutConfig = ctx.get("layout", IslandLayoutConfig.new())
	var fence_config: FenceConfig = ctx.get("fence_config", FenceConfig.new())
	var seed_value := int(ctx.get("seed_value", layout.layout_seed))

	results.append_array(static_checks(source, cfg))
	if source.grid.is_empty():
		return results
	var grid := source.grid
	var start := source.poi(WorldSource.POI_PLAYER_START)
	var reachable := PackedByteArray()
	if start != Vector2.INF:
		reachable = flood_fill(grid, start)

	_add_night_spawn_distance(source, cfg, start, results)

	if not reachable.is_empty():
		_add_reachability(source, reachable, results)

	_add_base_site_check(source, cfg, fence_config, reachable, start, results)
	_add_corridor_check(source, cfg, reachable, start, results)
	_add_forest_check(source, grid, cfg, reachable, results)
	_add_manual_check(source, results)

	var plan: Array = source.resource_plan(layout, seed_value)
	_add_resource_checks(source, cfg, layout, plan, reachable, results)
	_add_shortfalls(source, results)
	return results


## Kode yang tidak butuh flood fill (dipakai _get_configuration_warnings).
static func static_checks(source: AuthoredWorldSource, cfg: WorldConfig) -> Array:
	var results: Array = []
	if source == null or cfg == null:
		return results
	_add_outline_checks(source, cfg, results)
	_add_marker_checks(source, results)
	_add_spawn_count_checks(source, cfg, results)
	_add_overlap_check(source, cfg, results)
	return results


static func format_report(results: Array) -> String:
	var errors := 0
	var warnings := 0
	for result in results:
		if String(result.get("severity", "")) == "ERROR":
			errors += 1
		else:
			warnings += 1
	var lines := PackedStringArray()
	lines.append("Validasi dunia: %d ERROR, %d WARN" % [errors, warnings])
	for result in results:
		var position = result.get("position", null)
		var suffix := ""
		if position != null:
			suffix = " (%s)" % str(position)
		lines.append("[%s] %s: %s%s" % [
			String(result.get("severity", "")), String(result.get("code", "")),
			String(result.get("message", "")), suffix,
		])
	if results.is_empty():
		lines.append("Tidak ada masalah.")
	return "\n".join(lines)


## Entry point CLI bersama (tools/validate_world.gd hanya pembungkus tipis).
static func validate_scene(path: String, cfg: WorldConfig) -> Dictionary:
	var result := {"results": [], "report": "", "errors": 0, "warnings": 0, "exit_code": 0}
	var packed := load(path) as PackedScene
	if packed == null:
		result["report"] = "Tidak bisa memuat scene: %s" % path
		result["errors"] = 1
		result["exit_code"] = 1
		return result
	var instance := packed.instantiate()
	if not (instance is AuthoredWorld):
		result["report"] = "Root scene bukan AuthoredWorld: %s" % path
		result["errors"] = 1
		result["exit_code"] = 1
		if instance != null:
			instance.free()
		return result
	var world := instance as AuthoredWorld
	var source := world.make_source(cfg.cell_size if cfg != null else 32.0)
	var results := validate(source, cfg)
	result["results"] = results
	result["report"] = format_report(results)
	for entry in results:
		if String(entry.get("severity", "")) == "ERROR":
			result["errors"] = int(result["errors"]) + 1
		else:
			result["warnings"] = int(result["warnings"]) + 1
	result["exit_code"] = 1 if int(result["errors"]) > 0 else 0
	world.free()
	return result


# --- Grid helpers -----------------------------------------------------------

static func walkable_mask(grid: Dictionary) -> PackedByteArray:
	var walk: PackedByteArray = grid["walk"]
	var mask := PackedByteArray()
	mask.resize(walk.size())
	for index in walk.size():
		mask[index] = 1 if int(walk[index]) == 1 else 0
	return mask


## Sel yang terjangkau dari posisi start (4 tetangga, iteratif).
static func flood_fill(grid: Dictionary, start: Vector2) -> PackedByteArray:
	var total := int(grid["cols"]) * int(grid["rows"])
	var reached := PackedByteArray()
	reached.resize(total)
	reached.fill(0)
	var start_index := ZoneGrid.cell_index(grid, start)
	if start_index < 0:
		return reached
	var walk: PackedByteArray = grid["walk"]
	var cols := int(grid["cols"])
	var rows := int(grid["rows"])
	var queue := PackedInt32Array()
	queue.append(start_index)
	reached[start_index] = 1
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		var col := index % cols
		var row := floori(float(index) / float(cols))
		for step in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
			var next_col: int = col + int(step[0])
			var next_row: int = row + int(step[1])
			if next_col < 0 or next_row < 0 or next_col >= cols or next_row >= rows:
				continue
			var next := next_row * cols + next_col
			if int(reached[next]) == 1 or int(walk[next]) == 0:
				continue
			reached[next] = 1
			queue.append(next)
	return reached


## Erosi walkable mask selebar `cells` sel (kernel persegi).
static func erode(grid: Dictionary, cells: int) -> PackedByteArray:
	var walk := walkable_mask(grid)
	var cols := int(grid["cols"])
	var rows := int(grid["rows"])
	var eroded := PackedByteArray()
	eroded.resize(walk.size())
	eroded.fill(0)
	var radius := maxi(cells, 0)
	for row in rows:
		for col in cols:
			var index := row * cols + col
			if int(walk[index]) == 0:
				continue
			var solid := true
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					var c := col + dx
					var r := row + dy
					if c < 0 or r < 0 or c >= cols or r >= rows or int(walk[r * cols + c]) == 0:
						solid = false
						break
				if not solid:
					break
			if solid:
				eroded[index] = 1
	return eroded


static func is_reachable(grid: Dictionary, reachable: PackedByteArray, position: Vector2) -> bool:
	var index := ZoneGrid.cell_index(grid, position)
	if index < 0 or reachable.is_empty():
		return false
	return int(reachable[index]) == 1


# --- Kode -------------------------------------------------------------------

## severity_override dipakai saat satu kode bisa ERROR atau WARN (mis. kelapa).
static func _add(results: Array, code: String, message: String, position = null, severity_override := "") -> void:
	var severity := String(CODES[code]["severity"])
	if not severity_override.is_empty():
		severity = severity_override
	results.append({
		"code": code,
		"severity": severity,
		"message": message,
		"position": position,
	})


static func _add_outline_checks(source: AuthoredWorldSource, cfg: WorldConfig, results: Array) -> void:
	var outline := source.outline
	if outline.size() < 3:
		_add(results, "W001", "Outline pulau belum ada atau kurang dari 3 titik.")
	elif _is_self_intersecting(outline):
		_add(results, "W001", "Outline pulau memotong dirinya sendiri.", outline[0])
	if source.outline_count > 1:
		_add(results, "W002", "Ada %d ZoneArea outline; harus tepat satu." % source.outline_count)
	for area in source.zone_areas:
		var polygon: PackedVector2Array = area.get("polygon", PackedVector2Array())
		if polygon.size() > cfg.polygon_vertex_limit:
			_add(results, "W014", "Polygon '%s' punya %d vertex (batas %d)." % [
				String(area.get("name", "?")), polygon.size(), cfg.polygon_vertex_limit
			], polygon[0])
	for area in source.resource_areas:
		var polygon: PackedVector2Array = area.get("polygon", PackedVector2Array())
		if polygon.size() > cfg.polygon_vertex_limit:
			_add(results, "W014", "ResourceArea '%s' punya %d vertex (batas %d)." % [
				String(area.get("name", "?")), polygon.size(), cfg.polygon_vertex_limit
			], polygon[0])


static func _add_marker_checks(source: AuthoredWorldSource, results: Array) -> void:
	for poi_name in REQUIRED_MARKERS:
		var point := source.poi(poi_name)
		if point == Vector2.INF:
			_add(results, "W003", "Marker wajib '%s' belum ada." % String(poi_name))
			continue
		if not _inside_island(source, point) or not source.is_walkable(point):
			_add(results, "W004", "Marker '%s' di luar pulau atau tidak walkable." % String(poi_name), point)


static func _add_spawn_count_checks(source: AuthoredWorldSource, cfg: WorldConfig, results: Array) -> void:
	var points := source.night_spawn_points()
	if points.size() < cfg.min_spawn_points:
		_add(results, "W005", "Night spawn %d < minimum %d." % [points.size(), cfg.min_spawn_points])
	for point in points:
		if not source.is_walkable(point):
			_add(results, "W006", "Night spawn di sel tidak walkable.", point)


static func _add_overlap_check(source: AuthoredWorldSource, _cfg: WorldConfig, results: Array) -> void:
	var areas: Array = source.zone_areas
	for i in areas.size():
		for j in range(i + 1, areas.size()):
			var a: Dictionary = areas[i]
			var b: Dictionary = areas[j]
			if int(a.get("zone", -1)) == int(b.get("zone", -2)):
				continue
			if int(a.get("priority", 0)) != int(b.get("priority", 0)):
				continue
			var polygon_a: PackedVector2Array = a.get("polygon", PackedVector2Array())
			var polygon_b: PackedVector2Array = b.get("polygon", PackedVector2Array())
			if _polygons_overlap(polygon_a, polygon_b):
				var point: Variant = null
				if polygon_a.size() > 0:
					point = polygon_a[0]
				_add(results, "W013", "Zona '%s' dan '%s' menimpa dengan prioritas sama (%d)." % [
					String(a.get("name", "?")), String(b.get("name", "?")), int(a.get("priority", 0))
				], point)


static func _add_night_spawn_distance(source: AuthoredWorldSource, cfg: WorldConfig, start: Vector2, results: Array) -> void:
	if start == Vector2.INF:
		return
	for point in source.night_spawn_points():
		if point.distance_to(start) < cfg.min_spawn_distance:
			_add(results, "W007", "Night spawn %.0f px dari PlayerStart (< %.0f)." % [
				point.distance_to(start), cfg.min_spawn_distance
			], point)


static func _add_reachability(source: AuthoredWorldSource, reachable: PackedByteArray, results: Array) -> void:
	var grid := source.grid
	for poi_name in REQUIRED_REACHABLE:
		var point := source.poi(poi_name)
		if point == Vector2.INF:
			continue
		if not is_reachable(grid, reachable, point):
			_add(results, "W008", "'%s' tidak terjangkau dari PlayerStart." % String(poi_name), point)
	for point in source.night_spawn_points():
		if not is_reachable(grid, reachable, point):
			_add(results, "W008", "Night spawn tidak terjangkau dari PlayerStart.", point)
	for area in source.resource_areas:
		var polygon: PackedVector2Array = area.get("polygon", PackedVector2Array())
		if polygon.is_empty():
			continue
		if not _area_reachable(grid, reachable, polygon):
			_add(results, "W008", "ResourceArea '%s' tidak terjangkau." % String(area.get("name", "?")), polygon[0])


static func _add_base_site_check(
	source: AuthoredWorldSource,
	cfg: WorldConfig,
	fence_config: FenceConfig,
	reachable: PackedByteArray,
	start: Vector2,
	results: Array
) -> void:
	if start == Vector2.INF or reachable.is_empty():
		return
	var radius := fence_config.ring_radius + cfg.base_clearance_extra
	if _has_buildable_disk(source.grid, reachable, start, radius, 800.0):
		return
	_add(results, "W009", "Tidak ada tanah buildable radius %.0f px dalam 800 px dari PlayerStart." % radius, start)


static func _add_corridor_check(
	source: AuthoredWorldSource,
	cfg: WorldConfig,
	reachable: PackedByteArray,
	start: Vector2,
	results: Array
) -> void:
	var beacon := source.poi(WorldSource.POI_SIGNAL_BEACON)
	if start == Vector2.INF or beacon == Vector2.INF or reachable.is_empty():
		return
	var cells := int(ceil(cfg.min_corridor_width / 2.0 / float(source.grid["cell"])))
	var eroded := erode(source.grid, maxi(cells, 1))
	var eroded_grid := source.grid.duplicate()
	eroded_grid["walk"] = eroded
	var eroded_reachable := flood_fill(eroded_grid, start)
	if is_reachable(source.grid, eroded_reachable, beacon):
		return
	_add(results, "W012", "Setelah erosi %d sel, PlayerStart tidak bisa mencapai SignalBeacon." % cells, beacon)


static func _add_forest_check(
	_source: AuthoredWorldSource,
	grid: Dictionary,
	cfg: WorldConfig,
	reachable: PackedByteArray,
	results: Array
) -> void:
	if reachable.is_empty():
		return
	var zones: PackedByteArray = grid["zone"]
	var cell := float(grid["cell"])
	var forest_cells := 0
	for index in reachable.size():
		if int(reachable[index]) != 1:
			continue
		if int(zones[index]) == WorldZoneType.Zone.FOREST:
			forest_cells += 1
	var area := float(forest_cells) * cell * cell
	if area < cfg.min_forest_area:
		_add(results, "W016", "Area FOREST terjangkau %.0f px^2 < %.0f." % [area, cfg.min_forest_area])


static func _add_manual_check(source: AuthoredWorldSource, results: Array) -> void:
	for entry in source.manual_resources:
		var point: Vector2 = entry.get("position", Vector2.INF)
		if point == Vector2.INF:
			continue
		if not _inside_island(source, point) or source.is_inside_blocked(point):
			_add(results, "W017", "Resource manual '%s' di area terlarang/luar pulau." % String(entry.get("definition", "?")), point)


static func _add_resource_checks(
	source: AuthoredWorldSource,
	cfg: WorldConfig,
	layout: IslandLayoutConfig,
	plan: Array,
	reachable: PackedByteArray,
	results: Array
) -> void:
	var counted := {}
	for entry in plan:
		var point: Vector2 = entry["position"]
		if not is_reachable(source.grid, reachable, point):
			continue
		var definition: ResourceNodeDefinition = entry["definition"]
		if definition == null:
			continue
		var id := String(definition.id)
		counted[id] = int(counted.get(id, 0)) + 1
	for entry in source.manual_resources:
		if not is_reachable(source.grid, reachable, entry.get("position", Vector2.INF)):
			continue
		var id := String(entry.get("definition", ""))
		counted[id] = int(counted.get(id, 0)) + 1

	var formula_totals := _formula_totals(layout)
	for group_name in RESOURCE_GROUPS:
		var reachable_count := _count_group(counted, RESOURCE_GROUPS[group_name])
		if reachable_count <= 0:
			_add(results, "W010", "Tidak ada sumber %s yang terjangkau." % String(group_name))
			continue
		var required := float(formula_totals.get(group_name, 0)) * cfg.warn_node_ratio
		if float(reachable_count) < required:
			_add(results, "W011", "Sumber %s terjangkau %d < %.0f (rasio %.2f dari FORMULA)." % [
				String(group_name), reachable_count, required, cfg.warn_node_ratio
			])
	for group_name in OPTIONAL_GROUPS:
		var reachable_count := _count_group(counted, OPTIONAL_GROUPS[group_name])
		if reachable_count <= 0:
			_add(results, "W010", "Sumber %s tidak ada (opsional)." % String(group_name), null, "WARN")
			continue
		var required := float(formula_totals.get(group_name, 0)) * cfg.warn_node_ratio
		if float(reachable_count) < required:
			_add(results, "W011", "Sumber %s terjangkau %d < %.0f." % [String(group_name), reachable_count, required])

	var has_river := source.polygons_by_zone.has(WorldZoneType.Zone.RIVER)
	if source.water_access_points().is_empty() and not has_river:
		_add(results, "W010", "Tidak ada WaterAccess dan tidak ada area RIVER.")


static func _add_shortfalls(source: AuthoredWorldSource, results: Array) -> void:
	var shortfalls: Dictionary = source.get_shortfalls()
	var names: Array = shortfalls.keys()
	names.sort()
	for area_name in names:
		_add(results, "W015", "ResourceArea '%s' gagal menempatkan %d node." % [
			String(area_name), int(shortfalls[area_name])
		])


# --- Internal ---------------------------------------------------------------

static func _inside_island(source: AuthoredWorldSource, point: Vector2) -> bool:
	if source.outline.size() < 3:
		return false
	return Geometry2D.is_point_in_polygon(point, source.outline)


static func _count_group(counted: Dictionary, ids: Array) -> int:
	var total := 0
	for id in ids:
		total += int(counted.get(String(id), 0))
	return total


static func _formula_totals(layout: IslandLayoutConfig) -> Dictionary:
	return {
		"kayu": layout.camp_twig + layout.camp_small_tree + layout.forest_tree,
		"batu": layout.camp_small_rock + layout.west_small_rock + layout.west_big_rock,
		"fiber": layout.camp_fiber_bush + layout.forest_fiber_bush,
		"berry": layout.camp_berry_bush + layout.forest_berry_bush,
		"bambu": layout.river_bamboo,
		"kelapa": layout.south_coconut_palm,
	}


static func _area_reachable(grid: Dictionary, reachable: PackedByteArray, polygon: PackedVector2Array) -> bool:
	var cols := int(grid["cols"])
	var rows := int(grid["rows"])
	var cell := float(grid["cell"])
	var origin: Vector2 = grid["origin"]
	var bounds := ZoneGrid.polygon_bounds(polygon)
	var col_from := maxi(0, int(floor((bounds.position.x - origin.x) / cell)))
	var col_to := mini(cols - 1, int(floor((bounds.end.x - origin.x) / cell)))
	var row_from := maxi(0, int(floor((bounds.position.y - origin.y) / cell)))
	var row_to := mini(rows - 1, int(floor((bounds.end.y - origin.y) / cell)))
	for row in range(row_from, row_to + 1):
		for col in range(col_from, col_to + 1):
			var index := row * cols + col
			if int(reachable[index]) != 1:
				continue
			var center := origin + Vector2((col + 0.5) * cell, (row + 0.5) * cell)
			if Geometry2D.is_point_in_polygon(center, polygon):
				return true
	return false


static func _has_buildable_disk(
	grid: Dictionary,
	reachable: PackedByteArray,
	center: Vector2,
	radius: float,
	search_radius: float
) -> bool:
	var cols := int(grid["cols"])
	var rows := int(grid["rows"])
	var cell := float(grid["cell"])
	var origin: Vector2 = grid["origin"]
	var walk: PackedByteArray = grid["walk"]
	var build: PackedByteArray = grid["build"]
	var cell_radius := int(ceil(radius / cell))
	var col_from := maxi(0, int(floor((center.x - search_radius - origin.x) / cell)))
	var col_to := mini(cols - 1, int(floor((center.x + search_radius - origin.x) / cell)))
	var row_from := maxi(0, int(floor((center.y - search_radius - origin.y) / cell)))
	var row_to := mini(rows - 1, int(floor((center.y + search_radius - origin.y) / cell)))
	for row in range(row_from, row_to + 1, 2):
		for col in range(col_from, col_to + 1, 2):
			var index := row * cols + col
			if int(walk[index]) == 0 or int(build[index]) == 0 or int(reachable[index]) == 0:
				continue
			if _disk_ok(cols, rows, walk, build, reachable, col, row, cell_radius, cell):
				return true
	return false


static func _disk_ok(
	cols: int,
	rows: int,
	walk: PackedByteArray,
	build: PackedByteArray,
	reachable: PackedByteArray,
	col: int,
	row: int,
	cell_radius: int,
	cell: float
) -> bool:
	var radius_squared := (float(cell_radius) * cell) * (float(cell_radius) * cell)
	for dy in range(-cell_radius, cell_radius + 1):
		for dx in range(-cell_radius, cell_radius + 1):
			var c := col + dx
			var r := row + dy
			if c < 0 or r < 0 or c >= cols or r >= rows:
				return false
			if float(dx * dx + dy * dy) * cell * cell > radius_squared:
				continue
			var index := r * cols + c
			if int(walk[index]) == 0 or int(build[index]) == 0 or int(reachable[index]) == 0:
				return false
	return true


static func _is_self_intersecting(polygon: PackedVector2Array) -> bool:
	var count := polygon.size()
	for i in count:
		var a1 := polygon[i]
		var a2 := polygon[(i + 1) % count]
		for j in range(i + 1, count):
			if j == i or (j + 1) % count == i or j == (i + 1) % count:
				continue
			var b1 := polygon[j]
			var b2 := polygon[(j + 1) % count]
			if Geometry2D.segment_intersects_segment(a1, a2, b1, b2) != null:
				return true
	return false


static func _polygons_overlap(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	if a.size() < 3 or b.size() < 3:
		return false
	for point in a:
		if Geometry2D.is_point_in_polygon(point, b):
			return true
	for point in b:
		if Geometry2D.is_point_in_polygon(point, a):
			return true
	for i in a.size():
		var a1 := a[i]
		var a2 := a[(i + 1) % a.size()]
		for j in b.size():
			if Geometry2D.segment_intersects_segment(a1, a2, b[j], b[(j + 1) % b.size()]) != null:
				return true
	return false

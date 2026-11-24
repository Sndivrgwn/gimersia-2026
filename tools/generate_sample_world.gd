extends SceneTree

## Generator dunia AUTHORED (Mission 13 blok G).
## Jalankan: GODOT --headless --path . -s tools/generate_sample_world.gd
##
## Menulis:
##   res://src/levels/worlds/_template/world.tscn
##   res://src/levels/worlds/sample_island/world.tscn
##
## Semua angka geometri di file ini invented (lihat laporan blok G).

const TEMPLATE_PATH := "res://src/levels/worlds/_template/world.tscn"
const SAMPLE_PATH := "res://src/levels/worlds/sample_island/world.tscn"

const DEF_TWIG: ResourceNodeDefinition = preload("res://src/data/gathering/twig.tres")
const DEF_SMALL_TREE: ResourceNodeDefinition = preload("res://src/data/gathering/small_tree.tres")
const DEF_TREE: ResourceNodeDefinition = preload("res://src/data/gathering/tree.tres")
const DEF_SMALL_ROCK: ResourceNodeDefinition = preload("res://src/data/gathering/small_rock.tres")
const DEF_BIG_ROCK: ResourceNodeDefinition = preload("res://src/data/gathering/big_rock.tres")
const DEF_FIBER_BUSH: ResourceNodeDefinition = preload("res://src/data/gathering/fiber_bush.tres")
const DEF_BERRY_BUSH: ResourceNodeDefinition = preload("res://src/data/gathering/berry_bush.tres")
const DEF_COCONUT_PALM: ResourceNodeDefinition = preload("res://src/data/gathering/coconut_palm.tres")
const DEF_BAMBOO: ResourceNodeDefinition = preload("res://src/data/gathering/bamboo_clump.tres")


func _init() -> void:
	var failures := 0
	if not _save(_build_template(), TEMPLATE_PATH):
		failures += 1
	if not _save(_build_sample(), SAMPLE_PATH):
		failures += 1
	if failures > 0:
		print("BLOCKED: %d scene dunia gagal disimpan/di-pack" % failures)
	quit(1 if failures > 0 else 0)


# --- Template ---------------------------------------------------------------

func _build_template() -> AuthoredWorld:
	var world := _world("Template", 12345)
	world.world_name = "template"
	var outline := _rect(-800.0, -800.0, 800.0, 800.0)
	_zone(world, "IslandOutline", outline, WorldZoneType.Zone.FOREST, -100, true, ZoneArea.BuildRule.DEFAULT, true,
		"Tepi pulau template 1600 x 1600. Ganti polygon ini untuk dunia baru.")
	_zone(world, "Forest", outline, WorldZoneType.Zone.FOREST, -50, true, ZoneArea.BuildRule.DEFAULT, false,
		"Dasar hutan: seluruh pulau.")
	_zone(world, "Camp", _circle(Vector2.ZERO, 300.0, 24), WorldZoneType.Zone.CAMP, 10, true, ZoneArea.BuildRule.DEFAULT, false,
		"Zona camp awal: aman dan bisa dibangun.")
	_marker(world, "PlayerStart", Vector2(0.0, 64.0), "Titik spawn pemain saat scene dimulai.")
	_marker(world, "PlaneWreckage", Vector2(0.0, -185.0), "Badan pesawat yang jatuh: POI bangkai.")
	_marker(world, "EmergencySuitcase", Vector2(-48.0, 40.0), "Koper darurat: POI awal pemain.")
	_marker(world, "SignalBeacon", Vector2(0.0, 700.0), "Signal Beacon: tujuan akhir permainan.")
	_markers(world, "NightSpawns", _ring_points(Vector2.ZERO, 500.0, 700.0, 8, 111), "Titik spawn fauna malam (minimal 8).")
	_markers(world, "WaterAccess", [Vector2(400.0, 300.0)], "Titik akses air untuk mengisi waterskin.")
	_resource_area(world, "TemplateGathering", outline, [
		_entry(DEF_TWIG, 4),
		_entry(DEF_SMALL_ROCK, 3),
		_entry(DEF_FIBER_BUSH, 2),
		_entry(DEF_BERRY_BUSH, 2),
		_entry(DEF_BAMBOO, 2),
	], 70.0, "Sebaran resource contoh: satu entry per kategori wajib, jumlah kecil.")
	world.get_node("Visual").editor_description = "Tempat art dunia (Polygon2D/Sprite2D). Boleh kosong."
	world.get_node("Decor").editor_description = "Tempat dekorasi non-gameplay. Boleh kosong."
	world.get_node("Resources").editor_description = "ResourceArea dan node resource manual."
	return world


# --- Sample island ----------------------------------------------------------

func _build_sample() -> AuthoredWorld:
	var world := _world("Sample Island", 424242)
	world.world_name = "sample_island"
	var outline := _sample_outline()
	var camp := _circle(Vector2.ZERO, 800.0, 48)
	var river := _river_polygon()
	var lake := _circle(Vector2(900.0, -800.0), 350.0, 24)
	var rock := _regular_polygon(Vector2(-700.0, -1150.0), 260.0, 6, 0.4)

	_zone(world, "IslandOutline", outline, WorldZoneType.Zone.FOREST, -100, true, ZoneArea.BuildRule.DEFAULT, true,
		"Tepi pulau sample (±4400 px, 24 titik tidak beraturan).")
	_zone(world, "Forest", outline, WorldZoneType.Zone.FOREST, -50, true, ZoneArea.BuildRule.DEFAULT, false,
		"Hutan: dasar seluruh pulau.")
	_zone(world, "SouthBeach", _rect(-2400.0, 1400.0, 2400.0, 2400.0), WorldZoneType.Zone.SOUTH_BEACH, 0, true, ZoneArea.BuildRule.DEFAULT, false,
		"Pantai selatan: pasir, tidak untuk base.")
	_zone(world, "EastBeach", _rect(1400.0, -1400.0, 2400.0, 1400.0), WorldZoneType.Zone.EAST_BEACH, 1, true, ZoneArea.BuildRule.DEFAULT, false,
		"Pantai timur: pasir, tidak untuk base.")
	_zone(world, "WestCliffs", _rect(-2400.0, -1400.0, -1400.0, 1400.0), WorldZoneType.Zone.WEST_CLIFFS, 2, true, ZoneArea.BuildRule.DEFAULT, false,
		"Tebing barat: batu, tidak untuk base.")
	_zone(world, "Camp", camp, WorldZoneType.Zone.CAMP, 10, true, ZoneArea.BuildRule.DEFAULT, false,
		"Camp awal radius 800 px, 48 titik.")
	_zone(world, "River", river, WorldZoneType.Zone.RIVER, 20, true, ZoneArea.BuildRule.DEFAULT, false,
		"Sungai melengkung: bisa dilewati (lambat) tapi tidak bisa dibangun.")
	_zone(world, "Lake", lake, WorldZoneType.Zone.RIVER, 50, false, ZoneArea.BuildRule.FORBID, false,
		"Danau kecil: penghalang solid, tidak bisa dilewati.")
	_zone(world, "RockFormation", rock, WorldZoneType.Zone.FOREST, 50, false, ZoneArea.BuildRule.FORBID, false,
		"Formasi batu: penghalang solid di dalam hutan.")

	_marker(world, "PlayerStart", Vector2(0.0, 64.0), "Titik spawn pemain sample.")
	_marker(world, "PlaneWreckage", Vector2(0.0, -185.0), "Bangkai pesawat sample.")
	_marker(world, "EmergencySuitcase", Vector2(-48.0, 40.0), "Koper darurat sample.")
	_marker(world, "SignalBeacon", Vector2(0.0, 2100.0), "Signal Beacon di pantai selatan.")
	_markers(world, "NightSpawns", _night_spawns(outline, lake, rock), "16 titik spawn fauna malam di hutan, >= 1100 px dari PlayerStart.")
	_markers(world, "WaterAccess", _river_points(6), "6 titik akses air di sepanjang sungai.")

	_resource_area(world, "CampGathering", camp, [
		_entry(DEF_TWIG, 10),
		_entry(DEF_SMALL_ROCK, 8),
		_entry(DEF_FIBER_BUSH, 5),
		_entry(DEF_BERRY_BUSH, 4),
		_entry(DEF_SMALL_TREE, 6),
	], 70.0, "Starter camp: 33 node, mirip hitungan FORMULA.")
	_resource_area(world, "SouthBeachCoconuts", _rect(-2400.0, 1400.0, 2400.0, 2400.0), [
		_entry(DEF_COCONUT_PALM, 12),
	], 70.0, "12 kelapa di pantai selatan.")
	_resource_area(world, "WestCliffRocks", _rect(-2400.0, -1400.0, -1400.0, 1400.0), [
		_entry(DEF_SMALL_ROCK, 14),
		_entry(DEF_BIG_ROCK, 8),
	], 70.0, "22 batu di tebing barat.")
	_resource_area(world, "RiverBamboo", river, [
		_entry(DEF_BAMBOO, 14),
	], 70.0, "14 bambu di sepanjang sungai.")
	_resource_area(world, "ForestGathering", outline, [
		_entry(DEF_TREE, 30),
		_entry(DEF_FIBER_BUSH, 24),
		_entry(DEF_BERRY_BUSH, 18),
	], 70.0, "72 node hutan: pohon, fiber, berry.")

	world.get_node("Visual").editor_description = "Tempat art dunia sample. Kosong: warna zona yang tampil di editor."
	world.get_node("Decor").editor_description = "Dekorasi non-gameplay (kosong di sample)."
	world.get_node("Resources").editor_description = "ResourceArea sample; node manual boleh ditambah di sini."
	return world


# --- Scene helpers ----------------------------------------------------------

func _world(world_name: String, seed_value: int) -> AuthoredWorld:
	var world := AuthoredWorld.new()
	world.name = world_name
	world.world_name = world_name.to_lower()
	world.layout_seed = seed_value
	world.editor_description = "Akar dunia AUTHORED. Anak wajib: Visual, Zones, Markers, Resources, Decor."
	var visual := Node2D.new()
	visual.name = "Visual"
	world.add_child(visual)
	var zones := Node2D.new()
	zones.name = "Zones"
	world.add_child(zones)
	var markers := Node2D.new()
	markers.name = "Markers"
	world.add_child(markers)
	var resources := Node2D.new()
	resources.name = "Resources"
	world.add_child(resources)
	var decor := Node2D.new()
	decor.name = "Decor"
	world.add_child(decor)
	return world


func _marker(world: AuthoredWorld, marker_name: String, position_value: Vector2, description: String) -> Marker2D:
	var markers := world.get_node("Markers")
	var marker := Marker2D.new()
	marker.name = marker_name
	marker.position = position_value
	marker.editor_description = description
	markers.add_child(marker)
	return marker


func _markers(world: AuthoredWorld, container_name: String, points: Array, description: String) -> Node2D:
	var markers := world.get_node("Markers")
	var container := Node2D.new()
	container.name = container_name
	container.editor_description = description
	markers.add_child(container)
	var index := 1
	for point in points:
		var marker := Marker2D.new()
		marker.name = "%s%d" % [container_name, index]
		marker.position = point
		marker.editor_description = "%s #%d." % [description, index]
		container.add_child(marker)
		index += 1
	return container


func _zone(
	world: AuthoredWorld,
	node_name: String,
	polygon: PackedVector2Array,
	zone: int,
	priority: int,
	walkable: bool,
	build_rule: int,
	is_outline: bool,
	description: String
) -> ZoneArea:
	var area := ZoneArea.new()
	area.name = node_name
	area.polygon = polygon
	area.zone = zone
	area.priority = priority
	area.walkable = walkable
	area.build_rule = build_rule
	area.is_island_outline = is_outline
	area.editor_description = description
	var tint := WorldZoneType.color(zone)
	tint.a = 0.15 if is_outline else 0.35
	area.color = tint
	world.get_node("Zones").add_child(area)
	return area


func _resource_area(
	world: AuthoredWorld,
	node_name: String,
	polygon: PackedVector2Array,
	entries: Array,
	spacing: float,
	description: String
) -> ResourceArea:
	var area := ResourceArea.new()
	area.name = node_name
	area.polygon = polygon
	area.min_spacing = spacing
	area.editor_description = description
	for entry in entries:
		area.entries.append(entry)
	area.color = Color(0.9, 0.55, 0.2, 0.3)
	world.get_node("Resources").add_child(area)
	return area


func _entry(definition: ResourceNodeDefinition, count: int) -> ResourceSpawnEntry:
	var entry := ResourceSpawnEntry.new()
	entry.definition = definition
	entry.count = count
	return entry


func _save(world: AuthoredWorld, path: String) -> bool:
	_own_all(world, world)
	var packed := PackedScene.new()
	var error := packed.pack(world)
	if error != OK:
		push_error("generate_sample_world: pack gagal untuk %s (error %d)" % [path, error])
		world.free()
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	error = ResourceSaver.save(packed, path)
	if error != OK:
		push_error("generate_sample_world: simpan gagal untuk %s (error %d)" % [path, error])
		world.free()
		return false
	print("generate_sample_world: %s (%d node)" % [path, _count_nodes(world)])
	world.free()
	return true


## Wajib: owner setiap turunan = root, kalau tidak PackedScene.pack membuangnya.
func _own_all(root: Node, node: Node) -> void:
	for child in node.get_children():
		child.owner = root
		_own_all(root, child)


func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total


# --- Geometry ---------------------------------------------------------------

func _rect(x_from: float, y_from: float, x_to: float, y_to: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(x_from, y_from), Vector2(x_to, y_from), Vector2(x_to, y_to), Vector2(x_from, y_to),
	])


func _circle(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _regular_polygon(center: Vector2, radius: float, sides: int, angle_offset: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in sides:
		var angle := angle_offset + TAU * float(index) / float(sides)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _sample_outline() -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260113
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		var radius := rng.randf_range(2150.0, 2350.0)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


## Sungai melengkung: centerline x = -950 + 160*sin(y/450), lebar total 180 px.
func _river_center_x(y: float) -> float:
	return -950.0 + 160.0 * sin(y / 450.0)


func _river_points(count: int) -> Array:
	var points: Array = []
	var half_width := 90.0
	for index in count:
		var t := (float(index) + 0.5) / float(count)
		var y := lerpf(-1400.0, 1400.0, t)
		points.append(Vector2(_river_center_x(y) + half_width, y))
	return points


func _river_polygon() -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var steps := 24
	var half_width := 90.0
	for index in steps + 1:
		var y := lerpf(-1400.0, 1400.0, float(index) / float(steps))
		var center_x := _river_center_x(y)
		left.append(Vector2(center_x - half_width, y))
		right.append(Vector2(center_x + half_width, y))
	right.reverse()
	var points := PackedVector2Array()
	points.append_array(left)
	points.append_array(right)
	return points


func _ring_points(center: Vector2, min_radius: float, max_radius: float, count: int, seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var points: Array = []
	for index in count:
		var angle := TAU * float(index) / float(count) + rng.randf_range(-0.12, 0.12)
		var radius := rng.randf_range(min_radius, max_radius)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


## 16 titik hutan: >= 1100 px dari PlayerStart, di dalam outline, bukan di danau/batu.
func _night_spawns(outline: PackedVector2Array, lake: PackedVector2Array, rock: PackedVector2Array) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 778899
	var origin := Vector2(0.0, 64.0)
	var points: Array = []
	var attempts := 0
	while points.size() < 16 and attempts < 4000:
		attempts += 1
		var angle := rng.randf_range(0.0, TAU)
		var radius := rng.randf_range(1200.0, 1950.0)
		var point := origin + Vector2(cos(angle), sin(angle)) * radius
		if not Geometry2D.is_point_in_polygon(point, outline):
			continue
		if Geometry2D.is_point_in_polygon(point, lake) or Geometry2D.is_point_in_polygon(point, rock):
			continue
		points.append(point)
	return points

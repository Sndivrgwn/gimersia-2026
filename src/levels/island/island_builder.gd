class_name IslandBuilder
extends Node2D

## Membangun isi pulau secara deterministik dari `IslandLayoutConfig`.
##
## Dua tahap: `plan()` menghasilkan daftar entri (posisi + definisi + zona) tanpa
## menyentuh SceneTree, lalu `build()` men-spawn ResourceNode/Marker2D dari
## daftar itu. Tes memakai `plan()` supaya bisa memeriksa zona, jarak, dan
## keep-out tanpa scene.
##
## Semua node ditempatkan dengan rejection sampling: posisi harus berada di
## zona tujuannya sendiri, berjarak >= `min_spacing` dari node lain, dan di luar
## radius keep-out spawn/wreckage/koper/beacon.

const LAYOUT_DEFAULT: IslandLayoutConfig = preload("res://src/data/configs/island_layout.tres")
const RESOURCE_SCENE: PackedScene = preload("res://src/entities/props/resource_node/resource_node.tscn")

const DEF_TWIG := preload("res://src/data/gathering/twig.tres")
const DEF_SMALL_TREE: ResourceNodeDefinition = preload("res://src/data/gathering/small_tree.tres")
const DEF_TREE := preload("res://src/data/gathering/tree.tres")
const DEF_SMALL_ROCK := preload("res://src/data/gathering/small_rock.tres")
const DEF_BIG_ROCK := preload("res://src/data/gathering/big_rock.tres")
const DEF_FIBER_BUSH := preload("res://src/data/gathering/fiber_bush.tres")
const DEF_BERRY_BUSH := preload("res://src/data/gathering/berry_bush.tres")
const DEF_COCONUT_PALM := preload("res://src/data/gathering/coconut_palm.tres")
const DEF_BAMBOO := preload("res://src/data/gathering/bamboo_clump.tres")

const KIND_RESOURCE := &"resource"
const KIND_MARKER := &"marker"
const NIGHT_SPAWN_GROUP := &"night_spawn_point"

## Titik yang wajib bebas dari node resource.
const KEEP_OUT_POINTS: Array[Vector2] = [
	Vector2(0.0, 64.0),    # spawn pemain
	Vector2(0.0, -185.0),  # PlaneWreckage
	Vector2(-48.0, 40.0),  # Emergency Suitcase
]

@export var layout: IslandLayoutConfig = LAYOUT_DEFAULT
## Saat false, scene harus memanggil `build()` sendiri (dipakai tes).
@export var auto_build: bool = true
@export var resource_scene: PackedScene = RESOURCE_SCENE
## Opsional; ResourceNode memakai autoload DayNightManager bila kosong.
@export var clock: Node

var _rng := RandomNumberGenerator.new()
var _placed: Array[Vector2] = []


func _ready() -> void:
	if auto_build:
		build()


## Spawn semua entri ke `parent` (default: diri sendiri). Mengembalikan plan.
func build(parent: Node = null) -> Array[Dictionary]:
	var target: Node = self if parent == null else parent
	var entries := plan()
	var marker_index := 0

	for entry in entries:
		if entry["kind"] == KIND_MARKER:
			marker_index += 1
			var marker := Marker2D.new()
			marker.name = "NightSpawn%d" % marker_index
			marker.position = entry["position"]
			marker.add_to_group(NIGHT_SPAWN_GROUP)
			target.add_child(marker)
			continue

		var node := resource_scene.instantiate() as ResourceNode
		if node == null:
			push_error("IslandBuilder: resource_scene bukan ResourceNode")
			continue
		node.definition = entry["definition"]
		node.position = entry["position"]
		node.last_respawn_day = int(entry["last_respawn_day"])
		if clock != null:
			node.clock = clock
		target.add_child(node)

	return entries


## Rencana layout tanpa menyentuh SceneTree. Deterministik untuk layout yang sama.
func plan() -> Array[Dictionary]:
	_rng = RandomNumberGenerator.new()
	_rng.seed = layout.layout_seed
	_placed.clear()

	var entries: Array[Dictionary] = []
	var starters := layout.camp_starters_last_respawn_day

	_plan_zone(entries, IslandZones.Zone.CAMP, DEF_TWIG, layout.camp_twig, starters, true)
	_plan_zone(entries, IslandZones.Zone.CAMP, DEF_SMALL_ROCK, layout.camp_small_rock, starters, true)
	_plan_zone(entries, IslandZones.Zone.CAMP, DEF_FIBER_BUSH, layout.camp_fiber_bush, starters, true)
	_plan_zone(entries, IslandZones.Zone.CAMP, DEF_BERRY_BUSH, layout.camp_berry_bush, starters, true)
	_plan_zone(entries, IslandZones.Zone.CAMP, DEF_SMALL_TREE, layout.camp_small_tree, starters, true)

	_plan_zone(entries, IslandZones.Zone.SOUTH_BEACH, DEF_COCONUT_PALM, layout.south_coconut_palm, 0, false)
	_plan_zone(entries, IslandZones.Zone.WEST_CLIFFS, DEF_SMALL_ROCK, layout.west_small_rock, 0, false)
	_plan_zone(entries, IslandZones.Zone.WEST_CLIFFS, DEF_BIG_ROCK, layout.west_big_rock, 0, false)
	_plan_zone(entries, IslandZones.Zone.RIVER, DEF_BAMBOO, layout.river_bamboo, 0, false)
	_plan_zone(entries, IslandZones.Zone.FOREST, DEF_TREE, layout.forest_tree, 0, false)
	_plan_zone(entries, IslandZones.Zone.FOREST, DEF_FIBER_BUSH, layout.forest_fiber_bush, 0, false)
	_plan_zone(entries, IslandZones.Zone.FOREST, DEF_BERRY_BUSH, layout.forest_berry_bush, 0, false)

	_plan_markers(entries, layout.night_spawn_markers)
	return entries


func _plan_zone(
	entries: Array[Dictionary],
	zone: int,
	definition: ResourceNodeDefinition,
	count: int,
	last_respawn_day: int,
	camp_ring: bool
) -> void:
	for index in count:
		var point := _find_point(zone, camp_ring)
		if point == Vector2.INF:
			push_error("IslandBuilder: gagal menempatkan %s di zona %d" % [definition.id, zone])
			continue
		_placed.append(point)
		entries.append({
			"kind": KIND_RESOURCE,
			"definition": definition,
			"position": point,
			"zone": zone,
			"last_respawn_day": last_respawn_day,
		})


func _plan_markers(entries: Array[Dictionary], count: int) -> void:
	var limit := layout.half_size - layout.coast_margin
	for index in count:
		var chosen := Vector2.INF
		for attempt in layout.max_attempts:
			var point := Vector2(
				_rng.randf_range(-limit, limit),
				_rng.randf_range(-limit, limit)
			)
			if IslandZones.zone_at(point) != IslandZones.Zone.FOREST:
				continue
			if point.length() < layout.markers_min_distance:
				continue
			if not _is_clear(point):
				continue
			chosen = point
			break
		if chosen == Vector2.INF:
			push_error("IslandBuilder: gagal menempatkan night spawn marker")
			continue
		_placed.append(chosen)
		entries.append({
			"kind": KIND_MARKER,
			"position": chosen,
			"zone": IslandZones.Zone.FOREST,
		})


func _find_point(zone: int, camp_ring: bool) -> Vector2:
	var limit := layout.half_size - layout.coast_margin
	for attempt in layout.max_attempts:
		var point: Vector2
		if camp_ring:
			var angle := _rng.randf() * TAU
			var radius := _rng.randf_range(layout.camp_ring_min, layout.camp_ring_max)
			point = Vector2(cos(angle), sin(angle)) * radius
		elif zone == IslandZones.Zone.RIVER:
			point = Vector2(
				_rng.randf_range(IslandZones.RIVER_MIN_X, IslandZones.RIVER_MAX_X),
				_rng.randf_range(-limit, limit)
			)
		else:
			point = Vector2(
				_rng.randf_range(-limit, limit),
				_rng.randf_range(-limit, limit)
			)
		if IslandZones.zone_at(point) != zone:
			continue
		if not _is_clear(point):
			continue
		return point
	return Vector2.INF


func _is_clear(point: Vector2) -> bool:
	for keep_out in KEEP_OUT_POINTS:
		if point.distance_to(keep_out) < layout.keep_out_radius:
			return false
	if point.distance_to(IslandZones.BEACON_POSITION) < layout.beacon_keep_out:
		return false
	for other in _placed:
		if point.distance_to(other) < layout.min_spacing:
			return false
	return true

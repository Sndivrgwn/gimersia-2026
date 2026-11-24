class_name WorldController
extends Node

## Menyiapkan sumber dunia (Mission 13) SEBELUM IslandBuilder membangun isi
## pulau, jadi node ini wajib berada sebelum IslandBuilder di urutan tree.
##
## FORMULA: pulau rumus lama, tanpa perubahan visual/collision.
## AUTHORED: memuat AuthoredWorld dari config, menyembunyikan dunia rumus, lalu
## menaruh POI, marker spawn malam, dan RiverEdge dari data AUTHORED.

signal world_ready(source_id: StringName)

const DEFAULT_CONFIG: WorldConfig = preload("res://src/data/configs/world/world_config.tres")
const RIVER_EDGE_SCENE: PackedScene = preload("res://src/entities/props/river_edge/river_edge.tscn")
## Nama node POI yang dikenal; nama scene lama dipertahankan supaya path node
## island.tscn/island.gd tidak berubah.
const WRECKAGE_NAMES: Array[NodePath] = [^"PlaneWreckage", ^"Wreckage"]
const SUITCASE_NAMES: Array[NodePath] = [^"EmergencySuitcase", ^"Suitcase"]
const BEACON_NAMES: Array[NodePath] = [^"SignalBeacon", ^"Beacon"]
const PLAYER_NAME := ^"Player"
const FORMULA_GROUP := &"formula_world"
const FORMULA_ROOTS: Array[StringName] = [&"Ground", &"Coastline", &"RiverEdges"]
const NIGHT_SPAWN_GROUP := &"night_spawn_point"
const WORLD_NODE_NAME := &"World"

@export var config: WorldConfig = DEFAULT_CONFIG

var _applied_source: StringName = &""
var _authored_root: AuthoredWorld


func _ready() -> void:
	_start()


## Titik masuk ulang untuk tes (menukar config lalu menyiapkan sumber baru).
func apply_config(new_config: WorldConfig) -> void:
	config = new_config
	_start()


func get_source_id() -> StringName:
	return _applied_source


func get_authored_root() -> AuthoredWorld:
	return _authored_root


func _start() -> void:
	var resolved := config if config != null else WorldConfig.new()
	if resolved.mode == WorldConfig.Mode.AUTHORED and _setup_authored(resolved):
		return
	WorldRules.set_source(FormulaWorld.new())
	apply_pois()
	_applied_source = WorldRules.id()
	world_ready.emit(_applied_source)


func _exit_tree() -> void:
	WorldRules.reset()
	_applied_source = &""
	_authored_root = null


# --- AUTHORED ---------------------------------------------------------------

func _setup_authored(resolved: WorldConfig) -> bool:
	var packed := load(resolved.authored_scene_path) as PackedScene
	if packed == null:
		push_error("WorldController: scene AUTHORED tidak bisa dimuat: %s" % resolved.authored_scene_path)
		return _authored_failed(resolved)
	var instance := packed.instantiate()
	if not (instance is AuthoredWorld):
		push_error("WorldController: root scene AUTHORED harus AuthoredWorld: %s" % resolved.authored_scene_path)
		if instance != null:
			instance.free()
		return _authored_failed(resolved)
	var authored := instance as AuthoredWorld
	var warnings: PackedStringArray = authored.configuration_warnings()
	if not warnings.is_empty():
		push_error("WorldController: kontrak AUTHORED tidak valid (%s): %s" % [
			resolved.authored_scene_path, ", ".join(warnings)
		])
		authored.free()
		return _authored_failed(resolved)

	_authored_root = authored
	var holder := Node2D.new()
	holder.name = String(WORLD_NODE_NAME)
	add_child(holder)
	holder.add_child(authored)

	WorldRules.set_source(authored.make_source(resolved.cell_size))
	authored.build_collision(holder)
	_disable_formula_world()
	apply_pois()
	_apply_player_start()
	_spawn_night_markers(holder)
	_spawn_river_edges(holder)
	_applied_source = WorldRules.id()
	world_ready.emit(_applied_source)
	return true


func _authored_failed(resolved: WorldConfig) -> bool:
	if resolved.fallback_to_formula:
		push_warning("WorldController: dunia AUTHORED gagal; memakai FORMULA.")
		return false
	WorldRules.set_source(WorldSource.new())
	_applied_source = &"none"
	world_ready.emit(_applied_source)
	return true


## Sembunyikan + matikan collision dunia rumus (hanya jalur AUTHORED).
func _disable_formula_world() -> void:
	var root := get_parent()
	if root == null:
		return
	for node_name in FORMULA_ROOTS:
		var node := root.get_node_or_null(NodePath(String(node_name)))
		if node != null:
			_disable_formula_node(node)


func _disable_formula_node(node: Node) -> void:
	node.add_to_group(FORMULA_GROUP)
	if node is CanvasItem:
		(node as CanvasItem).visible = false
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CollisionObject2D:
		(node as CollisionObject2D).collision_layer = 0
		(node as CollisionObject2D).collision_mask = 0
	for child in node.get_children():
		_disable_formula_node(child)


func _apply_player_start() -> void:
	var start := WorldRules.poi(WorldSource.POI_PLAYER_START)
	if start == Vector2.INF:
		return
	var root := get_parent()
	if root == null:
		return
	var player := root.get_node_or_null(PLAYER_NAME)
	if player is Node2D:
		(player as Node2D).global_position = start


func _spawn_night_markers(holder: Node2D) -> void:
	var index := 1
	for point in WorldRules.night_spawn_points():
		var marker := Marker2D.new()
		marker.name = "NightSpawn%d" % index
		marker.position = point
		marker.add_to_group(NIGHT_SPAWN_GROUP)
		holder.add_child(marker)
		index += 1


func _spawn_river_edges(holder: Node2D) -> void:
	var index := 1
	for point in WorldRules.water_access_points():
		var edge := RIVER_EDGE_SCENE.instantiate() as Node2D
		if edge == null:
			continue
		edge.name = "WaterEdge%d" % index
		edge.position = point
		holder.add_child(edge)
		index += 1


# --- POI --------------------------------------------------------------------

## Pindahkan node POI hanya bila posisinya berbeda dari nilai provider. Di mode
## FORMULA ini no-op karena scene sudah memakai posisi yang sama.
func apply_pois() -> void:
	_apply_poi(WRECKAGE_NAMES, WorldSource.POI_PLANE_WRECKAGE)
	_apply_poi(SUITCASE_NAMES, WorldSource.POI_EMERGENCY_SUITCASE)
	_apply_poi(BEACON_NAMES, WorldSource.POI_SIGNAL_BEACON)


func _apply_poi(names: Array[NodePath], poi_name: StringName) -> void:
	var node := _resolve(names)
	if node == null:
		return
	var target := WorldRules.poi(poi_name)
	if target == Vector2.INF:
		return
	if node.position.is_equal_approx(target):
		return
	node.position = target


func _resolve(names: Array[NodePath]) -> Node2D:
	for candidate in names:
		var own := get_node_or_null(candidate) as Node2D
		if own != null:
			return own
		var parent := get_parent()
		if parent != null:
			var sibling := parent.get_node_or_null(candidate) as Node2D
			if sibling != null:
				return sibling
	return null

@tool
class_name AuthoredWorld
extends Node2D

## Kontrak scene dunia AUTHORED (Mission 13). Node akar yang dibaca WorldController:
## anak wajib Visual/Zones/Markers/Resources/Decor, marker POI, dan tepat satu
## ZoneArea outline. Aman di editor: tidak menyentuh autoload atau IslandZones.

const CHILD_VISUAL := &"Visual"
const CHILD_ZONES := &"Zones"
const CHILD_MARKERS := &"Markers"
const CHILD_RESOURCES := &"Resources"
const CHILD_DECOR := &"Decor"
const CHILD_NAMES: Array[StringName] = [CHILD_VISUAL, CHILD_ZONES, CHILD_MARKERS, CHILD_RESOURCES, CHILD_DECOR]

const MARKER_PLAYER_START := &"PlayerStart"
const MARKER_PLANE_WRECKAGE := &"PlaneWreckage"
const MARKER_EMERGENCY_SUITCASE := &"EmergencySuitcase"
const MARKER_SIGNAL_BEACON := &"SignalBeacon"
const NIGHT_SPAWNS := &"NightSpawns"
const WATER_ACCESS := &"WaterAccess"
const REQUIRED_MARKERS: Array[StringName] = [
	MARKER_PLAYER_START, MARKER_PLANE_WRECKAGE, MARKER_EMERGENCY_SUITCASE, MARKER_SIGNAL_BEACON,
]

## Nama marker scene -> nama POI WorldSource (konstanta ditulis literal supaya
## skrip @tool ini tidak perlu memuat skrip non-tool).
const POI_BY_MARKER := {
	MARKER_PLAYER_START: &"player_start",
	MARKER_PLANE_WRECKAGE: &"plane_wreckage",
	MARKER_EMERGENCY_SUITCASE: &"emergency_suitcase",
	MARKER_SIGNAL_BEACON: &"signal_beacon",
}

## Sama dengan Coastline di island.tscn (default Godot layer/mask = 1).
const COLLISION_LAYER := 1
const COLLISION_MASK := 1

enum ResourceMode { AREAS_AND_MANUAL, AREAS_ONLY, MANUAL_ONLY }

@export var world_name: String = ""
@export var layout_seed: int = 12345
@export var resource_mode: ResourceMode = ResourceMode.AREAS_AND_MANUAL
## Ringkasan satu baris hasil validasi terakhir (diisi tombol Validasi dunia).
@export_storage var last_validation_summary: String = ""
@export_tool_button("Validasi dunia") var validate_world: Callable = _validate_world


func _ready() -> void:
	add_to_group(&"authored_world")


func _validate_world() -> void:
	var config := WorldConfig.new()
	var source := make_source(config.cell_size)
	var results := WorldValidator.validate(source, config)
	var report := WorldValidator.format_report(results)
	print(report)
	var errors := 0
	var warnings := 0
	for entry in results:
		if String(entry["severity"]) == "ERROR":
			errors += 1
		else:
			warnings += 1
	last_validation_summary = "%s: %d ERROR, %d WARN" % [world_name, errors, warnings]


## Akses publik untuk WorldController/tes (mesin memakai versi underscore).
func configuration_warnings() -> PackedStringArray:
	return _get_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	for child_name in CHILD_NAMES:
		if get_node_or_null(NodePath(String(child_name))) == null:
			warnings.append("Anak wajib '%s' belum ada." % String(child_name))
	var markers := get_node_or_null(NodePath(String(CHILD_MARKERS)))
	if markers != null:
		for marker_name in REQUIRED_MARKERS:
			if markers.get_node_or_null(NodePath(String(marker_name))) == null:
				warnings.append("Marker '%s' belum ada di %s." % [String(marker_name), String(CHILD_MARKERS)])
	var outlines := 0
	for area in zone_areas():
		if area.is_island_outline:
			outlines += 1
	if outlines != 1:
		warnings.append("Butuh tepat satu ZoneArea outline (sekarang %d)." % outlines)
	var outline := outline_area()
	if outline != null and outline.polygon.size() < 3:
		warnings.append("Polygon outline butuh minimal 3 titik.")
	# Laporkan kode ERROR yang tidak butuh flood fill (W001-W006, W013, W014).
	if outline != null and outline.polygon.size() >= 3 and is_inside_tree():
		var source := make_source(WorldConfig.new().cell_size)
		for entry in WorldValidator.static_checks(source, WorldConfig.new()):
			var code := String(entry["code"])
			if String(entry["severity"]) == "ERROR" and not warnings.has("%s: %s" % [code, String(entry["message"])]):
				warnings.append("%s: %s" % [code, String(entry["message"])])
	return warnings


## Sumber dunia dari isi scene (koordinat global).
func make_source(cell_size: float = 32.0) -> AuthoredWorldSource:
	var source := AuthoredWorldSource.new()
	source.setup({
		"outline": outline_points(),
		"zone_areas": _zone_area_data(),
		"markers": _marker_positions(),
		"manual_nodes": _manual_nodes(),
		"manual_resources": _manual_resources(),
		"resource_areas": _resource_area_data(),
		"night_points": _marker_list(NIGHT_SPAWNS),
		"water_points": _marker_list(WATER_ACCESS),
		"cell_size": cell_size,
	})
	return source


## Collision dunia: tepi outline (segments) + polygon non-walkable (solid).
func build_collision(parent: Node) -> void:
	if parent == null:
		return
	var outline := outline_points()
	if outline.size() >= 3:
		var coast := StaticBody2D.new()
		coast.name = "CoastCollision"
		coast.collision_layer = COLLISION_LAYER
		coast.collision_mask = COLLISION_MASK
		var shape := CollisionPolygon2D.new()
		shape.name = "Outline"
		shape.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		shape.polygon = _to_parent_space(outline, parent)
		coast.add_child(shape)
		parent.add_child(coast)
	var blocked_shapes := 0
	for area in zone_areas():
		if area.walkable:
			continue
		var polygon := area.global_polygon()
		if polygon.size() < 3:
			continue
		if blocked_shapes == 0:
			var body := StaticBody2D.new()
			body.name = "BlockedCollision"
			body.collision_layer = COLLISION_LAYER
			body.collision_mask = COLLISION_MASK
			parent.add_child(body)
		var body_node := parent.get_node_or_null(NodePath("BlockedCollision")) as StaticBody2D
		if body_node == null:
			break
		var solid := CollisionPolygon2D.new()
		solid.name = "Blocked%d" % blocked_shapes
		solid.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		solid.polygon = _to_parent_space(polygon, parent)
		body_node.add_child(solid)
		blocked_shapes += 1


func zone_areas() -> Array[ZoneArea]:
	var result: Array[ZoneArea] = []
	var zones := get_node_or_null(NodePath(String(CHILD_ZONES)))
	if zones == null:
		return result
	for child in zones.get_children():
		if child is ZoneArea:
			result.append(child as ZoneArea)
	return result


func resource_areas() -> Array[ResourceArea]:
	var result: Array[ResourceArea] = []
	var resources := get_node_or_null(NodePath(String(CHILD_RESOURCES)))
	if resources == null:
		return result
	for child in resources.get_children():
		if child is ResourceArea:
			result.append(child as ResourceArea)
	return result


func outline_area() -> ZoneArea:
	for area in zone_areas():
		if area.is_island_outline:
			return area
	return null


func outline_points() -> PackedVector2Array:
	var area := outline_area()
	if area == null:
		return PackedVector2Array()
	return area.global_polygon()


func marker_position(marker_name: StringName) -> Vector2:
	var markers := get_node_or_null(NodePath(String(CHILD_MARKERS)))
	if markers == null:
		return Vector2.INF
	var marker := markers.get_node_or_null(NodePath(String(marker_name))) as Node2D
	if marker == null:
		return Vector2.INF
	return marker.global_position


func _zone_area_data() -> Array:
	var result: Array = []
	var zones := get_node_or_null(NodePath(String(CHILD_ZONES)))
	if zones == null:
		return result
	var children := zones.get_children()
	for index in children.size():
		var child := children[index]
		if child is ZoneArea:
			var area := child as ZoneArea
			result.append({
				"name": String(area.name),
				"polygon": area.global_polygon(),
				"zone": int(area.zone),
				"priority": area.priority,
				"order": index,
				"walkable": area.walkable,
				"build_rule": int(area.build_rule),
				"is_outline": area.is_island_outline,
			})
	return result


func _resource_area_data() -> Array:
	var result: Array = []
	if resource_mode == ResourceMode.MANUAL_ONLY:
		return result
	for area in resource_areas():
		result.append({
			"name": String(area.name),
			"polygon": area.global_polygon(),
			"entries": area.entries,
			"min_spacing": area.min_spacing,
			"enabled": area.enabled,
		})
	return result


func _marker_positions() -> Dictionary:
	var result := {}
	var markers := get_node_or_null(NodePath(String(CHILD_MARKERS)))
	if markers == null:
		return result
	for marker_name in REQUIRED_MARKERS:
		var point := marker_position(marker_name)
		if point == Vector2.INF:
			continue
		result[POI_BY_MARKER[marker_name]] = point
	return result


## Marker2D di dalam container (NightSpawns / WaterAccess), koordinat global.
func _marker_list(container_name: StringName) -> PackedVector2Array:
	var points := PackedVector2Array()
	var markers := get_node_or_null(NodePath(String(CHILD_MARKERS)))
	if markers == null:
		return points
	var container := markers.get_node_or_null(NodePath(String(container_name)))
	if container == null:
		return points
	for child in container.get_children():
		if child is Marker2D:
			points.append((child as Marker2D).global_position)
	return points


func _manual_nodes() -> Array[Vector2]:
	var points: Array[Vector2] = []
	if resource_mode == ResourceMode.AREAS_ONLY:
		return points
	var resources := get_node_or_null(NodePath(String(CHILD_RESOURCES)))
	if resources == null:
		return points
	for child in resources.get_children():
		if child is Node2D:
			points.append((child as Node2D).global_position)
	return points


## ResourceNode manual di dalam Resources (dibaca lewat get() supaya skrip
## @tool ini tidak perlu memuat kelas ResourceNode).
func _manual_resources() -> Array:
	var result: Array = []
	if resource_mode == ResourceMode.AREAS_ONLY:
		return result
	var resources := get_node_or_null(NodePath(String(CHILD_RESOURCES)))
	if resources == null:
		return result
	for child in resources.get_children():
		if not (child is Node2D):
			continue
		var definition = child.get("definition")
		if definition == null:
			continue
		var definition_id: StringName = &""
		var raw_id = definition.get("id")
		if raw_id != null:
			definition_id = raw_id
		result.append({
			"definition": definition_id,
			"position": (child as Node2D).global_position,
		})
	return result


func _to_parent_space(polygon: PackedVector2Array, parent: Node) -> PackedVector2Array:
	if not (parent is Node2D):
		return polygon
	var owner_2d := parent as Node2D
	var local := PackedVector2Array()
	for point in polygon:
		local.append(owner_2d.to_local(point))
	return local

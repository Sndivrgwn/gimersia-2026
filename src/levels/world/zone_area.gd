@tool
class_name ZoneArea
extends Polygon2D

## Wilayah zona dunia AUTHORED. Polygon ditulis dalam koordinat node ini; sumber
## dunia memakai koordinat global. Editor-only: mewarnai area + label zona, lalu
## disembunyikan saat runtime (grid yang jadi sumber kebenaran).

const GROUP := &"zone_area"
const LABEL_NAME := &"ZoneLabel"

enum BuildRule { DEFAULT, ALLOW, FORBID }

## Zona yang dipaksakan area ini ke sel-sel di dalamnya.
@export var zone: WorldZoneType.Zone = WorldZoneType.Zone.FOREST:
	set(value):
		zone = value
		_refresh_editor_style()
## Prioritas lebih tinggi menang; seri: sibling yang lebih akhir menang.
@export var priority: int = 0
## False = penghalang solid (tidak bisa dilewati, tidak bisa dibangun).
@export var walkable: bool = true
## DEFAULT mengikuti WorldZoneType.default_buildable(zone).
@export var build_rule: BuildRule = BuildRule.DEFAULT
## Tepat satu area per dunia: tepi pulau yang bisa dimainkan.
@export var is_island_outline: bool = false:
	set(value):
		is_island_outline = value
		_refresh_editor_style()


func _ready() -> void:
	add_to_group(GROUP)
	if Engine.is_editor_hint():
		_refresh_editor_style()
	else:
		visible = false


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if polygon.size() < 3:
		warnings.append("ZoneArea butuh minimal 3 titik polygon.")
	return warnings


## Polygon dalam koordinat global (polygon lokal + transform node).
func global_polygon() -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in polygon:
		points.append(global_transform * point)
	return points


func _refresh_editor_style() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	var tint := WorldZoneType.color(zone)
	tint.a = 0.15 if is_island_outline else 0.35
	color = tint
	var label := get_node_or_null(NodePath(String(LABEL_NAME))) as Label
	if label == null:
		label = Label.new()
		label.name = LABEL_NAME
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
	label.text = WorldZoneType.label_id(zone)
	label.position = _centroid() + Vector2(6.0, -10.0)
	label.modulate = Color(1.0, 1.0, 1.0, 0.9)


func _centroid() -> Vector2:
	if polygon.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for point in polygon:
		sum += point
	return sum / float(polygon.size())

@tool
class_name ResourceArea
extends Polygon2D

## Wilayah sebar resource dunia AUTHORED. Hanya editor yang menampilkannya;
## AuthoredWorldSource membaca entries + min_spacing saat menyusun plan.

const GROUP := &"resource_area"

@export var entries: Array[ResourceSpawnEntry] = []
## Jarak minimum antar node hasil sebar di area ini.
@export var min_spacing: float = 70.0
@export var enabled: bool = true


func _ready() -> void:
	add_to_group(GROUP)
	if Engine.is_editor_hint():
		color = Color(0.9, 0.55, 0.2, 0.3)
	else:
		visible = false


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if polygon.size() < 3:
		warnings.append("ResourceArea butuh minimal 3 titik polygon.")
	var usable := 0
	for entry in entries:
		if entry != null and entry.definition != null and entry.count > 0:
			usable += 1
	if usable == 0:
		warnings.append("ResourceArea belum punya entry resource yang valid.")
	return warnings


func global_polygon() -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in polygon:
		points.append(global_transform * point)
	return points

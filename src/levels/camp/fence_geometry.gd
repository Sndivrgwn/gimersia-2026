class_name FenceGeometry
extends RefCounted

## Geometri pagar, murni statis supaya mudah dites.

const EPSILON := 0.001


static func segments_cross(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
	var o1 := _orientation(a1, a2, b1)
	var o2 := _orientation(a1, a2, b2)
	var o3 := _orientation(b1, b2, a1)
	var o4 := _orientation(b1, b2, a2)

	if o1 != o2 and o3 != o4:
		return true

	if o1 == 0 and _on_segment(a1, a2, b1):
		return true
	if o2 == 0 and _on_segment(a1, a2, b2):
		return true
	if o3 == 0 and _on_segment(b1, b2, a1):
		return true
	if o4 == 0 and _on_segment(b1, b2, a2):
		return true
	return false


## Segmen pagar pertama (masih hidup) yang memotong garis from -> to.
## Sengaja tanpa tipe FenceSegment: memutus dependensi siklik
## FenceSegment -> FenceGeometry -> FenceSegment.
static func first_blocking_segment(from: Vector2, to: Vector2, segments: Array):
	for entry in segments:
		var segment = entry
		if segment == null or not is_instance_valid(segment):
			continue
		if not segment.has_method(&"get_endpoints") or not segment.has_method(&"get_current_hp"):
			continue
		if segment.get_current_hp() <= 0.0:
			continue
		var ends: PackedVector2Array = segment.get_endpoints()
		if ends.size() < 2:
			continue
		if segments_cross(from, to, ends[0], ends[1]):
			return segment
	return null


static func point_segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var length_squared := ab.length_squared()
	if length_squared <= EPSILON:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / length_squared, 0.0, 1.0)
	return point.distance_to(a + ab * t)


static func _orientation(a: Vector2, b: Vector2, c: Vector2) -> int:
	var value := (b - a).cross(c - a)
	if absf(value) <= EPSILON:
		return 0
	return 1 if value > 0.0 else 2


static func _on_segment(a: Vector2, b: Vector2, c: Vector2) -> bool:
	return c.x >= minf(a.x, b.x) - EPSILON and c.x <= maxf(a.x, b.x) + EPSILON \
		and c.y >= minf(a.y, b.y) - EPSILON and c.y <= maxf(a.y, b.y) + EPSILON

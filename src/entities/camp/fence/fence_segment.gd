class_name FenceSegment
extends CampStructure

## D2: satu segmen pagar. CampStructure tetap non-blocking (Node2D); badan
## fisik ada di StaticBody2D child pada FENCE_LAYER supaya fauna tertahan.

const SEGMENT_GROUP := &"fence_segment"

@export var segment_length: float = 66.0
@export var thickness: float = 10.0
@export var blocks_player: bool = false

var _body: StaticBody2D


func _enter_tree() -> void:
	add_to_group(SEGMENT_GROUP)


func _ready() -> void:
	super()
	_ensure_body()


func get_body() -> StaticBody2D:
	_ensure_body()
	return _body


func get_endpoints() -> PackedVector2Array:
	var half := segment_length * 0.5
	var direction := Vector2.RIGHT.rotated(global_rotation)
	return PackedVector2Array([
		global_position - direction * half,
		global_position + direction * half,
	])


func distance_to_point(point: Vector2) -> float:
	var ends := get_endpoints()
	if ends.size() < 2:
		return point.distance_to(global_position)
	return FenceGeometry.point_segment_distance(point, ends[0], ends[1])


func _ensure_body() -> void:
	if _body != null and is_instance_valid(_body):
		return
	_body = StaticBody2D.new()
	_body.name = "Body"
	_body.collision_layer = PhysicsLayers.FENCE_LAYER
	_body.collision_mask = 0
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(segment_length, thickness)
	shape.shape = rectangle
	_body.add_child(shape)
	add_child(_body)

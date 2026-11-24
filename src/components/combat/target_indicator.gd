class_name TargetIndicator
extends Node2D

## Fase 2C: penanda target auto-attack.
##
## Node2D kosmetik di dunia: mengikuti `CombatComponent.get_auto_target()` dan
## menggambar chevron kecil di atas hewan yang akan dipukul otomatis. Tidak
## membaca input dan tidak mengubah state gameplay; kalau tidak ada target,
## penanda disembunyikan.

const COMBAT_NAME := "CombatComponent"
const MARKER_COLOR := Color(1.0, 0.86, 0.35, 0.9)
const MARKER_OUTLINE := Color(0.25, 0.16, 0.05, 0.85)
const OFFSET_Y := 34.0

@export var combat: CombatComponent

var _marker: Polygon2D
var _outline: Polygon2D
var _target: Node


func _ready() -> void:
	_build()
	tick(0.0)


func _process(delta: float) -> void:
	tick(delta)


func tick(_delta: float = 0.0) -> void:
	_bind()
	var target: Node = combat.get_auto_target() if combat != null else null
	_target = target
	var body := target as Node2D
	if body == null:
		visible = false
		return
	global_position = body.global_position + Vector2(0.0, -OFFSET_Y)
	visible = true


## Target yang sedang ditandai (dipakai tes).
func get_target() -> Node:
	return _target if _target != null and is_instance_valid(_target) else null


func is_showing() -> bool:
	return visible and get_target() != null


func _bind() -> void:
	if combat == null or not is_instance_valid(combat):
		var parent := get_parent()
		combat = parent.get_node_or_null(COMBAT_NAME) as CombatComponent if parent != null else null


func _build() -> void:
	top_level = true
	z_index = 6
	visible = false
	var points := PackedVector2Array([
		Vector2(-7.0, -12.0), Vector2(7.0, -12.0), Vector2(0.0, 0.0)
	])
	_outline = Polygon2D.new()
	_outline.name = "Outline"
	_outline.color = MARKER_OUTLINE
	_outline.polygon = _scaled(points, 1.35)
	add_child(_outline)
	_marker = Polygon2D.new()
	_marker.name = "Marker"
	_marker.color = MARKER_COLOR
	_marker.polygon = points
	add_child(_marker)


func _scaled(points: PackedVector2Array, factor: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point * factor)
	return result

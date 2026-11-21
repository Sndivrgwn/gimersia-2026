class_name BasePlacementController
extends Node

## D1: B membuka preview ring yang mengikuti pemain; B lagi memasang base.
## Input dibaca dengan polling action (aturan INPUT RULE).

signal preview_changed(valid: bool, reason: String)
signal base_placed(center: Vector2)
signal placement_cancelled

const GROUP := &"base_placement"
const SNAP := 16.0
const RING_SEGMENTS := 48

@export var player: Node2D
@export var anchor: CampAnchor
## Untuk tes: Callable(Vector2) -> Dictionary {valid, reason}.
var rules_override: Callable = Callable()

var _preview_active: bool = false
var _preview_position: Vector2 = Vector2.ZERO
var _result: Dictionary = {"valid": false, "reason": ""}
var _ring: Line2D


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	InputSetup.ensure_actions()
	if player == null:
		player = get_parent() as Node2D
	if anchor == null:
		anchor = CampAnchor.find_anchor(self)
	_ensure_ring()
	refresh_ring()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(InputSetup.BASE_PLACE):
		if _preview_active:
			confirm()
		else:
			start_preview()
		return
	if not _preview_active:
		return
	if Input.is_action_just_pressed(&"ui_cancel"):
		cancel()
		return
	_update_preview()


func start_preview() -> void:
	if anchor == null:
		return
	_preview_active = true
	_update_preview()


func cancel() -> void:
	if not _preview_active:
		return
	_preview_active = false
	refresh_ring()
	placement_cancelled.emit()


func confirm() -> bool:
	if not _preview_active or anchor == null:
		return false
	_update_preview()
	if not bool(_result.get("valid", false)):
		return false
	_preview_active = false
	var placed := anchor.found(_preview_position)
	refresh_ring()
	if placed:
		base_placed.emit(_preview_position)
	return placed


func is_preview_active() -> bool:
	return _preview_active


func get_preview_position() -> Vector2:
	return _preview_position


func get_result() -> Dictionary:
	return _result


func set_preview_position(position: Vector2) -> void:
	_preview_position = position.snapped(Vector2(SNAP, SNAP))
	_result = evaluate_at(_preview_position)
	refresh_ring()
	preview_changed.emit(bool(_result.get("valid", false)), String(_result.get("reason", "")))


func evaluate_at(position: Vector2) -> Dictionary:
	if rules_override.is_valid():
		return rules_override.call(position) as Dictionary
	if anchor == null:
		return {"valid": false, "reason": "Base tidak tersedia"}
	return anchor.evaluate(position)


func refresh_ring() -> void:
	if _ring == null:
		return
	var radius := anchor.get_ring_radius() if anchor != null else BaseSiteConfig.new().ring_radius
	var points := PackedVector2Array()
	for index in RING_SEGMENTS:
		var angle := TAU * float(index) / float(RING_SEGMENTS)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	_ring.points = points
	_ring.visible = _preview_active
	_ring.position = _preview_position - player.global_position if player != null else Vector2.ZERO
	var valid := bool(_result.get("valid", false))
	_ring.default_color = Color(0.3, 1.0, 0.4, 0.8) if valid else Color(1.0, 0.3, 0.3, 0.8)


func _update_preview() -> void:
	if player == null:
		return
	set_preview_position(player.global_position)


func _ensure_ring() -> void:
	if _ring != null and is_instance_valid(_ring):
		return
	_ring = Line2D.new()
	_ring.name = "BasePreviewRing"
	_ring.width = 2.0
	_ring.z_index = 5
	add_child(_ring)

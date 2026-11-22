class_name ChopFeedback
extends Node2D

## Mission 7: umpan balik menebang pohon (tanpa audio).
## Menempel sebagai child ResourceNode hanya untuk definisi chop_feedback_enabled.

signal feedback_event(kind: StringName, position: Vector2)

const SHAKE_PX := 2.0
const SHAKE_HZ := 12.0
const CHIP_INTERVAL := 0.25
const FALL_TIME := 0.6
const FALL_DEGREES := 85.0
const REGROW_TIME := 0.5
const REGROW_SCALE := 0.3
const STUMP_SIZE := Vector2(16.0, 6.0)

var _target: Node
var _interactor: InteractorComponent
var _visual: Node2D
var _active: bool = false
var _shake_phase: float = 0.0
var _chip_timer: float = 0.0
var _fallen: bool = false
var _stump: Polygon2D


func _ready() -> void:
	_target = get_parent()
	_visual = _target.get_node_or_null("Visual") as Node2D
	_bind_interactor()


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	_poll_depleted()
	if _interactor == null:
		_bind_interactor()
	if not _active or _fallen:
		return
	_shake_phase += delta
	if _visual != null:
		_visual.position = Vector2(sin(_shake_phase * TAU * SHAKE_HZ) * SHAKE_PX, 0.0)
	_chip_timer += delta
	if _chip_timer >= CHIP_INTERVAL:
		_chip_timer = 0.0
		_spawn_chips()
		feedback_event.emit(&"chop_hit", global_position)


func is_chopping() -> bool:
	return _active and not _fallen


func is_fallen() -> bool:
	return _fallen


func get_stump() -> Polygon2D:
	return _stump


# --- Internal ---------------------------------------------------------------

func _bind_interactor() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group(&"player")
	if player == null:
		return
	_interactor = player.get_node_or_null("InteractorComponent") as InteractorComponent
	if _interactor == null:
		return
	if not _interactor.target_changed.is_connected(_on_target_changed):
		_interactor.target_changed.connect(_on_target_changed)
	if not _interactor.progress_changed.is_connected(_on_progress_changed):
		_interactor.progress_changed.connect(_on_progress_changed)


func _on_target_changed(target: Interactable) -> void:
	_active = target == _target
	if not _active:
		_stop_shake()


func _on_progress_changed(ratio: float) -> void:
	if _active and ratio > 0.0:
		return
	_active = false
	_stop_shake()


func _stop_shake() -> void:
	_chip_timer = 0.0
	if _visual != null:
		_visual.position = Vector2.ZERO


func _poll_depleted() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	if not _target.has_method(&"is_depleted"):
		return
	var depleted: bool = _target.is_depleted()
	if depleted and not _fallen:
		_start_fall()
	elif not depleted and _fallen:
		_regrow()


func _start_fall() -> void:
	_fallen = true
	_stop_shake()
	var parent := _target.get_parent()
	if parent != null:
		var body := Node2D.new()
		body.name = "TreeFall"
		if _visual != null:
			var copy := _duplicate_visual()
			if copy is Node2D:
				body.add_child(copy)
		body.global_position = _target.global_position
		parent.add_child(body)
		var tween := body.create_tween()
		tween.set_parallel(true)
		tween.tween_property(body, "rotation", deg_to_rad(FALL_DEGREES), FALL_TIME)
		tween.tween_property(body, "modulate:a", 0.0, FALL_TIME)
		tween.chain().tween_callback(body.queue_free)
		_spawn_stump(parent)
	feedback_event.emit(&"tree_fall", _target.global_position)


func _spawn_stump(parent: Node) -> void:
	if _stump != null and is_instance_valid(_stump):
		return
	_stump = Polygon2D.new()
	_stump.name = "TreeStump"
	var half := STUMP_SIZE * 0.5
	_stump.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
	_stump.color = Color(0.35, 0.22, 0.12, 1.0)
	_stump.global_position = _target.global_position
	_stump.z_index = -1
	parent.add_child(_stump)


## Salinan art bila slot punya art; kalau tidak, polygon placeholder lama.
func _duplicate_visual() -> Node:
	if _target != null and is_instance_valid(_target):
		var slot := _target.get_node_or_null("VisualSlot") as VisualSlot
		if slot != null and slot.is_showing_art():
			var art := slot.duplicate_art()
			if art != null:
				return art
	return _visual.duplicate() if _visual != null else null


func _regrow() -> void:
	_fallen = false
	if _stump != null and is_instance_valid(_stump):
		_stump.queue_free()
	_stump = null
	if _target == null or not is_instance_valid(_target):
		return
	(_target as Node2D).scale = Vector2(REGROW_SCALE, REGROW_SCALE)
	var tween := create_tween()
	tween.tween_property(_target, "scale", Vector2.ONE, REGROW_TIME)


func _spawn_chips() -> void:
	var parent := _target.get_parent() if _target != null else null
	if parent == null or not is_inside_tree():
		return
	var chips := CPUParticles2D.new()
	chips.name = "ChopChips"
	chips.one_shot = true
	chips.emitting = true
	chips.amount = 6
	chips.lifetime = 0.3
	chips.explosiveness = 1.0
	chips.spread = 180.0
	chips.initial_velocity_min = 30.0
	chips.initial_velocity_max = 70.0
	chips.gravity = Vector2(0.0, 160.0)
	chips.color = Color(0.6, 0.4, 0.2, 1.0)
	var chip_texture := Assets.ui_texture(&"fx_chip")
	if chip_texture != null:
		chips.texture = chip_texture
	chips.global_position = _target.global_position
	parent.add_child(chips)
	chips.finished.connect(chips.queue_free)

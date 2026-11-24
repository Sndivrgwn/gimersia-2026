class_name VisualDriver
extends Node

## Basis tipis untuk pemicu state animasi. Menempel sebagai child VisualSlot
## (dibuat oleh VisualSlot.attach) dan hanya membaca state publik entity.

var owner_node: Node
var slot: VisualSlot

var _last_state: StringName = &""
var _last_dir: StringName = &""
var _bound: bool = false


func setup(p_owner: Node, p_slot: VisualSlot) -> void:
	owner_node = p_owner
	slot = p_slot
	set_process(true)
	if not _bound:
		_bound = true
		bind()


## Override untuk menyambung sinyal entity.
func bind() -> void:
	pass


func _process(delta: float) -> void:
	step(delta)


## Override: dipanggil tiap frame.
func step(_delta: float) -> void:
	pass


## Kirim state ke slot, hanya bila berubah.
func push(state: StringName, dir: StringName = &"") -> void:
	if state == _last_state and (String(dir).is_empty() or dir == _last_dir):
		return
	_last_state = state
	if not String(dir).is_empty():
		_last_dir = dir
	if slot != null:
		slot.set_state(state, _last_dir)


func get_last_state() -> StringName:
	return _last_state


func get_last_dir() -> StringName:
	return _last_dir


# --- Helper bersama ---------------------------------------------------------

func owner_velocity() -> Vector2:
	if owner_node is CharacterBody2D:
		return (owner_node as CharacterBody2D).velocity
	if owner_node is Node2D and "velocity" in owner_node:
		return owner_node.get("velocity") as Vector2
	return Vector2.ZERO


func owner_facing(fallback: StringName = &"down") -> StringName:
	if owner_node != null and "facing_direction" in owner_node:
		return Dir4.from_vector(owner_node.get("facing_direction") as Vector2, fallback)
	return fallback


func sibling(path: String) -> Node:
	if owner_node == null or owner_node.get_parent() == null:
		return null
	return owner_node.get_parent().get_node_or_null(path)

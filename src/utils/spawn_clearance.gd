class_name SpawnClearance
extends RefCounted

## Mission 10 Phase 4: aturan jarak spawn fauna. Titik spawn tidak boleh lebih
## dekat dari `min_px` ke pemain atau badan fauna lain yang masih hidup.

const FAUNA_GROUP := &"fauna"
const PLAYER_GROUP := &"player"
const MIN_PX := 60.0


## True bila `point` cukup jauh dari pemain dan semua badan fauna.
static func is_clear(tree: SceneTree, point: Vector2, min_px: float = MIN_PX, ignore: Node = null) -> bool:
	if tree == null:
		return true
	for node in tree.get_nodes_in_group(PLAYER_GROUP):
		if node == ignore or not (node is Node2D) or not is_instance_valid(node):
			continue
		if point.distance_to((node as Node2D).global_position) < min_px:
			return false
	for node in tree.get_nodes_in_group(FAUNA_GROUP):
		if node == ignore or not (node is Node2D) or not is_instance_valid(node):
			continue
		if point.distance_to((node as Node2D).global_position) < min_px:
			return false
	return true

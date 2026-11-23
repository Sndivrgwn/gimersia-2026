class_name BodySeparation
extends RefCounted

## Mission 10 Phase 4: pemisah badan terakhir. Bila dua badan bertumpuk lebih
## dari `max_overlap_px`, badan yang memanggil bergeser menjauh paling banyak
## `separation_speed * delta` per tick. Tidak pernah menembus dinding/pagar
## (move_and_collide memakai mask badan), tidak pernah masuk zona sungai, dan
## tidak pernah bergerak mendekati pemain.

const FAUNA_GROUP := &"fauna"
const PLAYER_GROUP := &"player"
const DEFAULT_MAX_OVERLAP := 2.0
const DEFAULT_SEPARATION_SPEED := 60.0


## Geser `body` menjauh dari badan lain yang terlalu bertumpuk. Mengembalikan
## total perpindahan yang benar-benar dicoba (untuk tes).
static func apply(body: CharacterBody2D, delta: float, player: Node = null) -> Vector2:
	if body == null or not is_instance_valid(body) or delta <= 0.0:
		return Vector2.ZERO
	if body.get_tree() == null:
		return Vector2.ZERO
	var profile := BodyProfileApplier.profile_of(body)
	var max_overlap := profile.max_overlap_px if profile != null else DEFAULT_MAX_OVERLAP
	var speed := profile.separation_speed if profile != null else DEFAULT_SEPARATION_SPEED
	if speed <= 0.0:
		return Vector2.ZERO
	var radius := radius_of(body)
	var player_position := _position_of(player)
	var moved := Vector2.ZERO
	for other in _nearby_bodies(body):
		var other_radius := radius_of(other)
		var other_position := (other as Node2D).global_position
		var offset := body.global_position - other_position
		var distance := offset.length()
		if distance <= 0.0001:
			offset = Vector2.RIGHT
			distance = 0.0001
		var overlap := radius + other_radius - distance
		if overlap <= max_overlap:
			continue
		var direction := offset / distance
		var step := minf(overlap - max_overlap, speed * delta)
		# Jangan mendorong badan ke dalam pemain: hanya relevan bila pemain sudah
		# dekat; badan yang jauh tetap boleh berpisah walau pemain searah.
		if player_position != Vector2.INF:
			var to_player := player_position - body.global_position
			var player_distance := to_player.length()
			var near_player := radius + radius_of(player) + max_overlap + step
			if player_distance <= near_player and player_distance > 0.0001 \
					and direction.dot(to_player / player_distance) > 0.001:
				continue
		if step <= 0.0:
			continue
		var motion := direction * step
		if _is_river(body.global_position + motion):
			continue
		if _blocked_by_world(body, direction, step):
			continue
		# Depenetrasi harus bisa melepas badan yang SUDAH bertumpuk, jadi tidak
		# lewat move_and_collide (yang berhenti saat sudah bersentuhan). Dinding,
		# pagar, dan sungai sudah diperiksa di atas.
		body.global_position += motion
		moved += motion
	return moved


## Radius badan dari CircleShape2D pertama; default 12 px.
static func radius_of(body: Node) -> float:
	var node := body as Node2D
	if node == null:
		return 12.0
	for child in node.get_children():
		var shape_node := child as CollisionShape2D
		if shape_node == null:
			continue
		var circle := shape_node.shape as CircleShape2D
		if circle != null:
			return circle.radius
	return 12.0


static func _nearby_bodies(body: CharacterBody2D) -> Array[Node]:
	var result: Array[Node] = []
	var tree := body.get_tree()
	if tree == null:
		return result
	for group in [FAUNA_GROUP, PLAYER_GROUP]:
		for node in tree.get_nodes_in_group(group):
			if node == body or not (node is CharacterBody2D):
				continue
			if not result.has(node):
				result.append(node)
	# Badan tanpa grup (tes/stub) tetap dihitung bila bersaudara.
	var parent := body.get_parent()
	if parent != null:
		for child in parent.get_children():
			if child == body or not (child is CharacterBody2D):
				continue
			if not result.has(child):
				result.append(child)
	return result


static func _position_of(node: Node) -> Vector2:
	if node is Node2D and is_instance_valid(node):
		return (node as Node2D).global_position
	return Vector2.INF


static func _is_river(position: Vector2) -> bool:
	return IslandZones.zone_at(position) == IslandZones.Zone.RIVER


## Ray singkat ke arah gerak, diperpanjang radius badan, hanya terhadap dunia
## dan pagar. Mencegah depenetrasi menembus dinding/pagar.
static func _blocked_by_world(body: CharacterBody2D, direction: Vector2, step: float) -> bool:
	var world := body.get_world_2d()
	if world == null:
		return false
	var space := world.direct_space_state
	if space == null:
		return false
	var radius := radius_of(body)
	var from := body.global_position
	var to := from + direction * (step + radius)
	var query := PhysicsRayQueryParameters2D.create(
		from, to, PhysicsLayers.WORLD | PhysicsLayers.FENCE_LAYER, [body.get_rid()]
	)
	return not space.intersect_ray(query).is_empty()

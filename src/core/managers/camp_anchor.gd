class_name CampAnchor
extends Node

## D1: pusat base dinamis (bukan autoload). Sampai base ditentukan, pusatnya
## Vector2.ZERO (lokasi crash) supaya perilaku lama tetap sama.

signal base_founded(center: Vector2)

const GROUP := &"camp_anchor"
const DEFAULT_RESPAWN_OFFSET := Vector2(0.0, 64.0)
const STRUCTURE_GROUP := &"camp_structure"

@export var config: BaseSiteConfig

var _center: Vector2 = Vector2.ZERO
var _founded: bool = false
## Fase 4C: rotasi ring pagar yang dipilih saat base ditentukan (radian).
var _fence_rotation: float = 0.0


func _enter_tree() -> void:
	add_to_group(GROUP)


func get_center() -> Vector2:
	return _center


func is_founded() -> bool:
	return _founded


## Relokasi hanya boleh sebelum struktur pertama dibangun.
func can_found() -> bool:
	if not _founded:
		return true
	return built_structure_count() == 0


func built_structure_count() -> int:
	var tree := get_tree()
	if tree == null:
		return 0
	var count := 0
	for node in tree.get_nodes_in_group(STRUCTURE_GROUP):
		var structure := node as CampStructure
		if structure != null and is_instance_valid(structure) and not structure.is_queued_for_deletion():
			count += 1
	return count


func get_rules_config() -> BaseSiteConfig:
	if config == null:
		config = BaseSiteConfig.new()
	return config


## `fence_rotation` hanya disimpan bila base berhasil ditentukan.
func found(position: Vector2, fence_rotation: float = 0.0) -> bool:
	var result := BaseSiteRules.evaluate(position, get_rules_config(), not can_found())
	if not bool(result.get("valid", false)):
		return false
	_center = position
	_fence_rotation = wrapf(fence_rotation, -PI, PI)
	_founded = true
	base_founded.emit(_center)
	return true


## Rotasi ring pagar base (0 bila belum pernah diputar).
func get_fence_rotation() -> float:
	return _fence_rotation


func evaluate(position: Vector2) -> Dictionary:
	return BaseSiteRules.evaluate(position, get_rules_config(), not can_found())


func get_respawn_position() -> Vector2:
	return get_center() + DEFAULT_RESPAWN_OFFSET


func get_ring_radius() -> float:
	return get_rules_config().ring_radius


# --- Static helpers ---------------------------------------------------------

static func find_anchor(node: Node) -> CampAnchor:
	if node == null:
		return null
	var tree := node.get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(GROUP) as CampAnchor


static func center_of(node: Node) -> Vector2:
	var anchor := find_anchor(node)
	if anchor == null:
		return Vector2.ZERO
	return anchor.get_center()


static func respawn_position_of(node: Node) -> Vector2:
	var anchor := find_anchor(node)
	if anchor == null:
		# Tanpa base: titik spawn pemain dari provider dunia (konstanta lama jadi
		# cadangan kalau provider tidak tahu).
		var poi := WorldRules.poi(WorldSource.POI_PLAYER_START)
		return poi if poi != Vector2.INF else DEFAULT_RESPAWN_OFFSET
	return anchor.get_respawn_position()

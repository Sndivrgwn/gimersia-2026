class_name RepairComponent
extends Node

## Repair struktur camp: tahan R (action `repair`) selama 1.0 s pada struktur
## rusak terdekat dalam 96 px.
##
## Timer memakai delta nyata, bukan jam game. Bahan repair baru dikonsumsi saat
## hold selesai (atomik), lalu `CampStructure.repair(definition.repair_hp)`
## dipanggil. Progres reset saat R dilepas atau target keluar jangkauan.
##
## Input dibaca dengan polling (`Input.is_action_pressed`), bukan
## `_unhandled_input`; action `repair` didaftarkan `InputSetup.ensure_actions()`.

signal progress_changed(ratio: float)
signal repair_completed(structure: CampStructure)
signal repair_blocked(structure: CampStructure, reason: String)
signal target_changed(structure: CampStructure)

const STRUCTURE_GROUP := &"camp_structure"
const INPUT_ACTION := &"repair"
const PLAYER_GROUP := &"player"
const REPAIR_RANGE := 96.0
const REPAIR_HOLD_TIME := 1.0
const REASON_MISSING := "Bahan kurang"
const REASON_FULL := "Struktur sudah penuh"

## Jarak maksimum struktur yang bisa diperbaiki.
@export var repair_range: float = REPAIR_RANGE
## Lama hold R untuk satu repair (detik nyata).
@export var hold_time: float = REPAIR_HOLD_TIME
## Opsional; diisi otomatis dari parent (Player) bila kosong.
@export var inventory: InventoryComponent
@export var player: Node
## Matikan di scene tes bila input tidak ingin ikut aktif.
@export var input_enabled: bool = true

var _target: CampStructure
var _progress: float = 0.0
var _last_ratio: float = 0.0
var _blocked_key: String = ""


func _ready() -> void:
	InputSetup.ensure_actions()
	_bind()


func _process(delta: float) -> void:
	tick(delta)


# --- Read API ---------------------------------------------------------------

func get_target() -> CampStructure:
	return _target


func get_progress_ratio() -> float:
	return _last_ratio


func is_repairing() -> bool:
	return _progress > 0.0


## Prompt HUD untuk target saat ini; "" bila tidak ada target.
func get_target_prompt() -> String:
	if _target == null:
		return ""
	var text := "Tahan R: Perbaiki %s" % _target.get_display_name()
	var definition := _target.get_definition()
	if definition != null:
		var cost_text := definition.get_repair_cost_text()
		if not cost_text.is_empty():
			text += " (%s)" % cost_text
	return text


## Alasan struktur tidak bisa diperbaiki sekarang; "" bila bisa.
func get_block_reason(structure: CampStructure) -> String:
	if structure == null:
		return ""
	if not structure.is_damaged():
		return REASON_FULL
	if not _has_cost(structure):
		return REASON_MISSING
	return ""


# --- Tick -------------------------------------------------------------------

## Satu tick. `_process` hanya memanggil ini supaya tes deterministik.
func tick(delta: float) -> void:
	if delta <= 0.0:
		return

	_scan_target()
	if _target == null:
		_reset_progress()
		return

	if input_enabled and not Input.is_action_pressed(INPUT_ACTION):
		_reset_progress()
		return

	var reason := get_block_reason(_target)
	if not reason.is_empty():
		_emit_blocked(_target, reason)
		_reset_progress()
		return
	_blocked_key = ""

	_progress += delta
	_emit_progress(clampf(_progress / maxf(hold_time, 0.0001), 0.0, 1.0))
	if _progress >= hold_time:
		_complete(_target)


# --- Internal ---------------------------------------------------------------

func _bind() -> void:
	if player == null:
		player = get_parent()
	if inventory == null and player != null:
		inventory = player.get_node_or_null("InventoryComponent") as InventoryComponent


func _origin() -> Vector2:
	if player is Node2D:
		return (player as Node2D).global_position
	return Vector2.ZERO


func _scan_target() -> void:
	var tree := get_tree()
	if tree == null:
		_set_target(null)
		return

	var origin := _origin()
	var best: CampStructure = null
	var best_distance := repair_range
	for node in tree.get_nodes_in_group(STRUCTURE_GROUP):
		var structure := node as CampStructure
		if structure == null or not is_instance_valid(structure):
			continue
		if not structure.is_inside_tree() or structure.is_queued_for_deletion():
			continue
		var distance := origin.distance_to(structure.global_position)
		if distance <= best_distance:
			best_distance = distance
			best = structure
	_set_target(best)


func _set_target(structure: CampStructure) -> void:
	if structure == _target:
		return
	_target = structure
	_progress = 0.0
	_blocked_key = ""
	_emit_progress(0.0)
	target_changed.emit(_target)


func _complete(structure: CampStructure) -> void:
	if structure == null:
		return
	var definition := structure.get_definition()
	if definition == null:
		_reset_progress()
		return
	if not _consume_cost(definition):
		_emit_blocked(structure, REASON_MISSING)
		_reset_progress()
		return

	structure.repair(definition.repair_hp)
	_emit_progress(1.0)
	_progress = 0.0
	_progress_changed_zero()
	repair_completed.emit(structure)


func _consume_cost(definition: StructureDefinition) -> bool:
	if inventory == null:
		return false
	if not _has_cost_for(definition):
		return false

	var consumed: Array[ItemAmount] = []
	for amount in definition.repair_cost:
		if amount == null or amount.item == null or amount.count <= 0:
			continue
		if not inventory.remove_item(amount.item, amount.count):
			for paid in consumed:
				inventory.add_or_drop(paid.item, paid.count)
			return false
		consumed.append(amount)
	return true


func _has_cost(structure: CampStructure) -> bool:
	var definition := structure.get_definition() if structure != null else null
	return definition != null and _has_cost_for(definition)


func _has_cost_for(definition: StructureDefinition) -> bool:
	if inventory == null:
		return false
	for amount in definition.repair_cost:
		if amount == null or amount.item == null or amount.count <= 0:
			continue
		if not inventory.has_item(amount.item, amount.count):
			return false
	return true


func _emit_blocked(structure: CampStructure, reason: String) -> void:
	var key := "%d:%s" % [structure.get_instance_id(), reason]
	if key == _blocked_key:
		return
	_blocked_key = key
	repair_blocked.emit(structure, reason)


func _emit_progress(ratio: float) -> void:
	var clamped := clampf(ratio, 0.0, 1.0)
	if is_equal_approx(clamped, _last_ratio):
		return
	_last_ratio = clamped
	progress_changed.emit(clamped)


func _reset_progress() -> void:
	_progress = 0.0
	_emit_progress(0.0)


func _progress_changed_zero() -> void:
	_last_ratio = 0.0
	progress_changed.emit(0.0)

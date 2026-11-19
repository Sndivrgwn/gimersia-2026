class_name InteractorComponent
extends Node

## Pencari Interactable terdekat + penjalan hold-E.
##
## Komponen ini tidak punya clock sendiri: progres memakai delta frame nyata,
## bukan waktu game dari DayNightManager. Setelah satu interaksi selesai,
## tombol harus dilepas dulu sebelum bisa memulai lagi (tidak auto-chain).
## Ia hanya menyimpan progres/pilihan target; state gameplay ada di Interactable
## dan komponen pemain (Inventory/Needs/Stats).

signal target_changed(target: Interactable)
signal progress_changed(ratio: float)
signal interaction_completed(target: Interactable)
signal interaction_blocked(target: Interactable, reason: String)
signal interaction_cancelled(target: Interactable)

const DEFAULT_CONFIG: InteractionConfig = preload("res://src/data/configs/interaction_config.tres")
const INPUT_ACTION := &"interact"

## Angka tuning. Null berarti memakai InteractionConfig() bawaan.
@export var config: InteractionConfig = DEFAULT_CONFIG
## Matikan di scene tes bila input tidak ingin ikut aktif.
@export var enabled: bool = true

var _target: Interactable
var _progress: float = 0.0
var _last_ratio: float = 0.0
var _needs_release: bool = false
var _scan_timer: float = 0.0
var _blocked_target: Interactable
var _blocked_reason: String = ""


func _ready() -> void:
	InputSetup.ensure_actions()


func _process(delta: float) -> void:
	if not enabled:
		return
	_tick_scan(delta)
	_tick_hold(delta)


# --- Read API ---------------------------------------------------------------

func get_target() -> Interactable:
	return _target


## 0..1, dihitung dari hold_time target saat ini.
func get_progress_ratio() -> float:
	return _last_ratio


func is_waiting_for_release() -> bool:
	return _needs_release


func get_config() -> InteractionConfig:
	return _config()


## Statistik pemilik (Player). Null bila tidak ada.
func get_stats() -> StatsComponent:
	return _sibling("StatsComponent") as StatsComponent


func get_inventory() -> InventoryComponent:
	return _sibling("InventoryComponent") as InventoryComponent


func get_needs() -> NeedsComponent:
	return _sibling("NeedsComponent") as NeedsComponent


# --- Kontrol ----------------------------------------------------------------

## Batalkan interaksi yang sedang berjalan (progres -> 0).
func cancel() -> void:
	var target := _target
	_progress = 0.0
	_needs_release = false
	_emit_progress(0.0)
	if target != null:
		interaction_cancelled.emit(target)


# --- Internal ---------------------------------------------------------------

func _tick_scan(delta: float) -> void:
	_scan_timer += delta
	var interval: float = maxf(_config().scan_interval, 0.0)
	if interval > 0.0 and _scan_timer < interval:
		_validate_target()
		return

	_scan_timer = 0.0
	_set_target(_find_nearest())


func _validate_target() -> void:
	if _target == null:
		return
	if not is_instance_valid(_target) or not _target.is_inside_tree():
		_set_target(null)
		return
	if _distance_to(_target) > _config().interaction_range:
		_set_target(null)


func _set_target(new_target: Interactable) -> void:
	if new_target == _target:
		return

	if _target != null and _progress > 0.0:
		interaction_cancelled.emit(_target)

	_target = new_target
	_progress = 0.0
	_needs_release = false
	_blocked_target = null
	_blocked_reason = ""
	_emit_progress(0.0)
	target_changed.emit(_target)


func _tick_hold(delta: float) -> void:
	var pressed := Input.is_action_pressed(INPUT_ACTION)

	# Selesai sekali -> wajib lepas dulu.
	if _needs_release:
		if not pressed:
			_needs_release = false
			_progress = 0.0
			_emit_progress(0.0)
		return

	if _target == null:
		return

	if not pressed:
		if _progress > 0.0:
			_cancel_current()
		return

	if not _target.can_interact(self):
		_emit_blocked(_target)
		if _progress > 0.0:
			_progress = 0.0
			_emit_progress(0.0)
		return

	_blocked_target = null
	_blocked_reason = ""

	var hold_time: float = maxf(_target.get_hold_time(self), 0.0)
	if hold_time <= 0.0:
		_complete(_target)
		return

	_progress = minf(_progress + delta, hold_time)
	_emit_progress(_progress / hold_time)
	if _progress >= hold_time:
		_complete(_target)


func _complete(target: Interactable) -> void:
	_needs_release = true
	_progress = 0.0
	_emit_progress(1.0)
	target.interact(self)
	interaction_completed.emit(target)


func _cancel_current() -> void:
	var target := _target
	_progress = 0.0
	_emit_progress(0.0)
	if target != null:
		interaction_cancelled.emit(target)


func _emit_blocked(target: Interactable) -> void:
	var reason: String = target.get_block_reason(self)
	if target == _blocked_target and reason == _blocked_reason:
		return
	_blocked_target = target
	_blocked_reason = reason
	interaction_blocked.emit(target, reason)


func _emit_progress(ratio: float) -> void:
	var clamped := clampf(ratio, 0.0, 1.0)
	if is_equal_approx(clamped, _last_ratio):
		return
	_last_ratio = clamped
	progress_changed.emit(clamped)


func _find_nearest() -> Interactable:
	var tree := get_tree()
	if tree == null:
		return null

	var origin := _origin()
	var best: Interactable = null
	var best_distance: float = maxf(_config().interaction_range, 0.0)

	for node in tree.get_nodes_in_group(Interactable.GROUP):
		var candidate := node as Interactable
		if candidate == null or not is_instance_valid(candidate):
			continue
		if not candidate.is_inside_tree():
			continue
		var distance := origin.distance_to(candidate.global_position)
		if distance <= best_distance:
			best_distance = distance
			best = candidate
	return best


func _distance_to(target: Interactable) -> float:
	return _origin().distance_to(target.global_position)


func _origin() -> Vector2:
	var owner_node := get_parent()
	if owner_node is Node2D:
		return (owner_node as Node2D).global_position
	return Vector2.ZERO


func _sibling(node_name: String) -> Node:
	var owner_node := get_parent()
	if owner_node == null:
		return null
	return owner_node.get_node_or_null(node_name)


func _config() -> InteractionConfig:
	if config == null:
		config = InteractionConfig.new()
	return config

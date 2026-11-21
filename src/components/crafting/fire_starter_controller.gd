class_name FireStarterController
extends Node

## D3: minigame gesek batu untuk menyalakan campfire yang COLD.

signal started
signal strike_result(quality: int, success: bool)
signal finished(success: bool)

enum State { IDLE, ACTIVE, RESULT }
enum Quality { MISS, GOOD, PERFECT }

const GROUP := &"fire_starter"
const DEFAULT_CONFIG: FireStarterConfig = preload("res://src/data/configs/fire_starter_config.tres")

@export var config: FireStarterConfig = DEFAULT_CONFIG
@export var player: Node
@export var inventory: InventoryComponent

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Untuk tes: bila >= 0, dipakai sebagai hasil roll (bukan rng).
var roll_override: float = -1.0

var state: int = State.IDLE

## Node (bukan Campfire) untuk memutus dependensi siklik Campfire <-> controller.
var _campfire: Node
var _interactor: InteractorComponent
var _stats: StatsComponent
var _strikes: int = 0
var _marker: float = 0.0
var _direction: float = 1.0
var _cooldown: float = 0.0
var _result_timer: float = 0.0
var _last_quality: int = Quality.MISS
var _last_success: bool = false
var _last_cancel: StringName = &""
var _start_hp: float = 0.0


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	InputSetup.ensure_actions()
	if player == null:
		player = get_parent()
	if player != null:
		if inventory == null:
			inventory = player.get_node_or_null("InventoryComponent") as InventoryComponent
		_interactor = player.get_node_or_null("InteractorComponent") as InteractorComponent
		_stats = player.get_node_or_null("StatsComponent") as StatsComponent


func _process(delta: float) -> void:
	if state != State.ACTIVE:
		tick(delta)
		return
	if Input.is_action_just_pressed(&"ui_cancel"):
		cancel(&"ui_cancel")
		return
	if Input.is_action_just_pressed(InputSetup.INTERACT):
		strike()
		return
	tick(delta)


# --- API --------------------------------------------------------------------

func start(campfire: Node) -> bool:
	if campfire == null or state == State.ACTIVE or _cooldown > 0.0:
		return false
	if not campfire.can_ignite():
		return false
	if inventory == null or not inventory.has_item(ItemCatalog.STONE, config.stone_cost):
		return false
	if not inventory.remove_item(ItemCatalog.STONE, config.stone_cost):
		return false
	_campfire = campfire
	_strikes = 0
	_marker = 0.0
	_direction = 1.0
	_last_quality = Quality.MISS
	_last_success = false
	_last_cancel = &""
	_start_hp = _stats.current_hp if _stats != null else 0.0
	state = State.ACTIVE
	_lock_interactor(true)
	started.emit()
	return true


func strike() -> void:
	if state != State.ACTIVE or _campfire == null:
		return
	var quality := quality_at(_marker)
	var chance := get_success_chance(quality)
	var roll := roll_override if roll_override >= 0.0 else rng.randf()
	var success := roll <= chance
	_last_quality = quality
	_last_success = success
	strike_result.emit(quality, success)
	if success:
		_campfire.ignite()
		_finish(true)
		return
	_strikes += 1
	if _strikes >= config.strikes_per_attempt:
		_finish(false)


func cancel(reason: StringName = &"cancelled") -> void:
	if state != State.ACTIVE:
		return
	_last_cancel = reason
	_finish(false)


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	if _cooldown > 0.0:
		_cooldown = maxf(_cooldown - delta, 0.0)
	if state == State.RESULT:
		_result_timer -= delta
		if _result_timer <= 0.0:
			state = State.IDLE
		return
	if state != State.ACTIVE:
		return
	if not is_instance_valid(_campfire):
		cancel(&"campfire_gone")
		return
	if _should_cancel():
		cancel(_last_cancel if not _last_cancel.is_empty() else &"cancelled")
		return
	_advance_marker(delta)


func is_active() -> bool:
	return state == State.ACTIVE


func get_marker() -> float:
	return _marker


func set_marker(value: float) -> void:
	_marker = clampf(value, 0.0, 1.0)


func get_strikes() -> int:
	return _strikes


func get_last_quality() -> int:
	return _last_quality


func get_last_cancel() -> StringName:
	return _last_cancel


func get_last_success() -> bool:
	return _last_success


func get_cooldown() -> float:
	return _cooldown


func quality_at(value: float) -> int:
	var centered := absf(value - 0.5)
	if centered <= config.perfect_zone * 0.5:
		return Quality.PERFECT
	if centered <= config.good_zone * 0.5:
		return Quality.GOOD
	return Quality.MISS


func get_success_chance(quality: int) -> float:
	match quality:
		Quality.PERFECT:
			return config.perfect_chance
		Quality.GOOD:
			return config.good_chance
		_:
			return config.miss_chance


# --- Internal ---------------------------------------------------------------

func _advance_marker(delta: float) -> void:
	if config.sweep_period <= 0.0:
		return
	_marker += (delta / config.sweep_period) * 2.0 * _direction
	if _marker > 1.0:
		_marker = 2.0 - _marker
		_direction = -1.0
	elif _marker < 0.0:
		_marker = -_marker
		_direction = 1.0


func _should_cancel() -> bool:
	if player is Node2D and _campfire != null:
		if (_campfire as Node2D).global_position.distance_to((player as Node2D).global_position) > config.cancel_distance:
			_last_cancel = &"too_far"
			return true
	if InputSetup.is_movement_pressed():
		_last_cancel = &"moved"
		return true
	if _stats != null and _stats.current_hp < _start_hp:
		_last_cancel = &"hurt"
		return true
	return false


func _finish(success: bool) -> void:
	var campfire := _campfire
	_campfire = null
	state = State.RESULT
	_result_timer = 0.2
	if not success:
		_cooldown = config.fail_cooldown
	_lock_interactor(false)
	finished.emit(success)
	if success and campfire != null:
		pass


func _lock_interactor(value: bool) -> void:
	if _interactor != null and _interactor.has_method(&"set_locked"):
		_interactor.set_locked(value)

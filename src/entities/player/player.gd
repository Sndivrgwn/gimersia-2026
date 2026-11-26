class_name Player
extends CharacterBody2D

## Controller gerak pemain top-down.
## Player tidak menyimpan angka stat: semua nilai dibaca dari StatsComponent.

signal sprint_state_changed(is_sprinting: bool)

const DEFAULT_SNEAK: SneakConfig = preload("res://src/data/configs/sneak_config.tres")
const DEFAULT_WADING: WadingConfig = preload("res://src/data/configs/wading_config.tres")

@onready var stats: StatsComponent = $StatsComponent as StatsComponent

## Mission 9 fase 4: tuning jongkok dan air. Diisi .tres, bukan angka kode.
@export var sneak_config: SneakConfig = DEFAULT_SNEAK
@export var wading_config: WadingConfig = DEFAULT_WADING

## Diatur manual untuk sekarang. Modul Needs nanti yang mengunci sprint
## (mis. saat Fatigue <= 25); Player tidak menghitung Fatigue sendiri.
var can_sprint: bool = true

## Arah hadap terakhir yang tidak nol.
var facing_direction: Vector2 = Vector2.DOWN

## Pengali jarak knockback (hook pasif Sturdy).
var knockback_multiplier: float = 1.0

var _is_sprinting: bool = false
var _is_sneaking: bool = false
var _is_wading: bool = false
## Mission 9: sumber yang memblokir sprint (hunger, sneak, wading, ...).
var _sprint_blocks: Dictionary = {}
## Dorongan eksternal (knockback) yang meluruh selama durasinya.
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_remaining: float = 0.0
## UI yang butuh perhatian penuh (panel stasiun) mengunci gerak tanpa pause.
var _input_locked: bool = false


func _ready() -> void:
	InputSetup.ensure_actions()
	# Top-down: tanpa gravitasi dan tanpa moving platform.
	motion_mode = MOTION_MODE_FLOATING
	platform_on_leave = PLATFORM_ON_LEAVE_DO_NOTHING
	platform_floor_layers = 0
	platform_wall_layers = 0
	if stats == null:
		push_error("Player: StatsComponent tidak ditemukan.")
	BodyProfileApplier.apply(self, load("res://src/data/configs/physics/body_player.tres") as BodyProfile)
	VisualSlot.attach(self, &"player", [get_node_or_null("Visual")], null, PlayerVisual.new())


## True saat pemain sedang sprint (dibaca driver visual).
func is_sprinting() -> bool:
	return _is_sprinting


## Kunci input gerak selama panel stasiun terbuka. Dunia tetap berjalan:
## hanya input pemain yang diabaikan, tidak ada SceneTree.paused.
func set_input_locked(locked: bool) -> void:
	if _input_locked == locked:
		return
	_input_locked = locked
	if locked:
		velocity = Vector2.ZERO
		_set_sprinting(false)
		set_sneaking(false)


func is_input_locked() -> bool:
	return _input_locked


# --- Blokir sprint (Mission 9) ----------------------------------------------

## Tambah satu sumber blokir sprint. Beberapa sumber boleh aktif bersamaan.
func add_sprint_block(source: StringName) -> void:
	_sprint_blocks[source] = true
	if _is_sprinting:
		_set_sprinting(false)


func remove_sprint_block(source: StringName) -> void:
	_sprint_blocks.erase(source)


func is_sprint_blocked() -> bool:
	return not _sprint_blocks.is_empty()


func get_sprint_blocks() -> Array[StringName]:
	var result: Array[StringName] = []
	for key in _sprint_blocks:
		result.append(key)
	return result


## Mission 9 fase 4: jongkok memperlambat dan menyamarkan; sprint diblokir.
func set_sneaking(value: bool) -> void:
	if _is_sneaking == value:
		return
	_is_sneaking = value
	_set_sprint_block(&"sneak", value and _sneak().blocks_sprint)


func is_sneaking() -> bool:
	return _is_sneaking


## Pengali radius deteksi fauna terhadap pemain (1.0 = normal).
func get_stealth_multiplier() -> float:
	if not _is_sneaking:
		return 1.0
	return clampf(_sneak().detection_multiplier, 0.05, 1.0)


## Diisi WadingComponent saat pemain masuk/keluar zona sungai.
func set_wading(value: bool) -> void:
	if _is_wading == value:
		return
	_is_wading = value
	_set_sprint_block(&"wading", value and _wading().blocks_sprint)


func is_wading() -> bool:
	return _is_wading


## Pengali kecepatan gerak dari mode berjalan (jongkok x air).
func get_move_speed_multiplier() -> float:
	var multiplier := 1.0
	if _is_sneaking:
		multiplier *= maxf(_sneak().speed_multiplier, 0.0)
	if _is_wading:
		multiplier *= maxf(_wading().speed_multiplier, 0.0)
	return multiplier


func _sneak() -> SneakConfig:
	if sneak_config == null:
		sneak_config = DEFAULT_SNEAK
	return sneak_config


func _wading() -> WadingConfig:
	if wading_config == null:
		wading_config = DEFAULT_WADING
	return wading_config


func _set_sprint_block(source: StringName, enabled: bool) -> void:
	if enabled:
		add_sprint_block(source)
	else:
		remove_sprint_block(source)


func _physics_process(_delta: float) -> void:
	if _input_locked:
		velocity = Vector2.ZERO
		_set_sprinting(false)
		set_sneaking(false)
		return

	var input_direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var has_movement := input_direction.length_squared() > 0.0

	if has_movement:
		facing_direction = input_direction.normalized()

	set_sneaking(Input.is_action_pressed(&"sneak"))

	var wants_sprint := has_movement and can_sprint and not is_sprint_blocked() \
		and Input.is_action_pressed(&"sprint")
	_set_sprinting(wants_sprint)

	var speed := 0.0
	if stats != null:
		speed = stats.get_sprint_speed() if _is_sprinting else stats.get_move_speed()
	speed *= get_move_speed_multiplier()

	velocity = input_direction * speed
	move_and_slide()
	_apply_knockback_step(_delta)


## Dorongan sekali pakai (mis. Dash Boar). Total perpindahan = `distance`
## selama `duration`; collision tetap dihormati karena lewat move_and_slide().
func apply_knockback(direction: Vector2, distance: float, duration: float) -> void:
	if distance <= 0.0 or duration <= 0.0:
		return
	var dir := direction.normalized() if direction.length_squared() > 0.0001 else Vector2.ZERO
	if dir == Vector2.ZERO:
		return
	_knockback_remaining = duration
	_knockback_velocity = dir * (distance / duration)


func is_knocked_back() -> bool:
	return _knockback_remaining > 0.0


## Kecepatan dorongan saat ini (px/s); nol setelah durasi habis.
func get_knockback_velocity() -> Vector2:
	return _knockback_velocity


func _tick_knockback(delta: float) -> void:
	if _knockback_remaining <= 0.0:
		_knockback_velocity = Vector2.ZERO
		return
	_knockback_remaining = maxf(_knockback_remaining - delta, 0.0)
	# Epsilon: 10 langkah 0.02 s menyisakan sisa float ~1e-17.
	if _knockback_remaining <= 0.0001:
		_knockback_remaining = 0.0
		_knockback_velocity = Vector2.ZERO


## Langkah dorongan memakai delta eksplisit supaya total perpindahan = distance
## dan tetap berhenti di dinding (move_and_collide).
func _apply_knockback_step(delta: float) -> void:
	if _knockback_remaining <= 0.0001:
		_knockback_remaining = 0.0
		_knockback_velocity = Vector2.ZERO
		return
	var step := minf(delta, _knockback_remaining)
	move_and_collide(_knockback_velocity * step)
	_tick_knockback(step)


func _set_sprinting(value: bool) -> void:
	if _is_sprinting == value:
		return
	_is_sprinting = value
	sprint_state_changed.emit(_is_sprinting)

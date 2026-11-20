class_name Player
extends CharacterBody2D

## Controller gerak pemain top-down.
## Player tidak menyimpan angka stat: semua nilai dibaca dari StatsComponent.

signal sprint_state_changed(is_sprinting: bool)

@onready var stats: StatsComponent = $StatsComponent as StatsComponent

## Diatur manual untuk sekarang. Modul Needs nanti yang mengunci sprint
## (mis. saat Fatigue <= 25); Player tidak menghitung Fatigue sendiri.
var can_sprint: bool = true

## Arah hadap terakhir yang tidak nol.
var facing_direction: Vector2 = Vector2.DOWN

## Pengali jarak knockback (hook pasif Sturdy).
var knockback_multiplier: float = 1.0

var _is_sprinting: bool = false
## Dorongan eksternal (knockback) yang meluruh selama durasinya.
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_remaining: float = 0.0


func _ready() -> void:
	InputSetup.ensure_actions()
	# Top-down: tanpa gravitasi.
	motion_mode = MOTION_MODE_FLOATING
	if stats == null:
		push_error("Player: StatsComponent tidak ditemukan.")


func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var has_movement := input_direction.length_squared() > 0.0

	if has_movement:
		facing_direction = input_direction.normalized()

	var wants_sprint := has_movement and can_sprint and Input.is_action_pressed(&"sprint")
	_set_sprinting(wants_sprint)

	var speed := 0.0
	if stats != null:
		speed = stats.get_sprint_speed() if _is_sprinting else stats.get_move_speed()

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

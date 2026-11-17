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

var _is_sprinting: bool = false


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


func _set_sprinting(value: bool) -> void:
	if _is_sprinting == value:
		return
	_is_sprinting = value
	sprint_state_changed.emit(_is_sprinting)

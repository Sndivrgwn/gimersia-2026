
extends Area2D

## Semua efek zona aman memakai source_id ini agar bisa dilepas tanpa
## mengganggu modifier dari modul lain.
const SAFE_ZONE_SOURCE := &"safe_zone"

@export var phantom_camera: PhantomCamera2D

@export_group("Camera Zoom")
@export var normal_zoom: float = 1.0
@export var safe_zone_zoom: float = 2.5
@export var zoom_duration: float = 0.6

@export_group("Player Movement")
@export var slow_multiplier: float = 0.5

var zoom_tween: Tween

var current_player: Node2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player entered Safe Zone")

		current_player = body

		change_zoom(safe_zone_zoom)
		change_player_speed(slow_multiplier)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player exited Safe Zone")

		change_zoom(normal_zoom)
		change_player_speed(1.0)

		current_player = null


func change_zoom(target_zoom: float) -> void:
	if not is_instance_valid(phantom_camera):
		return

	if zoom_tween and zoom_tween.is_running():
		zoom_tween.kill()

	zoom_tween = create_tween()

	zoom_tween.set_trans(Tween.TRANS_SINE)
	zoom_tween.set_ease(Tween.EASE_IN_OUT)

	zoom_tween.tween_property(
		phantom_camera,
		"zoom",
		Vector2(target_zoom, target_zoom),
		zoom_duration
	)


func change_player_speed(multiplier: float) -> void:
	if not is_instance_valid(current_player):
		print("Player tidak valid!")
		return

	var player := current_player as Player
	if player == null or player.stats == null:
		return

	# Perlambatan memakai modifier supaya nilai dasar di PlayerBaseStats
	# tidak pernah ditimpa langsung.
	player.stats.remove_modifier(SAFE_ZONE_SOURCE)
	if not is_equal_approx(multiplier, 1.0):
		player.stats.add_modifier(
			SAFE_ZONE_SOURCE,
			&"move_speed",
			StatModifier.Kind.PERCENT,
			multiplier - 1.0
		)

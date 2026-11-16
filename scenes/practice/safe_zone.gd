
extends Area2D

@export var phantom_camera: PhantomCamera2D

@export_group("Camera Zoom")
@export var normal_zoom: float = 1.0
@export var safe_zone_zoom: float = 2.5
@export var zoom_duration: float = 0.6

@export_group("Player Movement")
@export var slow_multiplier: float = 0.5

var zoom_tween: Tween

var current_player: Node2D
var original_speed: float = -1.0


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
		original_speed = -1.0


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

	print("Player ditemukan: ", current_player.name)

	# Ambil script movement langsung dari Player
	var movement = current_player

	if not "speed" in movement:
		print("Variabel speed tidak ditemukan!")
		return

	print("Speed sebelum: ", movement.speed)

	if original_speed < 0:
		original_speed = movement.speed

	movement.speed = original_speed * multiplier

	print("Speed sesudah: ", movement.speed)

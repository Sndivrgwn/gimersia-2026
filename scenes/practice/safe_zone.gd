extends Area2D

@export var phantom_camera: PhantomCamera2D

@export_group("Camera Zoom")
@export var normal_zoom: float = 1.0
@export var safe_zone_zoom: float = 2.5
@export var zoom_duration: float = 0.6

var zoom_tween: Tween


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	print(body)
	if body.is_in_group("player"):
		print("it goes in")
		change_zoom(safe_zone_zoom)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		change_zoom(normal_zoom)


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

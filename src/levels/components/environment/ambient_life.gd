extends Node2D

## Mission 9 polish: partikel suasana (kunang-kunang malam, debu siang).
## Murni visual: tidak menambah node fisika, tidak menyentuh gameplay.
## Tekstur titik dibuat saat runtime (tidak ada biner di repo).

const DAY_AMOUNT := 14
const NIGHT_AMOUNT := 20
const SPAWN_RADIUS := 420.0

var _motes: CPUParticles2D
var _fireflies: CPUParticles2D
var _clock: Node
var _player: Node2D


func _ready() -> void:
	z_as_relative = false
	z_index = 3
	var dot_day := _make_dot(8, Color(1.0, 0.95, 0.8, 0.55))
	var dot_night := _make_dot(8, Color(1.0, 0.92, 0.45, 0.95))

	_motes = _make_particles(dot_day, DAY_AMOUNT, 9.0, 10.0, 26.0, 0.5, 1.0)
	_motes.name = "Motes"
	add_child(_motes)

	_fireflies = _make_particles(dot_night, NIGHT_AMOUNT, 7.0, 4.0, 16.0, 0.8, 1.6)
	_fireflies.name = "Fireflies"
	add_child(_fireflies)

	_player = get_tree().get_first_node_in_group(&"player") as Node2D
	_clock = get_node_or_null("/root/DayNightManager")
	_apply_night(_clock != null and _clock.has_method(&"is_night") and bool(_clock.call(&"is_night")))
	if _clock != null:
		if _clock.has_signal(&"night_started"):
			_clock.connect(&"night_started", _on_night_started)
		if _clock.has_signal(&"day_started"):
			_clock.connect(&"day_started", _on_day_started)


func _process(_delta: float) -> void:
	if _player != null:
		global_position = _player.global_position


## Dipakai tes: apakah partikel malam sedang aktif.
func is_night_mode() -> bool:
	return _fireflies != null and _fireflies.emitting


func _on_night_started(_day: int) -> void:
	_apply_night(true)


func _on_day_started(_day: int) -> void:
	_apply_night(false)


func _apply_night(is_night: bool) -> void:
	if _fireflies != null:
		_fireflies.emitting = is_night
	if _motes != null:
		_motes.emitting = not is_night


func _make_particles(texture: Texture2D, amount: int, lifetime: float, vmin: float, vmax: float, smin: float, smax: float) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.texture = texture
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = SPAWN_RADIUS
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = vmin
	particles.initial_velocity_max = vmax
	particles.scale_amount_min = smin
	particles.scale_amount_max = smax
	particles.local_coords = false
	particles.preprocess = lifetime
	particles.color = Color.WHITE
	return particles


func _make_dot(size: int, color: Color) -> ImageTexture:
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size - 1, size - 1) * 0.5
	var radius := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(center) / radius
			var a := clampf(1.0 - d, 0.0, 1.0)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * a * a))
	return ImageTexture.create_from_image(image)

extends Node2D

## Sandbox manual untuk StatsComponent + Player.
## Isi scene dibangun lewat kode agar stats_sandbox.tscn tetap minimal.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")

const FLOOR_SIZE := 2000.0
const FLOOR_GRID_STEP := 64.0
const FLOOR_COLOR := Color(0.13, 0.16, 0.14)
const GRID_COLOR := Color(1.0, 1.0, 1.0, 0.06)

const SOURCE_ZIRAH := &"debug_zirah_kulit"
const SOURCE_LAPAR := &"debug_lapar"
const SOURCE_KELELAHAN := &"debug_kelelahan_ekstrem"

const CONTROLS_TEXT := """DEBUG KEYS
1 / 2 / 3 / 4        : +1 STR / SPD / MAS / AGI
Ctrl + 1 / 2 / 3 / 4 : -1 STR / SPD / MAS / AGI
Z : toggle Zirah Kulit (+15 max HP, +20% damage reduction)
X : toggle Lapar (-15% move speed, -15% attack damage)
C : toggle Kelelahan Ekstrem (-45% move speed, -50% attack speed)
H : heal +20          J : set HP to 50
T : toggle can_sprint
R : reset (level 1, modifier uji mati, HP penuh)"""

var _player: Player
var _camera: Camera2D
var _debug_label: Label
var _controls_label: Label

var _zirah_active: bool = false
var _lapar_active: bool = false
var _kelelahan_active: bool = false


func _ready() -> void:
	InputSetup.ensure_actions()
	_create_player()
	_create_camera()
	_create_debug_ui()
	_connect_stats()
	_refresh_debug_label()


# Lantai placeholder digambar langsung oleh root, di belakang child nodes.
func _draw() -> void:
	var half := FLOOR_SIZE * 0.5
	draw_rect(Rect2(-half, -half, FLOOR_SIZE, FLOOR_SIZE), FLOOR_COLOR, true)

	var steps := int(FLOOR_SIZE / FLOOR_GRID_STEP)
	for index in range(steps + 1):
		var offset := -half + float(index) * FLOOR_GRID_STEP
		draw_line(Vector2(offset, -half), Vector2(offset, half), GRID_COLOR)
		draw_line(Vector2(-half, offset), Vector2(half, offset), GRID_COLOR)


func _create_player() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	add_child(_player)


func _create_camera() -> void:
	_camera = Camera2D.new()
	_camera.enabled = true
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0
	_player.add_child(_camera)
	_camera.make_current()


func _create_debug_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	_debug_label = Label.new()
	_debug_label.position = Vector2(16.0, 16.0)
	_debug_label.add_theme_font_size_override("font_size", 16)
	_debug_label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.9))
	layer.add_child(_debug_label)

	_controls_label = Label.new()
	_controls_label.position = Vector2(16.0, 430.0)
	_controls_label.add_theme_font_size_override("font_size", 14)
	_controls_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.72))
	_controls_label.text = CONTROLS_TEXT
	layer.add_child(_controls_label)


func _connect_stats() -> void:
	if _player == null or _player.stats == null:
		return
	_player.stats.stats_changed.connect(_on_stats_changed)
	_player.stats.hp_changed.connect(_on_hp_changed)


func _on_stats_changed() -> void:
	_refresh_debug_label()


func _on_hp_changed(_current: float, _max_value: float) -> void:
	_refresh_debug_label()


func _refresh_debug_label() -> void:
	if _debug_label == null or _player == null or _player.stats == null:
		return

	var stats := _player.stats
	var lines := PackedStringArray()
	lines.append("=== STATS SANDBOX ===")
	lines.append("Proficiency  STR %d | SPD %d | MAS %d | AGI %d" % [
		stats.strength_level, stats.speed_level, stats.mastery_level, stats.agility_level
	])
	lines.append("HP           %.1f / %.1f" % [stats.current_hp, stats.get_max_hp()])
	lines.append("Move speed   %.1f" % stats.get_move_speed())
	lines.append("Sprint speed %.1f" % stats.get_sprint_speed())
	lines.append("Attack dmg   %.1f" % stats.get_attack_damage())
	lines.append("Attack speed %.2f/s (cooldown %.2fs)" % [
		stats.get_attack_speed(), stats.get_attack_cooldown()
	])
	lines.append("Dodge        %.1f%%" % (stats.get_dodge_chance() * 100.0))
	lines.append("Dmg reduce   %.1f%%" % (stats.get_damage_reduction() * 100.0))
	lines.append("Craft time   x%.2f" % stats.get_craft_time_factor())
	lines.append("can_sprint   %s" % ("true" if _player.can_sprint else "false"))
	_debug_label.text = "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if _player == null or _player.stats == null:
		return

	var stats := _player.stats
	var key := key_event.physical_keycode

	if key_event.ctrl_pressed:
		match key:
			KEY_1:
				_adjust_level(stats, &"strength_level", -1)
			KEY_2:
				_adjust_level(stats, &"speed_level", -1)
			KEY_3:
				_adjust_level(stats, &"mastery_level", -1)
			KEY_4:
				_adjust_level(stats, &"agility_level", -1)
		return

	match key:
		KEY_1:
			_adjust_level(stats, &"strength_level", 1)
		KEY_2:
			_adjust_level(stats, &"speed_level", 1)
		KEY_3:
			_adjust_level(stats, &"mastery_level", 1)
		KEY_4:
			_adjust_level(stats, &"agility_level", 1)
		KEY_Z:
			_toggle_zirah()
		KEY_X:
			_toggle_lapar()
		KEY_C:
			_toggle_kelelahan()
		KEY_H:
			stats.heal(20.0)
		KEY_J:
			stats.set_hp(50.0)
		KEY_T:
			_player.can_sprint = not _player.can_sprint
			_refresh_debug_label()
		KEY_R:
			_reset_all()


## Setter level sudah meng-clamp dan memancarkan stats_changed.
func _adjust_level(stats: StatsComponent, property: StringName, amount: int) -> void:
	stats.set(property, int(stats.get(property)) + amount)


func _toggle_zirah() -> void:
	_zirah_active = not _zirah_active
	if _zirah_active:
		_player.stats.add_modifier(SOURCE_ZIRAH, &"max_hp", StatModifier.Kind.FLAT, 15.0)
		_player.stats.add_modifier(SOURCE_ZIRAH, &"damage_reduction", StatModifier.Kind.PERCENT, 0.20)
	else:
		_player.stats.remove_modifier(SOURCE_ZIRAH)


func _toggle_lapar() -> void:
	_lapar_active = not _lapar_active
	if _lapar_active:
		_player.stats.add_modifier(SOURCE_LAPAR, &"move_speed", StatModifier.Kind.PERCENT, -0.15)
		_player.stats.add_modifier(SOURCE_LAPAR, &"attack_damage", StatModifier.Kind.PERCENT, -0.15)
	else:
		_player.stats.remove_modifier(SOURCE_LAPAR)


func _toggle_kelelahan() -> void:
	_kelelahan_active = not _kelelahan_active
	if _kelelahan_active:
		_player.stats.add_modifier(SOURCE_KELELAHAN, &"move_speed", StatModifier.Kind.PERCENT, -0.45)
		_player.stats.add_modifier(SOURCE_KELELAHAN, &"attack_speed", StatModifier.Kind.PERCENT, -0.50)
	else:
		_player.stats.remove_modifier(SOURCE_KELELAHAN)


func _reset_all() -> void:
	var stats := _player.stats
	stats.strength_level = 1
	stats.speed_level = 1
	stats.mastery_level = 1
	stats.agility_level = 1

	stats.remove_modifier(SOURCE_ZIRAH)
	stats.remove_modifier(SOURCE_LAPAR)
	stats.remove_modifier(SOURCE_KELELAHAN)
	_zirah_active = false
	_lapar_active = false
	_kelelahan_active = false

	stats.set_hp(stats.get_max_hp())
	_player.can_sprint = true
	_refresh_debug_label()

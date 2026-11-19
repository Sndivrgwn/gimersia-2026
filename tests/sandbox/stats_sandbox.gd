extends Node2D

## Sandbox manual untuk StatsComponent + NeedsComponent + Player.
## Isi scene dibangun lewat kode agar stats_sandbox.tscn tetap minimal.
##
## Needs memakai NeedsComponent asli (bukan modifier tiruan), jadi tier Hunger/
## Thirst/Fatigue di sini berperilaku sama seperti di practice1. Drain tetap
## berjalan dari autoload DayNightManager; tombol debug hanya melompatkan nilai.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const NEEDS_HUD_SCENE: PackedScene = preload("res://src/ui/hud/needs/needs_hud.tscn")

const FLOOR_SIZE := 2000.0
const FLOOR_GRID_STEP := 64.0
const FLOOR_COLOR := Color(0.13, 0.16, 0.14)
const GRID_COLOR := Color(1.0, 1.0, 1.0, 0.06)

const SOURCE_ZIRAH := &"debug_zirah_kulit"

## Tombol debug memakai action Input Map `debug_*` dari `project.godot` [input].
const ACTION_LEVEL_UP: Array[StringName] = [
	&"debug_str_up",
	&"debug_spd_up",
	&"debug_mas_up",
	&"debug_agi_up",
]
const ACTION_LEVEL_DOWN: Array[StringName] = [
	&"debug_str_down",
	&"debug_spd_down",
	&"debug_mas_down",
	&"debug_agi_down",
]
const LEVEL_PROPERTIES: Array[StringName] = [
	&"strength_level",
	&"speed_level",
	&"mastery_level",
	&"agility_level",
]

const CONTROLS_TEXT := """DEBUG KEYS
1 / 2 / 3 / 4        : +1 STR / SPD / MAS / AGI
Ctrl + 1 / 2 / 3 / 4 : -1 STR / SPD / MAS / AGI
Z : toggle Zirah Kulit (+15 max HP, +20% damage reduction)
X : Hunger  -> 100 / 25 (LOW) / 0 (ZERO)  [cycle]
C : Thirst  -> 100 / 25 (LOW) / 0 (ZERO)  [cycle]
V : Fatigue -> 100 / 25 (LOW) / 0 (ZERO)  [cycle]
B : refill semua needs ke 100
Hold Shift + gerak : sprint (Fatigue -2.5/s, terkunci saat <= 25)
H : heal +20          J : set HP to 50
T : toggle can_sprint (Needs mengunci ulang saat Fatigue <= 25)
R : reset (level 1, Zirah mati, needs penuh, HP penuh)"""

const TIER_LOW_VALUE := 25.0
const TIER_FULL_VALUE := 100.0

var _player: Player
var _needs: NeedsComponent
var _camera: Camera2D
var _debug_label: Label
var _controls_label: Label

var _zirah_active: bool = false
var _sprinting: bool = false


func _ready() -> void:
	InputSetup.ensure_actions()
	_create_player()
	_create_camera()
	_create_debug_ui()
	_connect_signals()
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
	# Grup "player" dipasang oleh scene pemakai (sama seperti practice1.tscn);
	# NeedsHUD memakainya untuk menemukan komponen.
	_player.add_to_group(&"player")
	add_child(_player)
	_needs = _player.get_node_or_null("NeedsComponent") as NeedsComponent


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

	# HUD Needs yang sama dengan practice1; komponen dioper eksplisit supaya
	# tidak bergantung pada urutan _ready.
	var needs_hud := NEEDS_HUD_SCENE.instantiate()
	needs_hud.set(&"needs_component", _needs)
	add_child(needs_hud)


func _connect_signals() -> void:
	if _player == null or _player.stats == null:
		return
	_player.stats.stats_changed.connect(_on_stats_changed)
	_player.stats.hp_changed.connect(_on_hp_changed)

	_player.sprint_state_changed.connect(_on_sprint_state_changed)

	if _needs != null:
		_needs.value_changed.connect(_on_needs_changed)
		_needs.tier_changed.connect(_on_needs_tier_changed)


func _on_stats_changed() -> void:
	_refresh_debug_label()


func _on_hp_changed(_current: float, _max_value: float) -> void:
	_refresh_debug_label()


func _on_sprint_state_changed(is_sprinting: bool) -> void:
	_sprinting = is_sprinting
	_refresh_debug_label()


func _on_needs_changed(_need: int, _value: float) -> void:
	_refresh_debug_label()


func _on_needs_tier_changed(_need: int, _tier: int) -> void:
	_refresh_debug_label()


func _refresh_debug_label() -> void:
	if _debug_label == null or _player == null or _player.stats == null:
		return

	var stats := _player.stats
	var lines := PackedStringArray()
	lines.append("=== STATS + NEEDS SANDBOX ===")
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
	lines.append("Gather time  x%.2f  |  Craft time x%.2f" % [
		stats.get_gather_time_factor(), stats.get_craft_time_factor()
	])
	lines.append("Sprint drain x%.2f" % stats.get_sprint_fatigue_drain_factor())
	lines.append("Dodge        %.1f%%" % (stats.get_dodge_chance() * 100.0))
	lines.append("Dmg reduce   %.1f%%" % (stats.get_damage_reduction() * 100.0))
	lines.append("can_sprint   %s" % ("true" if _player.can_sprint else "false"))
	lines.append("Sprinting    %s" % ("true" if _sprinting else "false"))

	if _needs != null:
		lines.append("")
		lines.append("--- NEEDS ---")
		lines.append("Hunger   %5.1f  %s" % [_needs.get_value(NeedsComponent.Need.HUNGER), _tier_name(NeedsComponent.Need.HUNGER)])
		lines.append("Thirst   %5.1f  %s" % [_needs.get_value(NeedsComponent.Need.THIRST), _tier_name(NeedsComponent.Need.THIRST)])
		lines.append("Fatigue  %5.1f  %s" % [_needs.get_value(NeedsComponent.Need.FATIGUE), _tier_name(NeedsComponent.Need.FATIGUE)])

	_debug_label.text = "\n".join(lines)


func _tier_name(need: int) -> String:
	if _needs == null:
		return "-"
	match _needs.get_tier(need):
		NeedsComponent.Tier.LOW:
			return "LOW"
		NeedsComponent.Tier.ZERO:
			return "ZERO"
		_:
			return "NORMAL"


## Dibaca tiap frame lewat Input Map; tidak ada `_unhandled_input` maupun
## pencocokan raw keycode.
func _process(_delta: float) -> void:
	if _player == null or _player.stats == null:
		return

	var stats := _player.stats
	for index in ACTION_LEVEL_UP.size():
		if Input.is_action_just_pressed(ACTION_LEVEL_UP[index]):
			_adjust_level(stats, LEVEL_PROPERTIES[index], 1)
			return
		if Input.is_action_just_pressed(ACTION_LEVEL_DOWN[index]):
			_adjust_level(stats, LEVEL_PROPERTIES[index], -1)
			return

	if Input.is_action_just_pressed(&"debug_toggle_zirah"):
		_toggle_zirah()
	elif Input.is_action_just_pressed(&"debug_cycle_hunger"):
		_cycle_need(NeedsComponent.Need.HUNGER)
	elif Input.is_action_just_pressed(&"debug_cycle_thirst"):
		_cycle_need(NeedsComponent.Need.THIRST)
	elif Input.is_action_just_pressed(&"debug_cycle_fatigue"):
		_cycle_need(NeedsComponent.Need.FATIGUE)
	elif Input.is_action_just_pressed(&"debug_refill_needs"):
		_refill_needs()
	elif Input.is_action_just_pressed(&"debug_heal"):
		stats.heal(20.0)
	elif Input.is_action_just_pressed(&"debug_set_hp"):
		stats.set_hp(50.0)
	elif Input.is_action_just_pressed(&"debug_toggle_sprint"):
		_player.can_sprint = not _player.can_sprint
		_refresh_debug_label()
	elif Input.is_action_just_pressed(&"debug_reset"):
		_reset_all()


## Setter level sudah meng-clamp dan memancarkan stats_changed.
func _adjust_level(stats: StatsComponent, property: StringName, amount: int) -> void:
	stats.set(property, int(stats.get(property)) + amount)


## Siklus nilai: penuh -> LOW -> ZERO -> penuh. Efek tier dipasang oleh
## NeedsComponent, bukan oleh sandbox.
func _cycle_need(need: int) -> void:
	if _needs == null:
		return
	var value := _needs.get_value(need)
	if value > TIER_LOW_VALUE:
		_needs.set_value(need, TIER_LOW_VALUE)
	elif value > 0.0:
		_needs.set_value(need, 0.0)
	else:
		_needs.set_value(need, TIER_FULL_VALUE)
	_refresh_debug_label()


func _refill_needs() -> void:
	if _needs == null:
		return
	for need in [NeedsComponent.Need.HUNGER, NeedsComponent.Need.THIRST, NeedsComponent.Need.FATIGUE]:
		_needs.set_value(need, TIER_FULL_VALUE)
	_refresh_debug_label()


func _toggle_zirah() -> void:
	_zirah_active = not _zirah_active
	if _zirah_active:
		_player.stats.add_modifier(SOURCE_ZIRAH, &"max_hp", StatModifier.Kind.FLAT, 15.0)
		_player.stats.add_modifier(SOURCE_ZIRAH, &"damage_reduction", StatModifier.Kind.PERCENT, 0.20)
	else:
		_player.stats.remove_modifier(SOURCE_ZIRAH)


func _reset_all() -> void:
	var stats := _player.stats
	stats.strength_level = 1
	stats.speed_level = 1
	stats.mastery_level = 1
	stats.agility_level = 1

	stats.remove_modifier(SOURCE_ZIRAH)
	_zirah_active = false

	if _needs != null:
		for need in [NeedsComponent.Need.HUNGER, NeedsComponent.Need.THIRST, NeedsComponent.Need.FATIGUE]:
			_needs.set_value(need, TIER_FULL_VALUE)

	stats.set_hp(stats.get_max_hp())
	_player.can_sprint = true
	_refresh_debug_label()

class_name DayNightVisual
extends Node2D

## Visual half of the day/night cycle.
##
## Gameplay phases stay DAY/NIGHT. This component adds four visual conditions:
##   - MORNING: night -> morning -> day blend when a game day starts
##   - DAY: steady daylight after the dawn blend
##   - EVENING: day -> evening -> night blend when night starts
##   - NIGHT: steady night after the dusk blend
##
## The CanvasModulate tint is the single authority for world lighting. Light
## intensity from DayNightVisualConfig is folded into that tint, so no other
## node competes for the same property.
##
## Audio/other systems may listen to `atmosphere_changed` (MORNING/DAY/EVENING/
## NIGHT) in addition to DayNightManager's gameplay signals. The component owns
## no clock: all timing comes from the manager's phase changes plus one tween.

signal atmosphere_changed(atmosphere: int)

const MANAGER_PATH := "/root/DayNightManager"

@export var visual_config: DayNightVisualConfig

## Keeps the particle emitter centered on the active Camera2D.
@export var effects_follow_camera: bool = true

@onready var _canvas_modulate: CanvasModulate = get_node_or_null("CanvasModulate") as CanvasModulate
@onready var _effects: Node2D = get_node_or_null("Effects") as Node2D
@onready var _fireflies: CPUParticles2D = get_node_or_null("Effects/Fireflies") as CPUParticles2D
@onready var _day_motes: CPUParticles2D = get_node_or_null("Effects/DayMotes") as CPUParticles2D

# Untyped on purpose: the autoload has no class_name (it would clash with the
# singleton name), and string-based access keeps this scene usable on its own.
var _manager
var _tween: Tween
var _atmosphere: int = DayNightVisualConfig.Atmosphere.DAY
var _has_atmosphere: bool = false
var _from_color: Color = Color.WHITE
var _mid_color: Color = Color.WHITE
var _to_color: Color = Color.WHITE


func _ready() -> void:
	_manager = get_node_or_null(MANAGER_PATH)

	if _canvas_modulate == null:
		push_error("DayNightVisual: missing CanvasModulate child.")
		return

	if visual_config == null:
		push_warning("DayNightVisual: no DayNightVisualConfig assigned; keeping a neutral tint.")
		_set_world_color(Color.WHITE)
		_stop_effects()
		return

	_configure_effects()

	if _manager == null:
		push_warning("DayNightVisual: DayNightManager autoload not found; showing the steady day tint.")
		_set_atmosphere(DayNightVisualConfig.Atmosphere.DAY)
		_apply_atmosphere_color()
		return

	# Apply the current phase immediately so a scene never starts mid-fade.
	var start_atmosphere := DayNightVisualConfig.Atmosphere.NIGHT if _manager.is_night() else DayNightVisualConfig.Atmosphere.DAY
	_set_atmosphere(start_atmosphere)
	_apply_atmosphere_color()

	_manager.connect("phase_changed", _on_phase_changed)


func _process(_delta: float) -> void:
	if not effects_follow_camera or _effects == null:
		return
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		_effects.global_position = camera.get_screen_center_position()


## Current visual condition (DayNightVisualConfig.Atmosphere).
func get_atmosphere() -> int:
	return _atmosphere


func get_atmosphere_name() -> String:
	match _atmosphere:
		DayNightVisualConfig.Atmosphere.MORNING:
			return "MORNING"
		DayNightVisualConfig.Atmosphere.EVENING:
			return "EVENING"
		DayNightVisualConfig.Atmosphere.NIGHT:
			return "NIGHT"
		_:
			return "DAY"


func _on_phase_changed(_phase: int) -> void:
	_start_transition()


func _start_transition() -> void:
	if visual_config == null or _canvas_modulate == null:
		return

	var is_night: bool = _manager.is_night()
	var start_atmosphere := DayNightVisualConfig.Atmosphere.EVENING if is_night else DayNightVisualConfig.Atmosphere.MORNING
	var end_atmosphere := DayNightVisualConfig.Atmosphere.NIGHT if is_night else DayNightVisualConfig.Atmosphere.DAY

	# Blend from wherever the tint currently is, so an interrupted transition
	# never snaps or restarts from a stale color.
	_from_color = _canvas_modulate.color
	_mid_color = visual_config.get_effective_color(start_atmosphere)
	_to_color = visual_config.get_effective_color(end_atmosphere)

	# Atmosphere switches immediately (for audio/AI); the color catches up.
	_set_atmosphere(start_atmosphere)

	if _tween != null and _tween.is_valid():
		_tween.kill()

	var duration: float = visual_config.get_transition_duration()
	if duration <= 0.0:
		_set_world_color(_to_color)
		_set_atmosphere(end_atmosphere)
		return

	# Bound to this node, so TWEEN_PAUSE_BOUND freezes it while the tree is
	# paused and resumes from the same point.
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_LINEAR)
	_tween.tween_method(_apply_transition, 0.0, 1.0, duration)
	_tween.finished.connect(_on_transition_finished.bind(end_atmosphere))


func _apply_transition(t: float) -> void:
	# smoothstep eases both ends while the two color segments pass through the
	# morning/evening waypoint at the midpoint.
	var eased := smoothstep(0.0, 1.0, t)
	var color: Color
	if eased < 0.5:
		color = _from_color.lerp(_mid_color, eased * 2.0)
	else:
		color = _mid_color.lerp(_to_color, (eased - 0.5) * 2.0)
	_set_world_color(color)


func _on_transition_finished(end_atmosphere: int) -> void:
	_set_world_color(_to_color)
	_set_atmosphere(end_atmosphere)


func _apply_atmosphere_color() -> void:
	if visual_config == null:
		return
	_set_world_color(visual_config.get_effective_color(_atmosphere))


func _set_world_color(color: Color) -> void:
	if _canvas_modulate == null:
		return
	# CanvasModulate multiplies the world canvas; alpha must stay opaque so the
	# HUD (separate CanvasLayer) and the scene remain fully visible.
	_canvas_modulate.color = Color(color.r, color.g, color.b, 1.0)


func _set_atmosphere(atmosphere: int) -> void:
	if _has_atmosphere and _atmosphere == atmosphere:
		return
	_atmosphere = atmosphere
	_has_atmosphere = true
	_update_effects(atmosphere)
	atmosphere_changed.emit(atmosphere)


func _configure_effects() -> void:
	if _fireflies != null:
		_fireflies.amount = visual_config.firefly_amount
		_fireflies.color = visual_config.firefly_color
		_fireflies.emitting = false
	if _day_motes != null:
		_day_motes.amount = visual_config.day_mote_amount
		_day_motes.color = visual_config.day_mote_color
		_day_motes.emitting = false


func _update_effects(atmosphere: int) -> void:
	var effects_enabled := visual_config.enable_environment_effects
	var is_dark := atmosphere == DayNightVisualConfig.Atmosphere.EVENING or atmosphere == DayNightVisualConfig.Atmosphere.NIGHT

	if _fireflies != null:
		_fireflies.emitting = effects_enabled and visual_config.enable_fireflies and is_dark
	if _day_motes != null:
		_day_motes.emitting = effects_enabled and visual_config.enable_day_motes and not is_dark


func _stop_effects() -> void:
	if _fireflies != null:
		_fireflies.emitting = false
	if _day_motes != null:
		_day_motes.emitting = false

class_name DayNightVisual
extends Node2D

## Visual half of the day/night cycle.
##
## Gameplay phases stay DAY/NIGHT. This component adds four visual conditions:
##   - MORNING: night -> morning -> day blend over the last minute of night
##   - DAY: steady daylight
##   - EVENING: day -> evening -> night blend over the last minute of day
##   - NIGHT: steady night
##
## Timing comes from DayNightManager: the blend starts when the current phase
## has `transition_duration` seconds left, so dusk finishes exactly when night
## starts (and dawn exactly when day starts). Loading a scene mid-transition
## computes progress from the remaining time instead of restarting a tween.
##
## The CanvasModulate tint is the single authority for world lighting. The
## SunOverlay derives the sun's direction from the same clock (pure functions
## live in DayLightCurve).
##
## Audio/other systems may listen to `atmosphere_changed` (MORNING/DAY/EVENING/
## NIGHT) in addition to DayNightManager's gameplay signals.

signal atmosphere_changed(atmosphere: int)

const MANAGER_PATH := "/root/DayNightManager"

@export var visual_config: DayNightVisualConfig

## Mission 13: arah/durasi sapuan fajar-senja + arc HUD.
@export var sun_config: SunConfig

## Keeps the particle emitter centered on the active Camera2D.
@export var effects_follow_camera: bool = true

@onready var _canvas_modulate: CanvasModulate = get_node_or_null("CanvasModulate") as CanvasModulate
@onready var _sweep_overlay: CanvasLayer = get_node_or_null("SunSweepOverlay") as CanvasLayer
@onready var _effects: Node2D = get_node_or_null("Effects") as Node2D
@onready var _fireflies: CPUParticles2D = get_node_or_null("Effects/Fireflies") as CPUParticles2D
@onready var _day_motes: CPUParticles2D = get_node_or_null("Effects/DayMotes") as CPUParticles2D
@onready var _sun_overlay: CanvasLayer = get_node_or_null("SunOverlay") as CanvasLayer

# Untyped on purpose: the autoload has no class_name (it would clash with the
# singleton name), and string-based access keeps this scene usable on its own.
var _manager
var _atmosphere: int = DayNightVisualConfig.Atmosphere.DAY
var _has_atmosphere: bool = false
## Warna blend seragam (bukan tint sapuan) untuk perhitungan kegelapan api.
var _world_target_color: Color = Color.WHITE


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
		_hide_sun()
		return

	# Apply the current visual immediately so a scene never starts mid-fade.
	var start_atmosphere := DayNightVisualConfig.Atmosphere.NIGHT if _manager.is_night() else DayNightVisualConfig.Atmosphere.DAY
	_set_atmosphere(start_atmosphere)
	_manager.connect("phase_changed", _on_phase_changed)
	_update_visuals()


func _process(_delta: float) -> void:
	if effects_follow_camera and _effects != null:
		var camera := get_viewport().get_camera_2d()
		if camera != null:
			_effects.global_position = camera.get_screen_center_position()
	_update_visuals()


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


## Jendela transisi (detik game). Dipakai juga oleh api unggun untuk tahu
## kapan cahayanya harus meredup/menyala.
func get_transition_duration() -> float:
	return 0.0 if visual_config == null else visual_config.get_transition_duration()


## 0.0 = tint siang, 1.0 = tint malam. Dipakai PointLight2D api unggun supaya
## cahayanya tidak terlihat sekuat malam saat siang.
func get_world_darkness() -> float:
	if visual_config == null:
		return 0.0
	var day_luminance := DayLightCurve.luminance(visual_config.get_effective_color(DayNightVisualConfig.Atmosphere.DAY))
	var night_luminance := DayLightCurve.luminance(visual_config.get_effective_color(DayNightVisualConfig.Atmosphere.NIGHT))
	return DayLightCurve.darkness_from_luminance(
		DayLightCurve.luminance(_world_target_color),
		day_luminance,
		night_luminance
	)


func _on_phase_changed(_phase: int) -> void:
	_update_visuals()


func _update_visuals() -> void:
	if _manager == null or visual_config == null or _canvas_modulate == null:
		return

	var is_night := bool(_manager.is_night())
	var remaining := float(_manager.get_remaining_seconds())
	var duration := get_transition_duration()
	var progress := DayLightCurve.transition_progress(remaining, duration)

	if progress <= 0.0:
		var steady := DayNightVisualConfig.Atmosphere.NIGHT if is_night else DayNightVisualConfig.Atmosphere.DAY
		_set_atmosphere(steady)
		var steady_color := visual_config.get_effective_color(steady)
		_set_world_color(steady_color)
		_world_target_color = steady_color
		_clear_sweep()
	else:
		var start_atmosphere := DayNightVisualConfig.Atmosphere.NIGHT if is_night else DayNightVisualConfig.Atmosphere.DAY
		var mid_atmosphere := DayNightVisualConfig.Atmosphere.MORNING if is_night else DayNightVisualConfig.Atmosphere.EVENING
		var end_atmosphere := DayNightVisualConfig.Atmosphere.DAY if is_night else DayNightVisualConfig.Atmosphere.NIGHT
		_set_atmosphere(mid_atmosphere)
		# Mission 13 approximation: CanvasModulate memakai endpoint yang lebih
		# terang, SunSweepOverlay mengalikan bagian yang belum dilewati front ke
		# warna blend seragam lama. Titik awal/akhir tetap sama dengan fade lama;
		# sweep nonaktif jatuh ke blend_through yang lama persis.
		var plan := SunSweep.plan(
			sun_config,
			is_night,
			remaining,
			duration,
			visual_config.get_effective_color(start_atmosphere),
			visual_config.get_effective_color(mid_atmosphere),
			visual_config.get_effective_color(end_atmosphere)
		)
		_set_world_color(plan["color"])
		_world_target_color = plan["target"]
		if bool(plan["sweep"]):
			_apply_sweep(plan)
		else:
			_clear_sweep()

	_update_sun(is_night, remaining, duration)


func _apply_sweep(plan: Dictionary) -> void:
	if _sweep_overlay == null or sun_config == null:
		return
	_sweep_overlay.call(
		&"apply",
		float(plan["progress"]),
		int(plan["side"]),
		sun_config.softness,
		sun_config.warm_rim_strength,
		plan["ratio"]
	)


func _clear_sweep() -> void:
	if _sweep_overlay != null and _sweep_overlay.has_method(&"clear"):
		_sweep_overlay.call(&"clear")


func _update_sun(is_night: bool, remaining: float, duration: float) -> void:
	if _sun_overlay == null or not _sun_overlay.has_method(&"apply"):
		return
	# Fajar terjadi di akhir fase malam: arah matahari masih terbit (progress 0).
	var day_progress := 0.0 if is_night else clampf(float(_manager.get_phase_progress()), 0.0, 1.0)
	_sun_overlay.call(&"apply", day_progress, DayLightCurve.darkness(is_night, remaining, duration))


func _hide_sun() -> void:
	if _sun_overlay != null and _sun_overlay.has_method(&"hide_sun"):
		_sun_overlay.call(&"hide_sun")


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
	# Kunang-kunang hanya malam: senja/fajar masih terang.
	var is_night := atmosphere == DayNightVisualConfig.Atmosphere.NIGHT

	if _fireflies != null:
		_fireflies.emitting = effects_enabled and visual_config.enable_fireflies and is_night
	if _day_motes != null:
		_day_motes.emitting = effects_enabled and visual_config.enable_day_motes and not is_night


func _stop_effects() -> void:
	if _fireflies != null:
		_fireflies.emitting = false
	if _day_motes != null:
		_day_motes.emitting = false

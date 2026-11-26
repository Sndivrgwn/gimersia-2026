class_name IrisTransition
extends RefCounted

## Logika murni transisi lingkaran (iris wipe) dari tertutup penuh (0) ke
## terbuka penuh (1). Tanpa akses scene; hanya memakai delta nyata.

signal finished

var _hold_before: float = 0.15
var _duration: float = 0.8
var _start_radius: float = 0.0
var _ease_mode: int = SplashConfig.TransitionEase.EASE_OUT
var _elapsed: float = 0.0
var _radius: float = 0.0
var _finished: bool = false


func setup(cfg: SplashConfig) -> void:
	var active := cfg if cfg != null else SplashConfig.new()
	_hold_before = maxf(active.transition_hold_before, 0.0)
	_duration = maxf(active.transition_duration, 0.0)
	_start_radius = clampf(active.transition_start_radius, 0.0, 1.0)
	_ease_mode = active.transition_ease
	reset()


func reset() -> void:
	_elapsed = 0.0
	_radius = 0.0
	_finished = false


func tick(delta: float) -> void:
	if _finished:
		return
	var step := maxf(delta, 0.0)
	_elapsed += step

	if _elapsed < _hold_before:
		_radius = maxf(_radius, 0.0)
		return

	var progress := 1.0
	if _duration > 0.0:
		progress = clampf((_elapsed - _hold_before) / _duration, 0.0, 1.0)

	var eased := _apply_ease(progress)
	var candidate := clampf(lerpf(_start_radius, 1.0, eased), 0.0, 1.0)
	_radius = clampf(maxf(_radius, candidate), 0.0, 1.0)

	if progress >= 1.0:
		_radius = 1.0
		_finished = true
		finished.emit()


func radius() -> float:
	return _radius


func is_finished() -> bool:
	return _finished


func elapsed() -> float:
	return _elapsed


## Jarak dari tengah viewport ke sudut terjauh (px) agar lubang benar-benar
## menutupi seluruh layar pada rasio aspek apa pun.
static func max_radius_px(viewport_size: Vector2) -> float:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 0.0
	return (viewport_size * 0.5).length()


func _apply_ease(t: float) -> float:
	var clamped := clampf(t, 0.0, 1.0)
	match _ease_mode:
		SplashConfig.TransitionEase.LINEAR:
			return clamped
		SplashConfig.TransitionEase.EASE_IN_OUT:
			return clamped * clamped * (3.0 - 2.0 * clamped)
		_:
			var inv := 1.0 - clamped
			return 1.0 - inv * inv * inv

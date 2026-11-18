extends Node

## Single source of truth for the day/night cycle.
##
## This node runs as the `DayNightManager` autoload (see day_night_manager.tscn).
## It owns gameplay time, the current day and the current phase, and it is the
## only place where phase durations are tracked. Other systems should listen to
## its signals or read its public properties/functions instead of counting time.
##
## Pause behaviour: process_mode is PAUSABLE, so SceneTree.paused freezes the
## clock. Resuming continues from the exact stored phase_elapsed value.
##
## Signal order:
##   day_changed -> day_started -> phase_changed -> time_updated
##   night_started -> phase_changed -> time_updated
##   time_updated (once per displayed second while running)
##   rescue_started (after the final night ends; the clock stops)

signal day_started(day: int)
signal night_started(day: int)
signal day_changed(day: int)
signal phase_changed(phase: int)
signal time_updated(day: int, phase: int, remaining_seconds: float)
signal rescue_started

# Penambahan Modul 2 (backward-compatible).
signal started
signal dusk_started(day: int)
signal night_ended(day: int)
signal time_scale_changed(scale: float)
signal night_watch_changed(active: bool)
signal time_skipped(seconds: float)

enum Phase { DAY, NIGHT }

const MIN_PHASE_DURATION := 0.001
const DUSK_WARNING_SECONDS := 15.0
const NIGHT_WATCH_TIME_SCALE := 2.0
const DEFAULT_CONFIG: DayNightConfig = preload("res://src/data/configs/environment/day_night_default.tres")

## Gameplay config. Defaults to the 600s / 7-day resource.
@export var config: DayNightConfig = DEFAULT_CONFIG

## Optional accelerated config (60s cycle) for debugging.
@export var debug_config: DayNightConfig
@export var use_debug_config: bool = false

## When true, the first day starts as soon as the autoload is ready.
@export var auto_start: bool = true

var current_day: int = 1
var current_phase: int = Phase.DAY
var phase_duration: float = 0.0
var phase_elapsed: float = 0.0
var is_running: bool = false
var rescue_triggered: bool = false

var _active_config: DayNightConfig = DEFAULT_CONFIG
var _time_scale_override: float = -1.0
var _last_reported_second: int = -1
var _night_watch_active: bool = false
var _dusk_announced_day: int = 0


func _ready() -> void:
	# Explicit for clarity: the clock must stop while the tree is paused.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_resolve_config()
	if auto_start:
		start()


func _process(delta: float) -> void:
	if not is_running or rescue_triggered:
		return

	phase_elapsed += delta * get_time_scale()

	# Carry overflow into the next phase so a frame always lands on the right
	# phase, even with a high time_scale or a long frame.
	while not rescue_triggered and phase_elapsed >= phase_duration:
		var overflow := phase_elapsed - phase_duration
		if current_phase == Phase.DAY:
			_begin_night(overflow)
		elif current_day >= get_max_days():
			_trigger_rescue()
			return
		else:
			_begin_day(current_day + 1, overflow, true)

	_report_time()


# --- Public control ---------------------------------------------------------

## Restarts the cycle at Day 1, daytime. Used on new game / scene reload.
func start() -> void:
	var previous_scale := get_time_scale()
	_resolve_config()
	_deactivate_night_watch()
	rescue_triggered = false
	is_running = true
	_dusk_announced_day = 0
	_begin_day(1, 0.0, false)
	_emit_time_scale_changed(previous_scale)
	started.emit()


## Tick manual yang memakai pengali waktu; berguna untuk tes dan modul lain.
func advance(delta: float) -> void:
	if delta <= 0.0 or not is_running or rescue_triggered:
		return
	_advance_game_seconds(delta * get_time_scale())


## Majukan waktu game mentah (tanpa Night Watch) dan beri tahu modul lain
## lewat time_skipped berapa detik game yang benar-benar terpakai.
func skip_time(seconds: float) -> void:
	if seconds <= 0.0 or not is_running or rescue_triggered:
		return

	var before := get_total_elapsed_seconds()
	_advance_game_seconds(seconds)
	var advanced := get_total_elapsed_seconds() - before
	if advanced > 0.0:
		time_skipped.emit(advanced)


# --- Public read API --------------------------------------------------------

func is_day() -> bool:
	return current_phase == Phase.DAY


func is_night() -> bool:
	return current_phase == Phase.NIGHT


func get_phase_name() -> String:
	return "NIGHT" if is_night() else "DAY"


func get_remaining_seconds() -> float:
	return maxf(phase_duration - phase_elapsed, 0.0)


func get_phase_duration() -> float:
	return phase_duration


func get_phase_elapsed() -> float:
	return phase_elapsed


## 0.0 at the start of the current phase, 1.0 at its end.
func get_phase_progress() -> float:
	if phase_duration <= 0.0:
		return 0.0
	return clampf(phase_elapsed / phase_duration, 0.0, 1.0)


func get_max_days() -> int:
	return maxi(_active_config.max_days, 1)


func get_day_ratio(day: int = -1) -> float:
	return _active_config.get_day_ratio(_resolve_day(day))


func get_day_duration(day: int = -1) -> float:
	return _active_config.get_day_duration(_resolve_day(day))


func get_night_duration(day: int = -1) -> float:
	return _active_config.get_night_duration(_resolve_day(day))


func get_current_day() -> int:
	return current_day


func get_phase() -> int:
	return current_phase


## Total detik game yang sudah berjalan sejak Hari 1 pagi.
func get_total_elapsed_seconds() -> float:
	var total := 0.0
	for day in range(1, current_day):
		total += _active_config.get_day_duration(day)
		total += _active_config.get_night_duration(day)
	if current_phase == Phase.NIGHT:
		total += _active_config.get_day_duration(current_day)
	total += phase_elapsed
	return maxf(total, 0.0)


## Teks sisa waktu fase dalam format "MM:SS".
func get_remaining_text() -> String:
	var total := int(ceilf(get_remaining_seconds()))
	return "%02d:%02d" % [int(total / 60.0), total % 60]


func is_night_watch_active() -> bool:
	return _night_watch_active


func get_config() -> DayNightConfig:
	return _active_config


func get_time_scale() -> float:
	if rescue_triggered:
		return 0.0
	if _night_watch_active:
		var base_scale := _time_scale_override if _time_scale_override >= 0.0 else maxf(_active_config.time_scale, 0.0)
		return base_scale * NIGHT_WATCH_TIME_SCALE
	if _time_scale_override >= 0.0:
		return _time_scale_override
	return maxf(_active_config.time_scale, 0.0)


## Runtime-only clock speed override (debug/testing). Negative resets to config.
## `0.0` is a real override (used by the final-dawn freeze); only negatives clear it.
func set_time_scale(value: float) -> void:
	var previous_scale := get_time_scale()
	_time_scale_override = value if value >= 0.0 else -1.0
	_emit_time_scale_changed(previous_scale)


## Night Watch hanya boleh aktif saat malam. Fajar otomatis mematikannya.
func set_night_watch(active: bool) -> void:
	var should_activate := active and is_night() and not rescue_triggered
	if should_activate == _night_watch_active:
		return

	var previous_scale := get_time_scale()
	_night_watch_active = should_activate
	night_watch_changed.emit(_night_watch_active)
	_emit_time_scale_changed(previous_scale)


# --- Internal ---------------------------------------------------------------

func _resolve_config() -> void:
	var chosen: DayNightConfig = config
	if use_debug_config and debug_config != null:
		chosen = debug_config
	if chosen == null:
		push_warning("DayNightManager: no DayNightConfig assigned, using the default config.")
		chosen = DEFAULT_CONFIG
	_active_config = chosen


func _resolve_day(day: int) -> int:
	return day if day >= 1 else current_day


## Jalur transisi untuk advance()/skip_time(). Menjaga sisa detik saat satu
## lompatan melewati beberapa fase penuh.
func _advance_game_seconds(seconds: float) -> void:
	var remaining := seconds
	while remaining > 0.0 and is_running and not rescue_triggered:
		var until_phase_end := maxf(phase_duration - phase_elapsed, 0.0)
		if remaining < until_phase_end:
			phase_elapsed += remaining
			break

		phase_elapsed = phase_duration
		remaining -= until_phase_end
		if current_phase == Phase.DAY:
			_begin_night(0.0)
		elif current_day >= get_max_days():
			_trigger_rescue()
			return
		else:
			_begin_day(current_day + 1, 0.0, true)

	_report_time()


func _emit_dusk_if_due() -> void:
	if not is_running or rescue_triggered:
		return
	if current_phase != Phase.DAY:
		return
	if _dusk_announced_day == current_day:
		return
	if get_remaining_seconds() > DUSK_WARNING_SECONDS:
		return

	_dusk_announced_day = current_day
	dusk_started.emit(current_day)


func _deactivate_night_watch() -> void:
	if not _night_watch_active:
		return
	_night_watch_active = false
	night_watch_changed.emit(false)


func _emit_time_scale_changed(previous_scale: float) -> void:
	var current_scale := get_time_scale()
	if not is_equal_approx(previous_scale, current_scale):
		time_scale_changed.emit(current_scale)


func _begin_day(day: int, elapsed: float = 0.0, announce_change: bool = false) -> void:
	if current_phase == Phase.NIGHT:
		night_ended.emit(current_day)
	if _night_watch_active:
		var previous_scale := get_time_scale()
		_deactivate_night_watch()
		_emit_time_scale_changed(previous_scale)

	current_day = day
	current_phase = Phase.DAY
	phase_duration = maxf(_active_config.get_day_duration(day), MIN_PHASE_DURATION)
	phase_elapsed = clampf(elapsed, 0.0, phase_duration)
	_last_reported_second = -1

	if announce_change:
		day_changed.emit(current_day)
	day_started.emit(current_day)
	phase_changed.emit(current_phase)
	_report_time()


func _begin_night(elapsed: float = 0.0) -> void:
	_emit_dusk_if_due()
	current_phase = Phase.NIGHT
	phase_duration = maxf(_active_config.get_night_duration(current_day), MIN_PHASE_DURATION)
	phase_elapsed = clampf(elapsed, 0.0, phase_duration)
	_last_reported_second = -1

	night_started.emit(current_day)
	phase_changed.emit(current_phase)
	_report_time()


func _trigger_rescue() -> void:
	var previous_scale := get_time_scale()
	_deactivate_night_watch()
	rescue_triggered = true
	is_running = false
	phase_elapsed = phase_duration
	night_ended.emit(current_day)
	_report_time(true)
	_emit_time_scale_changed(previous_scale)
	rescue_started.emit()


func _report_time(force: bool = false) -> void:
	_emit_dusk_if_due()
	var remaining := get_remaining_seconds()
	var displayed_second := int(ceilf(remaining))
	if not force and displayed_second == _last_reported_second:
		return
	_last_reported_second = displayed_second
	time_updated.emit(current_day, current_phase, remaining)

class_name SplashSequencer
extends RefCounted

## Logika murni urutan layar pembuka (splash screen): fade-in, hold, fade-out,
## skip, smoothing progress bar, dan sinkronisasi dengan status load latar belakang.
## Tidak mengakses SceneTree; hanya memakai delta nyata.

enum State { PLAYING, WAITING_LOAD, DONE }

signal entry_started(index: int)
signal entry_finished(index: int)
signal finished(failed: bool)

var _config: SplashConfig
var _entries: Array[SplashEntry] = []
var _state: int = State.PLAYING
var _entry_index: int = -1
var _entry_elapsed: float = 0.0
var _entry_alpha: float = 0.0
var _entry_announced: bool = false
var _elapsed: float = 0.0
var _real_progress: float = 0.0
var _displayed_progress: float = 0.0
var _load_done: bool = false
var _load_failed: bool = false
var _failed: bool = false
var _bypass_min_total: bool = false


func setup(cfg: SplashConfig) -> void:
	_config = cfg if cfg != null else SplashConfig.new()
	_entries.clear()
	for item in _config.entries:
		if item != null:
			_entries.append(item)
	_state = State.PLAYING
	_entry_index = -1
	_entry_elapsed = 0.0
	_entry_alpha = 0.0
	_entry_announced = false
	_elapsed = 0.0
	_real_progress = 0.0
	_displayed_progress = 0.0
	_load_done = false
	_load_failed = false
	_failed = false
	_bypass_min_total = false

	if not _config.enabled or _entries.is_empty():
		_state = State.WAITING_LOAD
		_bypass_min_total = true
		return

	_entry_index = 0
	_entry_alpha = _compute_entry_alpha(_entries[0], 0.0)


## Lewati urutan logo dan min_total_seconds (dipakai untuk dev_skip / env / shown_this_session).
func force_skip_sequence() -> void:
	if _state == State.DONE:
		return
	_bypass_min_total = true
	if _state == State.PLAYING:
		if _entry_announced and _entry_index >= 0:
			entry_finished.emit(_entry_index)
		_entry_index = -1
		_entry_alpha = 0.0
		_entry_announced = false
		_state = State.WAITING_LOAD
	_check_completion()


func skip() -> void:
	if _config == null or _state != State.PLAYING:
		return
	if not _config.skip_enabled:
		return
	if _elapsed < maxf(_config.skip_min_seconds, 0.0):
		return
	if _entry_announced and _entry_index >= 0:
		entry_finished.emit(_entry_index)
	_entry_index = -1
	_entry_alpha = 0.0
	_entry_announced = false
	_state = State.WAITING_LOAD
	_check_completion()


func notify_load_progress(value: float) -> void:
	if _state == State.DONE:
		return
	var clamped := clampf(value, 0.0, 1.0)
	if not _load_done:
		clamped = minf(clamped, 0.99)
	_real_progress = maxf(_real_progress, clamped)


func notify_load_done(ok: bool) -> void:
	if _state == State.DONE:
		return
	if ok:
		_load_done = true
		_real_progress = 1.0
		_check_completion()
	else:
		_load_failed = true
		_finish(true)


func tick(delta: float) -> void:
	if _config == null or _state == State.DONE:
		return
	var step := maxf(delta, 0.0)
	_elapsed += step

	# Smoothing progress: tidak pernah turun, hanya menyentuh 1.0 setelah load_done(true).
	var speed := maxf(_config.bar_smooth_speed, 0.0)
	var target := _real_progress if _load_done else minf(_real_progress, 0.99)
	var next_progress := minf(target, _displayed_progress + speed * step)
	_displayed_progress = maxf(_displayed_progress, next_progress)

	if _config.max_wait_seconds > 0.0 and _elapsed >= _config.max_wait_seconds and not _load_done:
		_load_failed = true
		_finish(true)
		return

	if _state == State.PLAYING:
		_tick_playing(step)

	if _state == State.WAITING_LOAD:
		_check_completion()


# --- Getters ----------------------------------------------------------------

func state() -> int:
	return _state


func entry_index() -> int:
	return _entry_index


func entry_alpha() -> float:
	return _entry_alpha


func elapsed() -> float:
	return _elapsed


func progress_displayed() -> float:
	return _displayed_progress


func is_finished() -> bool:
	return _state == State.DONE


func failed() -> bool:
	return _failed


# --- Internal ---------------------------------------------------------------

func _tick_playing(step: float) -> void:
	if _entry_index < 0 or _entry_index >= _entries.size():
		_state = State.WAITING_LOAD
		_entry_index = -1
		_entry_alpha = 0.0
		return

	if not _entry_announced:
		_entry_announced = true
		entry_started.emit(_entry_index)

	_entry_elapsed += step
	while _state == State.PLAYING and _entry_index >= 0 and _entry_index < _entries.size():
		var current := _entries[_entry_index]
		var total := _entry_duration(current)
		if _entry_elapsed >= total:
			_entry_elapsed -= total
			var done_index := _entry_index
			_entry_announced = false
			entry_finished.emit(done_index)
			if _entry_index + 1 < _entries.size():
				_entry_index += 1
				_entry_announced = true
				entry_started.emit(_entry_index)
			else:
				_entry_index = -1
				_entry_alpha = 0.0
				_state = State.WAITING_LOAD
				break
		else:
			_entry_alpha = _compute_entry_alpha(current, _entry_elapsed)
			break


func _check_completion() -> void:
	if _state != State.WAITING_LOAD:
		return
	if _load_failed:
		_finish(true)
		return
	if not _load_done:
		return
	var min_total := maxf(_config.min_total_seconds, 0.0) if _config != null else 0.0
	if _bypass_min_total or _elapsed >= min_total:
		_displayed_progress = 1.0
		_finish(false)


func _finish(did_fail: bool) -> void:
	if _state == State.DONE:
		return
	_state = State.DONE
	_failed = did_fail
	_entry_index = -1
	_entry_alpha = 0.0
	finished.emit(did_fail)


func _entry_duration(entry: SplashEntry) -> float:
	return maxf(entry.fade_in, 0.0) + maxf(entry.hold_seconds, 0.0) + maxf(entry.fade_out, 0.0)


func _compute_entry_alpha(entry: SplashEntry, t: float) -> float:
	var fade_in := maxf(entry.fade_in, 0.0)
	var hold := maxf(entry.hold_seconds, 0.0)
	var fade_out := maxf(entry.fade_out, 0.0)
	if fade_in > 0.0 and t < fade_in:
		return clampf(t / fade_in, 0.0, 1.0)
	if t < fade_in + hold:
		return 1.0
	if fade_out > 0.0 and t < fade_in + hold + fade_out:
		return clampf(1.0 - (t - fade_in - hold) / fade_out, 0.0, 1.0)
	return 0.0

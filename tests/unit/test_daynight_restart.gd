extends GutTest

const MANAGER_SCRIPT := preload("res://src/core/managers/day_night_manager.gd")

var _clock: Node


func before_each() -> void:
	_clock = MANAGER_SCRIPT.new()
	_clock.auto_start = false
	_clock.name = "DayNightManager"
	add_child_autofree(_clock)


func test_restart_returns_to_day_one_daytime() -> void:
	_clock.start()
	_clock.advance(400.0)
	assert_eq(_clock.get_phase(), 1, "sudah masuk malam")

	_clock.restart()
	assert_eq(_clock.get_current_day(), 1)
	assert_eq(_clock.get_phase(), 0)
	assert_almost_eq(_clock.get_phase_elapsed(), 0.0, 0.001)
	assert_false(_clock.rescue_triggered)


func test_restart_clears_time_scale_and_night_watch() -> void:
	_clock.start()
	_clock.advance(400.0)
	_clock.set_night_watch(true)
	assert_true(_clock.is_night_watch_active())
	_clock.set_time_scale(0.0)

	_clock.restart()
	assert_false(_clock.is_night_watch_active())
	assert_almost_eq(_clock.get_time_scale(), _clock.get_config().time_scale, 0.001)


func test_restart_emits_fresh_start_signals() -> void:
	_clock.start()
	watch_signals(_clock)
	_clock.restart()
	assert_signal_emitted(_clock, "started")
	assert_signal_emitted(_clock, "day_started")
	assert_signal_emitted(_clock, "phase_changed")


func test_restart_after_rescue_starts_the_clock_again() -> void:
	_clock.start()
	var guard := 0
	while not _clock.rescue_triggered and guard < 60:
		_clock.skip_time(_clock.get_remaining_seconds() + 0.01)
		guard += 1
	assert_true(_clock.rescue_triggered)
	assert_almost_eq(_clock.get_time_scale(), 0.0, 0.001)

	_clock.restart()
	assert_false(_clock.rescue_triggered)
	assert_eq(_clock.get_current_day(), 1)
	assert_almost_eq(_clock.get_time_scale(), _clock.get_config().time_scale, 0.001)

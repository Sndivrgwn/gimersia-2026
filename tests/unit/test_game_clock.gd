extends GutTest

## Tes GameClock (DayNightManager) untuk Bagian 1.D, 1.C, 1.F, dan 3.C.
##
## Instance dibuat langsung dengan config 600 detik agar tes tidak bergantung
## pada .tres debug yang sedang dipakai scene. _process dimatikan supaya waktu
## tidak berjalan sendiri di antara assertion; semua langkah memakai advance().

const DayNightManagerScript = preload("res://src/core/managers/day_night_manager.gd")

var clock: DayNightManagerScript
var config: DayNightConfig

var _dusk_count: int = 0
var _dusk_day: int = -1
var _dusk_phase: int = -1
var _last_skipped: float = -1.0
var _last_time_scale: float = -1.0
var _signal_order: Array[String] = []


func before_each() -> void:
	config = DayNightConfig.new()
	config.max_days = 7
	config.cycle_duration = 600.0
	config.time_scale = 1.0

	var periods: Array[DayNightPeriod] = [
		_make_period(1, 3, 0.5),
		_make_period(4, 5, 0.4),
		_make_period(6, 7, 0.3),
	]
	config.periods = periods

	clock = DayNightManagerScript.new()
	clock.config = config
	clock.use_debug_config = false
	clock.auto_start = false
	add_child_autofree(clock)
	clock.set_process(false)

	_dusk_count = 0
	_dusk_day = -1
	_dusk_phase = -1
	_last_skipped = -1.0
	_last_time_scale = -1.0
	_signal_order.clear()

	clock.dusk_started.connect(_on_dusk_started)
	clock.time_skipped.connect(_on_time_skipped)
	clock.time_scale_changed.connect(_on_time_scale_changed)
	clock.night_ended.connect(_on_night_ended)
	clock.day_started.connect(_on_day_started)

	clock.start()


func _make_period(first_day: int, last_day: int, day_ratio: float) -> DayNightPeriod:
	var period := DayNightPeriod.new()
	period.first_day = first_day
	period.last_day = last_day
	period.day_ratio = day_ratio
	return period


func _on_dusk_started(day: int) -> void:
	_dusk_count += 1
	_dusk_day = day
	_dusk_phase = clock.current_phase


func _on_time_skipped(seconds: float) -> void:
	_last_skipped = seconds


func _on_time_scale_changed(scale: float) -> void:
	_last_time_scale = scale


func _on_night_ended(day: int) -> void:
	_signal_order.append("night_ended_%d" % day)


func _on_day_started(day: int) -> void:
	_signal_order.append("day_started_%d" % day)


# --- A. Data & jadwal -------------------------------------------------------

func test_durations_match_spec() -> void:
	assert_eq(clock.get_max_days(), 7)
	assert_true(clock.get_config() == config, "config aktif harus config buatan tes")

	assert_almost_eq(clock.get_day_duration(1), 300.0, 0.001)
	assert_almost_eq(clock.get_night_duration(1), 300.0, 0.001)
	assert_almost_eq(clock.get_day_duration(3), 300.0, 0.001)
	assert_almost_eq(clock.get_night_duration(3), 300.0, 0.001)

	assert_almost_eq(clock.get_day_duration(4), 240.0, 0.001)
	assert_almost_eq(clock.get_night_duration(4), 360.0, 0.001)
	assert_almost_eq(clock.get_day_duration(5), 240.0, 0.001)
	assert_almost_eq(clock.get_night_duration(5), 360.0, 0.001)

	assert_almost_eq(clock.get_day_duration(6), 180.0, 0.001)
	assert_almost_eq(clock.get_night_duration(6), 420.0, 0.001)
	assert_almost_eq(clock.get_day_duration(7), 180.0, 0.001)
	assert_almost_eq(clock.get_night_duration(7), 420.0, 0.001)


func test_total_game_duration_is_4200() -> void:
	var total := 0.0
	for day in range(1, 8):
		total += clock.get_day_duration(day)
		total += clock.get_night_duration(day)

	assert_almost_eq(total, 4200.0, 0.001)
	assert_almost_eq(clock.get_total_elapsed_seconds(), 0.0, 0.001)


# --- B. Alur waktu ----------------------------------------------------------

func test_start_state_and_manual_advance() -> void:
	assert_eq(clock.current_day, 1)
	assert_eq(clock.get_current_day(), 1)
	assert_eq(clock.current_phase, DayNightManagerScript.Phase.DAY)
	assert_eq(clock.get_phase(), DayNightManagerScript.Phase.DAY)
	assert_true(clock.is_day())
	assert_almost_eq(clock.get_remaining_seconds(), 300.0, 0.001)
	assert_almost_eq(clock.get_phase_progress(), 0.0, 0.001)

	clock.advance(45.0)
	assert_almost_eq(clock.get_phase_elapsed(), 45.0, 0.001)
	assert_almost_eq(clock.get_total_elapsed_seconds(), 45.0, 0.001)


func test_advance_carries_one_boundary() -> void:
	clock.advance(310.0)

	assert_eq(clock.current_day, 1)
	assert_eq(clock.current_phase, DayNightManagerScript.Phase.NIGHT)
	assert_true(clock.is_night())
	assert_almost_eq(clock.get_phase_elapsed(), 10.0, 0.001)
	assert_almost_eq(clock.get_total_elapsed_seconds(), 310.0, 0.001)


func test_advance_carries_multiple_phases() -> void:
	clock.advance(605.0)

	assert_eq(clock.current_day, 2)
	assert_true(clock.is_day())
	assert_almost_eq(clock.get_phase_elapsed(), 5.0, 0.001)
	assert_almost_eq(clock.get_total_elapsed_seconds(), 605.0, 0.001)


func test_start_resets_to_day_one() -> void:
	clock.advance(1000.0)

	watch_signals(clock)
	clock.start()

	assert_eq(clock.current_day, 1)
	assert_true(clock.is_day())
	assert_almost_eq(clock.get_phase_elapsed(), 0.0, 0.001)
	assert_almost_eq(clock.get_total_elapsed_seconds(), 0.0, 0.001)
	assert_signal_emitted(clock, "started")


func test_pause_uses_pausable_process_mode() -> void:
	assert_eq(clock.process_mode, Node.PROCESS_MODE_PAUSABLE)


# --- C. Senja ---------------------------------------------------------------

func test_dusk_emits_at_fifteen_seconds_once() -> void:
	clock.advance(285.0)

	assert_eq(_dusk_count, 1)
	assert_eq(_dusk_day, 1)
	assert_eq(_dusk_phase, DayNightManagerScript.Phase.DAY)
	assert_almost_eq(clock.get_remaining_seconds(), 15.0, 0.001)

	clock.advance(1.0)
	clock.advance(1.0)
	assert_eq(_dusk_count, 1)


func test_dusk_emits_before_a_big_jump_to_night() -> void:
	clock.advance(400.0)

	assert_eq(_dusk_count, 1)
	assert_eq(_dusk_day, 1)
	assert_eq(_dusk_phase, DayNightManagerScript.Phase.DAY)
	assert_eq(clock.current_phase, DayNightManagerScript.Phase.NIGHT)


func test_dusk_emits_once_per_day() -> void:
	clock.advance(285.0)
	assert_eq(_dusk_count, 1)

	clock.advance(15.0)
	clock.advance(300.0)
	assert_eq(clock.current_day, 2)

	clock.advance(285.0)
	assert_eq(_dusk_count, 2)
	assert_eq(_dusk_day, 2)


# --- D. Night Watch ---------------------------------------------------------

func test_night_watch_requires_night_and_doubles_time() -> void:
	clock.set_night_watch(true)
	assert_false(clock.is_night_watch_active())
	assert_almost_eq(clock.get_time_scale(), 1.0, 0.001)

	clock.advance(300.0)
	assert_true(clock.is_night())

	watch_signals(clock)
	clock.set_night_watch(true)

	assert_true(clock.is_night_watch_active())
	assert_almost_eq(clock.get_time_scale(), 2.0, 0.001)
	assert_almost_eq(_last_time_scale, 2.0, 0.001)
	assert_signal_emitted(clock, "night_watch_changed")
	assert_signal_emitted(clock, "time_scale_changed")

	clock.advance(10.0)
	assert_almost_eq(clock.get_phase_elapsed(), 20.0, 0.001)


func test_night_watch_stops_at_dawn() -> void:
	clock.advance(300.0)
	clock.set_night_watch(true)
	assert_true(clock.is_night_watch_active())

	watch_signals(clock)
	clock.advance(150.0)

	assert_eq(clock.current_day, 2)
	assert_true(clock.is_day())
	assert_false(clock.is_night_watch_active())
	assert_almost_eq(clock.get_time_scale(), 1.0, 0.001)
	assert_signal_emitted(clock, "night_watch_changed")
	assert_signal_emitted(clock, "night_ended")


func test_time_scale_change_signal() -> void:
	watch_signals(clock)

	clock.set_time_scale(2.0)
	assert_almost_eq(clock.get_time_scale(), 2.0, 0.001)
	assert_almost_eq(_last_time_scale, 2.0, 0.001)
	assert_signal_emitted(clock, "time_scale_changed")

	clock.set_time_scale(1.0)
	assert_almost_eq(clock.get_time_scale(), 1.0, 0.001)
	assert_almost_eq(_last_time_scale, 1.0, 0.001)


# --- E. Skip time -----------------------------------------------------------

func test_skip_time_ignores_night_watch() -> void:
	clock.advance(300.0)
	clock.set_night_watch(true)
	assert_almost_eq(clock.get_time_scale(), 2.0, 0.001)

	watch_signals(clock)
	clock.skip_time(45.0)

	assert_almost_eq(clock.get_phase_elapsed(), 45.0, 0.001)
	assert_almost_eq(clock.get_time_scale(), 2.0, 0.001)
	assert_almost_eq(_last_skipped, 45.0, 0.001)
	assert_signal_emitted(clock, "time_skipped")


func test_skip_time_crosses_a_phase_boundary() -> void:
	clock.skip_time(305.0)

	assert_eq(clock.current_day, 1)
	assert_eq(clock.current_phase, DayNightManagerScript.Phase.NIGHT)
	assert_almost_eq(clock.get_phase_elapsed(), 5.0, 0.001)
	assert_almost_eq(_last_skipped, 305.0, 0.001)


# --- F. Hari terakhir -------------------------------------------------------

func test_final_dawn_freezes_clock_and_caps_skip() -> void:
	watch_signals(clock)
	clock.skip_time(5000.0)

	assert_eq(clock.current_day, 7)
	assert_eq(clock.current_phase, DayNightManagerScript.Phase.NIGHT)
	assert_almost_eq(clock.get_remaining_seconds(), 0.0, 0.001)
	assert_true(clock.rescue_triggered)
	assert_false(clock.is_running)
	assert_almost_eq(clock.get_time_scale(), 0.0, 0.001)
	assert_almost_eq(_last_skipped, 4200.0, 0.001)
	assert_almost_eq(_last_time_scale, 0.0, 0.001)
	assert_almost_eq(clock.get_total_elapsed_seconds(), 4200.0, 0.001)
	assert_signal_emitted(clock, "rescue_started")
	assert_signal_emitted(clock, "night_ended")

	var elapsed_before := clock.get_total_elapsed_seconds()
	clock.skip_time(45.0)
	clock.advance(10.0)
	assert_almost_eq(clock.get_total_elapsed_seconds(), elapsed_before, 0.001)


func test_night_ended_precedes_new_day() -> void:
	_signal_order.clear()
	clock.advance(600.0)

	assert_eq(_signal_order.size(), 2)
	assert_eq(_signal_order[0], "night_ended_1")
	assert_eq(_signal_order[1], "day_started_2")


# --- Getter teks ------------------------------------------------------------

func test_remaining_text_format() -> void:
	assert_eq(clock.get_remaining_text(), "05:00")
	clock.advance(45.0)
	assert_eq(clock.get_remaining_text(), "04:15")

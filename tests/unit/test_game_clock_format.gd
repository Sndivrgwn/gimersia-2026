extends GutTest

## Mission 12: jam dunia nyata. Fungsi murni, getter manager (tanpa mengubah
## siklus), sinyal hour_changed, HUD, toast tidur, dan debug jump.

const FORMAT: ClockFormatConfig = preload("res://src/data/configs/environment/clock_format.tres")
const MANAGER_SCRIPT := preload("res://src/core/managers/day_night_manager.gd")
const TIME_HUD_SCENE: PackedScene = preload("res://src/ui/hud/time/time_hud.tscn")


class StubClock extends Node:
	var night := true
	var hour := 22.2333333
	var day := 3
	var remaining := 90.0
	var duration := 300.0

	func is_night() -> bool:
		return night

	func is_day() -> bool:
		return not night

	func get_current_day() -> int:
		return day

	func get_max_days() -> int:
		return 7

	func get_clock_hour() -> float:
		return hour

	func get_clock_text() -> String:
		return GameClockFormat.text(hour, true, 1)

	func get_clock_period() -> String:
		return GameClockFormat.period_of(hour, FORMAT)

	func get_clock_format() -> ClockFormatConfig:
		return FORMAT

	func get_phase_progress() -> float:
		return 0.5

	func get_phase_duration() -> float:
		return duration

	func get_remaining_seconds() -> float:
		return remaining


# --- Fungsi murni -----------------------------------------------------------

func test_day_maps_six_to_eighteen() -> void:
	assert_almost_eq(GameClockFormat.hour_of(true, 0.0, FORMAT), 6.0, 0.001)
	assert_almost_eq(GameClockFormat.hour_of(true, 0.5, FORMAT), 12.0, 0.001)
	assert_almost_eq(GameClockFormat.hour_of(true, 1.0, FORMAT), 18.0, 0.001)


func test_night_wraps_past_midnight() -> void:
	assert_almost_eq(GameClockFormat.hour_of(false, 0.0, FORMAT), 18.0, 0.001)
	assert_almost_eq(GameClockFormat.hour_of(false, 0.5, FORMAT), 0.0, 0.001, "tengah malam")
	assert_almost_eq(GameClockFormat.hour_of(false, 1.0, FORMAT), 6.0, 0.001, "fajar")


func test_custom_start_hours_and_clamping() -> void:
	var custom := ClockFormatConfig.new()
	custom.day_start_hour = 8.0
	custom.night_start_hour = 20.0
	assert_almost_eq(GameClockFormat.hour_of(true, 0.0, custom), 8.0, 0.001)
	assert_almost_eq(GameClockFormat.hour_of(true, 1.0, custom), 20.0, 0.001)
	assert_almost_eq(GameClockFormat.hour_of(false, 1.0, custom), 8.0, 0.001)
	assert_almost_eq(GameClockFormat.hour_of(true, -3.0, FORMAT), 6.0, 0.001, "progress dijepit")
	assert_almost_eq(GameClockFormat.hour_of(false, 7.0, FORMAT), 6.0, 0.001, "progress dijepit")


func test_text_formats() -> void:
	assert_eq(GameClockFormat.text(6.0, true, 1), "06:00")
	assert_eq(GameClockFormat.text(18.5, true, 1), "18:30")
	assert_eq(GameClockFormat.text(24.0, true, 1), "00:00")
	assert_eq(GameClockFormat.text(0.25, false, 1), "12:15 AM")
	assert_eq(GameClockFormat.text(13.5, false, 1), "01:30 PM")
	assert_eq(GameClockFormat.text(12.0, false, 1), "12:00 PM")


func test_minute_step_floors() -> void:
	assert_eq(GameClockFormat.text(14.0 + 59.0 / 60.0, true, 15), "14:45")
	assert_eq(GameClockFormat.text(6.0 + 10.0 / 60.0, true, 30), "06:00")
	assert_eq(GameClockFormat.text(6.0 + 45.0 / 60.0, true, 30), "06:30")


func test_period_names_at_every_boundary() -> void:
	assert_eq(GameClockFormat.period_of(5.0, FORMAT), "Pagi")
	assert_eq(GameClockFormat.period_of(6.0, FORMAT), "Pagi")
	assert_eq(GameClockFormat.period_of(9.99, FORMAT), "Pagi")
	assert_eq(GameClockFormat.period_of(10.0, FORMAT), "Siang")
	assert_eq(GameClockFormat.period_of(15.0, FORMAT), "Sore")
	assert_eq(GameClockFormat.period_of(18.0, FORMAT), "Malam")
	assert_eq(GameClockFormat.period_of(23.9, FORMAT), "Malam")
	assert_eq(GameClockFormat.period_of(0.0, FORMAT), "Malam", "Malam mencakup 00:00-05:00")
	assert_eq(GameClockFormat.period_of(4.99, FORMAT), "Malam")


func test_hours_between_wraps() -> void:
	assert_almost_eq(GameClockFormat.hours_between(6.0, 18.0), 12.0, 0.001)
	assert_almost_eq(GameClockFormat.hours_between(18.0, 6.0), 12.0, 0.001)
	assert_almost_eq(GameClockFormat.hours_between(22.0, 5.0), 7.0, 0.001)
	assert_almost_eq(GameClockFormat.hours_between(5.0, 5.0), 0.0, 0.001)


func test_seconds_until_hour_uses_the_phase_speed() -> void:
	# Hari 300 dtk = 12 jam dinding -> 25 dtk per jam.
	assert_almost_eq(GameClockFormat.seconds_until_hour(10.0, true, 0.0, 300.0, FORMAT), 100.0, 0.01)
	assert_almost_eq(GameClockFormat.seconds_until_hour(18.0, true, 0.0, 300.0, FORMAT), 300.0, 0.01)
	# Malam 300 dtk juga 12 jam dinding.
	assert_almost_eq(GameClockFormat.seconds_until_hour(0.0, false, 0.0, 300.0, FORMAT), 150.0, 0.01)
	assert_almost_eq(GameClockFormat.seconds_until_hour(6.0, false, 0.0, 300.0, FORMAT), 300.0, 0.01)


func test_next_period_start_uses_sunrise_for_pagi() -> void:
	assert_almost_eq(GameClockFormat.next_period_start_hour(6.0, FORMAT), 10.0, 0.001)
	assert_almost_eq(GameClockFormat.next_period_start_hour(9.0, FORMAT), 10.0, 0.001)
	assert_almost_eq(GameClockFormat.next_period_start_hour(16.0, FORMAT), 18.0, 0.001)
	assert_almost_eq(GameClockFormat.next_period_start_hour(18.0, FORMAT), 6.0, 0.001, "Malam -> terbit")
	assert_almost_eq(GameClockFormat.next_period_start_hour(0.0, FORMAT), 6.0, 0.001)


func test_sleep_toast_text() -> void:
	assert_eq(GameClockFormat.sleep_toast_text(22.0 + 10.0 / 60.0, 5.0 + 20.0 / 60.0, FORMAT),
		"Tidur: 22:10 -> 05:20")


# --- Manager ----------------------------------------------------------------

func _clock(day_ratio: float) -> Node:
	var config := DayNightConfig.new()
	config.cycle_duration = 600.0
	config.max_days = 7
	var period := DayNightPeriod.new()
	period.first_day = 1
	period.last_day = 7
	period.day_ratio = day_ratio
	var periods: Array[DayNightPeriod] = [period]
	config.periods = periods
	var clock: Node = MANAGER_SCRIPT.new()
	clock.auto_start = false
	clock.config = config
	clock.clock_format = FORMAT
	clock.start()
	autofree(clock)
	return clock


func test_clock_shows_fixed_hours_for_every_day_ratio() -> void:
	for ratio in [0.5, 0.6, 0.7]:
		var clock := _clock(ratio)
		assert_almost_eq(clock.get_clock_hour(), 6.0, 0.001, "ratio %s: mulai terbit" % ratio)
		assert_eq(clock.get_clock_text(), "06:00")
		clock.skip_time(clock.get_day_duration())
		assert_almost_eq(clock.get_clock_hour(), 18.0, 0.001, "ratio %s: mulai terbenam" % ratio)
		assert_eq(clock.get_clock_text(), "18:00")


func test_clock_speed_matches_phase_length() -> void:
	var clock := _clock(0.5)
	assert_almost_eq(GameClockFormat.seconds_per_hour(true, clock.get_phase_duration(), FORMAT), 25.0, 0.01)
	clock.skip_time(25.0)
	assert_almost_eq(clock.get_clock_hour(), 7.0, 0.001, "25 dtk = 1 jam game")
	var short_day := _clock(0.3)
	assert_almost_eq(GameClockFormat.seconds_per_hour(true, short_day.get_phase_duration(), FORMAT), 15.0, 0.01)


func test_hour_changed_once_per_hour() -> void:
	var clock := _clock(0.5)
	var hours: Array[int] = []
	clock.hour_changed.connect(func(hour: int) -> void: hours.append(hour))
	clock.advance(25.0)
	assert_eq(hours, [7], "satu jam = satu sinyal")
	clock.advance(10.0)
	assert_eq(hours, [7], "belum ganti jam")
	clock.advance(20.0)
	assert_eq(hours, [7, 8])


func test_hour_changed_once_after_skip_and_restart() -> void:
	var clock := _clock(0.5)
	var hours: Array[int] = []
	clock.hour_changed.connect(func(hour: int) -> void: hours.append(hour))
	clock.skip_time(clock.get_day_duration())
	assert_eq(hours, [18], "satu lompatan = satu sinyal (jam akhir)")
	hours.clear()
	clock.restart()
	assert_eq(hours, [6], "restart memancarkan jam 06:00 sekali")


func test_no_hour_signal_while_frozen() -> void:
	var clock := _clock(0.5)
	clock.set_time_scale(0.0)
	var hours: Array[int] = []
	clock.hour_changed.connect(func(hour: int) -> void: hours.append(hour))
	clock.advance(120.0)
	assert_eq(hours.size(), 0, "skala 0: jam tidak berubah, tidak ada sinyal")
	assert_almost_eq(clock.get_clock_hour(), 6.0, 0.001)


func test_night_watch_doubles_the_clock_rate() -> void:
	var normal := _clock(0.5)
	normal.skip_time(normal.get_day_duration())
	var before_normal: float = normal.get_clock_hour()
	normal.advance(25.0)
	var delta_normal := GameClockFormat.hours_between(before_normal, float(normal.get_clock_hour()))

	var watched := _clock(0.5)
	watched.skip_time(watched.get_day_duration())
	watched.set_night_watch(true)
	var before_watched: float = watched.get_clock_hour()
	watched.advance(25.0)
	var delta_watched := GameClockFormat.hours_between(before_watched, float(watched.get_clock_hour()))

	assert_almost_eq(delta_watched, delta_normal * 2.0, 0.01, "Jaga Malam x2")


func test_final_dawn_holds_six_am() -> void:
	var clock := _clock(0.5)
	for step in 30:
		if bool(clock.rescue_triggered):
			break
		clock.skip_time(clock.get_remaining_seconds())
	assert_true(clock.rescue_triggered)
	assert_almost_eq(clock.get_clock_hour(), 6.0, 0.001, "fajar terakhir membeku di 06:00")
	assert_eq(clock.get_clock_text(), "06:00")


func test_existing_signals_are_unchanged() -> void:
	var clock := _clock(0.5)
	var events: Array[String] = []
	clock.day_started.connect(func(day: int) -> void: events.append("day_%d" % day))
	clock.night_started.connect(func(day: int) -> void: events.append("night_%d" % day))
	clock.phase_changed.connect(func(phase: int) -> void: events.append("phase_%d" % phase))
	clock.time_updated.connect(func(day: int, phase: int, remaining: float) -> void:
		events.append("tick_%d_%d" % [day, int(remaining)]))
	clock.skip_time(clock.get_day_duration())
	assert_true(events.has("night_1"), "night_started tetap ada")
	assert_true(events.has("phase_1"), "phase_changed tetap ada")
	assert_true(events.has("tick_1_300"), "time_updated membawa sisa detik fase")
	assert_eq(clock.get_phase(), DayNightManager.Phase.NIGHT)


# --- HUD & debug ------------------------------------------------------------

func test_night_survival_hud_shows_clock_and_dawn_countdown() -> void:
	var clock := StubClock.new()
	add_child_autofree(clock)
	var hud := NightSurvivalHUD.new()
	add_child_autofree(hud)
	hud.clock = clock
	hud.set_day(3)
	hud.set_remaining(90.0)
	hud.tick(0.0)
	assert_string_contains(hud.get_text(), "Malam 3 | 22:14 | Fajar dalam 01:30")


func test_time_hud_shows_clock_period_and_day() -> void:
	var hud := TIME_HUD_SCENE.instantiate()
	add_child_autofree(hud)
	await wait_frames(1)
	var clock := StubClock.new()
	add_child_autofree(clock)
	hud.set("_manager", clock)
	hud.call("_refresh", 3, 90.0)
	assert_eq(hud.get_node("Root/Panel/Margin/VBox/ClockLabel").text, "22:14")
	assert_eq(hud.get_node("Root/Panel/Margin/VBox/PhaseLabel").text, "Malam")
	assert_eq(hud.get_node("Root/Panel/Margin/VBox/DayLabel").text, "Hari 3 / 7")
	assert_true(hud.get_node("Root/Panel/Margin/VBox/RemainingLabel").visible, "malam: hitung mundur tampil")


func test_sun_arc_follows_the_clock() -> void:
	var arc := SunArc.new()
	add_child_autofree(arc)
	arc.set_clock_hour(6.0, true, FORMAT)
	assert_almost_eq(arc.get_phase(), 0.0, 0.001, "terbit")
	arc.set_clock_hour(12.0, true, FORMAT)
	assert_almost_eq(arc.get_phase(), 0.5, 0.001, "tengah hari")
	assert_false(arc.is_night())
	arc.set_clock_hour(0.0, false, FORMAT)
	assert_almost_eq(arc.get_phase(), 0.5, 0.001, "tengah malam")
	assert_true(arc.is_night())
	# Tepat di batas fase (18:00 masih siang) glyph tetap di ujung busur, tidak
	# melompat balik ke awal karena selisih jamnya 0.
	arc.set_clock_hour(18.0, true, FORMAT, 1.0)
	assert_almost_eq(arc.get_phase(), 1.0, 0.001, "senja tepat 18:00")
	arc.set_clock_hour(6.0, false, FORMAT, 1.0)
	assert_almost_eq(arc.get_phase(), 1.0, 0.001, "fajar tepat 06:00")


func test_debug_jump_lands_exactly_on_the_period_hour() -> void:
	var clock := _clock(0.5)
	var target := GameClockFormat.next_period_start_hour(clock.get_clock_hour(), FORMAT)
	assert_almost_eq(target, 10.0, 0.001, "dari 06:00 berikutnya Siang")
	var seconds: float = GameClockFormat.seconds_until_hour(
		target, clock.is_day(), clock.get_phase_progress(), clock.get_phase_duration(), FORMAT
	)
	clock.skip_time(seconds)
	assert_almost_eq(clock.get_clock_hour(), 10.0, 0.001, "mendarat tepat di 10:00")

	# Target di fase berikutnya: habiskan fase, lalu hitung lagi.
	var night_target := GameClockFormat.next_period_start_hour(clock.get_clock_hour(), FORMAT)
	assert_almost_eq(night_target, 15.0, 0.001)
	var to_night: float = GameClockFormat.seconds_until_hour(
		night_target, clock.is_day(), clock.get_phase_progress(), clock.get_phase_duration(), FORMAT
	)
	clock.skip_time(to_night)
	assert_almost_eq(clock.get_clock_hour(), 15.0, 0.001)
	var morning := GameClockFormat.next_period_start_hour(clock.get_clock_hour(), FORMAT)
	assert_almost_eq(morning, 18.0, 0.001)
	clock.skip_time(clock.get_remaining_seconds())
	assert_almost_eq(clock.get_clock_hour(), 18.0, 0.001, "Malam mulai 18:00")
	clock.skip_time(clock.get_remaining_seconds())
	assert_almost_eq(clock.get_clock_hour(), 6.0, 0.001, "Malam -> fajar 06:00")

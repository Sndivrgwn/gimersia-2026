extends GutTest

## Transisi siang/sore/malam: jendela transisi dimulai saat sisa fase tinggal
## `transition_duration`, arah matahari, dan kegelapan untuk cahaya api.

const VISUAL_CONFIG := preload("res://src/data/configs/environment/day_night_visual_default.tres")


func test_transition_progress_uses_remaining_time() -> void:
	assert_almost_eq(DayLightCurve.transition_progress(60.0, 60.0), 0.0, 0.001, "menit ke-5 siang: belum transisi")
	assert_almost_eq(DayLightCurve.transition_progress(30.0, 60.0), 0.5, 0.001)
	assert_almost_eq(DayLightCurve.transition_progress(0.0, 60.0), 1.0, 0.001, "tepat saat fase berganti")
	assert_almost_eq(DayLightCurve.transition_progress(5.0, 0.0), 1.0, 0.001)


func test_dusk_runs_through_the_last_minute_of_day() -> void:
	assert_almost_eq(DayLightCurve.darkness(false, 120.0, 60.0), 0.0, 0.001, "menit ke-4 belum gelap")
	assert_almost_eq(DayLightCurve.darkness(false, 60.0, 60.0), 0.0, 0.001)
	assert_almost_eq(DayLightCurve.darkness(false, 30.0, 60.0), 0.5, 0.001)
	assert_almost_eq(DayLightCurve.darkness(false, 0.0, 60.0), 1.0, 0.001, "malam mulai tepat di menit ke-5")


func test_dawn_ends_exactly_when_day_starts() -> void:
	assert_almost_eq(DayLightCurve.darkness(true, 120.0, 60.0), 1.0, 0.001)
	assert_almost_eq(DayLightCurve.darkness(true, 30.0, 60.0), 0.5, 0.001)
	assert_almost_eq(DayLightCurve.darkness(true, 0.0, 60.0), 0.0, 0.001, "pagi mulai terang")


func test_blend_reaches_waypoint_at_midpoint() -> void:
	var day := Color(1.0, 1.0, 1.0)
	var evening := Color(1.0, 0.5, 0.2)
	var night := Color(0.2, 0.2, 0.4)
	_assert_color(DayLightCurve.blend_through(day, evening, night, 0.0), day)
	_assert_color(DayLightCurve.blend_through(day, evening, night, 0.5), evening)
	_assert_color(DayLightCurve.blend_through(day, evening, night, 1.0), night)


func _assert_color(actual: Color, expected: Color) -> void:
	assert_almost_eq(actual.r, expected.r, 0.001)
	assert_almost_eq(actual.g, expected.g, 0.001)
	assert_almost_eq(actual.b, expected.b, 0.001)


func test_sun_direction_crosses_the_sky() -> void:
	var sunrise := DayLightCurve.sun_direction(0.0)
	var noon := DayLightCurve.sun_direction(0.5)
	var sunset := DayLightCurve.sun_direction(1.0)
	assert_almost_eq(sunrise.x, -1.0, 0.001, "matahari terbit di kiri")
	assert_almost_eq(sunrise.y, 0.0, 0.001)
	assert_almost_eq(noon.x, 0.0, 0.001)
	assert_almost_eq(noon.y, -1.0, 0.001, "tengah hari di atas")
	assert_almost_eq(sunset.x, 1.0, 0.001, "terbenam di kanan")
	assert_almost_eq(sunset.y, 0.0, 0.001)


func test_default_cycle_uses_one_game_minute_of_transition() -> void:
	assert_almost_eq(VISUAL_CONFIG.transition_duration, 60.0, 0.001, "satu menit game untuk siklus 600 dtk")
	assert_almost_eq(DayLightCurve.luminance(Color(1.0, 1.0, 1.0)), 1.0, 0.001)


func test_darkness_from_luminance_is_clamped() -> void:
	assert_almost_eq(DayLightCurve.darkness_from_luminance(0.95, 0.95, 0.24), 0.0, 0.001)
	assert_almost_eq(DayLightCurve.darkness_from_luminance(0.24, 0.95, 0.24), 1.0, 0.001)
	assert_almost_eq(DayLightCurve.darkness_from_luminance(0.1, 0.95, 0.24), 1.0, 0.001)
	assert_almost_eq(DayLightCurve.darkness_from_luminance(1.0, 0.95, 0.24), 0.0, 0.001)

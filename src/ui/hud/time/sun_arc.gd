class_name SunArc
extends Control

## Mission 13: arc matahari/bulan kecil di TimeHUD (read-only).
##
## Glyph bergerak di sepanjang busur setengah lingkaran mengikuti fase hari:
## terbit di sisi `dawn_side`, di puncak saat tengah fase, dan turun di sisi
## seberang. Malam memakai busur yang sama untuk bulan. Bentuk placeholder
## digambar di _draw(); art opsional dibaca dari slot `ui_sun` / `ui_moon`.

const SUN_COLOR := Color(1.0, 0.86, 0.45, 1.0)
const MOON_COLOR := Color(0.82, 0.88, 1.0, 1.0)
const ARC_COLOR := Color(1.0, 1.0, 1.0, 0.22)
const GLYPH_RADIUS := 5.0
const ARC_STEPS := 24

var _progress: float = 0.0
var _is_night: bool = false
var _dawn_side: int = SunConfig.Side.RIGHT
var _sun_texture: Texture2D
var _moon_texture: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Slot jam (Mission 12) lebih dulu, lalu slot arc lama sebagai cadangan.
	_sun_texture = Assets.ui_texture(&"ui_clock_sun")
	if _sun_texture == null:
		_sun_texture = Assets.ui_texture(&"ui_sun")
	_moon_texture = Assets.ui_texture(&"ui_clock_moon")
	if _moon_texture == null:
		_moon_texture = Assets.ui_texture(&"ui_moon")


## Posisi glyph dari jam dinding: terbit di day_start_hour, terbenam di
## night_start_hour (Mission 12).
## `phase_progress` opsional (0..1) dipakai sebagai tie-breaker tepat di batas
## fase: saat jam baru menyentuh 18:00/06:00 selisih jamnya 0, sehingga tanpa
## ini glyph akan melompat balik ke awal busur selama satu frame.
func set_clock_hour(hour: float, is_day: bool, config: ClockFormatConfig, phase_progress: float = -1.0) -> void:
	var day_start := 6.0
	var night_start := 18.0
	if config != null:
		day_start = config.day_start_hour
		night_start = config.night_start_hour
	var span := GameClockFormat.hours_in_phase(is_day, config)
	var start := day_start if is_day else night_start
	var progress := 0.0
	if span > 0.0:
		progress = fposmod(hour - start, 24.0) / span
	if phase_progress >= 0.0 and (progress > 1.0 or (is_zero_approx(progress) and phase_progress > 0.5)):
		progress = phase_progress
	set_phase(clampf(progress, 0.0, 1.0), not is_day)


func set_dawn_side(side: int) -> void:
	_dawn_side = side
	queue_redraw()


func set_phase(day_progress: float, is_night: bool) -> void:
	var clamped := clampf(day_progress, 0.0, 1.0)
	if is_equal_approx(clamped, _progress) and is_night == _is_night:
		return
	_progress = clamped
	_is_night = is_night
	queue_redraw()


func get_phase() -> float:
	return _progress


func is_night() -> bool:
	return _is_night


func get_dawn_side() -> int:
	return _dawn_side


## Posisi glyph ternormalisasi (0..1) di dalam kotak arc.
## y = 1 di ujung busur, 0 di puncak; x = 0 kiri, 1 kanan.
static func arc_position(day_progress: float, dawn_side: int = SunConfig.Side.RIGHT) -> Vector2:
	var angle := PI * clampf(day_progress, 0.0, 1.0)
	var x := 0.5 - 0.5 * cos(angle)
	if dawn_side == SunConfig.Side.RIGHT:
		x = 1.0 - x
	return Vector2(x, 1.0 - sin(angle))


func _draw() -> void:
	var inner := Rect2(Vector2(GLYPH_RADIUS, GLYPH_RADIUS), size - Vector2(GLYPH_RADIUS * 2.0, GLYPH_RADIUS * 2.0))
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		return

	var points := PackedVector2Array()
	for index in ARC_STEPS + 1:
		var t := float(index) / float(ARC_STEPS)
		points.append(inner.position + _to_pixels(arc_position(t, _dawn_side), inner))
	draw_polyline(points, ARC_COLOR, 1.5)

	var center := inner.position + _to_pixels(arc_position(_progress, _dawn_side), inner)
	if _is_night:
		_draw_glyph(_moon_texture, center, MOON_COLOR, true)
	else:
		_draw_glyph(_sun_texture, center, SUN_COLOR, false)


func _to_pixels(normalized: Vector2, inner: Rect2) -> Vector2:
	return Vector2(normalized.x * inner.size.x, normalized.y * inner.size.y)


func _draw_glyph(texture: Texture2D, center: Vector2, color: Color, crescent: bool) -> void:
	if texture != null:
		var box := Rect2(center - Vector2(GLYPH_RADIUS, GLYPH_RADIUS), Vector2(GLYPH_RADIUS * 2.0, GLYPH_RADIUS * 2.0))
		draw_texture_rect(texture, box, false)
		return
	draw_circle(center, GLYPH_RADIUS, color)
	if crescent:
		# Bulan sabit placeholder: lubang seukuran 80% di kanan atas.
		draw_circle(center + Vector2(GLYPH_RADIUS * 0.45, -GLYPH_RADIUS * 0.3), GLYPH_RADIUS * 0.8, Color(0.05, 0.07, 0.1, 1.0))

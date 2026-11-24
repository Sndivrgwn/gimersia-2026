class_name SunSweep
extends RefCounted

## Mission 13: fungsi murni untuk sapuan fajar/senja.
##
## Approximation yang dipakai DayNightVisual:
##   - CanvasModulate memakai warna endpoint yang LEBIH TERANG (luminance).
##   - Overlay blend_mul mengalikan bagian layar yang BELUM dilewati front
##     dengan `ratio(brighter, target)`, sehingga di bagian itu warnanya sama
##     dengan transisi seragam lama.
##   - Bagian yang sudah dilewati front tidak dikalikan (mask 1), jadi hasilnya
##     tetap warna endpoint terang: fajar terlihat seperti cahaya yang menyapu
##     masuk, senja seperti bayangan yang menyapu masuk dari sisi seberang.
## Di titik awal dan akhir transisi hasilnya identik dengan fade seragam.
##
## Karena blend_mul hanya bisa menggelapkan, semua kanal ratio dijepit <= 1.

const SIDE_RIGHT := SunConfig.Side.RIGHT
const SIDE_LEFT := SunConfig.Side.LEFT


## 0 = front belum lewat, 1 = front sudah lewat.
## `side` = sisi asal front; `softness` = lebar tepi lembut (pecahan layar).
static func mask(progress: float, side: int, softness: float, x_norm: float) -> float:
	var t := clampf(progress, 0.0, 1.0)
	var x := clampf(x_norm, 0.0, 1.0)
	var edge := clampf(softness, 0.0, 1.0)
	if side == SIDE_LEFT:
		# Cahaya masuk dari kiri: front bergerak ke kanan.
		if edge <= 0.0:
			return 1.0 if x <= t else 0.0
		return 1.0 - smoothstep(t, t + edge, x)
	# Cahaya masuk dari kanan: front bergerak ke kiri.
	if edge <= 0.0:
		return 1.0 if x >= 1.0 - t else 0.0
	return smoothstep(1.0 - t - edge, 1.0 - t, x)


## Intensitas pita hangat: 1 tepat di front, 0 jauh dari front.
static func rim(progress: float, side: int, softness: float, x_norm: float) -> float:
	var t := clampf(progress, 0.0, 1.0)
	var x := clampf(x_norm, 0.0, 1.0)
	var front := t if side == SIDE_LEFT else 1.0 - t
	var width := maxf(clampf(softness, 0.0, 1.0), 0.02)
	return clampf(1.0 - absf(x - front) / width, 0.0, 1.0)


## Faktor multiply (<= 1 per kanal) supaya `from_color` menjadi `to_color`.
## Kanal `from` yang nol tidak bisa digelapkan, jadi hasilnya 1.0.
static func ratio(from_color: Color, to_color: Color) -> Color:
	return Color(
		_ratio_channel(from_color.r, to_color.r),
		_ratio_channel(from_color.g, to_color.g),
		_ratio_channel(from_color.b, to_color.b),
		1.0
	)


## Rencana satu frame transisi. Saat sweep nonaktif hasilnya persis transisi
## seragam lama (sweep=false, color=target, ratio putih).
static func plan(config: SunConfig, is_night: bool, remaining: float, duration: float,
		from_color: Color, mid_color: Color, to_color: Color) -> Dictionary:
	var progress := DayLightCurve.transition_progress(remaining, duration)
	var target := DayLightCurve.blend_through(from_color, mid_color, to_color, progress)
	var result := {
		"sweep": false,
		"color": target,
		"target": target,
		"ratio": Color.WHITE,
		"progress": progress,
		"side": SIDE_RIGHT,
		"seconds": 0.0,
	}
	if config == null or not config.sweep_enabled:
		return result
	var seconds := config.sweep_seconds_for(is_night)
	if seconds <= 0.0:
		return result

	var bright := from_color
	if DayLightCurve.luminance(to_color) > DayLightCurve.luminance(from_color):
		bright = to_color
	result["sweep"] = true
	result["color"] = bright
	result["ratio"] = ratio(bright, target)
	result["progress"] = clampf(1.0 - remaining / seconds, 0.0, 1.0)
	result["side"] = config.side_for(is_night)
	result["seconds"] = seconds
	return result


static func _ratio_channel(from_value: float, to_value: float) -> float:
	if from_value <= 0.0001:
		return 1.0
	return clampf(to_value / from_value, 0.0, 1.0)

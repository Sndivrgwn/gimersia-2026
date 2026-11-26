class_name DayLightCurve
extends RefCounted

## Kurva waktu visual yang dipakai DayNightVisual (tint + arah matahari) dan
## PointLight2D api unggun.
##
## Semua angka waktu berasal dari DayNightManager: transisi dimulai saat sisa
## fase tinggal `transition_seconds` (satu menit game untuk siklus 600 dtk),
## jadi sore selesai tepat saat malam mulai dan fajar selesai tepat saat
## pagi mulai.


## 0.0 di luar jendela transisi, 1.0 tepat saat fase berganti.
static func transition_progress(remaining_seconds: float, transition_seconds: float) -> float:
	if transition_seconds <= 0.0:
		return 1.0
	return clampf(1.0 - remaining_seconds / transition_seconds, 0.0, 1.0)


## 0.0 = terang (siang), 1.0 = gelap (malam).
## Malam menuju pagi: 1 -> 0 selama `transition_seconds` terakhir malam.
## Siang menuju malam: 0 -> 1 selama `transition_seconds` terakhir siang.
static func darkness(is_night: bool, remaining_seconds: float, transition_seconds: float) -> float:
	var progress := transition_progress(remaining_seconds, transition_seconds)
	if is_night:
		return clampf(1.0 - progress, 0.0, 1.0)
	return progress


static func daylight(is_night: bool, remaining_seconds: float, transition_seconds: float) -> float:
	return 1.0 - darkness(is_night, remaining_seconds, transition_seconds)


## Warna melewati waypoint (senja/fajar) di tengah transisi.
static func blend_through(from: Color, mid: Color, to: Color, t: float) -> Color:
	var eased := smoothstep(0.0, 1.0, clampf(t, 0.0, 1.0))
	if eased < 0.5:
		return from.lerp(mid, eased * 2.0)
	return mid.lerp(to, (eased - 0.5) * 2.0)


## Arah matahari di bidang layar: terbit di kiri (180°), tengah atas saat
## tengah hari (270°), terbenam di kanan (360°).
static func sun_direction(day_progress: float) -> Vector2:
	var angle := deg_to_rad(lerpf(180.0, 360.0, clampf(day_progress, 0.0, 1.0)))
	return Vector2(cos(angle), sin(angle))


## Kegelapan dari luminance tint dunia (dipakai api unggun).
static func darkness_from_luminance(world_luminance: float, day_luminance: float, night_luminance: float) -> float:
	if day_luminance <= night_luminance:
		return 0.0
	return clampf((day_luminance - world_luminance) / (day_luminance - night_luminance), 0.0, 1.0)


static func luminance(color: Color) -> float:
	return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b

@tool
class_name SunConfig
extends Resource

## Mission 13: arah dan durasi sapuan cahaya fajar/senja.
##
## Fajar menyapu dari `dawn_side`; senja selalu menyapu dari sisi sebaliknya,
## jadi cahaya pagi dan bayangan sore datang dari arah berlawanan. Semua nilai
## detik memakai jam game yang sama dengan DayNightVisualConfig.
##
## Nilai bawaan file .tres ditulis oleh tools/generate_sun_config.gd; durasi
## sapuan mengikuti `transition_duration` visual (60 s untuk siklus 600 dtk).

enum Side { RIGHT, LEFT }

@export_group("Sweep")

## False = transisi seragam lama (fade warna), tanpa overlay sapuan.
@export var sweep_enabled: bool = true

## Sisi tempat cahaya fajar masuk. Senja memakai sisi seberang.
## (int + @export_enum: anotasi `Side` di dalam kelas @tool bentrok di 4.7.)
@export_enum("RIGHT", "LEFT") var dawn_side: int = Side.RIGHT

@export_range(0.0, 300.0, 1.0, "suffix:s") var dawn_sweep_seconds: float = 60.0
@export_range(0.0, 300.0, 1.0, "suffix:s") var dusk_sweep_seconds: float = 60.0

## Lebar tepi lembut sebagai pecahan lebar layar (0 = tepi keras).
@export_range(0.0, 1.0, 0.01) var softness: float = 0.35

## Kekuatan pita hangat di tepi depan cahaya (0 = tanpa pita).
@export_range(0.0, 1.0, 0.01) var warm_rim_strength: float = 0.25

@export_group("HUD")

## Arc matahari/bulan kecil di TimeHUD.
@export var sun_arc_enabled: bool = true


## Sisi senja: kebalikan sisi fajar.
func dusk_side() -> int:
	return Side.LEFT if dawn_side == Side.RIGHT else Side.RIGHT


## `is_night` true = transisi malam -> pagi (fajar), false = siang -> malam.
func side_for(is_night: bool) -> int:
	return dawn_side if is_night else dusk_side()


## Durasi sapuan untuk transisi yang sedang berjalan.
func sweep_seconds_for(is_night: bool) -> float:
	return maxf(dawn_sweep_seconds if is_night else dusk_sweep_seconds, 0.0)

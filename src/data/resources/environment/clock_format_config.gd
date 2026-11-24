@tool
class_name ClockFormatConfig
extends Resource

## Mission 12: tampilan jam dunia nyata untuk siklus hari/malam.
##
## Siklus gameplay TIDAK berubah: hanya presentasi. Fase DAY dipetakan ke
## [day_start_hour, night_start_hour) dan fase NIGHT ke
## [night_start_hour, day_start_hour + 24). Jadi matahari selalu terbit di
## `day_start_hour` dan terbenam di `night_start_hour`, tetapi jarum jam bergerak
## lebih cepat/lambat sesuai panjang fase hari itu (mis. hari 300 dtk dengan
## rentang 12 jam = 25 dtk per jam game).
##
## Nilai di file .tres ditulis oleh tools/generate_clock_format.gd.

@export_group("Clock")

## Jam saat fase DAY mulai (= matahari terbit).
@export_range(0.0, 23.99, 0.25, "suffix:h") var day_start_hour: float = 6.0

## Jam saat fase NIGHT mulai (= matahari terbenam).
@export_range(0.0, 23.99, 0.25, "suffix:h") var night_start_hour: float = 18.0

## 24 jam ("18:05") atau 12 jam ("06:05 PM").
@export var use_24h: bool = true

## Menit dibulatkan ke bawah ke kelipatan ini (1 = tiap menit).
@export_range(1, 60, 1) var minute_step: int = 1

@export_group("Period labels")

## Nama periode, urut naik berdasarkan jam mulai. `Malam` (18) juga mencakup
## 00:00-05:00 karena rentangnya memutar lewat tengah malam.
@export var period_names: PackedStringArray = PackedStringArray(["Pagi", "Siang", "Sore", "Malam"])

## Jam mulai tiap periode, sejajar indeks dengan `period_names`.
@export var period_start_hours: PackedFloat32Array = PackedFloat32Array([5.0, 10.0, 15.0, 18.0])

@export var show_period_label: bool = true

@export_group("HUD")

## Hitung mundur "Fajar dalam mm:ss" hanya tampil saat malam.
@export var show_remaining_at_night: bool = true

## Sisa waktu fase siang (bawaan: tidak ditampilkan).
@export var show_remaining_by_day: bool = false

## Toast "Tidur: 22:10 -> 05:20" setelah tidur di Tenda.
@export var sleep_toast: bool = true


## Panjang fase DAY dalam jam dinding (bisa memutar lewat tengah malam).
func day_hours() -> float:
	var span := fposmod(night_start_hour - day_start_hour, 24.0)
	return span if span > 0.0 else 24.0


## Panjang fase NIGHT dalam jam dinding.
func night_hours() -> float:
	var span := fposmod(day_start_hour - night_start_hour, 24.0)
	return span if span > 0.0 else 24.0

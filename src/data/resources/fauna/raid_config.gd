class_name RaidConfig
extends Resource

## Mission 9: raid sebagai EVENT (bukan perilaku bawaan), batas populasi, dan
## jadwal raid per malam. Semua angka tuning raid ada di sini dan hanya di sini.
##
## Mode:
## - EVENT_ONLY (default): hanya boar bertanda `is_raider` yang menyerang
##   struktur, dan hanya pada jadwal RaidDirector.
## - ALWAYS: perilaku lama (boar hostile di dekat camp menyerang struktur).
## - OFF: boar tidak pernah menyerang struktur.
##
## Jadwal dibangun saat `night_started`: `raids_per_night[day-1]` dikali
## `global_pressure_multiplier`, dibulatkan, minimal 0. Raid pertama muncul
## setelah `first_raid_delay_min..first_raid_delay_max` detik game, raid
## berikutnya berjarak `max(raid_gap_min, raid_duration)` detik game.

enum Mode { EVENT_ONLY, ALWAYS, OFF }

## Tabel hostile malam spesifikasi NightScalingConfig (fallback bila array kosong).
const DEFAULT_NIGHT_CAP: Array[int] = [3, 4, 5, 6, 7, 9, 12]

@export_group("Mode")
@export var mode: int = Mode.EVENT_ONLY

@export_group("Jadwal Malam")
@export var raids_per_night: Array[int] = [1, 1, 1, 2, 2, 2, 3]
@export var raiders_per_raid: Array[int] = [1, 1, 2, 2, 3, 3, 4]
## Jeda raid pertama setelah malam mulai (detik game, sebelum pressure).
@export var first_raid_delay_min: float = 45.0
@export var first_raid_delay_max: float = 120.0
## Lama satu raid sebelum bubar (detik game).
@export var raid_duration: float = 40.0
## Jarak minimum antar raid (detik game, dihitung dari awal raid sebelumnya).
@export var raid_gap_min: float = 70.0
## Peringatan sebelum raid mulai (detik game).
@export var warning_seconds: float = 8.0

@export_group("Siang")
## Belum dipakai: raid siang mati secara desain (owner decision).
@export var day_raids_enabled: bool = false
@export var day_raids_per_day: Array[int] = [0, 0, 0, 0, 0, 0, 0]
@export var day_raiders_per_raid: Array[int] = [0, 0, 0, 0, 0, 0, 0]

@export_group("Populasi")
## Pengali global jumlah raid dan raider per malam (1.0 = sesuai tabel).
@export var global_pressure_multiplier: float = 1.0
## Batas populasi boar siang (FaunaQuota).
@export var day_boar_cap: int = 2
## Batas populasi rusa siang (FaunaQuota).
@export var day_deer_cap: int = 3
## Batas boar hostile hidup saat malam (NightSpawner). Kosong = tabel spesifikasi.
@export var night_active_hostile_cap: Array[int] = [2, 3, 3, 4, 5, 6, 8]
## Pengali interval spawn malam (1.0 = nilai NightScalingConfig).
@export var spawn_interval_multiplier: float = 1.0


## Jumlah raid untuk malam `day` (1..7) setelah pengali tekanan.
func get_raids_for_night(day: int) -> int:
	return _scaled(_value_at(raids_per_night, day))


## Jumlah raider maksimum satu raid malam `day`.
func get_raiders_for_raid(day: int) -> int:
	return _scaled(_value_at(raiders_per_raid, day))


## Batas boar hostile hidup malam `day`; array kosong = tabel spesifikasi.
func get_night_hostile_cap(day: int) -> int:
	if night_active_hostile_cap.is_empty():
		return _value_at(DEFAULT_NIGHT_CAP, day)
	return maxi(_value_at(night_active_hostile_cap, day), 0)


func get_spawn_interval_multiplier() -> float:
	return maxf(spawn_interval_multiplier, 0.01)


func is_event_only() -> bool:
	return mode == Mode.EVENT_ONLY


func is_off() -> bool:
	return mode == Mode.OFF


func _scaled(base: int) -> int:
	return maxi(int(round(float(base) * maxf(global_pressure_multiplier, 0.0))), 0)


func _value_at(values: Array[int], day: int) -> int:
	if values.is_empty():
		return 0
	return maxi(int(values[clampi(day - 1, 0, values.size() - 1)]), 0)

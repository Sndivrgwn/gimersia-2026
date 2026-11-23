class_name NeedsConfig
extends Resource

## Tuning for Hunger / Thirst / Fatigue (spesifikasi §7 "Needs").
##
## Semua angka needs ada di file ini dan hanya di sini. Instance
## `src/data/configs/needs_config.tres` sengaja tidak menimpa apa pun, jadi
## mengubah nilai di sini langsung mengubah gameplay (sama seperti
## `day_night_config.gd` untuk siklus hari).

@export_group("Values")
## Batas atas setiap need. Bawah selalu 0.
@export var max_value: float = 100.0
## Nilai awal saat komponen siap.
@export var start_value: float = 100.0
## Tier LOW mulai dari nilai ini ke bawah (<= 25).
@export var low_threshold: float = 25.0
## Tier ZERO mulai dari nilai ini ke bawah (<= 0).
@export var zero_threshold: float = 0.0
## Batas bawah drain saat tidur: tidur tidak boleh membunuh.
@export var sleep_min_value: float = 1.0

@export_group("Drain Per Second")
## Hunger per detik game saat siang.
@export var hunger_day_drain: float = 0.16
## Hunger per detik game saat malam.
@export var hunger_night_drain: float = 0.20
## Thirst per detik game saat siang.
@export var thirst_day_drain: float = 0.24
## Thirst per detik game saat malam.
@export var thirst_night_drain: float = 0.18
## Fatigue per detik nyata saat sprint (dikali faktor sprint drain).
@export var fatigue_sprint_drain: float = 2.5
## Fatigue per detik nyata saat jalan biasa (tidak sprint). Sengaja kecil:
## jalan lama-lama melelahkan, tapi jauh lebih lambat daripada sprint.
## 0.0 = hanya sprint yang menguras Fatigue.
@export var fatigue_walk_drain: float = 0.08
## Fatigue per detik nyata saat diam di tempat (regenerasi).
@export var fatigue_idle_regen: float = 1.0

@export_group("Fatigue Capacity")
## Plafon Fatigue yang hilang per detik nyata saat sprint. Sprint panjang
## menurunkan nilai maksimum Fatigue (mis. 100 -> 80); jalan dan diam tidak.
@export var fatigue_sprint_cap_drain: float = 0.4
## Makan/minum memulihkan plafon Fatigue sebesar ini (dipakai oleh item nanti).
@export var fatigue_meal_cap_restore: float = 10.0
## Tidur (time_skipped) memulihkan plafon Fatigue sebesar ini.
@export var sleep_fatigue_cap_restore: float = 25.0

@export_group("Balance (Mission 9)")
## Pengali semua drain Hunger/Thirst (1.0 = angka spesifikasi).
@export var global_drain_multiplier: float = 1.0
## Pengali drain Hunger. 0.6 = siklus pertama berakhir ~35 (target 30..45).
@export var hunger_drain_multiplier: float = 0.6
## Pengali drain Thirst. 0.57 = siklus pertama berakhir ~28 (target 15..35).
@export var thirst_drain_multiplier: float = 0.57
## Pengali tambahan per hari (indeks 0 = hari 1); 1.0 = tidak berubah.
@export var drain_multiplier_by_day: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
## Hunger <= nilai ini memblokir sprint (source &"hunger").
@export var hunger_sprint_lock_threshold: float = 30.0


## Pengali drain Hunger efektif untuk `day` (1..7).
func hunger_drain_scale(day: int) -> float:
	return maxf(global_drain_multiplier, 0.0) * maxf(hunger_drain_multiplier, 0.0) * _day_scale(day)


## Pengali drain Thirst efektif untuk `day` (1..7).
func thirst_drain_scale(day: int) -> float:
	return maxf(global_drain_multiplier, 0.0) * maxf(thirst_drain_multiplier, 0.0) * _day_scale(day)


func _day_scale(day: int) -> float:
	if drain_multiplier_by_day.is_empty():
		return 1.0
	return maxf(drain_multiplier_by_day[clampi(day - 1, 0, drain_multiplier_by_day.size() - 1)], 0.0)


@export_group("Zero Tier HP Loss Per Second")
## HP hilang per detik game saat Hunger ZERO.
@export var hunger_zero_hp_loss: float = 1.5
## HP hilang per detik game saat Thirst ZERO.
@export var thirst_zero_hp_loss: float = 2.0

@export_group("Modifiers (PERCENT, 0.10 = +10%)")
## Hunger LOW: move speed -15%.
@export var hunger_low_move_speed: float = -0.15
## Hunger LOW: attack damage -15%.
@export var hunger_low_attack_damage: float = -0.15
## Thirst LOW: drain Fatigue saat sprint +30%.
@export var thirst_low_sprint_fatigue_drain: float = 0.30
## Thirst LOW: attack speed -20%.
@export var thirst_low_attack_speed: float = -0.20
## Fatigue LOW: move speed -20%.
@export var fatigue_low_move_speed: float = -0.20
## Fatigue LOW dan ZERO: waktu gather +30%.
@export var fatigue_gather_time: float = 0.30
## Fatigue ZERO: move speed -45% (menggantikan nilai LOW).
@export var fatigue_zero_move_speed: float = -0.45
## Fatigue ZERO: attack speed -50%.
@export var fatigue_zero_attack_speed: float = -0.50

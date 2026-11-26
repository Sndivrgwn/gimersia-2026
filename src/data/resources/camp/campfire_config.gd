class_name CampfireConfig
extends Resource

## Tuning Campfire (bahan bakar, cahaya, refuel, dan bonus rest).
##
## Semua angka berasal dari spesifikasi §7.4. Instance `campfire_config.tres`
## tidak menimpa apa pun; nilai bawaan script yang dipakai.

@export_group("Awal")
## Mission 9 (keputusan owner): bangunan hanya menaruh DASAR api unggun. Api
## menyala lewat minigame gesek batu. True = perilaku lama (langsung menyala).
@export var start_lit: bool = false
## Bahan bakar awal (detik) yang disimpan walau api masih COLD.
@export var initial_fuel_seconds: float = 240.0
## Radius cahaya sebelum api pernah menyala (0 = tidak ada cahaya sama sekali).
@export var unlit_light_radius: float = 0.0

@export_group("Fuel")
## Lama, tidak dipakai lagi: digantikan `initial_fuel_seconds` (Mission 9).
@export var start_fuel: float = 240.0
## Bahan bakar maksimum (detik).
@export var max_fuel: float = 600.0
## Pengurasan bahan bakar per detik game saat siang.
@export var day_drain: float = 0.25
## Pengurasan bahan bakar per detik game saat malam.
@export var night_drain: float = 1.0
## Bahan bakar tidak bisa diisi lagi mulai dari nilai ini (tombol refuel mati).
@export var full_threshold: float = 580.0

@export_group("Refuel")
## Jumlah kayu per refuel.
@export var refuel_wood_cost: int = 2
## Bahan bakar yang ditambahkan per refuel (detik).
@export var refuel_seconds: float = 180.0
## Lama hold-E untuk refuel (detik nyata).
@export var refuel_hold_time: float = 0.5
## D3: api yang mati harus dinyalakan ulang dengan minigame gesek batu.
@export var manual_ignition_enabled: bool = true

@export_group("Light")
## Radius cahaya saat menyala.
@export var lit_light_radius: float = 240.0
## Radius cahaya ember setelah bahan bakar habis.
@export var ember_light_radius: float = 80.0
## Radius efek Dazzled (getter saja; musuh menyusul).
@export var dazzle_radius: float = 180.0
## Energi cahaya saat siang (darkness = 0.0).
@export_range(0.0, 3.0, 0.05) var light_energy_day: float = 0.6
## Energi cahaya saat sore/senja (darkness = 0.5).
@export_range(0.0, 3.0, 0.05) var light_energy_dusk: float = 1.0
## Energi cahaya saat malam penuh (darkness = 1.0).
@export_range(0.0, 3.0, 0.05) var light_energy_night: float = 1.4
## Lama transisi halus nyala/mati cahaya api (detik game).
@export_range(0.0, 5.0, 0.05, "suffix:s") var light_fade_seconds: float = 0.5

@export_group("Rest Bonus")
## Radius pemain dianggap beristirahat di dekat api.
@export var rest_radius: float = 120.0
## Regen Fatigue per detik saat beristirahat.
@export var rest_regen: float = 5.0
## Interval pengecekan pemain di sekitar api (detik nyata).
@export var rest_check_interval: float = 0.25

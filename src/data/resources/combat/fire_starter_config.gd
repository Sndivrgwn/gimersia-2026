class_name FireStarterConfig
extends Resource

## D3 manual ignition (invented values, lihat laporan).

@export var strikes_per_attempt: int = 3
## Marker ping-pong melintasi bar; satu lintasan penuh = sweep_period detik.
@export var sweep_period: float = 1.1
## Fraksi lebar bar (terpusat di 0.5).
@export var perfect_zone: float = 0.12
@export var good_zone: float = 0.30
## Peluang menyala per strike menurut kualitas.
@export var miss_chance: float = 0.10
@export var good_chance: float = 0.45
@export var perfect_chance: float = 0.80
## Hold-E untuk memulai percobaan.
@export var hold_time: float = 0.3
## Batu yang dipakai per percobaan (bukan per strike).
@export var stone_cost: int = 1
## Cooldown setelah percobaan gagal.
@export var fail_cooldown: float = 0.8
## Batal bila campfire lebih jauh dari ini.
@export var cancel_distance: float = 96.0

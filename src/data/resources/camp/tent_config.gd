class_name TentConfig
extends Resource

## Tuning Tenda Daun (tidur dan Jaga Malam).
##
## `hold_time` 1.5 s adalah nilai yang ditetapkan untuk misi ini (bukan angka
## spesifikasi); semua angka lain mengikuti spesifikasi §7.4.

## Lama hold-E untuk tidur (detik nyata).
@export var hold_time: float = 1.5
## Detik game yang dilewati saat tidur (sekali `skip_time`).
@export var skip_seconds: float = 45.0
## Jeda minimum dalam detik game sejak tidur terakhir.
@export var cooldown_seconds: float = 60.0
## Sisa siang minimum (detik game) agar boleh tidur.
@export var min_day_remaining: float = 60.0
## Lama hold-E untuk menyalakan Jaga Malam (0 = langsung, toggle).
@export var night_watch_hold_time: float = 0.0

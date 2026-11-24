class_name SneakConfig
extends Resource

## Mission 9 fase 4: angka mode jongkok (sneak).
## Semua angka ada di sini supaya bisa di-tune dari Inspector; Player tidak
## menyimpan nilai sendiri.

## Pengali kecepatan jalan saat jongkok (0.55 = 55% kecepatan normal).
@export var speed_multiplier: float = 0.55
## Pengali radius deteksi fauna terhadap pemain (0.6 = fauna "melihat" lebih dekat).
@export_range(0.05, 1.0, 0.01) var detection_multiplier: float = 0.6
## Jongkok tidak bisa sambil sprint.
@export var blocks_sprint: bool = true

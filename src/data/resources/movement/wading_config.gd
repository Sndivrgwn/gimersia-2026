class_name WadingConfig
extends Resource

## Mission 9 fase 4: angka berjalan di air sungai (wading).
## Spesifikasi V8 tidak memberi angka, jadi nilai di bawah adalah tuning awal
## (dicatat sebagai angka baru di laporan misi).

## Pengali kecepatan saat berada di zona sungai.
@export var speed_multiplier: float = 0.55
## Sprint diblokir selama mengarungi sungai.
@export var blocks_sprint: bool = true

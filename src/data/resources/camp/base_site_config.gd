class_name BaseSiteConfig
extends Resource

## Aturan validasi lokasi base (D1). Angka di sini invented (lihat laporan).

## Jarak minimum dari tepi pulau.
@export var coast_margin: float = 300.0
## Nilai cadangan; sumber tunggal radius sekarang FenceConfig.ring_radius.
@export var ring_radius: float = 200.0
## Mission 10: satu alur penempatan = camp + pagar.
@export var include_fence: bool = true
## True = seluruh segmen pagar langsung terbangun gratis (tes/cheat).
@export var fence_auto_build: bool = false
## Sumber geometri ring (dipakai BaseSiteRules + preview).
@export var fence_config: FenceConfig = preload("res://src/data/configs/fence_config.tres")
## Jarak aman tambahan dari strip sungai.
@export var river_clearance: float = 50.0

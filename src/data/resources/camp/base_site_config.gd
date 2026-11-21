class_name BaseSiteConfig
extends Resource

## Aturan validasi lokasi base (D1). Angka di sini invented (lihat laporan).

## Jarak minimum dari tepi pulau.
@export var coast_margin: float = 300.0
## Radius ring base (dipakai fence + jarak aman sungai). Sama dengan FenceConfig.
@export var ring_radius: float = 200.0
## Jarak aman tambahan dari strip sungai.
@export var river_clearance: float = 50.0

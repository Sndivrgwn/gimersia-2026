class_name InteractionConfig
extends Resource

## Angka tuning hold-E. Komponen membaca file ini supaya tidak ada angka ajaib
## di script.

## Jarak maksimum Interactable terdekat yang bisa dipakai (piksel).
@export var interaction_range: float = 64.0
## Selang pencarian target terdekat (detik nyata).
@export var scan_interval: float = 0.1

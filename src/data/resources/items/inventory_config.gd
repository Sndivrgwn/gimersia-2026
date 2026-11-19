class_name InventoryConfig
extends Resource

## Angka tuning inventory. Komponen dan pickup membaca file ini supaya tidak ada
## angka ajaib di script.

## Jumlah slot tas.
@export var bag_size: int = 12
## Jumlah slot hotbar; hotbar = slot tas 0..hotbar_size-1.
@export var hotbar_size: int = 5
## Jeda sebelum pickup boleh diambil (mencegah drop-lalu-ambil ulang).
@export var pickup_delay: float = 0.5
## Radius area pickup dalam piksel.
@export var pickup_radius: float = 24.0

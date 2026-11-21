class_name FenceConfig
extends Resource

## Angka ring pagar (invented, lihat laporan). Dipakai FenceRing + generator.

@export var ring_radius: float = 200.0
@export var segment_count: int = 20
@export var segment_length: float = 66.0
@export var thickness: float = 10.0
@export var hp: float = 60.0
@export var build_time: float = 1.5
@export var build_wood: int = 1
@export var build_fiber: int = 1
@export var repair_wood: int = 1
@export var repair_hp: float = 30.0
@export var aggro_priority: int = 3
## D2: pemain tidak diblokir pagar.
@export var blocks_player: bool = false

class_name IslandLayoutConfig
extends Resource

## Tuning layout pulau: seed, ukuran, jarak, keep-out, dan jumlah node per zona.
## Semua angka layout ada di `src/data/configs/island_layout.tres`; kode builder
## tidak boleh menanam angka sendiri.

## Seed RNG; seed sama -> posisi sama.
@export var seed: int = 20260101
## Setengah sisi pulau (pulau = kotak -half_size..+half_size).
@export var half_size: float = 2400.0
## Margin dari tepi pulau yang tidak dipakai untuk node.
@export var coast_margin: float = 150.0
## Jarak minimum antar node dan antar marker.
@export var min_spacing: float = 70.0
## Radius bebas di sekitar spawn, wreckage, dan koper.
@export var keep_out_radius: float = 140.0
## Radius bebas di sekitar Signal Beacon.
@export var beacon_keep_out: float = 150.0
## Cincin starter Zone 1 di sekitar camp.
@export var camp_ring_min: float = 220.0
@export var camp_ring_max: float = 700.0
## Percobaan rejection sampling per node sebelum menyerah.
@export var max_attempts: int = 2000
## Jarak minimum marker night spawn dari (0,0).
@export var markers_min_distance: float = 1100.0
## Starter Zone 1 hilang permanen setelah hari ini (spec: hari 5).
@export var camp_starters_last_respawn_day: int = 4

@export var camp_twig: int = 10
@export var camp_small_rock: int = 8
@export var camp_fiber_bush: int = 5
@export var camp_berry_bush: int = 4
@export var camp_small_tree: int = 6

@export var south_coconut_palm: int = 12

@export var west_small_rock: int = 14
@export var west_big_rock: int = 8

@export var river_bamboo: int = 14

@export var forest_tree: int = 30
@export var forest_fiber_bush: int = 24
@export var forest_berry_bush: int = 18

@export var night_spawn_markers: int = 16

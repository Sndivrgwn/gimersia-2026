class_name WorldConfig
extends Resource

## Konfigurasi inti dunia (Mission 13). Semua blok F..I membaca angka dari sini;
## angka di sini invented (lihat laporan blok F).

enum Mode { FORMULA, AUTHORED }

## FORMULA = pulau rumus lama; AUTHORED = scene dunia buatan (blok G).
@export var mode: Mode = Mode.FORMULA
## Scene dunia AUTHORED yang dimuat blok G.
@export var authored_scene_path: String = "res://src/levels/worlds/sample_island/world.tscn"
## Bila scene AUTHORED gagal dimuat, pakai FormulaWorld (blok G).
@export var fallback_to_formula: bool = true
## Ukuran grid untuk sampling reachability/koridor AUTHORED.
@export var cell_size: float = 32.0
## Minimal titik spawn malam yang harus lolos validasi AUTHORED.
@export var min_spawn_points: int = 8
## Jarak minimum titik spawn dari camp.
@export var min_spawn_distance: float = 1100.0
## Lebar koridor minimum agar dunia AUTHORED dianggap bisa dilewati.
@export var min_corridor_width: float = 96.0
## Radius bersih base = FenceConfig.ring_radius + nilai ini.
@export var base_clearance_extra: float = 50.0
## Rasio sel yang harus reachable agar dunia AUTHORED valid.
@export_range(0.0, 1.0) var reachability_required_ratio: float = 0.98
## Rasio node yang hilang yang masih ditoleransi (peringatan saja).
@export_range(0.0, 1.0) var warn_node_ratio: float = 0.5
## Batas jumlah vertex polygon AUTHORED (validasi impor).
@export var polygon_vertex_limit: int = 2000
## Luas minimum area hutan AUTHORED (px^2).
@export var min_forest_area: float = 1000000.0
## Ukuran sel overlay debug (px).
@export var overlay_cell_px: int = 64

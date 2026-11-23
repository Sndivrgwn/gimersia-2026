class_name StationConfig
extends Resource

## Mission 10 Phase 2: tuning stasiun (Meja Kerja / Api Unggun).
## Semua angka di sini invented (lihat laporan); ditulis oleh
## tools/generate_station_data.gd.

## Hold E sebelum panel stasiun terbuka (0 = sekali tekan).
@export var open_hold_time: float = 0.1
## Jarak pemain ke stasiun agar resep stasiun dianggap tersedia.
@export var use_range: float = 140.0
## Panel menutup sendiri bila pemain lebih jauh dari ini.
@export var panel_close_distance: float = 160.0
## Tab Crafting di tas hanya menampilkan resep tangan + info stasiun.
@export var bag_tab_hand_only: bool = true
## False = perilaku lama (E pada api unggun memicu gesek batu, tanpa panel).
@export var campfire_opens_panel: bool = true

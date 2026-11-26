class_name SplashConfig
extends Resource

## Konfigurasi layar pembuka (splash / loading screen) sebelum menu utama.

@export var enabled: bool = true
@export var entries: Array[SplashEntry] = []
@export var background_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var logo_max_size_ratio: float = 0.5
@export var skip_enabled: bool = true
@export var skip_min_seconds: float = 0.4
@export var show_loading_bar: bool = true
@export var loading_label: String = "Memuat..."
@export var bar_smooth_speed: float = 1.5
@export var min_total_seconds: float = 2.0
@export var max_wait_seconds: float = 15.0
@export var next_scene_path: String = "res://src/ui/menus/main_menu.tscn"
@export var preload_paths: PackedStringArray = PackedStringArray(["res://src/levels/island/island.tscn"])
@export var skip_if_already_shown: bool = true
@export var dev_skip: bool = false

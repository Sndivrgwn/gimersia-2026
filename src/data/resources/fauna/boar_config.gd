class_name BoarConfig
extends FaunaConfig

## Babi hutan (spesifikasi §7.3).

@export_group("Gigit")
@export var bite_damage: float = 12.0
@export var bite_range: float = 50.0
@export var bite_cooldown: float = 1.2

@export_group("Dash")
@export var dash_min_distance: float = 110.0
@export var dash_max_distance: float = 240.0
@export var dash_telegraph: float = 0.8
@export var dash_speed: float = 330.0
@export var dash_cooldown_day: float = 6.0
@export var dash_cooldown_night: float = 4.0
@export var dash_player_damage: float = 20.0
@export var dash_structure_damage: float = 40.0
@export var dash_hit_radius: float = 40.0

@export_group("Persepsi")
@export var detect_radius: float = 300.0
@export var leash_radius: float = 380.0
@export var camp_player_radius: float = 140.0
@export var raid_camp_radius: float = 500.0
@export var raid_clear_radius: float = 650.0

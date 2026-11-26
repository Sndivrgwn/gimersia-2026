class_name BoarConfig
extends FaunaConfig

## Babi hutan (spesifikasi §7.3).

@export_group("Timing")
## Lama state BITE ditahan supaya animasi gigit terlihat (detik nyata).
@export var bite_hold_time: float = 0.22
## Lama state RECOVER setelah dash menabrak (detik nyata).
@export var dash_recover_time: float = 0.3
## Jarak dorongan dash ke pemain (piksel; durasi ada di CombatConfig).
@export var dash_knockback_distance: float = 60.0

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

## Mission 9: babi memblokir pemain dan tahan sebagian knockback.
func _init() -> void:
	blocks_player = true
	knockback_resistance = 0.35


@export_group("Persepsi")
@export var detect_radius: float = 300.0
@export var leash_radius: float = 380.0
## Provoked hilang bila tidak ada hit yang bertukar selama ini (detik).
@export var provoke_calm_seconds: float = 10.0
@export var camp_player_radius: float = 140.0
@export var raid_camp_radius: float = 500.0
@export var raid_clear_radius: float = 650.0

@export_group("Smart Chase")
## Mission 16 (L3): false mengembalikan perilaku kejar lurus lama persis.
@export var smart_chase_enabled: bool = true
@export_range(0.0, 200.0, 1.0) var separation_radius_px: float = 48.0
@export_range(0.0, 5.0, 0.05) var separation_weight: float = 1.2
@export_range(1, 8, 1) var max_simultaneous_attackers: int = 2
@export_range(40.0, 300.0, 1.0) var circle_radius_px: float = 140.0
@export_range(0.1, 1.5, 0.05) var circle_speed_factor: float = 0.7
@export_range(2, 12, 1) var approach_slot_count: int = 5
@export_range(0.0, 2.0, 0.05) var windup_seconds: float = 0.45
@export_range(0.0, 2.0, 0.05) var recovery_seconds: float = 0.6
@export_range(0.2, 5.0, 0.05) var attack_cooldown_min: float = 1.2
@export_range(0.2, 6.0, 0.05) var attack_cooldown_max: float = 2.2
@export_range(0.0, 2.0, 0.05) var reaction_delay_max: float = 0.35
@export_range(1.0, 5.0, 0.1) var boar_charge_speed_multiplier: float = 2.6
@export_range(60.0, 500.0, 5.0) var boar_charge_distance_px: float = 220.0
@export_range(0.0, 150.0, 5.0) var boar_overshoot_px: float = 40.0
@export_range(100.0, 1200.0, 10.0) var lose_aggro_distance_px: float = 600.0

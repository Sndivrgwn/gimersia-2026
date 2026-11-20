class_name CombatConfig
extends Resource

## Tuning tempur pemain (spesifikasi §7.2). Instance: combat_config.tres.

@export_group("Serangan")
@export var bare_range: float = 45.0
## Sudut total kerucut ayunan manual (derajat).
@export var cone_angle_degrees: float = 90.0
@export var fatigue_cost_per_hit: float = 1.2

@export_group("Knockback")
@export var knockback_distance: float = 60.0
@export var knockback_duration: float = 0.2

@export_group("Bleed")
@export var bleed_dps: float = 2.0
@export var bleed_duration: float = 3.0
@export var bleed_weapon_ids: Array[StringName] = [&"bone_spear"]

@export_group("Umpan Balik")
@export var floating_text_lifetime: float = 0.8

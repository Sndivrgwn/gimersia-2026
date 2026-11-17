class_name PlayerBaseStats
extends Resource

## Nilai dasar seluruh stat pemain.
##
## Satu-satunya tempat angka "base" untuk Player dan StatsComponent. Rumus
## turunan (bonus proficiency, modifier, dan sebagainya) ada di StatsComponent.
## Resource ini bisa dibuat sebagai .tres nanti tanpa mengubah kode.

@export_group("Health")
@export var base_max_hp: float = 100.0
@export var hp_regen_per_sec: float = 0.0
@export var base_damage_reduction: float = 0.0
@export var max_damage_reduction: float = 0.9

@export_group("Movement")
@export var base_move_speed: float = 160.0
@export var sprint_multiplier: float = 1.5

@export_group("Combat")
@export var base_attack_damage: float = 8.0
@export var base_attack_range: float = 45.0
@export var base_attack_speed: float = 1.2
@export var base_dodge_chance: float = 0.0
@export var dodge_hard_cap: float = 0.5
@export var base_knockback_resistance: float = 0.0

@export_group("Survival")
@export var max_respawn_tokens: int = 3
@export var percent_modifier_floor: float = 0.25
@export var fatigue_sprint_threshold: float = 25.0

class_name ProficiencyConfig
extends Resource

## Tuning proficiency (spesifikasi V8 §7.6). Instance: proficiency_config.tres.
##
## Semua angka di sini berasal dari spec; jangan menulis angka XP di komponen.
## XP untuk naik level = xp_per_level_base x level saat ini (100 x level).

@export_group("Level")
@export var max_level: int = 10
@export var xp_per_level_base: float = 100.0

@export_group("Bonus Malam")
## XP tempur (hit, dodge, dash-survive, kill) dikali saat malam.
@export var night_xp_multiplier: float = 1.5

@export_group("Strength")
@export var strength_hit_xp: float = 10.0
@export var strength_tree_xp: float = 15.0
@export var strength_rock_xp: float = 15.0
@export var heavy_strike_level: int = 3
@export var heavy_strike_every: int = 4
@export var heavy_strike_multiplier: float = 1.3
@export var sturdy_level: int = 6
@export var sturdy_knockback_multiplier: float = 0.5

@export_group("Speed")
## Radius kamp (px dari (0,0)); di dalamnya tidak ada XP Speed (anti-farm).
@export var speed_camp_radius: float = 180.0
@export var speed_walk_distance: float = 100.0
@export var speed_walk_xp: float = 1.0
@export var speed_sprint_xp_per_second: float = 3.0
@export var light_footed_level: int = 3
@export var light_footed_sprint_percent: float = 0.10
@export var second_wind_level: int = 6
@export var second_wind_regen_multiplier: float = 1.25

@export_group("Mastery")
@export var mastery_gather_xp: float = 8.0
@export var mastery_craft_xp: float = 25.0
@export var mastery_cook_xp: float = 20.0
@export var resourceful_level: int = 3
@export var resourceful_chance: float = 0.20
@export var resourceful_bonus: int = 1
@export var master_chef_level: int = 6
@export var master_chef_bonus: float = 10.0

@export_group("Agility")
@export var agility_dodge_xp: float = 20.0
@export var agility_dodge_cooldown: float = 3.0
@export var agility_dash_miss_xp: float = 25.0
@export var agility_dash_miss_max_per_boar: int = 2
@export var agility_kill_xp: float = 30.0
@export var quick_reflex_level: int = 3
@export var quick_reflex_dodge_percent: float = 0.08
@export var quick_reflex_hp_threshold: float = 0.4
@export var swift_counter_level: int = 6
@export var swift_counter_multiplier: float = 1.25

@export_group("Death")
## Jumlah proficiency yang turun 1 level saat mati (spec: maksimal 2).
@export var death_debuff_levels: int = 2


## Level passive pertama setiap proficiency (spec: Lv 3).
@export var first_passive_level: int = 3


## Level di mana passive pertama terbuka (semua proficiency Lv 3).
func passive_level_for(_prof: int) -> int:
	return first_passive_level


## XP yang dibutuhkan untuk naik dari `level` ke `level + 1`.
func xp_to_next(level: int) -> float:
	if level >= max_level:
		return 0.0
	return xp_per_level_base * float(level)

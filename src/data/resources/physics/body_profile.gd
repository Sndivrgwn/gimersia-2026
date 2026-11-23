class_name BodyProfile
extends Resource

## Mission 10 Phase 4: profil massa/kolisi per body.
## Semantik knockback_taken_multiplier: pengali perpindahan yang diterima body
## saat terkena knockback (1.0 = penuh, 0.35 = sangat berat).

enum MassClass { LIGHT, MEDIUM, HEAVY }

@export var id: StringName = &""
@export var mass_class: MassClass = MassClass.MEDIUM
@export var radius: float = 12.0
@export var collision_layer: int = 1
@export var collision_mask: int = 1
## True = pemain tidak bisa berjalan menembus body ini.
@export var blocks_player: bool = true
## Tidak ada body yang mendorong body lain (owner decision: semuanya false).
@export var pushable_by_others: bool = false
@export var knockback_taken_multiplier: float = 1.0
@export var contact_stop_extra: float = 2.0
@export var separation_speed: float = 60.0
@export var max_overlap_px: float = 2.0

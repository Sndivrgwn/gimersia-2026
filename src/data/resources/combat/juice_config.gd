class_name JuiceConfig
extends Resource

## D5 juice (invented values, lihat laporan). Visual only, tanpa ubah balance.

@export var intensity: float = 1.0
@export var screenshake_enabled: bool = true
@export var hit_stop_light: float = 0.05
@export var hit_stop_heavy: float = 0.09
@export var shake_light: float = 3.0
@export var shake_light_time: float = 0.12
@export var shake_heavy: float = 6.0
@export var shake_heavy_time: float = 0.18
@export var shake_kill: float = 5.0
@export var shake_kill_time: float = 0.15
@export var shake_player_hurt: float = 7.0
@export var shake_player_hurt_time: float = 0.22
@export var knockback_light: float = 28.0
@export var knockback_heavy: float = 45.0
@export var knockback_time: float = 0.12
@export var squash_scale: Vector2 = Vector2(1.25, 0.8)
@export var squash_time: float = 0.12
@export var flash_color: Color = Color(3.0, 3.0, 3.0, 1.0)
@export var flash_time: float = 0.06
@export var hit_spark_count: int = 8
@export var kill_burst_count: int = 18
@export var player_lunge: float = 6.0
@export var player_lunge_time: float = 0.06
@export var manual_swing_buffer: float = 0.15
@export var low_hp_vignette_threshold: float = 25.0
@export var death_sequence_time: float = 0.25

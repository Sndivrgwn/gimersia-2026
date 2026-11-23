class_name FaunaConfig
extends Resource

## Angka bersama semua fauna. BoarConfig/DeerConfig menambah angka khusus.

@export_group("Dasar")
@export var max_hp: float = 80.0
@export var move_speed_day: float = 115.0
@export var move_speed_night: float = 115.0
@export var wander_speed_factor: float = 0.5
@export var wander_radius: float = 200.0
@export var wander_pause_min: float = 2.0
@export var wander_pause_max: float = 5.0

@export_group("Menyingkir")
@export var flee_despawn_distance: float = 600.0
@export var flee_despawn_timeout: float = 8.0

@export_group("Jatuhan")
@export var loot_ids: Array[StringName] = []
@export var loot_counts: Array[int] = []

@export_group("Tabrakan")
## Mission 9: fauna dengan blocks_player true berada di layer FAUNA_BODY,
## sehingga pemain (mask memuat FAUNA_BODY) tidak bisa menembusnya.
@export var blocks_player: bool = false
## Pengali perpindahan knockback yang diterima fauna (1.0 = penuh).
@export var knockback_resistance: float = 1.0
## Jarak henti tambahan di atas jumlah radius badan (px) saat mengejar target.
@export var contact_stop_extra: float = 2.0


## Jarak pusat-ke-pusat saat fauna mengejar target sudah dianggap menempel.
func get_contact_distance(target_radius: float, self_radius: float) -> float:
	return self_radius + target_radius + maxf(contact_stop_extra, 0.0)

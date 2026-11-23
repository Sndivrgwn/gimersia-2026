class_name DeerConfig
extends FaunaConfig

## Rusa pulau (spesifikasi §7.3). Selalu PASSIVE, tidak menyerang.

## Mission 9: rusa tidak memblokir pemain (tetap bisa ditembus) dan menerima
## knockback penuh.
func _init() -> void:
	blocks_player = false
	knockback_resistance = 1.0


@export_group("Kabur")
@export var flee_speed: float = 175.0
@export var flee_trigger_radius: float = 130.0
@export var flee_duration: float = 5.0

@export_group("Waspada (Mission 9 fase 4)")
## Radius waspada = radius kabur x faktor ini: rusa berhenti dan "menegakkan
## kepala" sebelum benar-benar kabur, jadi pemain melihat tanda dulu.
@export var alert_radius_factor: float = 1.25
## Lama berhenti waspada sebelum memutuskan kabur/ kembali mengembara.
@export var alert_time: float = 0.45

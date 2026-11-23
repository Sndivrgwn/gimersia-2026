class_name DeerConfig
extends FaunaConfig

## Rusa pulau (spesifikasi §7.3). Selalu PASSIVE, tidak menyerang.

## Mission 10 Phase 4: rusa kini badan padat yang memblokir pemain dan menerima
## knockback 0.6 (profil massa menimpa angka ini bila terpasang).
func _init() -> void:
	blocks_player = true
	knockback_resistance = 0.6


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

@export_group("Startle (Mission 10 Phase 4)")
## Lama rusa terpaku setelah waspada: jaminan minimal satu serangan.
@export var startle_seconds: float = 0.9
## Ramp kecepatan kabur (0 -> penuh) supaya masih bisa dikejar sesaat.
@export var flee_accel_seconds: float = 0.5
## Lantai radius deteksi saat pemain jongkok (tidak pernah 0).
@export var sneak_notice_floor_px: float = 24.0
## Lama rusa terpaku setelah kena serangan pertama (jendela serangan kedua).
@export var hit_stun: float = 0.35

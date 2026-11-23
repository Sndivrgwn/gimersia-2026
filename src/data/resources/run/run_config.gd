class_name RunConfig
extends Resource

## Mission 9: tuning satu run (perlindungan respawn). Semua angka di sini supaya
## bisa diubah dari .tres tanpa menyentuh kode.

@export_group("Respawn Protection")
## Lama perlindungan setelah respawn (detik NYATA, tidak terpengaruh time scale).
@export var respawn_protection_seconds: float = 5.0
## True: fauna tidak memilih pemain sebagai target selama perlindungan.
@export var protection_ignored_by_enemies: bool = true
## True: menyerang membatalkan sisa perlindungan.
@export var protection_ends_on_attack: bool = false
## Frekuensi kedip visual pemain selama perlindungan (Hz).
@export var protection_blink_hz: float = 6.0

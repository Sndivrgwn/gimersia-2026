class_name DawnRecapConfig
extends Resource

## Fase 1B: pengaturan panel rekap fajar. Panel tidak mem-pause game dan
## menutup sendiri setelah `panel_seconds` (bisa juga ditutup dengan Esc).

@export_range(1.0, 30.0, 0.5) var panel_seconds: float = 6.0
@export_range(0.0, 2.0, 0.05) var fade_seconds: float = 0.35

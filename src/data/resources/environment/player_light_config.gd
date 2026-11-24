@tool
class_name PlayerLightConfig
extends Resource

## Fase 1C: cahaya pemain saat malam.
##
## Angka radius dari spesifikasi: pemain 110 px, dengan Obor di slot terpilih
## 190 px. Energi mengikuti `DayNightVisual.get_world_darkness()` supaya
## transisi senja/fajar halus dan siang hari tidak menambah cahaya.

@export_group("Radius")
## Radius cahaya pemain tanpa obor (px).
@export_range(0.0, 400.0, 1.0) var player_radius: float = 110.0
## Radius cahaya pemain saat Obor ada di slot hotbar terpilih (px).
@export_range(0.0, 600.0, 1.0) var torch_radius: float = 190.0

@export_group("Energy")
## Energi saat siang (0 = cahaya benar-benar mati).
@export_range(0.0, 2.0, 0.01) var day_energy: float = 0.0
## Energi saat malam penuh.
@export_range(0.0, 2.0, 0.01) var night_energy: float = 1.0
## Tambahan energi saat obor aktif (0 = hanya radius yang berubah).
@export_range(0.0, 2.0, 0.01) var torch_energy_bonus: float = 0.0

@export_group("Visual")
@export var color: Color = Color(1.0, 0.86, 0.62, 1.0)
## Item yang dianggap "obor" (dicek dari slot hotbar terpilih).
@export var torch_item: ItemDefinition

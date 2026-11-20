class_name StructureDefinition
extends Resource

## Definisi satu struktur camp: HP, biaya bangun, waktu bangun, prioritas aggro,
## biaya repair, dan posisi slot.
##
## Angka ada di `.tres` `src/data/camp/*.tres`, dibuat lewat
## `tools/generate_structures.gd`. `scene` menunjuk scene struktur yang
## di-instance BlueprintSlot saat pembangunan selesai.

## Id stabil (English, snake_case). Sama dengan nama file `.tres`.
@export var id: StringName = &""
## Nama tampilan di prompt blueprint / repair.
@export var display_name: String = ""
## Scene struktur yang dipasang saat pembangunan selesai.
@export var scene: PackedScene
## HP maksimum struktur.
@export var max_hp: float = 100.0
## Bahan untuk membangun.
@export var build_cost: Array[ItemAmount] = []
## Lama hold-E membangun (detik nyata); dikali faktor waktu craft pemain.
@export var build_time: float = 1.0
## 0 = Campfire, 1 = Workbench/Chest, 2 = Tent (musuh memilih yang terkecil).
@export var aggro_priority: int = 0
## Bahan untuk repair (hold R).
@export var repair_cost: Array[ItemAmount] = []
## HP yang dipulihkan per repair.
@export var repair_hp: float = 0.0
## Posisi slot blueprint relatif ke pusat camp.
@export var slot_position: Vector2 = Vector2.ZERO


## Teks biaya, mis. "4 Kayu, 3 Batu, 2 Serat".
static func format_amounts(amounts: Array[ItemAmount]) -> String:
	var parts := PackedStringArray()
	for amount in amounts:
		if amount == null or amount.item == null or amount.count <= 0:
			continue
		parts.append("%d %s" % [amount.count, amount.item.display_name])
	return ", ".join(parts)


func get_build_cost_text() -> String:
	return format_amounts(build_cost)


func get_repair_cost_text() -> String:
	return format_amounts(repair_cost)

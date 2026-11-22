class_name AssetRegistry
extends Resource

## Daftar semua slot aset. Digenerate oleh tools/generate_asset_registry.gd;
## jangan diedit tangan (akan tertimpa saat generator dijalankan ulang).

@export var slots: Array[AssetSlotDefinition] = []


func get_slot(key: StringName) -> AssetSlotDefinition:
	for slot in slots:
		if slot != null and slot.key == key:
			return slot
	return null


func keys() -> PackedStringArray:
	var result := PackedStringArray()
	for slot in slots:
		if slot != null:
			result.append(String(slot.key))
	return result


func slots_in_category(category: StringName) -> Array[AssetSlotDefinition]:
	var result: Array[AssetSlotDefinition] = []
	for slot in slots:
		if slot != null and slot.category == category:
			result.append(slot)
	return result


func slots_with_priority(priority: int) -> Array[AssetSlotDefinition]:
	var result: Array[AssetSlotDefinition] = []
	for slot in slots:
		if slot != null and slot.priority == priority:
			result.append(slot)
	return result


func size() -> int:
	return slots.size()

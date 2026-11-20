class_name CampController
extends Node2D

## Registry struktur camp: membaca slot blueprint, melacak apa yang terbangun,
## dan menyediakan daftar terurut prioritas aggro untuk AI musuh nanti.
##
## Controller ini tidak menyimpan HP atau isi struktur; sumber kebenaran tetap
## node CampStructure masing-masing.

signal structure_built(id: StringName)
signal structure_destroyed(id: StringName)

## Slot blueprint (biasanya 4 anak node). Bila kosong, dikumpulkan otomatis
## dari anak bertipe BlueprintSlot.
@export var slots: Array[BlueprintSlot] = []

var _structures: Dictionary = {}
var _bound: Dictionary = {}


func _ready() -> void:
	_collect_slots()
	for slot in slots:
		if slot == null:
			continue
		if not slot.built.is_connected(_on_slot_built):
			slot.built.connect(_on_slot_built)
		var existing := slot.get_structure()
		if existing != null:
			_register(existing)


# --- Read API ---------------------------------------------------------------

func get_slots() -> Array[BlueprintSlot]:
	_collect_slots()
	return slots


func get_structure(id: StringName) -> CampStructure:
	var structure := _structures.get(id, null) as CampStructure
	if structure == null or not is_instance_valid(structure):
		return null
	if structure.is_queued_for_deletion():
		return null
	return structure


func get_structures() -> Array[CampStructure]:
	var result: Array[CampStructure] = []
	for id in _structures.keys():
		var structure := get_structure(id)
		if structure != null:
			result.append(structure)
	return result


func has_built(id: StringName) -> bool:
	return get_structure(id) != null


## Urut prioritas aggro menaik (Campfire 0 -> Workbench/Chest 1 -> Tent 2).
func get_structures_by_priority() -> Array[CampStructure]:
	var result := get_structures()
	result.sort_custom(_sort_by_priority)
	return result


func get_built_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for structure in get_structures():
		ids.append(structure.get_id())
	return ids


# --- Internal ---------------------------------------------------------------

func _collect_slots() -> void:
	if not slots.is_empty():
		return
	for child in get_children():
		var slot := child as BlueprintSlot
		if slot != null:
			slots.append(slot)


func _sort_by_priority(a: CampStructure, b: CampStructure) -> bool:
	return a.get_aggro_priority() < b.get_aggro_priority()


func _on_slot_built(structure: CampStructure) -> void:
	_register(structure)
	var id := structure.get_id()
	if id != &"":
		structure_built.emit(id)


func _register(structure: CampStructure) -> void:
	if structure == null:
		return
	var id := structure.get_id()
	if id == &"":
		push_warning("CampController: struktur tanpa id diabaikan.")
		return
	_structures[id] = structure
	if not _bound.has(id):
		structure.destroyed.connect(_on_structure_destroyed.bind(id))
		_bound[id] = true


func _on_structure_destroyed(id: StringName) -> void:
	_structures.erase(id)
	_bound.erase(id)
	structure_destroyed.emit(id)

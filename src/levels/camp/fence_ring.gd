class_name FenceRing
extends Node2D

## D2: ring BlueprintSlot pagar di sekeliling pusat base. Segmen TIDAK masuk
## registry CampController (yang tetap 4 struktur inti).

signal segment_built(index: int)

@export var definition: StructureDefinition
@export var config: FenceConfig

var _slots: Array[BlueprintSlot] = []
var _anchor: CampAnchor
var _built: Dictionary = {}


func _ready() -> void:
	_anchor = CampAnchor.find_anchor(self)
	if _anchor == null:
		return
	if not _anchor.base_founded.is_connected(_on_base_founded):
		_anchor.base_founded.connect(_on_base_founded)
	if _anchor.is_founded():
		build_ring(_anchor.get_center())


## Satu sumber geometri ring: dipakai builder DAN preview base (Mission 10).
## `angle_offset` (Fase 4C) memutar seluruh ring tanpa memindahkan pusat base.
static func layout(
	center: Vector2,
	fence_config: FenceConfig,
	angle_offset: float = 0.0
) -> Array[Dictionary]:
	var rules := fence_config if fence_config != null else FenceConfig.new()
	var count := maxi(rules.segment_count, 3)
	var step := TAU / float(count)
	var result: Array[Dictionary] = []
	for index in count:
		var angle := step * float(index) + angle_offset
		result.append({
			"position": center + Vector2(cos(angle), sin(angle)) * rules.ring_radius,
			"rotation": angle + PI * 0.5,
		})
	return result


func build_ring(center: Vector2) -> void:
	_clear_slots()
	if definition == null:
		push_warning("FenceRing: definition pagar kosong.")
		return
	# Fase 4C: ring mengikuti rotasi yang dipilih saat base ditentukan.
	var offset := 0.0
	if _anchor != null and is_instance_valid(_anchor):
		offset = _anchor.get_fence_rotation()
	var index := 0
	for entry in layout(center, config, offset):
		var slot := BlueprintSlot.new()
		slot.name = "FenceSlot%d" % index
		slot.definition = definition
		add_child(slot)
		# Root cause Mission 10: posisi lokal membuat ring jatuh di sekitar origin
		# setiap kali node induk tidak dipindah ke pusat base (mis. FenceRing di
		# bawah CampAnchor kosong). Geometri layout() SUDAH absolut, jadi slot
		# memakai top_level: posisinya tidak ikut transform induk yang mungkin
		# belum diperbarui pada frame yang sama saat anchor.found() dipanggil.
		slot.top_level = true
		slot.position = entry["position"] as Vector2
		# Tangen ring: segmen menyambung satu sama lain.
		slot.rotation = float(entry["rotation"])
		slot.built.connect(_on_slot_built.bind(index))
		_slots.append(slot)
		index += 1


func get_slots() -> Array[BlueprintSlot]:
	return _slots


func get_segments() -> Array[FenceSegment]:
	var result: Array[FenceSegment] = []
	for slot in _slots:
		if slot == null:
			continue
		var segment := slot.get_structure() as FenceSegment
		if segment != null:
			result.append(segment)
	return result


func get_built_count() -> int:
	return get_segments().size()


## Rotasi ring yang benar-benar dipakai (0 bila anchor belum ada).
func get_ring_rotation() -> float:
	if _anchor != null and is_instance_valid(_anchor):
		return _anchor.get_fence_rotation()
	return 0.0


func _on_slot_built(_structure: CampStructure, index: int) -> void:
	_built[index] = true
	segment_built.emit(index)


func _on_base_founded(center: Vector2) -> void:
	build_ring(center)


func _clear_slots() -> void:
	for slot in _slots:
		if slot != null and is_instance_valid(slot):
			slot.queue_free()
	_slots.clear()
	_built.clear()

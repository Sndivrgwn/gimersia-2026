class_name BlueprintSlot
extends Interactable

## Slot blueprint untuk satu struktur camp.
##
## Kosong: menampilkan garis besar transparan dan hold-E membangun struktur.
## Terbangun: placeholder disembunyikan dan slot tidak bisa dipakai lagi sampai
## struktur itu hancur (sinyal `destroyed`), lalu slot bisa dibangun ulang.
##
## Biaya dibaca dari `StructureDefinition.build_cost`; bahan dicek dulu, baru
## dikonsumsi. Waktu bangun memakai delta nyata lewat InteractorComponent.

signal built(structure: CampStructure)

const PROMPT_FORMAT := "Bangun %s (%s)"
const ALREADY_BUILT := "Sudah dibangun"
const MISSING_COST := "Bahan kurang"
const BROKEN_BLUEPRINT := "Blueprint rusak"
const PLACEHOLDER_COLOR := Color(0.95, 0.9, 0.55, 0.35)
const PLACEHOLDER_SIZE := Vector2(44.0, 44.0)

## Definisi struktur yang dibangun di slot ini. Wajib diisi.
@export var definition: StructureDefinition

var _structure: CampStructure
var _placeholder: Node2D
var _enabled: bool = true
var _disabled_reason: String = ""
## Cache hasil probe scene: instan hanya sekali per PackedScene.
var _probed_scene: PackedScene
var _probe_result: bool = false


func _ready() -> void:
	_build_placeholder()
	if definition != null:
		VisualSlot.attach(
			self,
			StringName("blueprint_" + String(definition.id)),
			[_placeholder.get_node_or_null("Outline"), _placeholder.get_node_or_null("Label")],
			_placeholder
		)
	_refresh_placeholder()


# --- Interactable -----------------------------------------------------------

func get_prompt(_interactor: Node) -> String:
	if definition == null:
		return ""
	var cost_text := definition.get_build_cost_text()
	return PROMPT_FORMAT % [definition.display_name, cost_text]


func get_hold_time(interactor: Node) -> float:
	if definition == null:
		return 0.0
	var factor := 1.0
	if interactor != null and interactor.has_method(&"get_stats"):
		var stats := interactor.get_stats() as StatsComponent
		if stats != null:
			factor = stats.get_craft_time_factor()
	return maxf(definition.build_time * factor, 0.0)


func can_interact(interactor: Node) -> bool:
	if not get_block_reason(interactor).is_empty():
		return false
	return true


## D1: slot bisa dimatikan (mis. base belum ditentukan). Additive.
func set_enabled(enabled: bool, reason: String = "") -> void:
	_enabled = enabled
	_disabled_reason = reason if not enabled else ""
	_refresh_placeholder()


func is_enabled() -> bool:
	return _enabled


func get_block_reason(interactor: Node) -> String:
	if definition == null:
		return ""
	if not _enabled:
		return _disabled_reason
	if _structure != null:
		return ALREADY_BUILT
	# Scene hilang / bukan CampStructure: slot tidak boleh memakan bahan sama
	# sekali, jadi alasan ini dicek sebelum biaya.
	if not _has_usable_scene():
		return BROKEN_BLUEPRINT
	if not _has_cost(interactor):
		return MISSING_COST
	return ""


func interact(interactor: Node) -> void:
	if definition == null or _structure != null:
		return
	# Guard terakhir sebelum menyentuh tas: scene rusak tidak boleh mengonsumsi.
	if not _has_usable_scene():
		push_warning("BlueprintSlot: scene untuk '%s' tidak bisa dipakai." % definition.id)
		return
	if not _consume_cost(interactor):
		return
	_spawn_structure()


## True bila `definition.scene` ada, bisa di-instance, dan root-nya CampStructure.
func _has_usable_scene() -> bool:
	if definition == null or definition.scene == null:
		return false

	var scene := definition.scene
	if scene == _probed_scene:
		return _probe_result

	var usable := scene.can_instantiate()
	if usable:
		var probe := scene.instantiate()
		usable = probe is CampStructure
		if probe != null:
			probe.free()
	_probed_scene = scene
	_probe_result = usable
	return usable


# --- Read API ---------------------------------------------------------------

func get_structure() -> CampStructure:
	return _structure


func is_built() -> bool:
	return _structure != null


func get_placeholder() -> Node2D:
	return _placeholder


# --- Internal ---------------------------------------------------------------

func _spawn_structure() -> void:
	var scene := definition.scene
	if scene == null:
		push_warning("BlueprintSlot: definition '%s' tidak punya scene." % definition.id)
		return

	var instance := scene.instantiate()
	var structure := instance as CampStructure
	if structure == null:
		push_warning("BlueprintSlot: scene '%s' bukan CampStructure." % definition.id)
		instance.queue_free()
		return

	structure.definition = definition
	var parent := get_parent()
	if parent == null:
		parent = self
	parent.add_child(structure)
	if structure is Node2D:
		(structure as Node2D).global_position = global_position
		(structure as Node2D).global_rotation = global_rotation
	_structure = structure
	structure.destroyed.connect(_on_structure_destroyed)
	_refresh_placeholder()
	built.emit(structure)


func _on_structure_destroyed() -> void:
	_structure = null
	_refresh_placeholder()


func _refresh_placeholder() -> void:
	if _placeholder != null:
		_placeholder.visible = _structure == null


func _has_cost(interactor: Node) -> bool:
	if definition == null:
		return false
	return ItemAmount.has_all(definition.build_cost, _inventory_of(interactor))


## Cek dulu semuanya, baru kurangi atomik lewat helper bersama.
func _consume_cost(interactor: Node) -> bool:
	if definition == null:
		return false
	return ItemAmount.consume_all(definition.build_cost, _inventory_of(interactor))


func _inventory_of(interactor: Node) -> InventoryComponent:
	if interactor == null or not interactor.has_method(&"get_inventory"):
		return null
	return interactor.get_inventory() as InventoryComponent


func _build_placeholder() -> void:
	if _placeholder != null:
		return
	_placeholder = Node2D.new()
	_placeholder.name = "Placeholder"
	add_child(_placeholder)

	var outline := Polygon2D.new()
	outline.name = "Outline"
	outline.color = PLACEHOLDER_COLOR
	var half := PLACEHOLDER_SIZE * 0.5
	outline.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	_placeholder.add_child(outline)

	var label := Label.new()
	label.name = "Label"
	label.text = definition.display_name if definition != null else ""
	label.position = Vector2(-40.0, -56.0)
	label.size = Vector2(80.0, 18.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.7, 0.9))
	_placeholder.add_child(label)

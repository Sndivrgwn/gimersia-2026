class_name CampStructure
extends Node2D

## Basis semua struktur camp: HP, damage, repair, prioritas aggro, dan HP bar.
##
## Struktur ini **non-blocking**: Node2D tanpa collision body, jadi pemain tidak
## bisa terjebak di dalamnya. `definition` diisi oleh pemanggil (BlueprintSlot /
## scene) sebelum masuk tree.
##
## Repair tidak menyentuh angka repair di sini: pemanggil (RepairComponent)
## yang mengonsumsi bahan dan memanggil `repair(definition.repair_hp)`.

signal damaged(amount: float, source: Node)
signal repaired(amount: float)
signal destroyed
signal hp_changed(current: float, max_value: float)

const GROUP := &"camp_structure"
const DEFAULT_MAX_HP := 100.0
const HP_BAR_SIZE := Vector2(48.0, 6.0)
const HP_BAR_OFFSET := Vector2(-24.0, -34.0)

## Definisi struktur (HP, biaya, prioritas aggro). Diisi pemanggil.
@export var definition: StructureDefinition

var max_hp: float = DEFAULT_MAX_HP
var current_hp: float = DEFAULT_MAX_HP

var _hp_bar: ProgressBar


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	apply_definition()
	_ensure_hp_bar()


# --- Setup / read API -------------------------------------------------------

## Terapkan HP dari definisi. Dipanggil _ready(); tes boleh memanggil langsung.
func apply_definition() -> void:
	if definition != null:
		max_hp = maxf(definition.max_hp, 1.0)
	else:
		max_hp = maxf(max_hp, 1.0)
	current_hp = max_hp
	_refresh_hp_bar()


func get_definition() -> StructureDefinition:
	return definition


func get_id() -> StringName:
	return definition.id if definition != null else &""


func get_display_name() -> String:
	if definition != null and not definition.display_name.is_empty():
		return definition.display_name
	return name


func get_max_hp() -> float:
	return max_hp


func get_current_hp() -> float:
	return current_hp


func is_damaged() -> bool:
	return current_hp < max_hp - 0.0001


func get_aggro_priority() -> int:
	return definition.aggro_priority if definition != null else 0


## HP bar hanya terlihat saat struktur rusak.
func get_hp_bar() -> ProgressBar:
	return _hp_bar


# --- Damage / repair --------------------------------------------------------

func take_damage(amount: float, source: Node) -> void:
	if amount <= 0.0 or current_hp <= 0.0:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	_refresh_hp_bar()
	hp_changed.emit(current_hp, max_hp)
	damaged.emit(amount, source)
	if current_hp <= 0.0:
		destroyed.emit()
		queue_free()


## Pulihkan HP, dibatasi max_hp. Mengembalikan jumlah HP yang benar-benar pulih.
func repair(amount: float) -> float:
	if amount <= 0.0 or current_hp <= 0.0:
		return 0.0
	var before := current_hp
	current_hp = minf(current_hp + amount, max_hp)
	var healed := current_hp - before
	if is_zero_approx(healed):
		return 0.0
	_refresh_hp_bar()
	hp_changed.emit(current_hp, max_hp)
	repaired.emit(healed)
	return healed


# --- Internal ---------------------------------------------------------------

func _ensure_hp_bar() -> void:
	if _hp_bar != null:
		return
	_hp_bar = get_node_or_null("HpBar") as ProgressBar
	if _hp_bar == null:
		_hp_bar = ProgressBar.new()
		_hp_bar.name = "HpBar"
		_hp_bar.position = HP_BAR_OFFSET
		_hp_bar.size = HP_BAR_SIZE
		_hp_bar.show_percentage = false
		_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_hp_bar)
	_refresh_hp_bar()


func _refresh_hp_bar() -> void:
	if _hp_bar == null:
		return
	_hp_bar.max_value = maxf(max_hp, 1.0)
	_hp_bar.value = current_hp
	_hp_bar.visible = is_damaged()

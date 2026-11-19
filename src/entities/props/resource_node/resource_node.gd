class_name ResourceNode
extends Interactable

## Node resource yang dipanen dengan hold-E.
##
## Semua angka (tool, waktu, yield, respawn) datang dari ResourceNodeDefinition.
## State node hanya "depleted atau tidak"; isi tas dan needs tetap milik pemain.
## RNG bisa diinjeksi lewat `rng_seed` supaya layout dan tes deterministik.

signal gathered(definition: ResourceNodeDefinition, amount: int, interactor: Node)

const PROMPT_FORMAT := "Tahan E: %s"
const DEPLETED_REASON := "Sudah dipanen"

const COLOR_WOOD := Color(0.55, 0.38, 0.22)
const COLOR_STONE := Color(0.62, 0.64, 0.66)
const COLOR_FIBER := Color(0.45, 0.70, 0.35)
const COLOR_BERRY := Color(0.75, 0.28, 0.38)
const COLOR_COCONUT := Color(0.45, 0.62, 0.35)
const COLOR_BAMBOO := Color(0.72, 0.72, 0.30)
const COLOR_DEFAULT := Color(0.5, 0.6, 0.45)

## Definisi node. Wajib diisi (scene/builder).
@export var definition: ResourceNodeDefinition
## > 0 = node hilang permanen setelah hari ini lewat (0 = tanpa batas).
@export var last_respawn_day: int = 0
## 0 = acak; selain 0 = deterministik (layout/tes).
@export var rng_seed: int = 0
## Opsional; bila kosong memakai autoload DayNightManager.
@export var clock: Node

var _depleted: bool = false
var _rng := RandomNumberGenerator.new()

@onready var _visual: Polygon2D = get_node_or_null("Visual") as Polygon2D
@onready var _label: Label = get_node_or_null("Label") as Label


func _ready() -> void:
	if rng_seed != 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()

	if _label != null:
		_label.text = "" if definition == null else definition.display_name
	if _visual != null:
		_visual.color = tint_for(definition)

	_connect_clock()


# --- Interactable -----------------------------------------------------------

func get_prompt(_interactor: Node) -> String:
	if definition == null:
		return ""
	return PROMPT_FORMAT % definition.display_name


func get_hold_time(interactor: Node) -> float:
	var base: float = 1.0 if definition == null else definition.gather_time
	var stats := _stats_of(interactor)
	if stats != null:
		base *= stats.get_gather_time_factor()
	return maxf(base, 0.0)


func can_interact(interactor: Node) -> bool:
	return not _depleted and _has_required_tool(interactor)


func get_block_reason(interactor: Node) -> String:
	if _depleted:
		return DEPLETED_REASON
	if definition == null:
		return ""
	if not _has_required_tool(interactor):
		return definition.get_block_reason()
	return ""


func interact(interactor: Node) -> void:
	if _depleted or definition == null:
		return

	var inventory := _inventory_of(interactor)
	if inventory == null:
		return

	var amount := definition.roll_yield(_rng)
	if amount > 0:
		inventory.add_or_drop(definition.item, amount)
	_spend_fatigue(interactor)
	_set_depleted(true)
	gathered.emit(definition, amount, interactor)


# --- State / clock ----------------------------------------------------------

func is_depleted() -> bool:
	return _depleted


## Ganti clock (dipakai tes dengan stub `day_started`).
func setup_clock(p_clock: Node) -> void:
	clock = p_clock
	_connect_clock()


func _connect_clock() -> void:
	var target: Node = clock
	if target == null:
		target = get_node_or_null("/root/DayNightManager")
	if target == null:
		return
	clock = target
	if target.has_signal(&"day_started") and not target.day_started.is_connected(_on_day_started):
		target.day_started.connect(_on_day_started)


func _on_day_started(day: int) -> void:
	if not _depleted:
		return

	if last_respawn_day > 0 and day > last_respawn_day:
		queue_free()
		return

	if _should_respawn(day):
		_set_depleted(false)


func _should_respawn(day: int) -> bool:
	if definition == null:
		return false
	match definition.respawn_rule:
		ResourceNodeDefinition.RespawnRule.DAILY:
			return day >= 2
		ResourceNodeDefinition.RespawnRule.EVERY_OTHER_DAY:
			return day >= 3 and day % 2 == 1
		_:
			return false


func _set_depleted(value: bool) -> void:
	_depleted = value
	visible = not value
	if value:
		remove_from_group(Interactable.GROUP)
	else:
		add_to_group(Interactable.GROUP)


# --- Helper -----------------------------------------------------------------

## Warna placeholder per resource (dipakai builder juga).
static func tint_for(def: ResourceNodeDefinition) -> Color:
	if def == null or def.item == null:
		return COLOR_DEFAULT
	match def.item.id:
		&"wood":
			return COLOR_WOOD
		&"stone":
			return COLOR_STONE
		&"fiber":
			return COLOR_FIBER
		&"berry":
			return COLOR_BERRY
		&"coconut":
			return COLOR_COCONUT
		&"bamboo":
			return COLOR_BAMBOO
		_:
			return COLOR_DEFAULT


func _has_required_tool(interactor: Node) -> bool:
	if definition == null:
		return false
	var tool_id := definition.get_required_tool_id()
	if tool_id == &"":
		return true
	var inventory := _inventory_of(interactor)
	if inventory == null:
		return false
	return inventory.has_tool(tool_id)


func _spend_fatigue(interactor: Node) -> void:
	if definition == null:
		return
	var needs := _needs_of(interactor)
	if needs == null:
		return
	needs.spend_fatigue(definition.fatigue_cost)


func _inventory_of(interactor: Node) -> InventoryComponent:
	if interactor == null or not interactor.has_method(&"get_inventory"):
		return null
	return interactor.get_inventory() as InventoryComponent


func _stats_of(interactor: Node) -> StatsComponent:
	if interactor == null or not interactor.has_method(&"get_stats"):
		return null
	return interactor.get_stats() as StatsComponent


func _needs_of(interactor: Node) -> NeedsComponent:
	if interactor == null or not interactor.has_method(&"get_needs"):
		return null
	return interactor.get_needs() as NeedsComponent

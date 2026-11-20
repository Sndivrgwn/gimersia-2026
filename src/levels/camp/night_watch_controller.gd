class_name NightWatchController
extends Node

## Jaga Malam: dinyalakan dari Tenda saat malam dengan Api Unggun menyala.
##
## ON memanggil `clock.set_night_watch(true)` (waktu game 2x). OFF memanggil
## `set_night_watch(false)` dan terjadi bila: ada input `move_*`, Campfire
## kehabisan bahan bakar / hancur, ada `camp_structure` yang menerima damage,
## atau fase berganti menjadi siang (`night_ended`).
##
## Input dibaca dengan polling, bukan `_unhandled_input`. Controller ini anak
## dari CampController dan menemukan Campfire/Tenda lewat registry camp.

signal watch_started
signal watch_stopped(reason: String)

const MOVE_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_up",
	&"move_down",
]
const REASON_DAY := "Hanya saat malam"
const REASON_NO_FIRE := "Butuh Api Unggun menyala"
const REASON_MOVED := "Bergerak"
const REASON_FIRE_OUT := "Api padam"
const REASON_ATTACKED := "Struktur diserang"
const REASON_DAWN := "Fajar"
const REASON_TOGGLED := "Dimatikan"

## Opsional; default autoload DayNightManager.
@export var clock: Node
## Opsional; default parent CampController.
@export var camp: CampController
## Matikan di scene tes bila input tidak ingin ikut aktif.
@export var input_enabled: bool = true

var _active: bool = false
var _fire: Campfire


func _ready() -> void:
	InputSetup.ensure_actions()
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	if camp == null:
		camp = get_parent() as CampController

	if clock != null and clock.has_signal(&"night_ended"):
		if not clock.night_ended.is_connected(_on_night_ended):
			clock.night_ended.connect(_on_night_ended)
	if camp != null and not camp.structure_built.is_connected(_on_camp_structure_built):
		camp.structure_built.connect(_on_camp_structure_built)

	_bind_built_structures()


func _process(delta: float) -> void:
	tick(delta)


## Satu tick. `_process` hanya memanggil ini supaya tes deterministik.
func tick(_delta: float) -> void:
	if not _active:
		return
	if input_enabled and _movement_pressed():
		stop(REASON_MOVED)
		return
	if clock == null or not clock.is_night():
		stop(REASON_DAWN)


# --- Read API ---------------------------------------------------------------

func is_active() -> bool:
	return _active


## Alasan tidak bisa mulai; "" bila bisa.
func get_start_block_reason() -> String:
	if clock == null or not clock.is_night():
		return REASON_DAY
	var fire := _resolve_fire()
	if fire == null or not fire.is_lit():
		return REASON_NO_FIRE
	return ""


func can_start() -> bool:
	return get_start_block_reason().is_empty()


# --- Kontrol ----------------------------------------------------------------

func start() -> bool:
	if _active:
		return false
	if not can_start():
		return false

	_active = true
	_bind_fire(_resolve_fire())
	_connect_structures()
	if clock != null and clock.has_method("set_night_watch"):
		clock.set_night_watch(true)
	watch_started.emit()
	return true


func stop(reason: String = REASON_TOGGLED) -> void:
	if not _active:
		return
	_active = false
	_fire = null
	if clock != null and clock.has_method("set_night_watch"):
		clock.set_night_watch(false)
	watch_stopped.emit(reason)


## Toggle dari Tenda (E saat malam).
func toggle() -> bool:
	if _active:
		stop(REASON_TOGGLED)
		return true
	return start()


# --- Internal ---------------------------------------------------------------

func _movement_pressed() -> bool:
	for action in MOVE_ACTIONS:
		if Input.is_action_pressed(action):
			return true
	return false


func _resolve_fire() -> Campfire:
	if camp != null:
		var built := camp.get_structure(&"campfire") as Campfire
		if built != null:
			return built

	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(CampStructure.GROUP):
		var fire := node as Campfire
		if fire != null and not fire.is_queued_for_deletion():
			return fire
	return null


func _bind_fire(fire: Campfire) -> void:
	_fire = fire
	if fire == null:
		return
	if not fire.fuel_depleted.is_connected(_on_fire_out):
		fire.fuel_depleted.connect(_on_fire_out)
	if not fire.destroyed.is_connected(_on_fire_out):
		fire.destroyed.connect(_on_fire_out)


func _connect_structures() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(CampStructure.GROUP):
		_connect_structure(node as CampStructure)


func _connect_structure(structure: CampStructure) -> void:
	if structure == null:
		return
	if not structure.damaged.is_connected(_on_structure_damaged):
		structure.damaged.connect(_on_structure_damaged)


func _bind_built_structures() -> void:
	if camp == null:
		return
	for structure in camp.get_structures():
		if structure is Tent:
			(structure as Tent).night_watch = self
		elif structure is Campfire:
			_bind_fire(structure as Campfire)


func _on_camp_structure_built(id: StringName) -> void:
	if camp == null:
		return
	var structure := camp.get_structure(id)
	if structure == null:
		return
	_connect_structure(structure)
	if structure is Tent:
		(structure as Tent).night_watch = self
	elif structure is Campfire:
		_bind_fire(structure as Campfire)


func _on_fire_out() -> void:
	stop(REASON_FIRE_OUT)


func _on_structure_damaged(_amount: float, _source: Node) -> void:
	stop(REASON_ATTACKED)


func _on_night_ended(_day: int) -> void:
	stop(REASON_DAWN)

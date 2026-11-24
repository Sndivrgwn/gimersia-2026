class_name DailyRunStats
extends Node

## Fase 1B: pencatat statistik per hari untuk rekap fajar.
##
## Read-only terhadap gameplay: hanya menyambung sinyal yang sudah ada
## (`ResourceNode.gathered`, `CombatComponent.enemy_killed`,
## `CampStructure.damaged/destroyed`). Saat `day_started` untuk hari ke-2 dan
## seterusnya, ringkasan hari sebelumnya dipancarkan lewat `day_summary` lalu
## penghitung harian direset. Total seluruh run disimpan untuk layar akhir
## (Fase 5).

signal day_summary(summary: Dictionary)

const PLAYER_GROUP := &"player"
const STRUCTURE_GROUP := &"camp_structure"
const SCAN_INTERVAL := 1.0

## Opsional; default autoload DayNightManager.
@export var clock: Node
## Opsional; default node di grup `player`.
@export var player: Node

var _day: int = 1
var _resources: int = 0
var _kills_boar: int = 0
var _kills_other: int = 0
var _base_damage: float = 0.0
var _structures_destroyed: int = 0
var _totals: Dictionary = {
	"resources": 0,
	"kills_boar": 0,
	"kills_other": 0,
	"base_damage": 0.0,
	"structures_destroyed": 0,
	"days": 0,
}
var _connected: Dictionary = {}
var _scan_timer: float = 0.0


func _ready() -> void:
	_bind_clock()
	_bind_player()
	_scan()


func _process(delta: float) -> void:
	_scan_timer -= delta
	if _scan_timer > 0.0:
		return
	_scan_timer = SCAN_INTERVAL
	_scan()


# --- API (HUD, debug, tes) ---------------------------------------------------

func get_day() -> int:
	return _day


func get_resources() -> int:
	return _resources


func get_kills_boar() -> int:
	return _kills_boar


func get_base_damage() -> float:
	return _base_damage


func get_structures_destroyed() -> int:
	return _structures_destroyed


func is_base_intact() -> bool:
	return _base_damage <= 0.0 and _structures_destroyed == 0


## Total seluruh run (dipakai layar Game Over/Victory di Fase 5).
func get_totals() -> Dictionary:
	return _totals.duplicate()


func record_gather(amount: int) -> void:
	_resources += maxi(amount, 0)


func record_kill(target: Node) -> void:
	if target is WildBoar:
		_kills_boar += 1
	else:
		_kills_other += 1


func record_base_damage(amount: float) -> void:
	_base_damage += maxf(amount, 0.0)


func record_structure_destroyed() -> void:
	_structures_destroyed += 1


## Tutup hari berjalan: kembalikan ringkasan, tambahkan ke total, lalu reset.
func finish_day() -> Dictionary:
	var summary := build_summary()
	_totals["resources"] += int(summary["resources"])
	_totals["kills_boar"] += int(summary["kills_boar"])
	_totals["kills_other"] += int(summary["kills_other"])
	_totals["base_damage"] += float(summary["base_damage"])
	_totals["structures_destroyed"] += int(summary["structures_destroyed"])
	_totals["days"] += 1
	_reset_day()
	return summary


func build_summary() -> Dictionary:
	return {
		"day": _day,
		"resources": _resources,
		"kills_boar": _kills_boar,
		"kills_other": _kills_other,
		"base_damage": _base_damage,
		"structures_destroyed": _structures_destroyed,
		"base_intact": is_base_intact(),
	}


# --- Internal ---------------------------------------------------------------

func _bind_clock() -> void:
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	if clock == null:
		return
	if clock.has_signal(&"day_started") and not clock.day_started.is_connected(_on_day_started):
		clock.day_started.connect(_on_day_started)
	if clock.has_method(&"get_current_day"):
		_day = int(clock.get_current_day())


func _bind_player() -> void:
	if player == null or not is_instance_valid(player):
		var tree := get_tree()
		player = tree.get_first_node_in_group(PLAYER_GROUP) if tree != null else null
	if player == null:
		return
	var combat := player.get_node_or_null("CombatComponent")
	if combat == null or not combat.has_signal(&"enemy_killed"):
		return
	if not combat.enemy_killed.is_connected(_on_enemy_killed):
		combat.enemy_killed.connect(_on_enemy_killed)


## Resource node dan struktur bisa lahir setelah build, jadi dipindai berkala
## dan tidak pernah didaftarkan dua kali (id instance).
func _scan() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(Interactable.GROUP):
		var resource := node as ResourceNode
		if resource == null or _connected.has(resource.get_instance_id()):
			continue
		_connected[resource.get_instance_id()] = true
		resource.gathered.connect(_on_gathered)
	for node in tree.get_nodes_in_group(STRUCTURE_GROUP):
		var structure := node as CampStructure
		if structure == null or _connected.has(structure.get_instance_id()):
			continue
		_connected[structure.get_instance_id()] = true
		structure.damaged.connect(_on_structure_damaged)
		structure.destroyed.connect(_on_structure_destroyed)
	_bind_player()


func _reset_day() -> void:
	_resources = 0
	_kills_boar = 0
	_kills_other = 0
	_base_damage = 0.0
	_structures_destroyed = 0


func _on_day_started(day: int) -> void:
	# Hari 1 adalah awal run: tidak ada hari sebelumnya untuk direkap.
	if day > 1 and _day > 0:
		day_summary.emit(finish_day())
	_day = day
	_reset_day()


func _on_gathered(_definition: ResourceNodeDefinition, amount: int, _interactor: Node) -> void:
	record_gather(amount)


func _on_enemy_killed(target: Node) -> void:
	record_kill(target)


func _on_structure_damaged(amount: float, _source: Node) -> void:
	record_base_damage(amount)


func _on_structure_destroyed() -> void:
	record_structure_destroyed()

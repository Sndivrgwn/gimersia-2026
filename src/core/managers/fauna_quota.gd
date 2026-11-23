class_name FaunaQuota
extends Node

## Kuota fauna pulau: 2 Boar + 3 Deer sejak awal, aturan fajar, dan aturan
## anti-softlock saat rescue. Bukan autoload; dipasang di island.tscn.
##
## Spawn memakai penanda grup &"night_spawn_point": pilih acak yang >= 600 px
## dari pemain; bila semuanya lebih dekat, pakai yang paling jauh.
## Clock dan RNG bisa di-inject untuk tes.

const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")
const DEER_SCENE: PackedScene = preload("res://src/entities/fauna/island_deer/island_deer.tscn")
const SPAWN_GROUP := &"night_spawn_point"
const PLAYER_GROUP := &"player"

@export var clock: Node
@export var fauna_parent: Node2D
@export var boar_target: int = 2
@export var deer_target: int = 3
@export var min_spawn_distance: float = 600.0
## Mission 10 Phase 4: jarak bersih minimum ke pemain/badan fauna lain.
@export var min_body_clearance: float = 60.0
@export var flee_duration: float = 8.0
@export var rescue_respawn_delay: float = 45.0
@export var rescue_max_extra_respawns: int = 4
## Pertanyaan desain §13: jaminan rusa saat rescue. Sengaja OFF.
@export var guarantee_deer_at_rescue: bool = false
## Mission 7: jaminan rusa saat rescue (min 2, respawn 45 s nyata, max 4).
@export var rescue_min_deer: int = 2
@export var rescue_max_extra_deer_respawns: int = 4
## Mission 9: batas populasi siang. Null = pakai boar_target/deer_target.
@export var raid_config: RaidConfig

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _rescue_mode: bool = false
var _respawn_timers: Array[float] = []
var _extra_respawns: int = 0
var _deer_respawn_timers: Array[float] = []
var _deer_extra_respawns: int = 0
var _initial_spawned: bool = false


func _ready() -> void:
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	_connect_clock()
	spawn_initial()


func _connect_clock() -> void:
	if clock == null:
		return
	if clock.has_signal("day_started") and not clock.is_connected("day_started", _on_day_started):
		clock.connect("day_started", _on_day_started)
	if clock.has_signal("rescue_started") and not clock.is_connected("rescue_started", _on_rescue_started):
		clock.connect("rescue_started", _on_rescue_started)


## Satu tick; timer respawn rescue memakai delta NYATA (time scale 0 saat itu).
func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	for index in range(_respawn_timers.size() - 1, -1, -1):
		_respawn_timers[index] -= delta
		if _respawn_timers[index] > 0.0:
			continue
		_respawn_timers.remove_at(index)
		_spawn_boar()
	for index in range(_deer_respawn_timers.size() - 1, -1, -1):
		_deer_respawn_timers[index] -= delta
		if _deer_respawn_timers[index] > 0.0:
			continue
		_deer_respawn_timers.remove_at(index)
		_spawn_deer_in_forest()


func _process(delta: float) -> void:
	tick(delta)


# --- Spawning ---------------------------------------------------------------

func spawn_initial() -> void:
	if _initial_spawned:
		return
	_initial_spawned = true
	for index in get_day_boar_cap():
		_spawn_boar()
	for index in get_day_deer_cap():
		_spawn_deer()


## Batas populasi boar siang (Mission 9: RaidConfig.day_boar_cap).
func get_day_boar_cap() -> int:
	return raid_config.day_boar_cap if raid_config != null else boar_target


## Batas populasi rusa siang (Mission 9: RaidConfig.day_deer_cap).
func get_day_deer_cap() -> int:
	return raid_config.day_deer_cap if raid_config != null else deer_target


func get_boar_count() -> int:
	var count := 0
	for node in _fauna_nodes():
		if node is WildBoar and not (node as WildBoar).is_fleeing():
			count += 1
	return count


func get_deer_count() -> int:
	var count := 0
	for node in _fauna_nodes():
		if node is IslandDeer and not (node as IslandDeer).is_fleeing():
			count += 1
	return count


func get_hostile_count() -> int:
	var count := 0
	for node in _fauna_nodes():
		var fauna := node as FaunaBase
		if fauna != null and fauna.temperament == FaunaBase.Temperament.HOSTILE:
			count += 1
	return count


## Posisi spawn sesuai aturan jarak; Vector2.ZERO bila tidak ada penanda.
func get_spawn_position() -> Vector2:
	var tree := get_tree()
	if tree == null:
		return Vector2.ZERO
	var player_position := _player_position()
	var anchor := CampAnchor.find_anchor(self)
	var base_center := Vector2.ZERO
	var base_clear := 0.0
	if anchor != null:
		base_center = anchor.get_center()
		base_clear = anchor.get_ring_radius() + 100.0
	var raw: Array[Vector2] = []
	var all: Array[Vector2] = []
	var far: Array[Vector2] = []
	for node in tree.get_nodes_in_group(SPAWN_GROUP):
		var marker := node as Node2D
		if marker == null:
			continue
		raw.append(marker.global_position)
		if base_clear > 0.0 and marker.global_position.distance_to(base_center) < base_clear:
			continue
		# Mission 10: jangan menumpuk dengan pemain/badan fauna yang sudah ada.
		if not SpawnClearance.is_clear(tree, marker.global_position, min_body_clearance):
			continue
		all.append(marker.global_position)
		if marker.global_position.distance_to(player_position) >= min_spawn_distance:
			far.append(marker.global_position)
	if all.is_empty():
		all = raw
	if not far.is_empty():
		return far[rng.randi_range(0, far.size() - 1)]
	if all.is_empty():
		return Vector2.ZERO
	var best := all[0]
	for point in all:
		if point.distance_to(player_position) > best.distance_to(player_position):
			best = point
	return best


func _spawn_boar() -> WildBoar:
	var boar := BOAR_SCENE.instantiate() as WildBoar
	if boar == null:
		return null
	boar.clock = clock
	_parent().add_child(boar)
	boar.global_position = get_spawn_position()
	boar.temperament = FaunaBase.Temperament.NEUTRAL
	boar.died.connect(_on_fauna_died)
	return boar


## Mission 7: rusa jaminan rescue muncul di FOREST, jauh dari base & pemain.
func _spawn_deer_in_forest() -> IslandDeer:
	var deer := DEER_SCENE.instantiate() as IslandDeer
	if deer == null:
		return null
	deer.clock = clock
	_parent().add_child(deer)
	deer.global_position = _forest_spawn_position()
	deer.died.connect(_on_fauna_died)
	return deer


func _forest_spawn_position() -> Vector2:
	var tree := get_tree()
	if tree == null:
		return get_spawn_position()
	var anchor := CampAnchor.find_anchor(self)
	var base_center := anchor.get_center() if anchor != null else Vector2.ZERO
	var base_clear := (anchor.get_ring_radius() + 100.0) if anchor != null else 0.0
	var player_position := _player_position()
	var forest: Array[Vector2] = []
	for node in tree.get_nodes_in_group(SPAWN_GROUP):
		var marker := node as Node2D
		if marker == null:
			continue
		if IslandZones.zone_at(marker.global_position) != IslandZones.Zone.FOREST:
			continue
		if base_clear > 0.0 and marker.global_position.distance_to(base_center) < base_clear:
			continue
		if marker.global_position.distance_to(player_position) < min_spawn_distance:
			continue
		if not SpawnClearance.is_clear(tree, marker.global_position, min_body_clearance):
			continue
		forest.append(marker.global_position)
	if forest.is_empty():
		return get_spawn_position()
	return forest[rng.randi_range(0, forest.size() - 1)]


func _spawn_deer() -> IslandDeer:
	var deer := DEER_SCENE.instantiate() as IslandDeer
	if deer == null:
		return null
	deer.clock = clock
	_parent().add_child(deer)
	deer.global_position = get_spawn_position()
	deer.died.connect(_on_fauna_died)
	return deer


# --- Aturan fajar -----------------------------------------------------------

func _on_day_started(day: int) -> void:
	if day < 2:
		return
	_apply_dawn_rule()


func _apply_dawn_rule() -> void:
	var player_position := _player_position()
	var boars: Array[WildBoar] = []
	for node in _fauna_nodes():
		var boar := node as WildBoar
		if boar != null and not boar.is_fleeing():
			boars.append(boar)

	var boar_cap := get_day_boar_cap()
	var deer_cap := get_day_deer_cap()
	# Sisa malam kabur sampai paling banyak `boar_cap` Boar tersisa.
	for index in range(boar_cap, boars.size()):
		boars[index].begin_flee(player_position, flee_duration)

	# Survivor kembali NEUTRAL dengan multiplier 1.0.
	for index in mini(boar_cap, boars.size()):
		boars[index].reset_night_scaling()
		boars[index].set_temperament(FaunaBase.Temperament.NEUTRAL)

	while get_boar_count() < boar_cap:
		_spawn_boar()
	while get_deer_count() < deer_cap:
		_spawn_deer()


# --- Aturan rescue ----------------------------------------------------------

func _on_rescue_started() -> void:
	_rescue_mode = true
	var player_position := _player_position()
	for node in _fauna_nodes():
		var fauna := node as FaunaBase
		if fauna == null:
			continue
		if fauna is WildBoar and get_boar_count() <= get_day_boar_cap() and not fauna.is_fleeing():
			# Boar yang dijamin tetap ada; jangan disuruh kabur.
			fauna.reset_night_scaling()
			fauna.set_temperament(FaunaBase.Temperament.NEUTRAL)
			continue
		fauna.begin_flee(player_position, flee_duration)

	while get_boar_count() < get_day_boar_cap():
		var boar := _spawn_boar()
		if boar != null:
			boar.set_temperament(FaunaBase.Temperament.NEUTRAL)
	if guarantee_deer_at_rescue:
		while get_deer_count() < rescue_min_deer:
			_spawn_deer_in_forest()


func _on_fauna_died(node: Node) -> void:
	if not _rescue_mode:
		return
	if node is IslandDeer:
		if guarantee_deer_at_rescue and _deer_extra_respawns < rescue_max_extra_deer_respawns:
			_deer_extra_respawns += 1
			_deer_respawn_timers.append(rescue_respawn_delay)
		return
	if not (node is WildBoar):
		return
	if _extra_respawns >= rescue_max_extra_respawns:
		return
	_extra_respawns += 1
	_respawn_timers.append(rescue_respawn_delay)


func get_extra_respawns_left() -> int:
	return maxi(rescue_max_extra_respawns - _extra_respawns, 0)


func get_deer_extra_respawns_left() -> int:
	return maxi(rescue_max_extra_deer_respawns - _deer_extra_respawns, 0)


# --- Internal ---------------------------------------------------------------

func _parent() -> Node:
	if fauna_parent != null and is_instance_valid(fauna_parent):
		return fauna_parent
	var created := get_node_or_null("Fauna") as Node2D
	if created == null:
		created = Node2D.new()
		created.name = "Fauna"
		add_child(created)
	fauna_parent = created
	return created


func _fauna_nodes() -> Array[Node]:
	var result: Array[Node] = []
	var parent := _parent()
	for child in parent.get_children():
		if child is FaunaBase:
			result.append(child)
	return result


func _player_position() -> Vector2:
	var tree := get_tree()
	if tree == null:
		return Vector2.ZERO
	var player := tree.get_first_node_in_group(PLAYER_GROUP) as Node2D
	if player == null:
		return Vector2.ZERO
	return player.global_position

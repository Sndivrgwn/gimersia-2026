class_name NightSpawner
extends Node

## Spawner malam: saat night_started semua Boar hidup menjadi HOSTILE dengan
## scaling malam itu, satu Boar langsung muncul, lalu satu per interval selama
## jumlah Boar HOSTILE di bawah batas malam tersebut.
##
## Timer memakai delta x clock.get_time_scale(). Bukan autoload.

const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")
const DEFAULT_SCALING: NightScalingConfig = preload("res://src/data/configs/fauna/night_scaling_config.tres")
const DEFAULT_RAID_CONFIG: RaidConfig = preload("res://src/data/configs/fauna/raid_config.tres")

@export var clock: Node
@export var fauna_parent: Node2D
@export var night_scaling: NightScalingConfig = DEFAULT_SCALING
## Mission 9: batas hostile malam + pengali interval spawn.
@export var raid_config: RaidConfig = DEFAULT_RAID_CONFIG

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _night: int = 0
var _active: bool = false
var _timer: float = 0.0
var _spawned_this_night: int = 0


func _ready() -> void:
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	if night_scaling == null:
		night_scaling = DEFAULT_SCALING
	_connect_clock()


func _connect_clock() -> void:
	if clock == null:
		return
	if clock.has_signal("night_started") and not clock.is_connected("night_started", _on_night_started):
		clock.connect("night_started", _on_night_started)
	if clock.has_signal("day_started") and not clock.is_connected("day_started", _on_day_started):
		clock.connect("day_started", _on_day_started)
	if clock.has_signal("rescue_started") and not clock.is_connected("rescue_started", _on_rescue_started):
		clock.connect("rescue_started", _on_rescue_started)


func tick(delta: float) -> void:
	if not _active or delta <= 0.0:
		return
	_timer += delta * _time_scale()
	if _timer < get_spawn_interval():
		return
	_timer = 0.0
	if get_hostile_count() >= get_hostile_cap():
		return
	_spawn_boar()


## Batas hostile hidup malam ini (Mission 9: RaidConfig menimpa tabel spec).
func get_hostile_cap() -> int:
	if raid_config != null:
		return raid_config.get_night_hostile_cap(_night)
	return night_scaling.get_max_enemies(_night)


func get_spawn_interval() -> float:
	var base := night_scaling.get_spawn_interval(_night)
	if raid_config == null:
		return base
	return base * raid_config.get_spawn_interval_multiplier()


## Mission 9: RaidDirector minta boar tambahan untuk satu raid (batas hostile
## tetap dihormati).
func spawn_raid_boar() -> WildBoar:
	if get_hostile_count() >= get_hostile_cap():
		return null
	return _spawn_boar()


func _process(delta: float) -> void:
	tick(delta)


func get_night() -> int:
	return _night


func is_active() -> bool:
	return _active


func get_hostile_count() -> int:
	var count := 0
	for node in _boars():
		if node.temperament == FaunaBase.Temperament.HOSTILE:
			count += 1
	return count


func get_spawn_count_this_night() -> int:
	return _spawned_this_night


# --- Internal ---------------------------------------------------------------

func _on_night_started(day: int) -> void:
	_night = clampi(day, 1, 7)
	_active = true
	_timer = 0.0
	_spawned_this_night = 0

	var multiplier := night_scaling.get_hp_damage_multiplier(_night)
	for boar in _boars():
		boar.set_temperament(FaunaBase.Temperament.HOSTILE)
		boar.apply_night_scaling(multiplier, multiplier)

	_spawn_boar()


func _on_day_started(_day: int) -> void:
	_active = false
	_timer = 0.0


func _on_rescue_started() -> void:
	_active = false


func _spawn_boar() -> WildBoar:
	var boar := BOAR_SCENE.instantiate() as WildBoar
	if boar == null:
		return null
	boar.clock = clock
	_parent().add_child(boar)
	boar.global_position = _spawn_position()
	var multiplier := night_scaling.get_hp_damage_multiplier(_night)
	boar.apply_night_scaling(multiplier, multiplier)
	boar.set_temperament(FaunaBase.Temperament.HOSTILE)
	_spawned_this_night += 1
	return boar


func _spawn_position() -> Vector2:
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
	var far: Array[Vector2] = []
	var all: Array[Vector2] = []
	var raw: Array[Vector2] = []
	for node in tree.get_nodes_in_group(&"night_spawn_point"):
		var marker := node as Node2D
		if marker == null:
			continue
		raw.append(marker.global_position)
		if base_clear > 0.0 and marker.global_position.distance_to(base_center) < base_clear:
			continue
		all.append(marker.global_position)
		if marker.global_position.distance_to(player_position) >= 600.0:
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


func _boars() -> Array[WildBoar]:
	var result: Array[WildBoar] = []
	var parent := _parent()
	for child in parent.get_children():
		var boar := child as WildBoar
		if boar != null:
			result.append(boar)
	return result


func _parent() -> Node:
	if fauna_parent != null and is_instance_valid(fauna_parent):
		return fauna_parent
	var tree := get_tree()
	if tree != null:
		var found := tree.current_scene.get_node_or_null("Fauna") as Node2D if tree.current_scene != null else null
		if found != null:
			fauna_parent = found
			return found
	var created := get_node_or_null("../Fauna") as Node2D
	if created != null:
		fauna_parent = created
		return created
	created = Node2D.new()
	created.name = "Fauna"
	add_child(created)
	fauna_parent = created
	return created


func _player_position() -> Vector2:
	var tree := get_tree()
	if tree == null:
		return Vector2.ZERO
	var player := tree.get_first_node_in_group(&"player") as Node2D
	if player == null:
		return Vector2.ZERO
	return player.global_position


func _time_scale() -> float:
	if clock != null and clock.has_method(&"get_time_scale"):
		return float(clock.get_time_scale())
	return 1.0

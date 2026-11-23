extends GutTest

class StubClock extends Node:
	signal night_started(day: int)
	signal day_started(day: int)
	signal rescue_started
	var night: bool = false
	var day: int = 1
	var scale: float = 1.0

	func is_night() -> bool:
		return night

	func get_current_day() -> int:
		return day

	func get_time_scale() -> float:
		return scale


var _clock: StubClock
var _parent: Node2D
var _spawner: NightSpawner


func before_each() -> void:
	_clock = StubClock.new()
	add_child_autofree(_clock)
	var player := Node2D.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	for index in 3:
		var marker := Marker2D.new()
		marker.add_to_group(&"night_spawn_point")
		add_child_autofree(marker)
		marker.global_position = Vector2(800.0 + 100.0 * index, 0.0)

	_parent = Node2D.new()
	add_child_autofree(_parent)
	_spawner = NightSpawner.new()
	_spawner.clock = _clock
	_spawner.fauna_parent = _parent
	_spawner.rng.seed = 3
	add_child_autofree(_spawner)


func _boars() -> int:
	var count := 0
	for child in _parent.get_children():
		if child is WildBoar:
			count += 1
	return count


func test_night_start_spawns_one_immediately() -> void:
	_clock.night_started.emit(1)
	assert_eq(_boars(), 1)
	assert_eq(_spawner.get_hostile_count(), 1)


func test_interval_spawns_until_cap() -> void:
	_clock.night_started.emit(1)
	_spawner.tick(45.0)
	assert_eq(_boars(), 2)
	# Mission 9 (R4): batas hostile malam 1 turun dari 3 (tabel spec) ke 2
	# (RaidConfig night_active_hostile_cap).
	_spawner.tick(45.0)
	assert_eq(_boars(), 2, "batas malam 1 = 2")
	assert_eq(_spawner.get_hostile_count(), 2)


func test_time_scale_is_applied() -> void:
	_clock.night_started.emit(2)
	_clock.scale = 2.0
	_spawner.tick(20.0)
	assert_eq(_boars(), 2)


func test_zero_time_scale_stops_spawning() -> void:
	_clock.night_started.emit(1)
	_clock.scale = 0.0
	_spawner.tick(120.0)
	assert_eq(_boars(), 1)


func test_new_boars_get_night_scaling() -> void:
	_clock.night_started.emit(5)
	for child in _parent.get_children():
		if child is WildBoar:
			assert_almost_eq((child as WildBoar).get_damage_multiplier(), 1.3, 0.001)
			assert_eq((child as WildBoar).get_health().get_max_hp(), 104.0)


func test_day_start_stops_spawning() -> void:
	_clock.night_started.emit(1)
	_clock.day_started.emit(2)
	_spawner.tick(300.0)
	assert_eq(_boars(), 1)
	assert_false(_spawner.is_active())

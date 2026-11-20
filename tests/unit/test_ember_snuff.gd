extends GutTest

class StubClock extends Node:
	var night: bool = true
	var day: int = 5

	func is_night() -> bool:
		return night

	func get_current_day() -> int:
		return day

	func get_time_scale() -> float:
		return 1.0


class StubFauna extends Node2D:
	func _ready() -> void:
		add_to_group(&"fauna")


var _clock: StubClock
var _fire: Campfire


func before_each() -> void:
	_clock = StubClock.new()
	add_child_autofree(_clock)
	_fire = preload("res://src/entities/camp/campfire/campfire.tscn").instantiate() as Campfire
	add_child_autofree(_fire)
	_fire.clock = _clock
	_fire.set_fuel(300.0)


func test_remove_fuel_is_clamped() -> void:
	_fire.remove_fuel(8.0)
	assert_almost_eq(_fire.get_fuel(), 292.0, 0.001)
	_fire.remove_fuel(9999.0)
	assert_eq(_fire.get_fuel(), 0.0)
	assert_false(_fire.is_lit())


func test_ember_snuff_on_night_five() -> void:
	var fauna := StubFauna.new()
	add_child_autofree(fauna)
	_fire.take_damage(12.0, fauna)
	assert_almost_eq(_fire.get_fuel(), 292.0, 0.001)


func test_ember_snuff_only_from_night_five() -> void:
	var fauna := StubFauna.new()
	add_child_autofree(fauna)
	_clock.day = 4
	_fire.take_damage(12.0, fauna)
	assert_almost_eq(_fire.get_fuel(), 300.0, 0.001)

	_clock.day = 6
	_clock.night = false
	_fire.take_damage(12.0, fauna)
	assert_almost_eq(_fire.get_fuel(), 300.0, 0.001)


func test_non_fauna_source_does_not_snuff() -> void:
	var source := Node2D.new()
	add_child_autofree(source)
	_fire.take_damage(12.0, source)
	assert_almost_eq(_fire.get_fuel(), 300.0, 0.001)

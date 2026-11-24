extends GutTest

class StubClock extends Node:
	var night: bool = false

	func is_night() -> bool:
		return night

	func get_current_day() -> int:
		return 1


var _clock: StubClock
var _fauna: FaunaBase


func before_each() -> void:
	_clock = StubClock.new()
	add_child_autofree(_clock)
	_fauna = FaunaBase.new()
	add_child_autofree(_fauna)
	_fauna.clock = _clock
	_fauna.config = FaunaConfig.new()
	_fauna.config.max_hp = 80.0
	_fauna.ensure_ready()


func test_temperament_and_auto_target_rules() -> void:
	_fauna.temperament = FaunaBase.Temperament.NEUTRAL
	assert_false(_fauna.can_be_auto_targeted())
	_fauna.provoke(null)
	assert_true(_fauna.can_be_auto_targeted())

	_fauna.temperament = FaunaBase.Temperament.PASSIVE
	_fauna.provoke(null)
	assert_true(_fauna.is_provoked())
	_fauna.temperament = FaunaBase.Temperament.HOSTILE
	assert_true(_fauna.can_be_auto_targeted())


func test_speed_modifiers_multiply_and_clear() -> void:
	_fauna.set_speed_modifier(&"a", 0.7)
	_fauna.set_speed_modifier(&"b", 0.5)
	assert_almost_eq(_fauna.get_speed_factor(), 0.35, 0.001)
	_fauna.clear_speed_modifier(&"a")
	assert_almost_eq(_fauna.get_speed_factor(), 0.5, 0.001)
	_fauna.set_attack_speed_modifier(&"a", 0.75)
	assert_almost_eq(_fauna.get_attack_speed_factor(), 0.75, 0.001)


func test_speed_follows_phase() -> void:
	_fauna.config.move_speed_day = 115.0
	_fauna.config.move_speed_night = 150.0
	_clock.night = false
	assert_eq(_fauna.get_move_speed(), 115.0)
	_clock.night = true
	assert_eq(_fauna.get_move_speed(), 150.0)


func test_hp_bar_shows_only_when_damaged() -> void:
	assert_false(_fauna.get_hp_bar().visible)
	_fauna.get_health().take_damage(10.0, null)
	assert_true(_fauna.get_hp_bar().visible)
	assert_eq(_fauna.get_hp_bar().value, 70.0)


func test_night_scaling_keeps_hp_ratio() -> void:
	_fauna.get_health().take_damage(40.0, null)
	_fauna.apply_night_scaling(1.5, 1.5)
	assert_eq(_fauna.get_health().get_max_hp(), 120.0)
	assert_eq(_fauna.get_damage_multiplier(), 1.5)
	assert_almost_eq(_fauna.get_health().get_current_hp(), 60.0, 0.001)

	_fauna.reset_night_scaling()
	assert_eq(_fauna.get_health().get_max_hp(), 80.0)
	assert_eq(_fauna.get_damage_multiplier(), 1.0)
	assert_false(_fauna.is_provoked())


func test_dazzle_from_lit_campfire() -> void:
	var fire := preload("res://src/entities/camp/campfire/campfire.tscn").instantiate() as Campfire
	add_child_autofree(fire)
	fire.global_position = _fauna.global_position + Vector2(50.0, 0.0)
	fire.set_fuel(100.0)
	# Mission 9 (R4): api unggun baru dibangun COLD.
	fire.ignite()
	_fauna.tick(0.1)
	assert_almost_eq(_fauna.get_speed_factor(), 0.7, 0.001)
	assert_almost_eq(_fauna.get_attack_speed_factor(), 0.75, 0.001)

	fire.set_fuel(0.0)
	_fauna.tick(0.1)
	assert_almost_eq(_fauna.get_speed_factor(), 1.0, 0.001)

	fire.global_position = _fauna.global_position + Vector2(400.0, 0.0)
	fire.set_fuel(100.0)
	_fauna.tick(0.1)
	assert_almost_eq(_fauna.get_speed_factor(), 1.0, 0.001)

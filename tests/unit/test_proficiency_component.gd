extends GutTest

class StubClock extends Node:
	var night: bool = false
	var rescuing: bool = false
	signal day_started(day: int)
	signal rescue_started

	func is_night() -> bool:
		return night

	func get_current_day() -> int:
		return 1

	func get_time_scale() -> float:
		return 1.0

	func get_max_days() -> int:
		return 7


var _player: Player
var _prof: ProficiencyComponent
var _clock: StubClock


func before_each() -> void:
	_player = preload("res://src/entities/player/player.tscn").instantiate() as Player
	add_child_autofree(_player)
	var inventory := InventoryComponent.new()
	inventory.name = "InventoryComponent"
	_player.add_child(inventory)

	_clock = StubClock.new()
	add_child_autofree(_clock)

	_prof = ProficiencyComponent.new()
	_player.add_child(_prof)
	_prof.clock = _clock
	_prof.rng_seed = 7


func after_each() -> void:
	_player.queue_free()


func test_level_up_carries_overflow() -> void:
	_prof.add_xp(ProficiencyComponent.Prof.STRENGTH, 250.0)
	# Lv1 -> Lv2 butuh 100, sisa 150 < 200 (Lv2 -> Lv3).
	assert_eq(_player.stats.strength_level, 2)
	assert_almost_eq(_prof.get_xp(ProficiencyComponent.Prof.STRENGTH), 150.0, 0.01)


func test_max_level_locks_xp_at_zero() -> void:
	_player.stats.strength_level = 10
	_prof.add_xp(ProficiencyComponent.Prof.STRENGTH, 500.0)
	assert_eq(_player.stats.strength_level, 10)
	assert_eq(_prof.get_xp(ProficiencyComponent.Prof.STRENGTH), 0.0)


func test_max_reached_level_tracks_only_the_maximum() -> void:
	_prof.add_xp(ProficiencyComponent.Prof.MASTERY, 100.0)
	assert_eq(_prof.get_max_reached_level(ProficiencyComponent.Prof.MASTERY), 2)
	_player.stats.mastery_level = 1
	assert_eq(_prof.get_max_reached_level(ProficiencyComponent.Prof.MASTERY), 2)


func test_combat_xp_is_multiplied_at_night() -> void:
	_clock.night = true
	_prof.add_xp(ProficiencyComponent.Prof.STRENGTH, 10.0, true)
	assert_almost_eq(_prof.get_xp(ProficiencyComponent.Prof.STRENGTH), 15.0, 0.01)

	_prof.add_xp(ProficiencyComponent.Prof.MASTERY, 10.0, false)
	assert_almost_eq(_prof.get_xp(ProficiencyComponent.Prof.MASTERY), 10.0, 0.01)


func test_sturdy_halves_knockback_at_strength_six() -> void:
	_player.stats.strength_level = 6
	assert_almost_eq(_player.knockback_multiplier, 0.5, 0.001)
	_player.stats.strength_level = 5
	assert_almost_eq(_player.knockback_multiplier, 1.0, 0.001)


func test_heavy_strike_every_fourth_landed_hit() -> void:
	_player.stats.strength_level = 3
	var damages: Array[float] = []
	for index in 4:
		damages.append(_prof._modify_hit(100.0, null))
	assert_almost_eq(damages[0], 100.0, 0.01)
	assert_almost_eq(damages[3], 130.0, 0.01)


func test_second_wind_multiplies_only_the_campfire_override() -> void:
	var needs := NeedsComponent.new()
	needs.name = "TestNeeds"
	_player.add_child(needs)
	needs.clock = _clock
	_prof.needs = needs
	_player.stats.speed_level = 6

	needs.set_idle_regen_override(&"campfire", 5.0)
	assert_almost_eq(needs.get_idle_regen(), 5.0 * 1.25, 0.01)
	needs.clear_idle_regen_override(&"campfire")
	assert_almost_eq(needs.get_idle_regen(), needs.get_config().fatigue_idle_regen, 0.01)


func test_death_debuff_drops_two_highest_eligible_levels() -> void:
	_player.stats.strength_level = 4
	_prof.add_xp(ProficiencyComponent.Prof.STRENGTH, 0.0)
	_prof._max_reached[ProficiencyComponent.Prof.STRENGTH] = 4
	_player.stats.agility_level = 3
	_prof._max_reached[ProficiencyComponent.Prof.AGILITY] = 3
	_player.stats.speed_level = 2
	_prof._max_reached[ProficiencyComponent.Prof.SPEED] = 2
	_player.stats.mastery_level = 1

	var changed := _prof.apply_death_debuff()
	assert_eq(changed, [ProficiencyComponent.Prof.STRENGTH, ProficiencyComponent.Prof.AGILITY])
	assert_eq(_player.stats.strength_level, 3)
	assert_eq(_player.stats.agility_level, 2)
	assert_eq(_player.stats.speed_level, 2)
	assert_eq(_prof.get_xp(ProficiencyComponent.Prof.STRENGTH), 0.0)


func test_death_debuff_skips_level_one() -> void:
	var changed := _prof.apply_death_debuff()
	assert_true(changed.is_empty())
	assert_eq(_player.stats.strength_level, 1)

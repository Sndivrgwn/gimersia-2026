extends GutTest

class StubClock extends Node:
	var night: bool = false
	var day: int = 1
	var scale: float = 1.0

	func is_night() -> bool:
		return night

	func get_current_day() -> int:
		return day

	func get_time_scale() -> float:
		return scale


class StubPlayer extends Node2D:
	var stats: StatsComponent
	var receiver: PlayerDamageReceiver
	var facing_direction := Vector2.RIGHT
	var knockback_multiplier := 1.0

	func _init() -> void:
		stats = StatsComponent.new()
		stats.name = "StatsComponent"
		add_child(stats)
		receiver = PlayerDamageReceiver.new()
		receiver.name = "PlayerDamageReceiver"
		add_child(receiver)


const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")


func _setup(night: bool = false) -> Array:
	var clock := StubClock.new()
	add_child_autofree(clock)
	clock.night = night
	var player := StubPlayer.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2.ZERO
	var boar := BOAR_SCENE.instantiate() as WildBoar
	boar.clock = clock
	boar.player = player
	add_child_autofree(boar)
	boar.global_position = Vector2(200.0, 0.0)
	boar.ensure_ready()
	return [boar, player, clock]


func test_day_boar_is_neutral_until_provoked() -> void:
	var setup := _setup(false)
	var boar := setup[0] as WildBoar
	assert_eq(boar.get_temperament(), FaunaBase.Temperament.NEUTRAL)
	assert_false(boar.can_be_auto_targeted())
	boar.provoke(null)
	assert_true(boar.can_be_auto_targeted())
	assert_eq(boar.get_temperament(), FaunaBase.Temperament.NEUTRAL, "siang tetap NEUTRAL, hanya provoked")


func test_night_boar_is_hostile() -> void:
	var setup := _setup(true)
	var boar := setup[0] as WildBoar
	assert_eq(boar.get_temperament(), FaunaBase.Temperament.HOSTILE)
	assert_true(boar.can_be_auto_targeted())
	assert_eq(boar.get_move_speed(), 150.0)


func test_bite_damages_player_in_range() -> void:
	var setup := _setup(true)
	var boar := setup[0] as WildBoar
	var player := setup[1] as StubPlayer
	boar.global_position = Vector2(40.0, 0.0)
	var before: float = player.stats.current_hp
	boar.tick(0.01)
	assert_eq(player.stats.current_hp, before - 12.0)


func test_dash_telegraph_then_hit_with_knockback() -> void:
	var setup := _setup(true)
	var boar := setup[0] as WildBoar
	var player := setup[1] as StubPlayer
	boar.global_position = Vector2(180.0, 0.0)
	var before: float = player.stats.current_hp
	boar.tick(0.01)
	assert_eq(boar.get_state(), WildBoar.State.DASH_TELEGRAPH)
	boar.tick(0.8)
	assert_eq(boar.get_state(), WildBoar.State.DASH)
	watch_signals(boar)
	for index in 40:
		boar.tick(0.05)
		if player.stats.current_hp < before:
			break
	assert_eq(player.stats.current_hp, before - 20.0)
	assert_gt(boar.get_state(), WildBoar.State.DASH_TELEGRAPH)


func test_dash_not_used_outside_window() -> void:
	var setup := _setup(true)
	var boar := setup[0] as WildBoar
	boar.global_position = Vector2(500.0, 0.0)
	boar.tick(0.05)
	assert_ne(boar.get_state(), WildBoar.State.DASH_TELEGRAPH)


func test_day_boar_leashes_back_to_neutral() -> void:
	var setup := _setup(false)
	var boar := setup[0] as WildBoar
	boar.provoke(null)
	boar.global_position = Vector2(500.0, 0.0)
	boar.tick(0.05)
	assert_false(boar.is_provoked())
	assert_eq(boar.get_temperament(), FaunaBase.Temperament.NEUTRAL)


func test_boar_targets_camp_structure_when_raiding() -> void:
	var setup := _setup(true)
	var boar := setup[0] as WildBoar
	var structure := CampStructure.new()
	structure.definition = StructureDefinition.new()
	structure.definition.max_hp = 120.0
	structure.definition.aggro_priority = 0
	add_child_autofree(structure)
	structure.apply_definition()
	structure.global_position = Vector2(30.0, 0.0)
	boar.global_position = Vector2(80.0, 0.0)
	var player := setup[1] as StubPlayer
	player.global_position = Vector2(900.0, 0.0)
	# Mission 9 (R4): struktur hanya diserang raider (EVENT_ONLY) atau saat mode
	# ALWAYS; tes lama mengasumsikan semua boar hostile menyerang struktur.
	boar.set_raider(true)
	var before: float = structure.get_current_hp()
	boar.tick(0.01)
	assert_lt(structure.get_current_hp(), before)


func test_scaled_damage_multiplier() -> void:
	var setup := _setup(true)
	var boar := setup[0] as WildBoar
	var player := setup[1] as StubPlayer
	boar.apply_night_scaling(1.5, 1.5)
	boar.global_position = Vector2(40.0, 0.0)
	var before: float = player.stats.current_hp
	boar.tick(0.01)
	assert_eq(player.stats.current_hp, before - 18.0)

extends GutTest

## Mission 9 Phase 3.5: regen HP pasif yang diskalakan Hunger/Thirst.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")


class StubClock extends Node:
	var scale_value: float = 1.0

	func get_time_scale() -> float:
		return scale_value

	func is_night() -> bool:
		return false

	func get_current_day() -> int:
		return 1


var clock: StubClock
var player: Player
var stats: StatsComponent
var needs: NeedsComponent
var regen: HealthRegenComponent


func before_each() -> void:
	clock = StubClock.new()
	add_child_autofree(clock)
	player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.set_physics_process(false)
	stats = player.get_node("StatsComponent") as StatsComponent
	needs = player.get_node("NeedsComponent") as NeedsComponent
	needs.set_process(false)
	needs.setup(clock, stats, player)
	regen = HealthRegenComponent.new()
	regen.name = "HealthRegenComponent"
	player.add_child(regen)
	regen.set_process(false)
	regen.config = preload("res://src/data/configs/health_regen_config.tres")
	regen.clock = clock
	regen._bind()
	regen.set_since_damage(regen.config.out_of_combat_delay)
	stats.set_hp(stats.get_max_hp() * 0.5)


# --- Kurva ------------------------------------------------------------------

func test_curve_sampling_is_linear() -> void:
	var points := PackedVector2Array([Vector2(0, 0), Vector2(30, 0.3), Vector2(60, 0.75), Vector2(100, 1.0)])
	assert_almost_eq(HealthRegenConfig.sample_curve(points, 0.0), 0.0, 0.001)
	assert_almost_eq(HealthRegenConfig.sample_curve(points, 15.0), 0.15, 0.001)
	assert_almost_eq(HealthRegenConfig.sample_curve(points, 30.0), 0.3, 0.001)
	assert_almost_eq(HealthRegenConfig.sample_curve(points, 45.0), 0.525, 0.001)
	assert_almost_eq(HealthRegenConfig.sample_curve(points, 100.0), 1.0, 0.001)
	assert_almost_eq(HealthRegenConfig.sample_curve(points, 200.0), 1.0, 0.001, "di atas kurva: nilai ujung")


func test_final_multiplier_is_the_worst_of_hunger_and_thirst() -> void:
	var config := HealthRegenConfig.new()
	assert_almost_eq(config.get_multiplier(100.0, 100.0), 1.0, 0.001)
	assert_almost_eq(config.get_multiplier(100.0, 30.0), 0.3, 0.001)
	assert_almost_eq(config.get_multiplier(60.0, 30.0), 0.3, 0.001, "min dari keduanya")


# --- Tick -------------------------------------------------------------------

func test_no_regen_while_hp_is_full() -> void:
	stats.set_hp(stats.get_max_hp())
	regen.tick(30.0)
	assert_almost_eq(stats.current_hp, stats.get_max_hp(), 0.001)


func test_regen_waits_for_out_of_combat_delay() -> void:
	regen.set_since_damage(0.0)
	stats.set_hp(stats.get_max_hp() - 30.0)
	regen.tick(2.0)
	assert_almost_eq(stats.current_hp, stats.get_max_hp() - 30.0, 0.001, "masih dalam jeda")
	regen.tick(5.0)
	assert_gt(stats.current_hp, stats.get_max_hp() - 30.0, "regen mulai setelah 6 dtk")


func test_damage_restarts_the_out_of_combat_delay() -> void:
	regen.tick(7.0)
	stats.set_hp(stats.current_hp - 20.0)
	var after_damage := stats.current_hp
	regen.tick(3.0)
	assert_almost_eq(stats.current_hp, after_damage, 0.001, "damage mengulang jeda")


func test_regen_scales_with_hunger_and_thirst() -> void:
	needs.set_value(NeedsComponent.Need.HUNGER, 100.0)
	needs.set_value(NeedsComponent.Need.THIRST, 100.0)
	stats.set_hp(stats.get_max_hp() * 0.5)
	var before := stats.current_hp
	regen.tick(10.0)
	var full_regen := stats.current_hp - before
	assert_almost_eq(full_regen, 5.0, 0.05, "0.5 HP/dtk selama 10 dtk")

	needs.set_value(NeedsComponent.Need.THIRST, 30.0)
	stats.set_hp(stats.get_max_hp() * 0.5)
	before = stats.current_hp
	regen.tick(10.0)
	assert_almost_eq(stats.current_hp - before, full_regen * 0.3, 0.1, "thirst 30 = 0.3x")


func test_no_regen_at_zero_tier() -> void:
	needs.set_value(NeedsComponent.Need.HUNGER, 0.0)
	stats.set_hp(stats.get_max_hp() * 0.5)
	var before := stats.current_hp
	regen.tick(20.0)
	assert_almost_eq(stats.current_hp, before, 0.001, "kerusakan kelaparan menang")


func test_regen_follows_game_time_scale() -> void:
	needs.set_value(NeedsComponent.Need.HUNGER, 100.0)
	needs.set_value(NeedsComponent.Need.THIRST, 100.0)
	clock.scale_value = 2.0
	stats.set_hp(stats.get_max_hp() * 0.5)
	var before := stats.current_hp
	regen.tick(10.0)
	assert_almost_eq(stats.current_hp - before, 10.0, 0.1, "Jaga Malam x2 menggandakan regen")

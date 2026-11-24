extends GutTest

## Mission 9 Phase 0.3 + 3.4: pengukuran drain satu siklus penuh (Hari 1 siang
## 300 s + malam 300 s, time scale 1, diam, tanpa makan) dan batas target.

class StubClock extends Node:
	var night: bool = false
	var day: int = 1
	var scale_value: float = 1.0

	func is_night() -> bool:
		return night

	func get_current_day() -> int:
		return day

	func get_time_scale() -> float:
		return scale_value


const TICK := 1.0
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")

var clock: StubClock
var needs: NeedsComponent


func before_each() -> void:
	clock = StubClock.new()
	add_child_autofree(clock)
	needs = NeedsComponent.new()
	needs.name = "NeedsComponent"
	needs.clock = clock
	add_child_autofree(needs)
	needs.set_process(false)
	needs.tick(TICK)


## Jalankan satu siklus penuh dengan `config` tertentu.
func _run_cycle(config: NeedsConfig) -> Dictionary:
	needs.config = config
	needs.set_value(NeedsComponent.Need.HUNGER, 100.0)
	needs.set_value(NeedsComponent.Need.THIRST, 100.0)
	clock.night = false
	clock.day = 1
	for index in 300:
		needs.tick(TICK)
	var hunger_day := needs.get_value(NeedsComponent.Need.HUNGER)
	var thirst_day := needs.get_value(NeedsComponent.Need.THIRST)
	clock.night = true
	for index in 300:
		needs.tick(TICK)
	return {
		"hunger_day": hunger_day,
		"thirst_day": thirst_day,
		"hunger_night": needs.get_value(NeedsComponent.Need.HUNGER),
		"thirst_night": needs.get_value(NeedsComponent.Need.THIRST),
	}


func _baseline_config() -> NeedsConfig:
	var config := NeedsConfig.new()
	config.global_drain_multiplier = 1.0
	config.hunger_drain_multiplier = 1.0
	config.thirst_drain_multiplier = 1.0
	return config


func test_baseline_cycle_numbers_before_rebalance() -> void:
	var result := _run_cycle(_baseline_config())
	print("PHASE0.3 baseline: hunger day=%.2f night=%.2f | thirst day=%.2f night=%.2f" % [
		result["hunger_day"], result["hunger_night"],
		result["thirst_day"], result["thirst_night"],
	])
	assert_almost_eq(result["hunger_day"], 52.0, 0.5)
	assert_almost_eq(result["thirst_day"], 28.0, 0.5)


func test_first_cycle_lands_inside_the_targets() -> void:
	var result := _run_cycle(NeedsConfig.new())
	print("PHASE3.4 balanced: hunger day=%.2f night=%.2f | thirst day=%.2f night=%.2f" % [
		result["hunger_day"], result["hunger_night"],
		result["thirst_day"], result["thirst_night"],
	])
	assert_gte(result["hunger_night"], 30.0, "Hunger akhir siklus 1 >= 30")
	assert_lte(result["hunger_night"], 45.0, "Hunger akhir siklus 1 <= 45")
	assert_gte(result["thirst_night"], 15.0, "Thirst akhir siklus 1 >= 15")
	assert_lte(result["thirst_night"], 35.0, "Thirst akhir siklus 1 <= 35")


func test_multipliers_keep_the_spec_day_night_ratio() -> void:
	var config := NeedsConfig.new()
	assert_gt(config.hunger_night_drain, config.hunger_day_drain, "malam tetap lebih cepat")
	assert_lt(config.thirst_night_drain, config.thirst_day_drain, "malam tetap lebih lambat")


func test_per_day_multiplier_scales_the_drain() -> void:
	var config := NeedsConfig.new()
	config.drain_multiplier_by_day = [1.0, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0]
	assert_almost_eq(config.hunger_drain_scale(2), config.hunger_drain_scale(1) * 2.0, 0.001)
	clock.day = 2
	needs.config = config
	var before := needs.get_value(NeedsComponent.Need.HUNGER)
	needs.tick(10.0)
	var drained := before - needs.get_value(NeedsComponent.Need.HUNGER)
	assert_almost_eq(drained, config.hunger_day_drain * config.hunger_drain_scale(2) * 10.0, 0.01)


func test_global_multiplier_applies_to_both_needs() -> void:
	var config := NeedsConfig.new()
	config.global_drain_multiplier = 2.0
	clock.day = 1
	needs.config = config
	var hunger_before := needs.get_value(NeedsComponent.Need.HUNGER)
	var thirst_before := needs.get_value(NeedsComponent.Need.THIRST)
	needs.tick(10.0)
	assert_almost_eq(hunger_before - needs.get_value(NeedsComponent.Need.HUNGER),
		config.hunger_day_drain * config.hunger_drain_scale(1) * 10.0, 0.01)
	assert_almost_eq(thirst_before - needs.get_value(NeedsComponent.Need.THIRST),
		config.thirst_day_drain * config.thirst_drain_scale(1) * 10.0, 0.01)


# --- Sprint lock ------------------------------------------------------------

func test_hunger_at_threshold_blocks_sprint_and_31_unlocks() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	player.set_physics_process(false)
	needs.player = player
	needs.config = NeedsConfig.new()
	needs.set_value(NeedsComponent.Need.HUNGER, 30.0)
	assert_true(player.is_sprint_blocked())
	assert_true(player.get_sprint_blocks().has(&"hunger"))
	assert_true(needs.is_hunger_sprint_locked())
	needs.set_value(NeedsComponent.Need.HUNGER, 31.0)
	assert_false(player.is_sprint_blocked(), "di atas 30 sprint kembali aktif")
	assert_false(needs.is_hunger_sprint_locked())

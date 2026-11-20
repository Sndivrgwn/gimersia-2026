extends GutTest

const CONFIG: NightScalingConfig = preload("res://src/data/configs/fauna/night_scaling_config.tres")


func test_table_values_match_spec() -> void:
	var max_enemies := [3, 4, 5, 6, 7, 9, 12]
	var intervals := [45.0, 40.0, 35.0, 30.0, 25.0, 20.0, 15.0]
	var multipliers := [1.0, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5]
	for night in range(1, 8):
		assert_eq(CONFIG.get_max_enemies(night), max_enemies[night - 1])
		assert_eq(CONFIG.get_spawn_interval(night), intervals[night - 1])
		assert_eq(CONFIG.get_hp_damage_multiplier(night), multipliers[night - 1])


func test_night_index_is_clamped() -> void:
	assert_eq(CONFIG.get_max_enemies(0), 3)
	assert_eq(CONFIG.get_max_enemies(99), 12)
	assert_eq(CONFIG.get_hp_damage_multiplier(-5), 1.0)

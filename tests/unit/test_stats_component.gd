extends GutTest

## Tes unit StatsComponent (GUT 9.x, Godot 4).
## Angka yang diuji mengikuti rumus Bagian 5.B spesifikasi.

var stats: StatsComponent


func before_each() -> void:
	stats = StatsComponent.new()
	add_child_autofree(stats)


func test_default_values() -> void:
	assert_eq(stats.strength_level, 1)
	assert_eq(stats.speed_level, 1)
	assert_eq(stats.mastery_level, 1)
	assert_eq(stats.agility_level, 1)
	assert_almost_eq(stats.get_max_hp(), 100.0, 0.001)
	assert_almost_eq(stats.get_move_speed(), 160.0, 0.001)
	assert_almost_eq(stats.get_sprint_speed(), 240.0, 0.001)
	assert_almost_eq(stats.get_attack_damage(), 8.0, 0.001)
	assert_almost_eq(stats.get_attack_speed(), 1.2, 0.001)
	assert_almost_eq(stats.get_dodge_chance(), 0.0, 0.001)
	assert_almost_eq(stats.get_attack_cooldown(), 0.8333333, 0.001)


func test_strength_level_4() -> void:
	stats.strength_level = 4
	assert_almost_eq(stats.get_max_hp(), 115.0, 0.001)
	assert_almost_eq(stats.get_attack_damage(), 10.4, 0.001)


func test_speed_level_3() -> void:
	stats.speed_level = 3
	assert_almost_eq(stats.get_move_speed(), 172.8, 0.001)
	assert_almost_eq(stats.get_sprint_speed(), 276.48, 0.001)


func test_agility_level_6() -> void:
	stats.agility_level = 6
	assert_almost_eq(stats.get_dodge_chance(), 0.10, 0.001)
	assert_almost_eq(stats.get_attack_speed(), 1.5, 0.001)


func test_dodge_hard_cap() -> void:
	stats.agility_level = 10
	stats.add_modifier(&"uji_dodge", &"dodge", StatModifier.Kind.PERCENT, 0.6)
	assert_almost_eq(stats.get_dodge_chance(), 0.5, 0.001)


func test_percent_modifiers_additive() -> void:
	stats.add_modifier(&"lapar", &"move_speed", StatModifier.Kind.PERCENT, -0.15)
	stats.add_modifier(&"kelelahan_ekstrem", &"move_speed", StatModifier.Kind.PERCENT, -0.45)
	assert_almost_eq(stats.get_move_speed(), 64.0, 0.001)

	stats.add_modifier(&"penalti_besar", &"move_speed", StatModifier.Kind.PERCENT, -1.0)
	assert_almost_eq(stats.get_move_speed(), 40.0, 0.001)


func test_leather_armor() -> void:
	stats.add_modifier(&"zirah_kulit", &"max_hp", StatModifier.Kind.FLAT, 15.0)
	stats.add_modifier(&"zirah_kulit", &"damage_reduction", StatModifier.Kind.PERCENT, 0.20)
	assert_almost_eq(stats.get_max_hp(), 115.0, 0.001)
	assert_almost_eq(stats.get_damage_reduction(), 0.20, 0.001)
	assert_almost_eq(stats.calc_incoming_damage(10.0), 8.0, 0.001)


func test_remove_modifier() -> void:
	stats.add_modifier(&"buff_move", &"move_speed", StatModifier.Kind.PERCENT, 0.5)
	assert_almost_eq(stats.get_move_speed(), 240.0, 0.001)

	watch_signals(stats)
	stats.remove_modifier(&"buff_move")
	assert_almost_eq(stats.get_move_speed(), 160.0, 0.001)
	assert_signal_emitted(stats, "stats_changed")


func test_hp_clamp_on_max_hp_drop() -> void:
	stats.add_modifier(&"zirah_kulit", &"max_hp", StatModifier.Kind.FLAT, 15.0)
	stats.set_hp(stats.get_max_hp())
	assert_almost_eq(stats.current_hp, 115.0, 0.001)

	watch_signals(stats)
	stats.remove_modifier(&"zirah_kulit")
	assert_almost_eq(stats.get_max_hp(), 100.0, 0.001)
	assert_almost_eq(stats.current_hp, 100.0, 0.001)
	assert_signal_emitted(stats, "hp_changed")


func test_level_setter_clamp() -> void:
	stats.strength_level = 99
	assert_eq(stats.strength_level, 10)
	stats.strength_level = -3
	assert_eq(stats.strength_level, 1)

	stats.speed_level = 0
	assert_eq(stats.speed_level, 1)
	stats.mastery_level = 11
	assert_eq(stats.mastery_level, 10)
	stats.agility_level = -1
	assert_eq(stats.agility_level, 1)


func test_craft_time_factor() -> void:
	stats.mastery_level = 4
	assert_almost_eq(stats.get_craft_time_factor(), 0.82, 0.001)
	stats.mastery_level = 10
	assert_almost_eq(stats.get_craft_time_factor(), 0.46, 0.001)

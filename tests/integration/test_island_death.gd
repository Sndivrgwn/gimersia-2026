extends GutTest

const IslandHarness = preload("res://tests/integration/island_harness.gd")

var _harness: IslandHarness


func before_each() -> void:
	_harness = IslandHarness.new()
	_harness.setup(self)


func after_each() -> void:
	if _harness != null:
		_harness.teardown()
		_harness = null


func test_s4_death_loop() -> void:
	var stats := _harness.stats
	var needs := _harness.needs
	var inv := _harness.inventory
	var prof := _harness.proficiency
	var death := _harness.death
	var player := _harness.player
	var clock := _harness.clock

	# Equip a weapon and put items in bag
	inv.add_item(ItemCatalog.WOODEN_SPEAR, 1)
	inv.equip(ItemCatalog.WOODEN_SPEAR)
	assert_not_null(inv.get_equipped(ItemDefinition.EquipmentSlot.WEAPON), "Weapon harus terpasang")

	inv.add_item(ItemCatalog.WOOD, 10)
	inv.add_item(ItemCatalog.BERRY, 5)
	assert_eq(inv.count_of(ItemCatalog.WOOD), 10)
	assert_eq(inv.count_of(ItemCatalog.BERRY), 5)

	# Give proficiency XP
	prof.add_xp(ProficiencyComponent.Prof.SPEED, 300.0)
	var speed_level_before := prof.get_level(ProficiencyComponent.Prof.SPEED)

	# Move player to a specific position
	player.global_position = Vector2(300.0, 400.0)
	var death_pos := player.global_position

	watch_signals(death)

	# --- Death 1 ---
	stats.set_hp(0.0)
	assert_signal_emitted(death, "died")
	assert_true(death.can_respawn(), "Kematian 1 harus bisa respawn")
	assert_eq(death.get_respawns_remaining(), 2, "Sisa token setelah kematian 1 harus 2")

	# Loot bag holds the bag stacks
	var loot_bag := death.get_last_loot_bag()
	assert_not_null(loot_bag, "LootBag harus dibuat di lokasi kematian")
	assert_eq(loot_bag.global_position, death_pos, "LootBag harus berada di lokasi kematian")
	assert_gt(loot_bag.get_stack_count(), 0, "LootBag harus berisi stack item")
	assert_gt(loot_bag.get_total_items(), 0, "LootBag harus berisi total item dari tas")

	# Bag empty, equipment kept
	assert_eq(inv.count_of(ItemCatalog.WOOD), 0, "Tas pemain harus kosong setelah mati")
	assert_eq(inv.count_of(ItemCatalog.BERRY), 0, "Tas pemain harus kosong setelah mati")
	assert_not_null(inv.get_equipped(ItemDefinition.EquipmentSlot.WEAPON), "Equipment harus tetap terpasang")

	# Mission 9 (R4, keputusan owner): selama layar mati seluruh game dibekukan
	# (FreezeController alasan &"death") sehingga jam game berhenti.
	assert_true(get_tree().paused, "game dibekukan saat mati")
	assert_almost_eq(clock.get_time_scale(), 0.0, 0.001, "jam berhenti saat mati")

	# Respawn
	var max_hp_at_respawn := stats.get_max_hp()
	assert_true(death.respawn(), "Respawn harus berhasil")
	assert_eq(player.global_position, Vector2(0.0, 64.0), "Posisi respawn harus (0, 64)")
	assert_almost_eq(stats.current_hp, max_hp_at_respawn * 0.7, 0.1, "HP harus 70% setelah respawn")
	assert_almost_eq(needs.get_value(NeedsComponent.Need.HUNGER), 60.0, 0.1, "Hunger harus 60 setelah respawn")
	assert_almost_eq(needs.get_value(NeedsComponent.Need.THIRST), 60.0, 0.1, "Thirst harus 60 setelah respawn")
	assert_almost_eq(needs.get_value(NeedsComponent.Need.FATIGUE), 80.0, 0.1, "Fatigue harus 80 setelah respawn")

	# Debuff applied on respawn
	var speed_level_after := prof.get_level(ProficiencyComponent.Prof.SPEED)
	assert_true(speed_level_after <= speed_level_before, "Proficiency debuff harus diterapkan pada respawn")

	# --- Death 2 ---
	stats.set_hp(0.0)
	assert_true(death.can_respawn(), "Kematian 2 harus bisa respawn")
	assert_eq(death.get_respawns_remaining(), 1, "Sisa token setelah kematian 2 harus 1")
	assert_true(death.respawn(), "Respawn 2 harus berhasil")

	# --- Death 3 ---
	stats.set_hp(0.0)
	assert_true(death.can_respawn(), "Kematian 3 harus bisa respawn (token 0)")
	assert_eq(death.get_respawns_remaining(), 0, "Sisa token setelah kematian 3 harus 0")
	assert_true(death.respawn(), "Respawn 3 harus berhasil")

	# --- Death 4 ---
	stats.set_hp(0.0)
	assert_signal_emitted(death, "game_over")
	assert_false(death.can_respawn(), "Kematian 4 tidak boleh bisa respawn (game over)")
	assert_false(death.respawn(), "Respawn pada kematian 4 harus gagal")

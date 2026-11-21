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


func test_s3_night_loop() -> void:
	var spawner := _harness.spawner
	var clock := _harness.clock
	var camp := _harness.camp
	var inter := _harness.interactor
	var inv := _harness.inventory

	# Build Campfire at camp
	inv.add_item(ItemCatalog.WOOD, 4)
	inv.add_item(ItemCatalog.STONE, 3)
	inv.add_item(ItemCatalog.FIBER, 2)
	var campfire_slot := camp.get_node("CampfireSlot") as BlueprintSlot
	campfire_slot.interact(inter)
	var campfire := camp.get_structure(&"campfire") as Campfire
	assert_not_null(campfire, "Campfire harus terbangun")
	assert_true(campfire.is_lit(), "Campfire harus menyala")

	# 1. Advance to night 1 (day_seconds is 450)
	_harness.advance_time(450.0)
	assert_true(clock.is_night(), "Clock harus berada di fase malam")
	assert_eq(clock.get_current_day(), 1, "Malam hari 1")

	# NightSpawner spawns at least 1 hostile immediately
	var hostiles_night1 := spawner.get_hostile_count()
	assert_true(hostiles_night1 >= 1, "NightSpawner harus men-spawn setidaknya 1 hostile saat malam 1 dimulai")

	# Advance across night 1 in steps, never exceed table max (3 for night 1)
	var max_night1 := spawner.night_scaling.get_max_enemies(1)
	assert_eq(max_night1, 3, "Max enemies malam 1 adalah 3")
	for i in range(5):
		_harness.advance_time(45.0)
		assert_true(spawner.get_hostile_count() <= max_night1, "Jumlah hostile malam 1 tidak boleh melebihi max 3")

	# 2. Hostile boar far from camp does not raid an empty camp
	var boars := []
	for child in _harness.fauna_parent.get_children():
		if child is WildBoar:
			boars.append(child as WildBoar)
	assert_gt(boars.size(), 0, "Harus ada WildBoar di pulau")

	var far_boar := boars[0] as WildBoar
	far_boar.global_position = Vector2(1800.0, 1800.0)
	far_boar.tick(0.1)
	assert_false(far_boar.raid_camp, "Boar jauh dari camp tidak boleh raid_camp")

	# 3. Boar inside camp damages structures by priority
	# Build Chest (priority 1) in addition to Campfire (priority 0)
	inv.add_item(ItemCatalog.WOOD, 6)
	inv.add_item(ItemCatalog.FIBER, 2)
	var chest_slot := camp.get_node("ChestSlot") as BlueprintSlot
	chest_slot.interact(inter)
	var chest := camp.get_structure(&"chest") as CampStructure
	assert_not_null(chest, "Chest harus terbangun")

	var camp_boar := boars[0] as WildBoar
	# Refuel campfire so it is lit and dazzle is active (D3: nyalakan bila COLD)
	campfire.set_fuel(200.0)
	if campfire.is_cold():
		campfire.ignite()

	# Raid camp hanya boleh terjadi saat boar HOSTILE (malam).
	while not clock.is_night():
		clock.skip_time(clock.get_remaining_seconds() + 0.1)
		_harness.advance_time(0.1)

	# Position player in camp (length <= raid_camp_radius 180) but beyond camp_player_radius (140)
	# so boar triggers raid_camp and prioritizes structures over the player
	_harness.player.global_position = Vector2(0.0, 160.0)
	camp_boar.global_position = Vector2(0.0, 0.0)
	camp_boar.tick(0.1)
	camp_boar.tick(0.1)
	assert_true(camp_boar.raid_camp, "Boar HOSTILE di dalam area camp harus raid_camp")
	var target_struct := camp_boar.nearest_structure()
	assert_eq(target_struct, campfire, "Struktur dengan prioritas aggro tertinggi harus ditarget (Campfire priority 0 < Chest priority 1)")

	# 4. Dazzled applies near a lit Campfire
	camp_boar.global_position = campfire.global_position + Vector2(50.0, 0.0)
	camp_boar.tick(0.1)
	assert_almost_eq(camp_boar.get_speed_factor(), 0.7, 0.01, "Boar di dekat Campfire harus terkena Dazzled (speed 0.7)")
	assert_almost_eq(camp_boar.get_attack_speed_factor(), 0.75, 0.01, "Boar di dekat Campfire harus terkena Dazzled (attack speed 0.75)")

	# 5. Ember Snuff only on nights >= 5
	# Currently night 1: damage from fauna does NOT reduce fuel by Ember Snuff
	var fuel_before_n1 := campfire.get_fuel()
	campfire.take_damage(10.0, camp_boar)
	var fuel_after_n1 := campfire.get_fuel()
	# Only normal passive drain if any, fuel_loss (15s) is NOT applied
	assert_gt(fuel_after_n1, fuel_before_n1 - 10.0, "Ember Snuff tidak boleh aktif pada malam 1")

	# Skip to night 4 and check spawner max (6)
	while clock.get_current_day() < 4 or clock.is_day():
		clock.skip_time(clock.get_remaining_seconds() + 0.1)
		_harness.advance_time(0.1)
	assert_eq(clock.get_current_day(), 4, "Hari 4")
	assert_true(clock.is_night(), "Malam hari 4")
	var max_night4 := spawner.night_scaling.get_max_enemies(4)
	assert_eq(max_night4, 6, "Max enemies malam 4 adalah 6")
	for i in range(5):
		_harness.advance_time(30.0)
		assert_true(spawner.get_hostile_count() <= max_night4, "Hostile malam 4 <= 6")

	# On night 4, ember snuff still does not apply
	campfire.set_fuel(200.0)
	var fuel_before_n4 := campfire.get_fuel()
	campfire.take_damage(10.0, camp_boar)
	var fuel_after_n4 := campfire.get_fuel()
	assert_almost_eq(fuel_after_n4, fuel_before_n4, 0.5, "Ember Snuff tidak aktif pada malam 4")

	# Skip to night 5: ember snuff MUST apply
	while clock.get_current_day() < 5 or clock.is_day():
		clock.skip_time(clock.get_remaining_seconds() + 0.1)
		_harness.advance_time(0.1)
	assert_eq(clock.get_current_day(), 5, "Hari 5")
	assert_true(clock.is_night(), "Malam hari 5")

	campfire.set_fuel(200.0)
	var fuel_before_n5 := campfire.get_fuel()
	campfire.take_damage(10.0, camp_boar)
	var fuel_after_n5 := campfire.get_fuel()
	assert_almost_eq(fuel_after_n5, fuel_before_n5 - campfire.ember_snuff_config.fuel_loss, 1.0, "Ember Snuff aktif pada malam 5 (-fuel_loss)")

	# Skip to night 7 and check spawner max (12)
	while clock.get_current_day() < 7 or clock.is_day():
		clock.skip_time(clock.get_remaining_seconds() + 0.1)
		_harness.advance_time(0.1)
	assert_eq(clock.get_current_day(), 7, "Hari 7")
	assert_true(clock.is_night(), "Malam hari 7")
	var max_night7 := spawner.night_scaling.get_max_enemies(7)
	assert_eq(max_night7, 12, "Max enemies malam 7 adalah 12")
	for i in range(5):
		_harness.advance_time(15.0)
		assert_true(spawner.get_hostile_count() <= max_night7, "Hostile malam 7 <= 12")

	# 6. Dawn rule leaves at most 2 boars and tops deer to 3 at days 2-7
	# Let's test dawn transition on a fresh cycle
	# Reset clock to day 2 night, let boars spawn, then transition to dawn (day 3)
	clock.restart()
	clock.skip_time(450.0) # Night 1
	clock.skip_time(150.0) # Day 2
	clock.skip_time(450.0) # Night 2
	# Spawn several hostiles during night 2
	_harness.advance_time(80.0)

	# Transition to day 3 dawn
	clock.skip_time(clock.get_remaining_seconds() + 0.1)
	_harness.advance_time(0.1)
	assert_true(clock.is_day(), "Fajar hari 3 aktif")
	assert_eq(clock.get_current_day(), 3, "Hari 3")

	# Count non-fleeing boars and deer
	var active_boars := 0
	var deer_count := 0
	for child in _harness.fauna_parent.get_children():
		if child is WildBoar:
			if not (child as WildBoar).is_fleeing():
				active_boars += 1
		elif child is IslandDeer:
			deer_count += 1

	assert_true(active_boars <= 2, "Aturan fajar menyisakan paling banyak 2 Boar aktif")
	assert_eq(deer_count, 3, "Aturan fajar memastikan jumlah rusa top-up ke 3")

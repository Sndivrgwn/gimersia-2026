extends GutTest

const IslandHarness = preload("res://tests/integration/island_harness.gd")

var _harness: IslandHarness


func before_each() -> void:
	if OS.get_environment("GIMERSIA_SLOW") != "1":
		return
	_harness = IslandHarness.new()
	_harness.setup(self)
	# Mission 9 (R4): soak adalah simulasi invariant 7 hari, bukan tes kematian.
	# Sejak layar mati membekukan jam (keputusan owner), kehabisan token respawn
	# akan menghentikan jam permanen dan rescue tidak pernah tercapai.
	if _harness.death != null:
		_harness.death.respawns_remaining = 1000


func after_each() -> void:
	if _harness != null:
		_harness.teardown()
		_harness = null


func test_7_day_soak() -> void:
	if SlowGuard.skip_unless_slow(self):
		return
	var player := _harness.player
	var stats := _harness.stats
	var needs := _harness.needs
	var inv := _harness.inventory
	var camp := _harness.camp
	var inter := _harness.interactor
	var clock := _harness.clock
	var spawner := _harness.spawner
	var death := _harness.death
	var fauna_parent := _harness.fauna_parent

	# 1. Give full test kit
	inv.add_item(ItemCatalog.WOOD, 30)
	inv.add_item(ItemCatalog.STONE, 20)
	inv.add_item(ItemCatalog.FIBER, 20)
	inv.add_item(ItemCatalog.BAMBOO, 10)
	inv.add_item(ItemCatalog.BONE, 10)
	inv.add_item(ItemCatalog.HIDE, 10)
	inv.add_item(ItemCatalog.RAW_MEAT, 6)
	inv.add_item(ItemCatalog.BERRY, 6)

	# 2. Build lit Campfire and Tent at camp
	var campfire_slot := camp.get_node("CampfireSlot") as BlueprintSlot
	var tent_slot := camp.get_node("TentSlot") as BlueprintSlot

	campfire_slot.interact(inter)
	tent_slot.interact(inter)

	var campfire := camp.get_structure(&"campfire") as Campfire
	var tent := camp.get_structure(&"tent") as CampStructure
	assert_not_null(campfire, "Campfire harus berdiri")
	assert_not_null(tent, "Tent harus berdiri")
	# Mission 9 (R4): bangunan baru COLD; harness menyalakan api lewat jalur resmi.
	campfire.ignite()
	assert_true(campfire.is_lit(), "Campfire harus menyala")

	var step := 0.5
	var total_steps := int(ceil(4200.0 / step)) # ~8400 steps
	var invariant_violation := ""

	var node_count_day2 := -1
	var node_count_day7 := -1
	var recorded_day2 := false
	var recorded_day7 := false

	var start_ticks := Time.get_ticks_msec()

	for step_idx in range(total_steps):
		if clock.rescue_triggered:
			break

		_harness.advance_time(step)

		# Auto-respawn player if killed during soak
		if death.is_dead and death.can_respawn():
			death.respawn()

		# Periodically refuel campfire if wood is available and fuel is low
		if campfire != null and is_instance_valid(campfire) and campfire.get_fuel() < 60.0:
			if inv.count_of(ItemCatalog.WOOD) >= 2:
				campfire.refuel(player)

		# Record node count at Day 2 morning
		var current_day: int = clock.get_current_day()
		if not recorded_day2 and current_day == 2 and clock.is_day():
			node_count_day2 = get_tree().get_node_count()
			recorded_day2 = true

		# Record node count at Day 7 morning
		if not recorded_day7 and current_day == 7 and clock.is_day():
			node_count_day7 = get_tree().get_node_count()
			recorded_day7 = true

		# --- Invariants ---
		# 1. No NaN in player position
		if is_nan(player.global_position.x) or is_nan(player.global_position.y):
			invariant_violation = "NaN in player position at step %d" % step_idx
			break

		# 2. No NaN in fauna position & count boars/deer
		var boars := 0
		var deer := 0
		for child in fauna_parent.get_children():
			if child is Node2D:
				var pos: Vector2 = (child as Node2D).global_position
				if is_nan(pos.x) or is_nan(pos.y):
					invariant_violation = "NaN in fauna position at step %d" % step_idx
					break
			if child is WildBoar:
				boars += 1
			elif child is IslandDeer:
				deer += 1

		if not invariant_violation.is_empty():
			break

		# 3. Boar count and deer count never negative
		if boars < 0 or deer < 0:
			invariant_violation = "Negative fauna count (boars: %d, deer: %d) at step %d" % [boars, deer, step_idx]
			break

		# 4. Needs values in [0, 100]
		for need_idx in [NeedsComponent.Need.HUNGER, NeedsComponent.Need.THIRST, NeedsComponent.Need.FATIGUE]:
			var val := needs.get_value(need_idx)
			if val < -0.01 or val > 100.01:
				invariant_violation = "Need %d out of bounds [%.2f] at step %d" % [need_idx, val, step_idx]
				break

		if not invariant_violation.is_empty():
			break

		# 5. HP within [0, max]
		var cur_hp := stats.current_hp
		var max_hp := stats.get_max_hp()
		if cur_hp < -0.01 or cur_hp > max_hp + 0.01:
			invariant_violation = "HP out of bounds [%.2f / %.2f] at step %d" % [cur_hp, max_hp, step_idx]
			break

		# 6. Hostile count <= night table max
		if clock.is_night():
			var hostiles := spawner.get_hostile_count()
			var table_max := spawner.night_scaling.get_max_enemies(current_day)
			if hostiles > table_max:
				invariant_violation = "Hostile count %d exceeded max %d at day %d, step %d" % [hostiles, table_max, current_day, step_idx]
				break

		# 7. Structures never below 0 HP without being freed
		for struct in camp.get_structures():
			if struct != null and is_instance_valid(struct):
				if struct.get_current_hp() < -0.01:
					invariant_violation = "Structure %s HP below 0 (%.2f) at step %d" % [struct.id, struct.get_current_hp(), step_idx]
					break

		if not invariant_violation.is_empty():
			break

	var elapsed_total_s := float(Time.get_ticks_msec() - start_ticks) / 1000.0
	print("Soak completed in %.2f s (limit 90s)" % elapsed_total_s)

	# Verify invariants held
	assert_eq(invariant_violation, "", "Semua invariant harus terpenuhi selama 7 hari simulasi")

	# Final check: clock reached rescue
	assert_true(clock.rescue_triggered, "Clock harus mencapai rescue di akhir hari 7")

	# Node count growth check
	if not recorded_day7:
		node_count_day7 = get_tree().get_node_count()

	assert_gt(node_count_day2, 0, "Node count day 2 harus tercatat")
	assert_gt(node_count_day7, 0, "Node count day 7 harus tercatat")

	var growth := float(node_count_day7 - node_count_day2) / float(node_count_day2)
	print("Node count growth: Day 2 = %d, Day 7 = %d (growth = %.2f%%)" % [node_count_day2, node_count_day7, growth * 100.0])
	assert_true(growth <= 0.20, "Pertumbuhan node count tidak boleh melebihi 20%% (aktual: %.2f%%)" % [growth * 100.0])

extends GutTest

## Mission 7 / Phase 1: keputusan owner (rusa, flare, batu, Master Chef).

const PROF_CONFIG: ProficiencyConfig = preload("res://src/data/configs/proficiency_config.tres")

class StubClock extends Node:
	var rescue_triggered := false
	var night := true
	func is_night() -> bool: return night
	func get_time_scale() -> float: return 1.0
	func get_current_day() -> int: return 7

class StubFire extends Node2D:
	var ignited := false
	func can_ignite() -> bool: return true
	func get_ignite_block_reason() -> String: return "Butuh Batu" if not ignited else ""
	func ignite() -> void: ignited = true


# --- 1.1 Deer guarantee -----------------------------------------------------

func _make_quota(flag: bool) -> FaunaQuota:
	var fauna := Node2D.new()
	fauna.name = "Fauna"
	add_child_autofree(fauna)
	var quota := FaunaQuota.new()
	quota.clock = StubClock.new()
	add_child_autofree(quota.clock)
	quota.fauna_parent = fauna
	quota.boar_target = 0
	quota.deer_target = 0
	quota.guarantee_deer_at_rescue = flag
	add_child_autofree(quota)
	return quota


func _deer_count(quota: FaunaQuota) -> int:
	var count := 0
	for child in quota.fauna_parent.get_children():
		if child is IslandDeer:
			count += 1
	return count


func test_rescue_spawns_two_deer_when_guaranteed() -> void:
	var quota := _make_quota(true)
	quota._on_rescue_started()
	assert_eq(_deer_count(quota), 2, "flag ON -> minimal 2 rusa saat rescue")


func test_rescue_does_not_spawn_deer_when_flag_off() -> void:
	var quota := _make_quota(false)
	quota._on_rescue_started()
	assert_eq(_deer_count(quota), 0, "flag OFF -> tidak dijamin")


func test_guaranteed_deer_respawns_after_45s_with_own_counter() -> void:
	var quota := _make_quota(true)
	quota._on_rescue_started()
	assert_eq(_deer_count(quota), 2)
	var boar_left := quota.get_extra_respawns_left()

	for child in quota.fauna_parent.get_children():
		if child is IslandDeer:
			child.get_health().take_damage(9999.0, null)
			break
	await get_tree().process_frame
	assert_eq(_deer_count(quota), 1)
	assert_eq(quota.get_deer_extra_respawns_left(), 3)

	quota.tick(44.0)
	assert_eq(_deer_count(quota), 1, "belum 45 s nyata")
	quota.tick(1.0)
	assert_eq(_deer_count(quota), 2, "rusa jaminan respawn setelah 45 s")
	assert_eq(quota.get_extra_respawns_left(), boar_left, "counter boar terpisah")


# --- 1.2 Flare consumed -----------------------------------------------------

func _make_beacon() -> Array:
	var clock := StubClock.new()
	clock.rescue_triggered = true
	add_child_autofree(clock)
	var inv := InventoryComponent.new()
	add_child_autofree(inv)
	var beacon := SignalBeacon.new()
	beacon.clock = clock
	beacon.inventory = inv
	add_child_autofree(beacon)
	return [beacon, inv]


func test_beacon_consumes_flare_and_wins_once() -> void:
	var setup := _make_beacon()
	var beacon := setup[0] as SignalBeacon
	var inv := setup[1] as InventoryComponent
	inv.add_item(ItemCatalog.SIGNAL_FLARE, 1)
	watch_signals(beacon)

	beacon.interact(null)
	assert_signal_emitted(beacon, "victory_triggered")
	assert_eq(inv.count_of(ItemCatalog.SIGNAL_FLARE), 0, "flare dikonsumsi")

	beacon.interact(null)
	assert_eq(get_signal_emit_count(beacon, "victory_triggered"), 1, "victory tetap sekali")


func test_beacon_without_flare_never_wins() -> void:
	var setup := _make_beacon()
	var beacon := setup[0] as SignalBeacon
	watch_signals(beacon)
	beacon.interact(null)
	assert_false(get_signal_emit_count(beacon, "victory_triggered") > 0, "tanpa flare tidak victory")


# --- 1.3 Stone rule ---------------------------------------------------------

func _make_starter() -> Array:
	var player := Node2D.new()
	player.name = "Player"
	add_child_autofree(player)
	var inv := InventoryComponent.new()
	inv.name = "InventoryComponent"
	player.add_child(inv)
	var controller := FireStarterController.new()
	player.add_child(controller)
	var fire := StubFire.new()
	add_child_autofree(fire)
	return [controller, inv, fire]


func test_success_keeps_stone() -> void:
	var setup := _make_starter()
	var controller := setup[0] as FireStarterController
	var inv := setup[1] as InventoryComponent
	var fire := setup[2] as StubFire
	inv.add_item(ItemCatalog.STONE, 1)

	assert_true(controller.start(fire))
	assert_eq(inv.count_of(ItemCatalog.STONE), 1, "start tidak memakai batu")
	controller.roll_override = 0.0
	controller.set_marker(0.5)
	controller.strike()
	assert_true(fire.ignited)
	assert_eq(inv.count_of(ItemCatalog.STONE), 1, "sukses tidak memakai batu")


func test_failure_consumes_one_stone() -> void:
	var setup := _make_starter()
	var controller := setup[0] as FireStarterController
	var inv := setup[1] as InventoryComponent
	var fire := setup[2] as StubFire
	inv.add_item(ItemCatalog.STONE, 1)

	assert_true(controller.start(fire))
	controller.roll_override = 1.0
	controller.set_marker(0.05)
	controller.strike()
	controller.strike()
	controller.strike()
	assert_false(controller.is_active())
	assert_eq(inv.count_of(ItemCatalog.STONE), 0, "gagal memakai 1 batu")


func test_cancel_keeps_stone() -> void:
	var setup := _make_starter()
	var controller := setup[0] as FireStarterController
	var inv := setup[1] as InventoryComponent
	var fire := setup[2] as StubFire
	inv.add_item(ItemCatalog.STONE, 1)

	assert_true(controller.start(fire))
	controller.cancel(&"test")
	assert_eq(inv.count_of(ItemCatalog.STONE), 1, "batal tidak memakai batu")


func test_zero_stone_cannot_start() -> void:
	var setup := _make_starter()
	var controller := setup[0] as FireStarterController
	var fire := setup[2] as StubFire
	assert_false(controller.start(fire), "Butuh Batu")


# --- 1.4 Master Chef --------------------------------------------------------

func _make_mastery_player(level: int) -> Array:
	var player := Node2D.new()
	add_child_autofree(player)
	var inv := InventoryComponent.new()
	player.add_child(inv)
	var needs := NeedsComponent.new()
	player.add_child(needs)
	inv.needs_component = needs
	var stats := StatsComponent.new()
	player.add_child(stats)
	var prof := ProficiencyComponent.new()
	prof.config = PROF_CONFIG
	prof.inventory = inv
	prof.needs = needs
	prof.stats = stats
	player.add_child(prof)
	stats.mastery_level = level
	await get_tree().process_frame
	return [inv, needs, prof]


func test_master_chef_adds_bonus_to_cooked_meat() -> void:
	var setup := await _make_mastery_player(6)
	var inv := setup[0] as InventoryComponent
	var needs := setup[1] as NeedsComponent
	needs.set_value(NeedsComponent.Need.HUNGER, 10.0)
	inv.add_item(ItemCatalog.COOKED_MEAT, 1)
	inv.use_slot(0)
	assert_almost_eq(needs.get_value(NeedsComponent.Need.HUNGER), 65.0, 0.01, "45 + bonus 10")


func test_master_chef_absent_at_level_five() -> void:
	var setup := await _make_mastery_player(5)
	var inv := setup[0] as InventoryComponent
	var needs := setup[1] as NeedsComponent
	needs.set_value(NeedsComponent.Need.HUNGER, 10.0)
	inv.add_item(ItemCatalog.COOKED_MEAT, 1)
	inv.use_slot(0)
	assert_almost_eq(needs.get_value(NeedsComponent.Need.HUNGER), 55.0, 0.01, "tanpa bonus")


func test_master_chef_thirst_items() -> void:
	var setup := await _make_mastery_player(6)
	var inv := setup[0] as InventoryComponent
	var needs := setup[1] as NeedsComponent
	needs.set_value(NeedsComponent.Need.THIRST, 10.0)
	inv.add_item(ItemCatalog.BOILED_WATER, 1)
	inv.use_slot(0)
	assert_almost_eq(needs.get_value(NeedsComponent.Need.THIRST), 80.0, 0.01, "60 + bonus 10")


func test_master_chef_ignores_other_items() -> void:
	var setup := await _make_mastery_player(6)
	var inv := setup[0] as InventoryComponent
	var needs := setup[1] as NeedsComponent
	needs.set_value(NeedsComponent.Need.HUNGER, 10.0)
	inv.add_item(ItemCatalog.BERRY, 1)
	inv.use_slot(0)
	assert_almost_eq(needs.get_value(NeedsComponent.Need.HUNGER), 22.0, 0.01, "berry +12 saja")

extends GutTest

## Phase 4 (D3): campfire COLD + minigame gesek batu.

class StubPlayer extends Node2D:
	func get_inventory() -> InventoryComponent:
		return get_node("InventoryComponent") as InventoryComponent

	func _init() -> void:
		var stats := StatsComponent.new()
		stats.name = "StatsComponent"
		add_child(stats)
		var inventory := InventoryComponent.new()
		inventory.name = "InventoryComponent"
		add_child(inventory)
		var interactor := InteractorComponent.new()
		interactor.name = "InteractorComponent"
		add_child(interactor)
		var starter := FireStarterController.new()
		starter.name = "FireStarterController"
		add_child(starter)


const CONFIG: FireStarterConfig = preload("res://src/data/configs/fire_starter_config.tres")


func _make_campfire() -> Array:
	var campfire := Campfire.new()
	add_child_autofree(campfire)
	var refuel := CampfireRefuel.new()
	campfire.add_child(refuel)
	return [campfire, refuel]


func _make_player(at: Vector2) -> StubPlayer:
	var player := StubPlayer.new()
	add_child_autofree(player)
	player.global_position = at
	return player


func test_config_defaults() -> void:
	assert_eq(CONFIG.strikes_per_attempt, 3)
	assert_almost_eq(CONFIG.sweep_period, 1.1, 0.001)
	assert_almost_eq(CONFIG.perfect_zone, 0.12, 0.001)
	assert_almost_eq(CONFIG.good_zone, 0.30, 0.001)
	assert_almost_eq(CONFIG.miss_chance, 0.10, 0.001)
	assert_almost_eq(CONFIG.good_chance, 0.45, 0.001)
	assert_almost_eq(CONFIG.perfect_chance, 0.80, 0.001)
	assert_eq(CONFIG.stone_cost, 1)
	assert_almost_eq(CONFIG.fail_cooldown, 0.8, 0.001)


func test_campfire_becomes_cold_and_stays_cold_after_refuel() -> void:
	var setup := _make_campfire()
	var campfire := setup[0] as Campfire
	var refuel := setup[1] as CampfireRefuel
	assert_true(campfire.is_lit(), "campfire baru menyala")

	campfire.set_fuel(0.0)
	assert_true(campfire.is_cold())
	assert_false(campfire.is_lit())
	assert_eq(campfire.get_light_radius(), campfire.config.ember_light_radius)
	assert_false(campfire.is_station_active(), "memasak harus diblokir saat cold")
	assert_eq(refuel.get_prompt(null), CampfireRefuel.PROMPT_FUEL)

	campfire.set_fuel(120.0)
	assert_true(campfire.is_cold(), "isi bahan bakar tidak menyalakan api")
	assert_true(campfire.needs_ignition())
	assert_true(campfire.can_ignite())
	assert_eq(refuel.get_prompt(null), CampfireRefuel.PROMPT_IGNITE)

	var crowbar := StubPlayer.new()
	add_child_autofree(crowbar)
	var inventory := crowbar.get_node("InventoryComponent") as InventoryComponent
	assert_eq(refuel.get_block_reason(crowbar), "Butuh Batu")
	inventory.add_item(ItemCatalog.STONE, 2)
	assert_eq(refuel.get_block_reason(crowbar), "")

	assert_true(campfire.ignite())
	assert_true(campfire.is_lit())
	assert_true(campfire.is_station_active())
	assert_false(campfire.needs_ignition())


func test_controller_success_ignites_and_locks_interactor() -> void:
	var setup := _make_campfire()
	var campfire := setup[0] as Campfire
	campfire.set_fuel(0.0)
	campfire.set_fuel(120.0)

	var player := _make_player(Vector2(10.0, 10.0))
	var inventory := player.get_node("InventoryComponent") as InventoryComponent
	var interactor := player.get_node("InteractorComponent") as InteractorComponent
	var controller := player.get_node("FireStarterController") as FireStarterController
	inventory.add_item(ItemCatalog.STONE, 1)

	watch_signals(controller)
	assert_true(controller.start(campfire))
	assert_true(controller.is_active())
	assert_true(interactor.is_locked(), "interactor dikunci selama minigame")
	assert_eq(inventory.count_of(ItemCatalog.STONE), 1, "M7: sukses tidak memakai batu")

	controller.set_marker(0.5)
	controller.roll_override = 0.0
	controller.strike()
	assert_true(campfire.is_lit(), "strike sukses menyalakan api")
	assert_signal_emitted(controller, "started")
	assert_signal_emitted(controller, "finished")
	assert_false(interactor.is_locked(), "interactor dibuka kembali")
	assert_eq(controller.get_last_quality(), FireStarterController.Quality.PERFECT)


func test_controller_three_misses_fail_and_cooldown() -> void:
	var setup := _make_campfire()
	var campfire := setup[0] as Campfire
	campfire.set_fuel(0.0)
	campfire.set_fuel(120.0)

	var player := _make_player(Vector2(10.0, 10.0))
	var inventory := player.get_node("InventoryComponent") as InventoryComponent
	var controller := player.get_node("FireStarterController") as FireStarterController
	inventory.add_item(ItemCatalog.STONE, 3)

	assert_true(controller.start(campfire))
	controller.roll_override = 1.0
	controller.set_marker(0.05)
	controller.strike()
	controller.strike()
	assert_true(controller.is_active(), "masih ada strike tersisa")
	controller.strike()
	assert_false(controller.is_active())
	assert_false(campfire.is_lit())
	assert_gt(controller.get_cooldown(), 0.0)
	assert_false(controller.start(campfire), "cooldown memblokir percobaan baru")
	assert_eq(inventory.count_of(ItemCatalog.STONE), 2, "M7: batu dipakai hanya saat gagal")


func test_controller_cancels_when_too_far() -> void:
	var setup := _make_campfire()
	var campfire := setup[0] as Campfire
	campfire.set_fuel(0.0)
	campfire.set_fuel(120.0)

	var player := _make_player(Vector2.ZERO)
	var inventory := player.get_node("InventoryComponent") as InventoryComponent
	var controller := player.get_node("FireStarterController") as FireStarterController
	var interactor := player.get_node("InteractorComponent") as InteractorComponent
	inventory.add_item(ItemCatalog.STONE, 1)

	assert_true(controller.start(campfire))
	player.global_position = Vector2(500.0, 0.0)
	controller.tick(0.1)
	assert_false(controller.is_active())
	assert_eq(controller.get_last_cancel(), &"too_far")
	assert_false(interactor.is_locked())


func test_quality_bands() -> void:
	var player := _make_player(Vector2.ZERO)
	var controller := player.get_node("FireStarterController") as FireStarterController
	assert_eq(controller.quality_at(0.5), FireStarterController.Quality.PERFECT)
	assert_eq(controller.quality_at(0.42), FireStarterController.Quality.GOOD)
	assert_eq(controller.quality_at(0.1), FireStarterController.Quality.MISS)
	assert_almost_eq(controller.get_success_chance(FireStarterController.Quality.PERFECT), 0.80, 0.001)
	assert_almost_eq(controller.get_success_chance(FireStarterController.Quality.GOOD), 0.45, 0.001)
	assert_almost_eq(controller.get_success_chance(FireStarterController.Quality.MISS), 0.10, 0.001)


func test_hud_reports_status() -> void:
	var setup := _make_campfire()
	var campfire := setup[0] as Campfire
	campfire.set_fuel(0.0)
	campfire.set_fuel(120.0)
	var player := _make_player(Vector2.ZERO)
	var inventory := player.get_node("InventoryComponent") as InventoryComponent
	var controller := player.get_node("FireStarterController") as FireStarterController
	inventory.add_item(ItemCatalog.STONE, 1)

	var hud := preload("res://src/ui/hud/crafting/fire_starter_hud.gd").new() as FireStarterHUD
	add_child_autofree(hud)
	hud.controller = controller
	controller.start(campfire)
	hud.refresh()
	assert_true(hud.is_showing())
	controller.roll_override = 0.0
	controller.set_marker(0.5)
	controller.strike()
	hud.refresh()
	assert_eq(hud.get_status_text(), FireStarterHUD.TEXT_SUCCESS)

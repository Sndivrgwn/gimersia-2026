extends GutTest

## Tes Poin 5: anti soft-lock Hari 7 (Workbench), DayNightManager.restore_state,
## dan SaveService (simpan/muat/file rusak/hapus).

const TEST_SAVE_PATH := "user://test_point5_save_run.json"
const SIGNAL_FLARE_RECIPE: RecipeDefinition = preload("res://src/data/recipes/signal_flare.tres")
const STONE_AXE_RECIPE: RecipeDefinition = preload("res://src/data/recipes/stone_axe.tres")
const LEATHER_VEST_RECIPE: RecipeDefinition = preload("res://src/data/recipes/leather_vest.tres")
const DAY_NIGHT_SCENE: PackedScene = preload("res://src/core/managers/day_night_manager.tscn")


class StubDayClock extends Node:
	var day: int = 1

	func get_current_day() -> int:
		return day


class StubWorkbench extends Node2D:
	var station_type: int = RecipeDefinition.Station.WORKBENCH
	var active: bool = true

	func _enter_tree() -> void:
		add_to_group(CraftingComponent.STATION_GROUP)

	func is_station_active() -> bool:
		return active


func after_each() -> void:
	SaveService.clear_save(TEST_SAVE_PATH)
	SaveService.cancel_pending_load()


# --- Step 3: Anti soft-lock Hari 7 ------------------------------------------

func test_day7_rescue_fallback_unlocks_signal_flare_and_axe_when_no_workbench() -> void:
	var player := Node2D.new()
	add_child_autofree(player)
	var inv := InventoryComponent.new()
	inv.name = "InventoryComponent"
	inv.hotbar_input_enabled = false
	player.add_child(inv)
	var stats := StatsComponent.new()
	stats.name = "StatsComponent"
	player.add_child(stats)
	var clock := StubDayClock.new()
	add_child_autofree(clock)

	var craft := CraftingComponent.new()
	craft.input_enabled = false
	craft.clock = clock
	player.add_child(craft)
	craft.setup(player, inv, stats)

	# Hari 6 tanpa Workbench: signal_flare & stone_axe masih terkunci.
	clock.day = 6
	assert_false(craft.is_rescue_fallback_active(), "Hari 6 belum rescue fallback")
	assert_ne(craft.get_block_reason(SIGNAL_FLARE_RECIPE), "", "Hari 6 butuh Workbench")

	# Hari 7 tanpa Workbench: signal_flare & stone_axe terbuka, resep lain tetap terkunci.
	clock.day = 7
	assert_true(craft.is_rescue_fallback_active(), "Hari 7 tanpa Workbench -> fallback aktif")
	inv.add_item(ItemCatalog.WOOD, 5)
	inv.add_item(ItemCatalog.STONE, 2)
	inv.add_item(ItemCatalog.BONE, 3)
	inv.add_item(ItemCatalog.HIDE, 2)
	inv.add_item(ItemCatalog.FIBER, 2)
	assert_eq(craft.get_block_reason(SIGNAL_FLARE_RECIPE), "", "Hari 7 signal_flare bisa dirakit tangan")
	assert_eq(craft.get_block_reason(STONE_AXE_RECIPE), "", "Hari 7 stone_axe bisa dirakit tangan")
	assert_ne(craft.get_block_reason(LEATHER_VEST_RECIPE), "", "Resep non-krusial tetap butuh Workbench")

	# Jika ada Workbench aktif di pulau (walau jauh), fallback mati.
	var wb := StubWorkbench.new()
	wb.global_position = Vector2(5000.0, 5000.0)
	add_child_autofree(wb)
	assert_false(craft.is_rescue_fallback_active(), "Ada Workbench aktif -> fallback nonaktif")


# --- Step 4: DayNightManager.restore_state & SaveService --------------------

func test_day_night_restore_state() -> void:
	var mgr := DAY_NIGHT_SCENE.instantiate()
	mgr.auto_start = false
	add_child_autofree(mgr)
	mgr.restore_state(4, mgr.Phase.NIGHT, 123.5, false)
	assert_eq(mgr.get_current_day(), 4)
	assert_true(mgr.is_night())
	assert_almost_eq(mgr.get_phase_elapsed(), 123.5, 0.01)
	assert_false(mgr.rescue_triggered)


func test_save_service_round_trip_and_corrupt_tolerance() -> void:
	# File hilang / rusak harus aman.
	assert_false(SaveService.has_save(TEST_SAVE_PATH))
	var f := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	f.store_string("{not valid json")
	f.close()
	assert_false(SaveService.has_save(TEST_SAVE_PATH), "File rusak diabaikan aman")

	var mgr := DAY_NIGHT_SCENE.instantiate()
	mgr.auto_start = false
	add_child_autofree(mgr)
	mgr.restore_state(3, mgr.Phase.DAY, 88.0, false)

	var island := Node2D.new()
	add_child_autofree(island)
	var player := Node2D.new()
	player.name = "Player"
	player.global_position = Vector2(150.0, -90.0)
	island.add_child(player)

	var stats := StatsComponent.new()
	stats.name = "StatsComponent"
	player.add_child(stats)
	stats.strength_level = 4
	stats.speed_level = 3
	stats.set_hp(77.5)

	var needs := NeedsComponent.new()
	needs.name = "NeedsComponent"
	needs.clock = mgr
	needs.stats = stats
	needs.player = player
	player.add_child(needs)
	needs.set_value(NeedsComponent.Need.HUNGER, 42.0)
	needs.set_value(NeedsComponent.Need.THIRST, 55.0)
	needs.set_value(NeedsComponent.Need.FATIGUE, 63.0)

	var inv := InventoryComponent.new()
	inv.name = "InventoryComponent"
	inv.hotbar_input_enabled = false
	player.add_child(inv)
	inv.add_item(ItemCatalog.WOOD, 7)
	inv.add_item(ItemCatalog.STONE, 4)
	inv.equip(ItemCatalog.STONE_AXE)
	inv.equip(ItemCatalog.WOODEN_SPEAR)

	var death := DeathController.new()
	death.name = "DeathController"
	death.player = player
	island.add_child(death)
	death.respawns_remaining = 1

	assert_true(SaveService.save_island(island, TEST_SAVE_PATH, mgr), "Save harus berhasil")
	assert_true(SaveService.has_save(TEST_SAVE_PATH))
	var summary := SaveService.read_summary(TEST_SAVE_PATH)
	assert_eq(int(summary["day"]), 3)

	# Ubah state lalu load ulang untuk memastikan semua dipulihkan.
	mgr.restore_state(1, mgr.Phase.DAY, 0.0, false)
	player.global_position = Vector2.ZERO
	stats.strength_level = 1
	stats.set_hp(10.0)
	needs.set_value(NeedsComponent.Need.HUNGER, 100.0)
	inv.remove_item(ItemCatalog.WOOD, 7)
	death.respawns_remaining = 3

	assert_true(SaveService.load_island(island, TEST_SAVE_PATH, mgr), "Load harus berhasil")
	assert_eq(mgr.get_current_day(), 3)
	assert_almost_eq(mgr.get_phase_elapsed(), 88.0, 0.01)
	assert_almost_eq(player.global_position.x, 150.0, 0.01)
	assert_almost_eq(player.global_position.y, -90.0, 0.01)
	assert_eq(stats.strength_level, 4)
	assert_eq(stats.speed_level, 3)
	assert_almost_eq(stats.current_hp, 77.5, 0.01)
	assert_almost_eq(needs.get_value(NeedsComponent.Need.HUNGER), 42.0, 0.01)
	assert_almost_eq(needs.get_value(NeedsComponent.Need.THIRST), 55.0, 0.01)
	assert_eq(inv.count_of(ItemCatalog.WOOD), 7)
	assert_eq(inv.count_of(ItemCatalog.STONE), 4)
	assert_true(inv.has_tool(ItemCatalog.STONE_AXE))
	assert_eq(death.get_respawns_remaining(), 1)

	SaveService.clear_save(TEST_SAVE_PATH)
	assert_false(SaveService.has_save(TEST_SAVE_PATH))

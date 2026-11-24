extends GutTest

## Fase 1: tujuan harian (1A), rekap fajar (1B), cahaya pemain (1C).

const GOALS_CONFIG: DailyGoalConfig = preload("res://src/data/configs/daily_goals.tres")
const LIGHT_CONFIG: PlayerLightConfig = preload("res://src/data/configs/player_light_config.tres")
const RECAP_SCRIPT := preload("res://src/ui/hud/recap/dawn_recap_hud.gd")
const GOAL_HUD_SCRIPT := preload("res://src/ui/hud/goals/daily_goal_hud.gd")
const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")


class StubCamp extends Node:
	var built: Dictionary = {}

	func has_built(id: StringName) -> bool:
		return bool(built.get(id, false))


class StubAnchor extends Node:
	var founded := false

	func is_founded() -> bool:
		return founded


class StubHotbar extends Node:
	var item: ItemDefinition

	func get_held_item() -> ItemDefinition:
		return item


class StubClock extends Node:
	var day := 1

	func get_current_day() -> int:
		return day


# --- 1A: tujuan harian ------------------------------------------------------

func test_goal_config_groups_by_day() -> void:
	assert_gt(GOALS_CONFIG.get_goal_count(), 0, "config punya tujuan")
	var day_one := GOALS_CONFIG.get_goals_for_day(1)
	assert_gt(day_one.size(), 0, "Hari 1 punya tujuan")
	for goal in day_one:
		assert_eq(goal.day, 1)
		assert_false(goal.describe().is_empty(), "teks tujuan tidak kosong")
	assert_eq(GOALS_CONFIG.get_goals_for_day(99).size(), 0, "hari tanpa data kosong")
	# Ketujuh hari punya tujuan supaya baris HUD tidak pernah kosong.
	for day in range(1, 8):
		assert_gt(GOALS_CONFIG.get_goals_for_day(day).size(), 0, "hari %d punya tujuan" % day)


func test_item_goal_reads_inventory() -> void:
	var inventory := InventoryComponent.new()
	add_child_autofree(inventory)
	var goal := DailyGoal.new()
	goal.kind = DailyGoal.Kind.ITEM_COUNT
	goal.item = ItemCatalog.WOOD
	goal.count = 3
	assert_false(goal.is_met(inventory, null, null), "awalnya belum")
	inventory.add_item(ItemCatalog.WOOD, 3)
	assert_true(goal.is_met(inventory, null, null), "3 kayu memenuhi")
	assert_false(DailyGoal.new().is_met(null, null, null), "tanpa data = belum")


func test_tool_and_weapon_goals() -> void:
	var inventory := InventoryComponent.new()
	add_child_autofree(inventory)
	var tool := DailyGoal.new()
	tool.kind = DailyGoal.Kind.TOOL_OWNED
	tool.item = ItemCatalog.STONE_AXE
	assert_false(tool.is_met(inventory, null, null))
	inventory.equip(ItemCatalog.STONE_AXE)
	assert_true(tool.is_met(inventory, null, null), "kapak batu dimiliki")

	var weapon := DailyGoal.new()
	weapon.kind = DailyGoal.Kind.WEAPON_EQUIPPED
	weapon.item = ItemCatalog.STONE_SPEAR
	assert_false(weapon.is_met(inventory, null, null))
	inventory.equip(ItemCatalog.STONE_SPEAR)
	assert_true(weapon.is_met(inventory, null, null), "tombak batu terpasang")

	var armor := DailyGoal.new()
	armor.kind = DailyGoal.Kind.ARMOR_EQUIPPED
	armor.item = ItemCatalog.LEATHER_VEST
	assert_false(armor.is_met(inventory, null, null))
	inventory.equip(ItemCatalog.LEATHER_VEST)
	assert_true(armor.is_met(inventory, null, null), "rompi kulit terpasang")


func test_structure_and_base_goals() -> void:
	var camp := StubCamp.new()
	add_child_autofree(camp)
	var anchor := StubAnchor.new()
	add_child_autofree(anchor)
	var goal := DailyGoal.new()
	goal.kind = DailyGoal.Kind.STRUCTURE_BUILT
	goal.structure_id = &"campfire"
	assert_false(goal.is_met(null, camp, anchor))
	camp.built[&"campfire"] = true
	assert_true(goal.is_met(null, camp, anchor), "api unggun terbangun")

	var base := DailyGoal.new()
	base.kind = DailyGoal.Kind.BASE_FOUNDED
	assert_false(base.is_met(null, camp, anchor))
	anchor.founded = true
	assert_true(base.is_met(null, camp, anchor), "base ditentukan")


func test_goal_hud_lists_every_goal_of_the_day() -> void:
	var clock := StubClock.new()
	add_child_autofree(clock)
	clock.day = 2
	var hud := GOAL_HUD_SCRIPT.new()
	hud.config = GOALS_CONFIG
	hud.clock = clock
	add_child_autofree(hud)
	var text: String = hud.get_text()
	assert_true(text.begins_with("Hari 2:"), "baris diawali hari: %s" % text)
	for goal in GOALS_CONFIG.get_goals_for_day(2):
		assert_string_contains(text, goal.describe())
	assert_string_contains(text, "(0/3)", "penghitung progres")

	clock.day = 1
	hud.refresh()
	assert_string_contains(hud.get_text(), "bangun api unggun")
	assert_string_contains(hud.get_text(), "(0/3)")


# --- 1B: rekap fajar --------------------------------------------------------

func test_daily_stats_counts_and_resets() -> void:
	var stats := DailyRunStats.new()
	add_child_autofree(stats)
	stats.record_gather(4)
	stats.record_gather(2)
	var boar := BOAR_SCENE.instantiate()
	stats.record_kill(boar)
	stats.record_kill(null)
	stats.record_base_damage(12.0)
	assert_eq(stats.get_resources(), 6)
	assert_eq(stats.get_kills_boar(), 1, "babi dihitung terpisah")
	assert_false(stats.is_base_intact(), "base kena damage")

	var summary := stats.finish_day()
	assert_eq(int(summary["day"]), 1)
	assert_eq(int(summary["resources"]), 6)
	assert_eq(int(summary["kills_boar"]), 1)
	assert_eq(int(summary["kills_other"]), 1)
	assert_false(bool(summary["base_intact"]))
	assert_eq(stats.get_resources(), 0, "penghitung harian direset")
	assert_true(stats.is_base_intact(), "base utuh lagi setelah reset")
	assert_eq(int(stats.get_totals()["resources"]), 6, "total run disimpan")
	boar.free()


func test_daily_stats_destroyed_structure_marks_base_broken() -> void:
	var stats := DailyRunStats.new()
	add_child_autofree(stats)
	stats.record_structure_destroyed()
	assert_false(stats.is_base_intact())
	assert_eq(int(stats.build_summary()["structures_destroyed"]), 1)


func test_recap_hud_shows_and_closes() -> void:
	var hud := RECAP_SCRIPT.new()
	add_child_autofree(hud)
	assert_false(hud.is_open(), "awalnya tertutup")
	hud.show_summary({
		"day": 2, "resources": 12, "kills_boar": 2,
		"structures_destroyed": 0, "base_intact": true,
	})
	assert_true(hud.is_open())
	assert_eq(hud.get_title_text(), "Hari 2 selesai")
	assert_string_contains(hud.get_body_text(), "12 resource")
	hud.close()
	assert_false(hud.is_open(), "bisa ditutup pemain")


func test_recap_text_formats() -> void:
	assert_eq(
		RECAP_SCRIPT.format_summary({
			"day": 2, "resources": 12, "kills_boar": 2,
			"structures_destroyed": 0, "base_intact": true,
		}),
		"12 resource · 2 babi · base utuh"
	)
	assert_eq(
		RECAP_SCRIPT.format_summary({
			"day": 3, "resources": 3, "kills_boar": 0,
			"structures_destroyed": 2, "base_intact": false,
		}),
		"3 resource · 0 babi · base rusak (2 hancur)"
	)


# --- 1C: cahaya pemain ------------------------------------------------------

func test_player_light_radius_follows_torch() -> void:
	var hotbar := StubHotbar.new()
	add_child_autofree(hotbar)
	hotbar.item = ItemCatalog.TORCH
	var light := PlayerLight.new()
	light.config = LIGHT_CONFIG
	light.hotbar = hotbar
	add_child_autofree(light)
	assert_not_null(light.get_light_node(), "PointLight2D dibuat")
	assert_almost_eq(light.get_radius(), 190.0, 0.01, "obor = 190 px")
	assert_true(light.is_torch_active())

	hotbar.item = ItemCatalog.WOOD
	assert_almost_eq(light.get_radius(), 110.0, 0.01, "tanpa obor = 110 px")
	assert_false(light.is_torch_active())


func test_player_light_energy_follows_darkness() -> void:
	var hotbar := StubHotbar.new()
	add_child_autofree(hotbar)
	var light := PlayerLight.new()
	light.config = LIGHT_CONFIG
	light.hotbar = hotbar
	add_child_autofree(light)
	assert_almost_eq(light.get_energy(0.0), 0.0, 0.01, "siang: padam")
	assert_almost_eq(light.get_energy(0.5), 0.5, 0.01, "senja: setengah")
	assert_almost_eq(light.get_energy(1.0), 1.0, 0.01, "malam: penuh")

extends GutTest

const IslandHarness = preload("res://tests/integration/island_harness.gd")

const RECIPE_STONE_AXE := preload("res://src/data/recipes/stone_axe.tres")
const RECIPE_COOKED_MEAT := preload("res://src/data/recipes/cooked_meat.tres")

var _harness: IslandHarness


func before_each() -> void:
	_harness = IslandHarness.new()
	_harness.setup(self)


func after_each() -> void:
	if _harness != null:
		_harness.teardown()
		_harness = null


func test_s2_survival_loop() -> void:
	var inv := _harness.inventory
	var inter := _harness.interactor
	var camp := _harness.camp
	var player := _harness.player

	# 1. Give exact materials via inventory for all four structures:
	# Campfire: 4 wood, 3 stone, 2 fiber
	# Workbench: 5 wood, 2 stone, 3 fiber
	# Chest: 6 wood, 2 fiber
	# Tent: 6 wood, 6 fiber, 2 bamboo
	# Total: 21 wood, 5 stone, 13 fiber, 2 bamboo
	inv.add_item(ItemCatalog.WOOD, 21)
	inv.add_item(ItemCatalog.STONE, 5)
	inv.add_item(ItemCatalog.FIBER, 13)
	inv.add_item(ItemCatalog.BAMBOO, 2)

	# 2. Build all four structures through BlueprintSlot
	var campfire_slot := camp.get_node("CampfireSlot") as BlueprintSlot
	var wb_slot := camp.get_node("WorkbenchSlot") as BlueprintSlot
	var chest_slot := camp.get_node("ChestSlot") as BlueprintSlot
	var tent_slot := camp.get_node("TentSlot") as BlueprintSlot

	assert_true(campfire_slot.can_interact(inter), "CampfireSlot harus bisa diinteraksi")
	campfire_slot.interact(inter)
	assert_true(camp.has_built(&"campfire"), "Campfire harus terdaftar di CampController")

	assert_true(wb_slot.can_interact(inter), "WorkbenchSlot harus bisa diinteraksi")
	wb_slot.interact(inter)
	assert_true(camp.has_built(&"workbench"), "Workbench harus terdaftar di CampController")

	assert_true(chest_slot.can_interact(inter), "ChestSlot harus bisa diinteraksi")
	chest_slot.interact(inter)
	assert_true(camp.has_built(&"chest"), "Chest harus terdaftar di CampController")

	assert_true(tent_slot.can_interact(inter), "TentSlot harus bisa diinteraksi")
	tent_slot.interact(inter)
	assert_true(camp.has_built(&"tent"), "Tent harus terdaftar di CampController")

	# Cost consumed
	assert_eq(inv.count_of(ItemCatalog.WOOD), 0, "Semua 21 kayu harus dikonsumsi untuk membangun")
	assert_eq(inv.count_of(ItemCatalog.STONE), 0, "Semua 5 batu harus dikonsumsi untuk membangun")
	assert_eq(inv.count_of(ItemCatalog.FIBER), 0, "Semua 13 serat harus dikonsumsi untuk membangun")
	assert_eq(inv.count_of(ItemCatalog.BAMBOO), 0, "Semua 2 bambu harus dikonsumsi untuk membangun")

	# 3. Gather a tree with a granted axe via ResourceNode
	var builder := _harness.island.get_node("IslandBuilder")
	var tree_node: ResourceNode = null
	for child in builder.get_children():
		if child is ResourceNode and (child as ResourceNode).definition.id == &"tree":
			tree_node = child as ResourceNode
			break
	assert_not_null(tree_node, "Pohon harus ditemukan di pulau")

	# Grant axe to equip
	inv.equip(ItemCatalog.STONE_AXE)
	assert_true(inv.has_tool(&"stone_axe"), "Pemain harus memiliki tool stone_axe")

	var wood_before := inv.count_of(ItemCatalog.WOOD)
	tree_node.interact(inter)
	var wood_after := inv.count_of(ItemCatalog.WOOD)
	assert_gt(wood_after, wood_before, "Mengumpulkan pohon harus menghasilkan kayu ke tas")

	# 4. Craft stone_axe at the Workbench
	# Unequip tool first so REASON_TOOL_OWNED does not block crafting
	inv.unequip(ItemDefinition.EquipmentSlot.TOOL)
	assert_false(inv.has_tool(&"stone_axe"), "Tool stone_axe berhasil dilepas")

	# Move player close to WorkbenchSlot (-96, -32)
	player.global_position = Vector2(-96, -32)

	# Recipe requires 2 wood, 2 stone, 1 fiber
	inv.add_item(ItemCatalog.WOOD, 2)
	inv.add_item(ItemCatalog.STONE, 2)
	inv.add_item(ItemCatalog.FIBER, 1)

	var crafting := _harness.crafting
	assert_true(crafting.can_craft(RECIPE_STONE_AXE), "Harus bisa craft stone_axe di dekat Workbench")
	assert_true(crafting.start_craft(RECIPE_STONE_AXE), "Harus berhasil memulai craft stone_axe")
	crafting.tick(RECIPE_STONE_AXE.craft_time + 0.1)
	assert_false(crafting.is_crafting(), "Crafting stone_axe harus selesai")
	assert_true(inv.has_tool(&"stone_axe"), "Hasil craft stone_axe terpasang sebagai tool")

	# 5. Cook meat at the lit Campfire and eat it (needs rise)
	var campfire := camp.get_structure(&"campfire") as Campfire
	assert_not_null(campfire, "Campfire instance harus valid")
	assert_true(campfire.is_lit(), "Campfire yang baru dibangun harus dalam keadaan menyala")

	# Move player close to Campfire (0, 0)
	player.global_position = Vector2(0, 0)

	inv.add_item(ItemCatalog.RAW_MEAT, 1)
	assert_true(crafting.can_craft(RECIPE_COOKED_MEAT), "Harus bisa masak daging di api unggun yang menyala")
	assert_true(crafting.start_craft(RECIPE_COOKED_MEAT), "Harus berhasil mulai masak daging")
	crafting.tick(RECIPE_COOKED_MEAT.craft_time + 0.1)
	assert_gt(inv.count_of(ItemCatalog.COOKED_MEAT), 0, "Daging masak harus ada di inventory")

	# Lower hunger to verify eating raises needs
	var needs := _harness.needs
	needs.set_value(NeedsComponent.Need.HUNGER, 40.0)
	var hunger_before := needs.get_value(NeedsComponent.Need.HUNGER)

	# Find slot of cooked_meat
	var meat_slot := -1
	for slot_idx in inv.get_capacity():
		var item := inv.get_slot_item(slot_idx)
		if item != null and item.id == &"cooked_meat":
			meat_slot = slot_idx
			break
	assert_ne(meat_slot, -1, "Slot daging masak harus ditemukan")

	assert_true(inv.use_slot(meat_slot), "Makan daging masak harus berhasil")
	var hunger_after := needs.get_value(NeedsComponent.Need.HUNGER)
	assert_gt(hunger_after, hunger_before, "Hunger harus meningkat setelah makan daging masak")

	# 6. Sleep in the Tent by day (skip_time called once, Fatigue cap and fill rise)
	var tent := camp.get_structure(&"tent") as Tent
	assert_not_null(tent, "Tent instance harus valid")

	# Sprint to lower fatigue cap and fill
	player.velocity = Vector2(240.0, 0.0)
	player.sprint_state_changed.emit(true)
	needs.tick(50.0)
	player.sprint_state_changed.emit(false)

	var cap_before := needs.get_fatigue_cap()
	var fatigue_before := needs.get_value(NeedsComponent.Need.FATIGUE)
	assert_lt(cap_before, 100.0, "Plafon Fatigue harus turun akibat sprint")

	watch_signals(_harness.clock)
	assert_true(tent.can_sleep(), "Harus bisa tidur di siang hari")
	assert_true(tent.sleep(player), "Pemain harus berhasil tidur")
	assert_signal_emitted(_harness.clock, "time_skipped")

	var cap_after := needs.get_fatigue_cap()
	var fatigue_after := needs.get_value(NeedsComponent.Need.FATIGUE)
	assert_gt(cap_after, cap_before, "Plafon Fatigue harus naik setelah tidur di Tenda")
	assert_gt(fatigue_after, fatigue_before, "Nilai Fatigue harus naik setelah tidur di Tenda")

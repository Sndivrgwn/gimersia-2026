extends GutTest

## Regresi alur camp nyata di island.tscn: E membuka panel stasiun/peti,
## craft berjalan, peti bisa menyimpan, dan QTE api unggun membuka resep.

const IslandHarness = preload("res://tests/integration/island_harness.gd")

var h: IslandHarness


func before_each() -> void:
	h = IslandHarness.new()
	h.setup(self)


func after_each() -> void:
	if h != null:
		h.teardown()
		h = null


func _build_camp() -> void:
	h.inventory.add_item(ItemCatalog.WOOD, 100)
	h.inventory.add_item(ItemCatalog.STONE, 100)
	h.inventory.add_item(ItemCatalog.FIBER, 100)
	for slot in h.camp.get_slots():
		var id := String(slot.definition.id) if slot.definition != null else ""
		if id in ["campfire", "workbench", "chest"]:
			slot.interact(h.interactor)
	await wait_frames(2)
	assert_true(h.camp.has_built(&"workbench"), "meja kerja terbangun")
	assert_true(h.camp.has_built(&"chest"), "peti terbangun")
	assert_true(h.camp.has_built(&"campfire"), "api unggun terbangun")


func _press_interact() -> void:
	# Interactor memindai target tiap `scan_interval`; beri satu scan penuh dulu
	# supaya E sungguhan memilih stasiun/peti seperti di gameplay.
	await wait_frames(4)
	Input.action_press(InputSetup.INTERACT)
	await wait_frames(8)
	Input.action_release(InputSetup.INTERACT)
	await wait_frames(2)


func test_workbench_panel_opens_with_e_and_crafts() -> void:
	await _build_camp()
	h.inventory.add_item(ItemCatalog.WOOD, 10)
	h.inventory.add_item(ItemCatalog.STONE, 10)
	h.inventory.add_item(ItemCatalog.FIBER, 10)
	var bench := h.camp.get_structure(&"workbench")
	h.player.global_position = bench.global_position
	await _press_interact()

	var panel := h.island.get_node("StationPanel") as StationPanel
	assert_true(panel.is_open(), "E di meja kerja membuka panel")
	assert_gt(panel.get_rows().size(), 0, "resep meja kerja tampil")
	var row: CraftingRow = panel.get_rows()[0]
	assert_false(row.is_craft_disabled(), "bahan lengkap membuat Craft aktif")
	row.press_craft()
	assert_true(h.crafting.is_crafting(), "craft mulai")
	assert_true(panel.get_progress().visible, "progress terlihat")
	for index in 200:
		if not h.crafting.is_crafting():
			break
		h.crafting.tick(0.05)
	assert_false(h.crafting.is_crafting(), "craft selesai")
	assert_string_contains(panel.get_status_text(), "Selesai")
	panel.close()


func test_chest_panel_opens_with_e_and_stores_items() -> void:
	await _build_camp()
	var chest := h.camp.get_structure(&"chest") as Chest
	h.player.global_position = chest.global_position
	await _press_interact()

	var panel := h.island.get_node("ChestPanel") as ChestPanel
	assert_true(panel.is_open(), "E di peti membuka panel")
	assert_eq(panel.chest, chest, "panel membuka peti yang diinteraksi")
	h.inventory.add_item(ItemCatalog.WOOD, 5)
	panel.refresh()
	panel.call(&"_on_bag_slot", _first_bag_slot_with(h.inventory, ItemCatalog.WOOD))
	assert_gt(chest.get_component().count_of(ItemCatalog.WOOD), 0, "barang masuk ke peti")
	h.inventory.add_item(ItemCatalog.WOOD, 4)
	panel.refresh()
	panel.store_all()
	assert_eq(h.inventory.count_of(ItemCatalog.WOOD), 0, "Simpan semua mengosongkan kayu di tas")
	assert_gt(chest.get_component().count_of(ItemCatalog.WOOD), 9, "semua kayu ada di peti")
	panel.close()


func test_campfire_qte_keeps_panel_open_and_unlocks_recipes() -> void:
	await _build_camp()
	var fire := h.camp.get_structure(&"campfire") as Campfire
	h.player.global_position = fire.global_position
	h.inventory.add_item(ItemCatalog.STONE, 5)
	await _press_interact()

	var panel := h.island.get_node("StationPanel") as StationPanel
	assert_true(panel.is_open(), "E di api unggun membuka panel")
	var cold_row: CraftingRow = panel.get_rows()[0]
	assert_true(cold_row.is_locked(), "resep terkunci saat api dingin")
	panel.flint_pressed()
	assert_true(panel.is_open(), "panel tetap terbuka saat QTE")
	var starter := h.player.get_node("FireStarterController") as FireStarterController
	assert_true(starter.is_active(), "QTE gesek batu mulai")
	starter.roll_override = 0.0
	starter.set_marker(0.5)
	starter.strike()
	assert_true(fire.is_lit(), "api menyala")
	assert_true(panel.is_open(), "panel tetap terbuka setelah menyala")
	assert_false(panel.get_rows()[0].is_locked(), "resep langsung aktif")
	panel.close()


func _first_bag_slot_with(inventory: InventoryComponent, item: ItemDefinition) -> int:
	for index in inventory.get_capacity():
		if inventory.get_slot_item(index) == item:
			return index
	return 0

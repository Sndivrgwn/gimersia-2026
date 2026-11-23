extends GutTest

## Mission 10 Phase 2 (R8): reproduksi "Butuh Meja Kerja" pada island.tscn asli.
## Base didirikan, Meja Kerja + Api Unggun dibangun lewat BlueprintSlot asli.

const IslandHarness = preload("res://tests/integration/island_harness.gd")

var _harness: IslandHarness
var _built: Dictionary = {}


func before_each() -> void:
	_harness = IslandHarness.new()
	_harness.setup(self)


func after_each() -> void:
	if _harness != null:
		_harness.teardown()
		_harness = null





func _slot_of(id: StringName) -> BlueprintSlot:
	for slot in _harness.camp.get_slots():
		if slot.definition != null and slot.definition.id == id:
			return slot
	return null


func _build(id: StringName) -> CampStructure:
	var slot := _slot_of(id)
	if slot == null:
		return null
	# Bahan diberikan tepat sesuai build_cost (stack tas terbatas).
	for entry in slot.definition.build_cost:
		_harness.inventory.add_item(entry.item, entry.count)
	print("slot=", id, " enabled=", slot.is_enabled(), " reason=", slot.get_block_reason(_harness.interactor))
	slot.interact(_harness.interactor)
	return slot.get_structure()


func _stand_next_to(node: Node2D) -> void:
	_harness.player.global_position = node.global_position + Vector2(0.0, 24.0)


func test_workbench_station_is_usable_after_real_build() -> void:
	var bench := _build(&"workbench")
	assert_not_null(bench, "meja kerja terbangun lewat BlueprintSlot")
	if bench == null:
		return
	# BlueprintSlot menaruh struktur di parent slot (CampController), bukan slot.
	print("bench_parent=", bench.get_parent().name, " bench_pos=", bench.global_position)
	print("slot_pos=", _slot_of(&"workbench").global_position, " player=", _harness.player.global_position)
	_stand_next_to(bench)
	print("player_after=", _harness.player.global_position, " dist=", _harness.player.global_position.distance_to(bench.global_position))

	var stations := _harness.crafting.get_stations_in_range()
	print("stations_in_range=", stations.size(), " range=", _harness.crafting.station_range)
	assert_true(stations.has(bench), "meja kerja harus terdeteksi sebagai stasiun aktif")

	var workbench_recipes := 0
	for recipe in _harness.crafting.get_available_recipes():
		if recipe.station == RecipeDefinition.Station.WORKBENCH:
			workbench_recipes += 1
	print("workbench_recipes_available=", workbench_recipes)
	assert_gt(workbench_recipes, 0, "resep meja kerja harus terbuka")


## Akar bug "Butuh Meja Kerja": tab Crafting dibangun saat panel _ready (belum ada
## stasiun) dan tidak dihitung ulang saat panel dibuka kembali.
func test_bag_crafting_tab_refreshes_after_station_built() -> void:
	var panel := _harness.island.get_node("BagPanel")
	panel.toggle_panel()
	panel.toggle_panel()

	var bench := _build(&"workbench")
	assert_not_null(bench, "meja kerja terbangun")
	if bench == null:
		return
	_stand_next_to(bench)
	panel.toggle_panel()

	var locked_station_rows := 0
	var hand_rows := 0
	for row in panel.get_crafting_rows():
		if row.get_recipe().station == RecipeDefinition.Station.HAND:
			hand_rows += 1
		elif row.is_locked():
			locked_station_rows += 1
	var info := panel.get_node("Root/Frame/Margin/VBox/Tabs/Crafting").find_child("StationInfo", true, false)
	panel.toggle_panel()
	assert_eq(locked_station_rows, 0, "resep stasiun tidak boleh lagi tampil terkunci di tab tas")
	assert_gt(hand_rows, 0, "resep tangan tetap ada")
	assert_not_null(info, "tab tas menampilkan info 'Dibuka lewat E di Meja Kerja / Api Unggun'")
	assert_string_contains((info as Label).text, "Dibuka lewat E")


func test_station_panel_opens_and_crafts_with_station() -> void:
	var bench := _build(&"workbench")
	assert_not_null(bench, "meja kerja terbangun")
	if bench == null:
		return
	_stand_next_to(bench)
	var panel := _harness.island.get_node("StationPanel") as StationPanel
	assert_true(panel.open(bench, _harness.interactor), "panel stasiun terbuka")
	assert_eq(panel.get_title_text(), "MEJA KERJA")
	assert_gt(panel.get_rows().size(), 0, "baris resep meja kerja ada")

	var axe_recipe: RecipeDefinition = null
	for recipe in _harness.crafting.get_recipes_for(RecipeDefinition.Station.WORKBENCH):
		if recipe.result != null and recipe.result.id == &"stone_axe":
			axe_recipe = recipe
	assert_not_null(axe_recipe, "resep stone_axe ada")
	if axe_recipe == null:
		return
	for entry in axe_recipe.ingredients:
		_harness.inventory.add_item(entry.item, entry.count)
	assert_true(_harness.crafting.start_craft(axe_recipe, bench), "craft lewat stasiun dimulai")
	_harness.crafting.tick(axe_recipe.craft_time + 0.1)
	assert_true(_harness.inventory.has_tool(&"stone_axe"), "hasil craft langsung dimiliki sebagai alat")
	panel.close()
	assert_false(panel.is_open())


func test_station_craft_cancels_when_leaving_range() -> void:
	var bench := _build(&"workbench")
	if bench == null:
		return
	_stand_next_to(bench)
	var recipe: RecipeDefinition = null
	for candidate in _harness.crafting.get_recipes_for(RecipeDefinition.Station.WORKBENCH):
		if candidate.craft_time > 0.5:
			recipe = candidate
			break
	if recipe == null:
		return
	for entry in recipe.ingredients:
		_harness.inventory.add_item(entry.item, entry.count)
	assert_true(_harness.crafting.start_craft(recipe, bench))
	_harness.player.global_position = bench.global_position + Vector2(400.0, 0.0)
	watch_signals(_harness.crafting)
	_harness.crafting.tick(0.1)
	assert_signal_emitted(_harness.crafting, "craft_cancelled")


func test_lit_campfire_station_is_usable_after_real_build() -> void:
	var fire := _build(&"campfire")
	assert_not_null(fire, "api unggun terbangun lewat BlueprintSlot")
	if fire == null:
		return
	var campfire := fire as Campfire
	campfire.set_fuel(campfire.get_max_fuel())
	var ignited := campfire.ignite()
	print("campfire_ignited=", ignited, " needs_ignition=", campfire.needs_ignition())
	assert_true(ignited, "api unggun bisa dinyalakan setelah diisi bahan bakar")
	_stand_next_to(fire)
	assert_true(
		_harness.crafting.get_stations_in_range().has(fire),
		"api unggun menyala harus terdeteksi sebagai stasiun"
	)
	var fire_recipes := 0
	for recipe in _harness.crafting.get_available_recipes():
		if recipe.station == RecipeDefinition.Station.CAMPFIRE:
			fire_recipes += 1
	assert_gt(fire_recipes, 0, "resep api unggun harus terbuka")

extends GutTest

## Mission 16 (L1 & L2): cahaya api unggun halus siang->sore->malam dan
## regresi masak di StationPanel saat api unggun sedang menyala & membakar fuel.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const CAMPFIRE_SCENE: PackedScene = preload("res://src/entities/camp/campfire/campfire.tscn")
const CAMPFIRE_DEF: StructureDefinition = preload("res://src/data/camp/campfire.tres")
const COOKED_MEAT_RECIPE: RecipeDefinition = preload("res://src/data/recipes/cooked_meat.tres")


class StubDarknessVisual extends Node2D:
	var darkness: float = 0.0

	func get_world_darkness() -> float:
		return darkness


class StubClock extends Node:
	var night: bool = false
	var scale: float = 1.0

	func is_night() -> bool:
		return night

	func get_time_scale() -> float:
		return scale


class StubInteractor extends Node:
	var inventory: InventoryComponent

	func get_inventory() -> InventoryComponent:
		return inventory


# --- L1: Cahaya api unggun di sore & malam ----------------------------------

func test_l1_lit_campfire_energy_rises_monotonically_from_day_to_dusk_to_night() -> void:
	var visual := StubDarknessVisual.new()
	visual.add_to_group(&"day_night_visual")
	add_child_autofree(visual)

	var clock := StubClock.new()
	add_child_autofree(clock)

	var fire := CAMPFIRE_SCENE.instantiate() as Campfire
	fire.definition = CAMPFIRE_DEF
	fire.clock = clock
	add_child_autofree(fire)
	fire.set_process(false)

	# Api mati (COLD): tetap gelap (energy == 0).
	visual.darkness = 0.5
	fire.tick(0.1)
	assert_almost_eq(fire.get_light().energy, 0.0, 0.001, "api mati tetap gelap di sore")
	assert_false(fire.get_light().visible)

	# Nyalakan api: fade naik halus mengikuti time_scale, lalu monoton dari siang -> sore -> malam.
	assert_true(fire.ignite())
	fire.tick(1.0)

	visual.darkness = 0.0
	fire.tick(0.016)
	var e_day := fire.get_light().energy
	assert_almost_eq(e_day, fire.config.light_energy_day, 0.01, "energi siang = light_energy_day")

	var prev := e_day
	for step in range(1, 21):
		visual.darkness = float(step) / 20.0
		fire.tick(0.016)
		var cur := fire.get_light().energy
		assert_gt(cur, 0.0, "energi sore/malam > 0")
		assert_gte(cur, prev, "naik monoton menuju malam")
		assert_lt(cur - prev, 0.08, "tidak ada loncatan energi antar langkah")
		prev = cur

	assert_almost_eq(fire.get_light().energy, fire.config.light_energy_night, 0.01, "energi malam = light_energy_night")


func test_l1_fade_respects_time_scale_and_mid_dusk_load_is_immediate() -> void:
	var visual := StubDarknessVisual.new()
	visual.add_to_group(&"day_night_visual")
	visual.darkness = 0.5
	add_child_autofree(visual)

	var clock := StubClock.new()
	clock.scale = 0.0
	add_child_autofree(clock)

	var fire := CAMPFIRE_SCENE.instantiate() as Campfire
	fire.definition = CAMPFIRE_DEF
	fire.clock = clock
	add_child_autofree(fire)
	fire.set_process(false)
	fire.ignite()
	# time_scale = 0: fade tidak bergerak.
	fire.tick(0.5)
	assert_almost_eq(fire.get_light().energy, 0.0, 0.001, "time_scale 0 membekukan fade cahaya")

	clock.scale = 1.0
	fire.tick(1.0)
	assert_almost_eq(fire.get_light().energy, fire.config.light_energy_dusk, 0.01)

	# Load langsung di tengah sore dengan start_lit = true: langsung benar tanpa kedip.
	var cfg_lit := CampfireConfig.new()
	cfg_lit.start_lit = true
	var loaded := CAMPFIRE_SCENE.instantiate() as Campfire
	loaded.definition = CAMPFIRE_DEF
	loaded.config = cfg_lit
	loaded.clock = clock
	add_child_autofree(loaded)
	loaded.set_process(false)
	assert_almost_eq(loaded.get_light().energy, cfg_lit.light_energy_dusk, 0.01, "load di tengah sore langsung benar")


# --- L2: Masak di campfire (regresi tombol tidak hancur oleh fuel_changed) --

func test_l2_burning_campfire_does_not_destroy_rows_and_cooking_succeeds() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	player.add_to_group(&"player")
	add_child_autofree(player)
	(player.get_node("NeedsComponent") as NeedsComponent).set_process(false)

	var inventory := InventoryComponent.new()
	inventory.name = "InventoryComponent"
	inventory.setup(player)
	player.add_child(inventory)
	inventory.set_process(false)

	var crafting := CraftingComponent.new()
	crafting.name = "CraftingComponent"
	crafting.setup(player, inventory, player.stats)
	crafting.input_enabled = false
	player.add_child(crafting)
	crafting.set_process(false)

	var clock := StubClock.new()
	add_child_autofree(clock)

	var fire := CAMPFIRE_SCENE.instantiate() as Campfire
	fire.definition = CAMPFIRE_DEF
	fire.clock = clock
	add_child_autofree(fire)
	fire.global_position = player.global_position + Vector2(20.0, 0.0)
	fire.set_process(false)

	var interactor := StubInteractor.new()
	interactor.inventory = inventory
	player.add_child(interactor)

	var panel := StationPanel.new()
	add_child_autofree(panel)
	panel.player = player
	panel.crafting = crafting

	# 1) Saat api mati: masak ditolak dengan pesan jelas, inventori tidak berubah.
	inventory.add_item(ItemCatalog.RAW_MEAT, 2)
	assert_true(panel.open(fire, interactor))
	var cold_row: CraftingRow = _find_row(panel, &"cooked_meat")
	assert_not_null(cold_row)
	assert_true(cold_row.is_craft_disabled(), "tombol Buat mati saat api belum menyala")
	assert_string_contains(cold_row.get_block_reason(), "Api belum menyala")
	assert_false(crafting.start_craft(COOKED_MEAT_RECIPE, fire), "start_craft ditolak saat api mati")
	assert_eq(inventory.count_of(ItemCatalog.RAW_MEAT), 2)
	assert_eq(inventory.count_of(ItemCatalog.COOKED_MEAT), 0)

	# 2) Nyalakan api, lalu tick Campfire berkali-kali (fuel_changed terpancar tiap frame!):
	#    Baris & tombol TIDAK boleh dihancurkan (regresi bug L2).
	assert_true(fire.ignite())
	var warm_row: CraftingRow = _find_row(panel, &"cooked_meat")
	assert_not_null(warm_row)
	var row_id := warm_row.get_instance_id()

	for _i in 10:
		fire.tick(0.016)
		panel.tick(0.016)

	assert_true(is_instance_valid(warm_row), "row tidak hancur saat fuel_changed terpancar tiap frame")
	assert_eq(_find_row(panel, &"cooked_meat").get_instance_id(), row_id, "instance tombol tetap sama")
	assert_false(warm_row.is_craft_disabled(), "tombol Buat aktif saat api menyala & bahan ada")

	# 3) Klik Buat berkali-kali cepat tidak menduplikasi item; bahan berkurang, hasil bertambah.
	warm_row.press_craft()
	warm_row.press_craft()
	assert_true(crafting.is_crafting())
	var t := 0.0
	while t < 10.0 and crafting.is_crafting():
		crafting.tick(0.25)
		fire.tick(0.25)
		t += 0.25

	assert_false(crafting.is_crafting())
	assert_eq(inventory.count_of(ItemCatalog.RAW_MEAT), 1, "bahan berkurang tepat 1")
	assert_eq(inventory.count_of(ItemCatalog.COOKED_MEAT), 1, "hasil bertambah tepat 1 tanpa duplikasi")

	# 4) Bahan habis -> pesan jelas & inventori tidak berubah.
	inventory.remove_item(ItemCatalog.RAW_MEAT, 1)
	panel.refresh_rows()
	assert_true(warm_row.is_craft_disabled(), "tombol nonaktif saat bahan kosong")
	assert_false(warm_row.get_block_reason().is_empty(), "pesan gagal bahan kurang muncul")
	assert_false(crafting.start_craft(COOKED_MEAT_RECIPE, fire))
	assert_eq(inventory.count_of(ItemCatalog.COOKED_MEAT), 1)


func _find_row(panel: StationPanel, recipe_id: StringName) -> CraftingRow:
	for row in panel.get_rows():
		if row is CraftingRow and (row as CraftingRow).get_recipe().id == recipe_id:
			return row as CraftingRow
	return null

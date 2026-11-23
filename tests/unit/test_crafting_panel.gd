extends GutTest

## Tes tab Crafting di BagPanel: daftar resep (tersedia + terkunci), teks
## have/need, tombol Craft -> start_craft -> konsumsi bahan, progres, dan batal.
## Panel tidak menyimpan state gameplay; semua angka dibaca dari komponen.

const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const CraftingComponentScript = preload("res://src/components/crafting/crafting_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const BAG_PANEL_SCENE: PackedScene = preload("res://src/ui/panels/inventory/bag_panel.tscn")


class StubStation extends Node2D:
	var station_type: int = RecipeDefinition.Station.WORKBENCH

	func is_station_active() -> bool:
		return true


var player: Player
var inventory: InventoryComponentScript
var crafting
var panel


func before_each() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	player.add_to_group(&"player")
	add_child_autofree(player)
	(player.get_node("NeedsComponent") as NeedsComponent).set_process(false)

	inventory = InventoryComponentScript.new()
	inventory.name = "InventoryComponent"
	inventory.setup(player)
	player.add_child(inventory)
	inventory.set_process(false)

	crafting = CraftingComponentScript.new()
	crafting.name = "CraftingComponent"
	crafting.setup(player, inventory, player.stats)
	crafting.input_enabled = false
	player.add_child(crafting)
	crafting.set_process(false)
	# Mission 10 (R4): tab Crafting bag kini hand-only. Tes ini menguji tampilan
	# lama (semua resep + bagian terkunci), jadi pakai duplikat config dengan
	# flag kompatibilitas dimatikan (tidak bocor ke tes lain).
	if crafting.station_config != null:
		var legacy_station: StationConfig = crafting.station_config.duplicate()
		legacy_station.bag_tab_hand_only = false
		crafting.station_config = legacy_station

	# Panel menemukan InventoryComponent + CraftingComponent lewat grup player.
	panel = BAG_PANEL_SCENE.instantiate()
	add_child_autofree(panel)


# --- Daftar resep -----------------------------------------------------------

func test_tab_lists_all_recipes_split_into_available_and_locked() -> void:
	var rows: Array = panel.get_crafting_rows()
	assert_eq(rows.size(), 13, "semua 13 resep tampil")
	assert_eq(_rows_unlocked().size(), 3, "hanya 3 resep tangan yang terbuka")
	assert_eq(_rows_locked().size(), 10, "sisanya menunggu stasiun")

	for row in _rows_locked():
		assert_true(row.is_craft_disabled(), "resep terkunci tidak bisa di-craft")
		assert_ne(row.get_block_reason(), "", "resep terkunci punya alasan")


func test_ingredients_show_have_need_and_highlight_missing() -> void:
	inventory.add_item(ItemCatalog.WOOD, 3)
	inventory.add_item(ItemCatalog.FIBER, 1)

	var row := _row_for(&"wooden_spear")
	assert_not_null(row)
	assert_eq(row.get_ingredient_count(), 2)
	assert_true(row.get_ingredient_text(0).ends_with("3/3"), "kayu cukup")
	assert_true(row.get_ingredient_text(1).ends_with("1/2"), "serat kurang")
	assert_false(row.is_ingredient_missing(0))
	assert_true(row.is_ingredient_missing(1), "bahan kurang ditandai merah")
	assert_eq(row.get_block_reason(), CraftingComponentScript.REASON_NO_INGREDIENTS)
	assert_true(row.is_craft_disabled())


func test_locked_row_names_station_and_is_dimmed() -> void:
	var row := _row_for(&"stone_axe")
	assert_not_null(row)
	assert_true(row.is_locked())
	assert_eq(row.get_block_reason(), "Butuh Workbench")
	assert_true(row.is_craft_disabled())
	assert_true(row.modulate.a < 1.0, "baris terkunci diredupkan")


func test_row_shows_have_need_for_weapon_slot_ingredient() -> void:
	inventory.add_item(ItemCatalog.WOOD, 3)
	inventory.add_item(ItemCatalog.FIBER, 2)
	_row_for(&"wooden_spear").press_craft()
	crafting.tick(2.0)

	# Resep tombak batu memakai tombak kayu dari slot WEAPON, bukan dari tas.
	var row := _row_for(&"stone_spear")
	assert_not_null(row)
	var found := false
	for index in row.get_recipe().ingredients.size():
		var amount := row.get_recipe().ingredients[index]
		if amount.item != null and amount.item.id == ItemCatalog.WOODEN_SPEAR.id:
			found = true
			assert_true(row.get_ingredient_text(index).ends_with("1/1"), "senjata terpasang dihitung")
	assert_true(found, "resep memakai tombak kayu sebagai bahan")


# --- Aksi craft -------------------------------------------------------------

func test_craft_from_row_consumes_ingredients_and_updates_status() -> void:
	inventory.add_item(ItemCatalog.WOOD, 3)
	inventory.add_item(ItemCatalog.FIBER, 2)

	var row := _row_for(&"wooden_spear")
	assert_not_null(row)
	assert_false(row.is_craft_disabled(), "bahan lengkap -> tombol aktif")

	row.press_craft()
	assert_true(crafting.is_crafting())
	assert_string_contains(panel.get_crafting_status_text(), "Membuat")

	var progress: ProgressBar = panel.get_crafting_progress()
	assert_true(progress.visible)

	crafting.tick(2.0)

	assert_false(crafting.is_crafting())
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 0, "bahan terpakai saat selesai")
	assert_eq(inventory.count_of(ItemCatalog.FIBER), 0)
	assert_string_contains(panel.get_crafting_status_text(), "Selesai")
	assert_false(progress.visible)

	var refreshed := _row_for(&"wooden_spear")
	assert_true(refreshed.is_craft_disabled(), "senjata setara sudah terpasang")


func test_progress_bar_tracks_craft_ratio() -> void:
	inventory.add_item(ItemCatalog.WOOD, 3)
	inventory.add_item(ItemCatalog.FIBER, 2)

	_row_for(&"wooden_spear").press_craft()
	crafting.tick(1.0)

	var progress: ProgressBar = panel.get_crafting_progress()
	assert_almost_eq(progress.value, 0.5, 0.05, "1.0 s dari 2.0 s")


func test_cancel_button_stops_craft_without_consuming() -> void:
	inventory.add_item(ItemCatalog.WOOD, 3)
	inventory.add_item(ItemCatalog.FIBER, 2)

	_row_for(&"wooden_spear").press_craft()
	assert_true(crafting.is_crafting())

	panel.cancel_current_craft()

	assert_false(crafting.is_crafting())
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 3, "batal tidak memakai bahan")
	assert_string_contains(panel.get_crafting_status_text(), "Batal")


# --- Stasiun ----------------------------------------------------------------

func test_station_in_range_rebuilds_list_while_open() -> void:
	panel.toggle_panel()
	var unlocked_before: int = _rows_unlocked().size()

	var bench := StubStation.new()
	add_child_autofree(bench)
	bench.add_to_group(&"crafting_station")
	bench.global_position = (player as Node2D).global_position + Vector2(40, 0)

	crafting.tick(0.0)

	assert_true(_rows_unlocked().size() > unlocked_before, "resep Workbench terbuka")
	var axe := _row_for(&"stone_axe")
	assert_not_null(axe)
	assert_false(axe.is_locked())
	assert_true(axe.is_craft_disabled(), "bahan kosong -> Craft tetap nonaktif")
	assert_eq(axe.get_block_reason(), CraftingComponentScript.REASON_NO_INGREDIENTS)


# --- Helper -----------------------------------------------------------------

func _rows_unlocked() -> Array:
	var result: Array = []
	for row in panel.get_crafting_rows():
		if not row.is_locked():
			result.append(row)
	return result


func _rows_locked() -> Array:
	var result: Array = []
	for row in panel.get_crafting_rows():
		if row.is_locked():
			result.append(row)
	return result


func _row_for(item_id: StringName) -> CraftingRow:
	for row in panel.get_crafting_rows():
		if row.get_recipe().result != null and row.get_recipe().result.id == item_id:
			return row
	return null

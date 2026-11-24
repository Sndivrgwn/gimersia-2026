extends GutTest

## Fase 4B: tombol Craft xN (batch) dan highlight baris yang siap di-craft.

const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const CraftingComponentScript = preload("res://src/components/crafting/crafting_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const BAG_PANEL_SCENE: PackedScene = preload("res://src/ui/panels/inventory/bag_panel.tscn")

## Obor: 2 kayu + 1 serat, 1.5 s, HAND; hasilnya tidak menempati slot equipment
## sehingga batch bisa berulang tanpa aturan equip memblokir siklus kedua.
const TORCH: RecipeDefinition = preload("res://src/data/recipes/torch.tres")

var player: Player
var inventory: InventoryComponentScript
var crafting


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


func test_batch_crafts_repeatedly_until_requested_count() -> void:
	inventory.add_item(ItemCatalog.WOOD, 6)
	inventory.add_item(ItemCatalog.FIBER, 3)

	assert_true(crafting.start_craft(TORCH, null, 3))
	assert_eq(crafting.get_batch_total(), 3)
	assert_eq(crafting.get_batch_remaining(), 3)

	for cycle in 3:
		assert_true(crafting.is_crafting(), "siklus %d berjalan" % (cycle + 1))
		crafting.tick(1.5)

	assert_false(crafting.is_crafting())
	assert_eq(crafting.get_batch_remaining(), 0, "batch selesai")
	assert_eq(crafting.get_batch_done(), 3)
	assert_eq(inventory.count_of(&"torch"), 3, "tiga obor dihasilkan")
	assert_eq(inventory.count_of(&"wood"), 0)
	assert_eq(inventory.count_of(&"fiber"), 0)


func test_batch_stops_when_ingredients_run_out() -> void:
	inventory.add_item(ItemCatalog.WOOD, 4)
	inventory.add_item(ItemCatalog.FIBER, 2)

	assert_true(crafting.start_craft(TORCH, null, 3))
	crafting.tick(1.5)
	assert_true(crafting.is_crafting(), "siklus kedua dimulai otomatis")
	crafting.tick(1.5)

	assert_false(crafting.is_crafting(), "bahan habis -> batch berhenti")
	assert_eq(crafting.get_batch_remaining(), 0)
	assert_eq(inventory.count_of(&"torch"), 2)
	assert_eq(inventory.count_of(&"wood"), 0)


func test_cancel_stops_the_whole_batch() -> void:
	inventory.add_item(ItemCatalog.WOOD, 6)
	inventory.add_item(ItemCatalog.FIBER, 3)
	crafting.start_craft(TORCH, null, 3)
	crafting.tick(1.5)

	crafting.cancel_craft("Dibatalkan")
	assert_false(crafting.is_crafting())
	assert_eq(crafting.get_batch_total(), 0, "batch ikut dibatalkan")
	assert_eq(inventory.count_of(&"torch"), 1)


func test_row_highlight_follows_craftability() -> void:
	var panel := _make_panel()
	var row: CraftingRow = _row_for(panel, &"torch")
	assert_not_null(row)
	assert_false(row.is_highlighted(), "bahan belum ada -> tidak disorot")

	inventory.add_item(ItemCatalog.WOOD, 2)
	inventory.add_item(ItemCatalog.FIBER, 1)
	row.refresh()
	assert_true(row.is_highlighted(), "bahan lengkap -> baris disorot")
	panel.queue_free()


func test_row_quantity_is_passed_to_start_craft() -> void:
	var panel := _make_panel()
	var row: CraftingRow = _row_for(panel, &"torch")
	assert_not_null(row)
	inventory.add_item(ItemCatalog.WOOD, 6)
	inventory.add_item(ItemCatalog.FIBER, 3)
	row.refresh()

	assert_eq(row.get_batch_quantity(), 1, "bawaan x1")
	row.set_batch_quantity(3)
	assert_eq(row.get_batch_quantity(), 3)

	row.press_craft()
	assert_true(crafting.is_crafting())
	assert_eq(crafting.get_batch_total(), 3, "jumlah dari SpinBox dipakai")
	panel.queue_free()


# --- Helper -----------------------------------------------------------------

func _make_panel() -> CanvasLayer:
	var panel := BAG_PANEL_SCENE.instantiate()
	add_child_autofree(panel)
	return panel


func _row_for(panel: CanvasLayer, id: StringName) -> CraftingRow:
	for row in panel.get_crafting_rows():
		if row.get_recipe() != null and row.get_recipe().id == id:
			return row
	return null

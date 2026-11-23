extends GutTest

## Panel Meja Kerja/Api Unggun: membuka panel mengunci gerak pemain (dunia
## tetap jalan), baris resep bisa di-craft, dan ChestPanel tidak lagi
## menyambung ke sinyal interaction_requested milik stasiun.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const WORKBENCH_SCENE: PackedScene = preload("res://src/entities/camp/workbench/workbench.tscn")
const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const CraftingComponentScript = preload("res://src/components/crafting/crafting_component.gd")

var player: Player
var inventory: InventoryComponent
var crafting: CraftingComponent
var bench: Node2D
var panel: StationPanel


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

	bench = WORKBENCH_SCENE.instantiate() as Node2D
	add_child_autofree(bench)
	bench.global_position = player.global_position + Vector2(32.0, 0.0)

	panel = StationPanel.new()
	panel.name = "StationPanel"
	add_child_autofree(panel)
	panel.player = player
	panel.crafting = crafting


func test_open_locks_movement_and_crafting_works() -> void:
	inventory.add_item(ItemCatalog.WOOD, 10)
	inventory.add_item(ItemCatalog.STONE, 10)
	inventory.add_item(ItemCatalog.FIBER, 10)

	assert_true(panel.open(bench, player), "panel stasiun terbuka")
	assert_true(panel.is_open())
	assert_true(player.is_input_locked(), "pemain tidak bisa bergerak selama panel terbuka")
	assert_gt(panel.get_rows().size(), 0, "resep Meja Kerja tampil")

	var row = panel.get_rows()[0]
	var wood_before := inventory.count_of(ItemCatalog.WOOD)
	assert_false(row.is_craft_disabled(), "bahan lengkap: tombol Craft aktif")
	row.press_craft()
	assert_true(crafting.is_crafting(), "craft mulai dari panel")

	var elapsed := 0.0
	while elapsed < 20.0 and crafting.is_crafting():
		crafting.tick(0.5)
		elapsed += 0.5

	assert_false(crafting.is_crafting(), "craft selesai")
	assert_lt(inventory.count_of(ItemCatalog.WOOD), wood_before, "bahan terkonsumsi")

	panel.close()
	assert_false(panel.is_open())
	assert_false(player.is_input_locked(), "gerak kembali setelah panel ditutup")


func test_chest_panel_does_not_listen_to_stations() -> void:
	var chest_panel := ChestPanel.new()
	add_child_autofree(chest_panel)
	chest_panel.call(&"_scan_chests")

	var connected: Dictionary = chest_panel.get(&"_connected_chests")
	assert_false(connected.has(bench.get_instance_id()), "workbench bukan peti")

	for connection in bench.interaction_requested.get_connections():
		var callable: Callable = connection["callable"]
		assert_ne(callable.get_object(), chest_panel, "tidak ada koneksi ke ChestPanel")

	bench.request_station_panel(player)
	assert_false(chest_panel.is_open(), "E di stasiun tidak membuka panel peti")

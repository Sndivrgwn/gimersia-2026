extends Node

## Harness sementara: render BagPanel tab Tas + tab Crafting pada 1152x648.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const BAG_PANEL_SCENE: PackedScene = preload("res://src/ui/panels/inventory/bag_panel.tscn")

var player: Player
var inventory: InventoryComponent
var crafting: CraftingComponent
var panel


func _ready() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	player.add_to_group(&"player")
	add_child(player)
	(player.get_node("NeedsComponent") as NeedsComponent).set_process(false)

	inventory = player.get_node_or_null("InventoryComponent") as InventoryComponent
	if inventory == null:
		inventory = InventoryComponent.new()
		inventory.name = "InventoryComponent"
		inventory.setup(player)
		player.add_child(inventory)
	inventory.set_process(false)

	crafting = CraftingComponent.new()
	crafting.name = "CraftingComponent"
	crafting.setup(player, inventory, player.stats)
	crafting.input_enabled = false
	player.add_child(crafting)
	crafting.set_process(false)

	inventory.add_item(ItemCatalog.WOOD, 5)
	inventory.add_item(ItemCatalog.FIBER, 12)
	inventory.add_item(ItemCatalog.STONE, 3)
	inventory.add_item(ItemCatalog.COOKED_MEAT, 3)
	inventory.add_item(ItemCatalog.BOILED_WATER, 2)
	inventory.add_item(ItemCatalog.RAW_MEAT, 4)
	inventory.equip(ItemCatalog.WOODEN_SPEAR)
	inventory.equip(ItemCatalog.LEATHER_VEST)

	panel = BAG_PANEL_SCENE.instantiate()
	panel.open_on_start = true
	add_child(panel)

	await _frames(4)
	await _capture("res://.ui_check/bag_tab.png")

	panel.get_node("Root/Frame/Margin/VBox/Tabs").current_tab = 1
	await _frames(4)
	await _capture("res://.ui_check/bag_crafting.png")

	get_tree().quit(0)


func _frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame


func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("SAVED ", path, " ", img.get_size())

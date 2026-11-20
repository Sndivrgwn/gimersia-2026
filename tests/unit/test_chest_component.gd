extends GutTest

## Tes ChestComponent: 24 slot, stacking seperti tas, sisa muat, transfer
## dua arah, dan sinyal.

const ChestScript = preload("res://src/components/storage/chest_component.gd")
const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")

var chest
var player: Player
var inventory: InventoryComponentScript


func before_each() -> void:
	chest = ChestScript.new()
	add_child_autofree(chest)

	player = PLAYER_SCENE.instantiate() as Player
	player.add_to_group(&"player")
	add_child_autofree(player)
	(player.get_node("NeedsComponent") as NeedsComponent).set_process(false)

	inventory = InventoryComponentScript.new()
	inventory.name = "InventoryComponent"
	inventory.setup(player)
	player.add_child(inventory)
	inventory.set_process(false)


func after_each() -> void:
	for child in get_tree().root.get_children():
		if child is ItemPickup:
			child.queue_free()


func test_has_24_slots() -> void:
	assert_eq(chest.get_capacity(), 24)
	assert_eq(chest.get_slots().size(), 24)
	assert_true(chest.is_empty())
	assert_false(chest.is_full())


func test_stacks_top_up_then_use_leftmost_empty_slot() -> void:
	chest.add_item(ItemCatalog.WOOD, 15)
	assert_eq(chest.get_slot_count(0), 15)

	chest.add_item(ItemCatalog.WOOD, 10)

	assert_eq(chest.get_slot_count(0), 20, "stack pertama penuh dulu")
	assert_eq(chest.get_slot_count(1), 5)
	assert_eq(chest.count_of(ItemCatalog.WOOD), 25)


func test_leftover_when_all_slots_full() -> void:
	for index in chest.get_capacity():
		chest.add_item(ItemCatalog.STONE, 20)
	assert_true(chest.is_full())

	var leftover: int = chest.add_item(ItemCatalog.WOOD, 5)

	assert_eq(leftover, 5)
	assert_eq(chest.count_of(ItemCatalog.WOOD), 0)


func test_remove_item_is_atomic() -> void:
	chest.add_item(ItemCatalog.WOOD, 10)

	assert_false(chest.remove_item(ItemCatalog.WOOD, 11), "tidak cukup -> tidak ada yang dihapus")
	assert_eq(chest.count_of(ItemCatalog.WOOD), 10)

	assert_true(chest.remove_item(ItemCatalog.WOOD, 4))
	assert_eq(chest.count_of(ItemCatalog.WOOD), 6)


func test_move_to_bag_moves_whole_stack() -> void:
	chest.add_item(ItemCatalog.WOOD, 8)

	assert_true(chest.move_to_bag(0, inventory))

	assert_eq(chest.count_of(ItemCatalog.WOOD), 0)
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 8)


func test_move_to_bag_keeps_leftover_when_bag_is_full() -> void:
	for index in inventory.get_capacity():
		inventory.add_item(ItemCatalog.STONE, 20)
	chest.add_item(ItemCatalog.WOOD, 5)

	assert_false(chest.move_to_bag(0, inventory), "tas penuh")
	assert_eq(chest.count_of(ItemCatalog.WOOD), 5, "tetap di peti")


func test_move_from_bag_moves_whole_stack() -> void:
	inventory.add_item(ItemCatalog.STONE, 7)

	assert_true(chest.move_from_bag(inventory, 0))

	assert_eq(inventory.count_of(ItemCatalog.STONE), 0)
	assert_eq(chest.count_of(ItemCatalog.STONE), 7)


func test_move_from_bag_keeps_leftover_in_bag_when_chest_is_full() -> void:
	for index in chest.get_capacity():
		chest.add_item(ItemCatalog.STONE, 20)
	inventory.add_item(ItemCatalog.WOOD, 5)

	assert_false(chest.move_from_bag(inventory, 0))
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 5, "tetap di tas")
	assert_eq(chest.count_of(ItemCatalog.WOOD), 0)


func test_signals_fire_once_per_action() -> void:
	watch_signals(chest)

	chest.add_item(ItemCatalog.WOOD, 3)

	assert_signal_emit_count(chest, "slot_changed", 1)
	assert_signal_emit_count(chest, "contents_changed", 1)


func test_clear_empties_every_slot() -> void:
	chest.add_item(ItemCatalog.WOOD, 3)
	chest.add_item(ItemCatalog.STONE, 4)

	chest.clear()

	assert_true(chest.is_empty())
	assert_eq(chest.count_of(ItemCatalog.STONE), 0)

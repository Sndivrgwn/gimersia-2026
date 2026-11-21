extends GutTest

## Mission 7 / Phase 4: ChestPanel.

class StubBag extends Node:
	var locked := false
	var open := false
	func set_locked(value: bool) -> void: locked = value
	func is_locked() -> bool: return locked
	func toggle_panel() -> void:
		if not locked:
			open = not open
	func is_open() -> bool: return open

class StubChest extends Node2D:
	signal interaction_requested(interactor)
	signal destroyed
	var component: ChestComponent
	func get_component() -> ChestComponent:
		return component


func _make_chest() -> StubChest:
	var chest := StubChest.new()
	var component := ChestComponent.new()
	add_child_autofree(component)
	chest.component = component
	add_child_autofree(chest)
	return chest


func _make_player() -> Node2D:
	var player := Node2D.new()
	add_child_autofree(player)
	var inv := InventoryComponent.new()
	inv.name = "InventoryComponent"
	player.add_child(inv)
	return player


func _make_panel(chest: StubChest, player: Node2D) -> ChestPanel:
	var panel := ChestPanel.new()
	add_child_autofree(panel)
	panel.setup(chest, player.get_node("InventoryComponent") as InventoryComponent, player)
	return panel


func test_open_and_close_with_bag_lock() -> void:
	var chest := _make_chest()
	var player := _make_player()
	var bag := StubBag.new()
	add_child_autofree(bag)
	var panel := _make_panel(chest, player)
	panel.bag_panel = bag
	watch_signals(panel)

	assert_true(panel.open_for(chest, panel.inventory, player))
	assert_true(panel.is_open())
	assert_true(bag.is_locked(), "tas dikunci saat peti terbuka")
	bag.toggle_panel()
	assert_false(bag.is_open(), "toggle tas diabaikan")

	panel.close()
	assert_false(panel.is_open())
	assert_false(bag.is_locked())
	assert_signal_emitted(panel, "closed")


func test_move_chest_to_bag_partial_fit() -> void:
	var chest := _make_chest()
	var player := _make_player()
	var inv := player.get_node("InventoryComponent") as InventoryComponent
	inv.add_item(ItemCatalog.STONE, 12)
	chest.component.add_item(ItemCatalog.STONE, 15)
	var panel := _make_panel(chest, player)
	panel.open_for(chest, inv, player)

	panel._on_chest_slot(0)
	var moved := inv.count_of(ItemCatalog.STONE)
	assert_gt(moved, 12, "sebagian pindah ke tas")
	assert_eq(moved + chest.component.count_of(ItemCatalog.STONE), 27, "tidak ada item hilang")


func test_move_bag_to_chest() -> void:
	var chest := _make_chest()
	var player := _make_player()
	var inv := player.get_node("InventoryComponent") as InventoryComponent
	inv.add_item(ItemCatalog.STONE, 5)
	var panel := _make_panel(chest, player)
	panel.open_for(chest, inv, player)

	panel._on_bag_slot(0)
	assert_eq(chest.component.count_of(ItemCatalog.STONE), 5)


func test_take_all_with_full_bag() -> void:
	var chest := _make_chest()
	var player := _make_player()
	var inv := player.get_node("InventoryComponent") as InventoryComponent
	for index in inv.get_capacity():
		inv.add_item(ItemCatalog.STONE, 20)
	chest.component.add_item(ItemCatalog.WOOD, 5)
	var panel := _make_panel(chest, player)
	panel.open_for(chest, inv, player)

	panel.take_all()
	assert_eq(chest.component.count_of(ItemCatalog.WOOD), 5, "tas penuh -> tidak ada yang pindah")


func test_auto_close_on_destruction_and_distance() -> void:
	var chest := _make_chest()
	var player := _make_player()
	var panel := _make_panel(chest, player)
	panel.open_for(chest, panel.inventory, player)

	player.global_position = Vector2(500.0, 0.0)
	panel._process(0.016)
	assert_false(panel.is_open(), "menjauh > 120 px menutup panel")

	player.global_position = Vector2.ZERO
	panel.open_for(chest, panel.inventory, player)
	chest.free()
	panel._process(0.016)
	assert_false(panel.is_open(), "peti hancur menutup panel")

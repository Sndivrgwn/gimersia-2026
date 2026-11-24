extends GutTest

## Fase 4A: UX tas — pecah tumpukan (Shift + klik kiri) dan tombol Urutkan.

const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const BAG_PANEL_SCENE: PackedScene = preload("res://src/ui/panels/inventory/bag_panel.tscn")

var player: Player
var inventory: InventoryComponentScript


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


# --- Pecah tumpukan ---------------------------------------------------------

func test_split_moves_half_to_first_empty_slot() -> void:
	inventory.add_item(ItemCatalog.BERRY, 10)

	assert_true(inventory.split_slot(0))
	assert_eq(inventory.get_slot_count(0), 5, "separuh tetap di slot asal")
	assert_eq(inventory.get_slot_count(1), 5, "separuh pindah ke slot kosong pertama")
	assert_same(inventory.get_slot_item(1), ItemCatalog.BERRY)
	assert_eq(inventory.count_of(&"berry"), 10, "tidak ada item yang hilang")


func test_split_odd_count_keeps_larger_half_on_source() -> void:
	inventory.add_item(ItemCatalog.WOOD, 7)

	assert_true(inventory.split_slot(0))
	assert_eq(inventory.get_slot_count(0), 4)
	assert_eq(inventory.get_slot_count(1), 3)


func test_split_rejects_single_item_empty_slot_and_full_bag() -> void:
	assert_false(inventory.split_slot(0), "slot kosong")

	inventory.add_item(ItemCatalog.WOOD, 1)
	assert_false(inventory.split_slot(0), "satu item tidak bisa dipecah")

	inventory.add_item(ItemCatalog.WATERSKIN, 11)
	assert_true(inventory.is_full())
	assert_false(inventory.split_slot(0), "tidak ada slot kosong tujuan")


func test_shift_click_on_bag_slot_splits_stack() -> void:
	inventory.clear()
	inventory.add_item(ItemCatalog.BERRY, 6)

	var panel := BAG_PANEL_SCENE.instantiate()
	panel.inventory = inventory
	add_child_autofree(panel)

	var slot: BagSlot = panel.get_slots()[0]
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.shift_pressed = true
	slot._gui_input(event)

	assert_eq(inventory.get_slot_count(0), 3)
	assert_eq(inventory.get_slot_count(1), 3, "Shift + klik kiri memecah tumpukan")


# --- Urutkan ----------------------------------------------------------------

func test_sort_merges_stacks_and_orders_by_category_then_id() -> void:
	inventory.add_item(ItemCatalog.BERRY, 5)
	inventory.add_item(ItemCatalog.STONE, 2)
	inventory.add_item(ItemCatalog.BERRY, 3)
	inventory.add_item(ItemCatalog.WOOD, 4)

	assert_true(inventory.sort())
	assert_same(inventory.get_slot_item(0), ItemCatalog.STONE, "RESOURCE dulu, id stone < wood")
	assert_same(inventory.get_slot_item(1), ItemCatalog.WOOD)
	assert_same(inventory.get_slot_item(2), ItemCatalog.BERRY, "CONSUMABLE setelah RESOURCE")
	assert_eq(inventory.get_slot_count(2), 8, "dua stack berry digabung")
	assert_true(inventory.is_slot_empty(3), "slot kosong di belakang")
	assert_eq(inventory.count_of(&"berry"), 8, "tidak ada item hilang")


func test_sort_is_noop_when_already_ordered() -> void:
	inventory.add_item(ItemCatalog.STONE, 2)
	inventory.add_item(ItemCatalog.BERRY, 4)

	assert_false(inventory.sort(), "urutan sudah benar -> tidak ada perubahan")
	assert_same(inventory.get_slot_item(0), ItemCatalog.STONE)
	assert_same(inventory.get_slot_item(1), ItemCatalog.BERRY)


func test_sort_button_in_panel_sorts_inventory() -> void:
	inventory.clear()
	inventory.add_item(ItemCatalog.BERRY, 4)
	inventory.add_item(ItemCatalog.STONE, 2)

	var panel := BAG_PANEL_SCENE.instantiate()
	panel.inventory = inventory
	add_child_autofree(panel)

	var button: Button = panel.get_sort_button()
	assert_not_null(button, "tab Tas punya tombol Urutkan")
	button.pressed.emit()

	assert_same(inventory.get_slot_item(0), ItemCatalog.STONE)
	assert_same(inventory.get_slot_item(1), ItemCatalog.BERRY)

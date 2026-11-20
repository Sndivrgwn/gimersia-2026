extends GutTest

class StubInteractor extends Node:
	var inventory: InventoryComponent

	func get_inventory() -> InventoryComponent:
		return inventory


var _bag: LootBag
var _inventory: InventoryComponent
var _interactor: StubInteractor


func before_each() -> void:
	_inventory = InventoryComponent.new()
	add_child_autofree(_inventory)

	_interactor = StubInteractor.new()
	add_child_autofree(_interactor)
	_interactor.inventory = _inventory

	_bag = preload("res://src/entities/props/loot_bag/loot_bag.tscn").instantiate() as LootBag
	add_child_autofree(_bag)
	var stacks: Array[ItemStack] = [
		ItemStack.new(ItemCatalog.WOOD, 3),
		ItemStack.new(ItemCatalog.STONE, 2),
	]
	_bag.setup(stacks)


func test_prompt_and_total_items() -> void:
	assert_eq(_bag.get_prompt(null), LootBag.PROMPT)
	assert_eq(_bag.get_total_items(), 5)
	assert_eq(_bag.get_hold_time(null), 1.0)
	assert_true(_bag.can_interact(null))


func test_interact_moves_everything_into_the_bag() -> void:
	_bag.interact(_interactor)
	assert_eq(_inventory.count_of(ItemCatalog.WOOD), 3)
	assert_eq(_inventory.count_of(ItemCatalog.STONE), 2)
	assert_eq(_bag.get_total_items(), 0)


func test_full_inventory_keeps_the_leftover() -> void:
	# Isi seluruh 12 slot supaya tidak ada ruang untuk kayu.
	for index in _inventory.get_capacity():
		_inventory.add_item(ItemCatalog.BERRY, 20)
	_bag.interact(_interactor)
	assert_eq(_inventory.count_of(ItemCatalog.WOOD), 0)
	assert_eq(_bag.get_total_items(), 5, "sisa tetap di loot bag")
	assert_true(_bag.can_interact(null))

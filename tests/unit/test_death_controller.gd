extends GutTest

class StubClock extends Node:
	signal day_started(day: int)
	signal rescue_started

	func is_night() -> bool:
		return false

	func get_time_scale() -> float:
		return 1.0

	func get_current_day() -> int:
		return 1

	func get_max_days() -> int:
		return 7


var _player: Player
var _inventory: InventoryComponent
var _needs: NeedsComponent
var _prof: ProficiencyComponent
var _death: DeathController
var _clock: StubClock


func before_each() -> void:
	_player = preload("res://src/entities/player/player.tscn").instantiate() as Player
	add_child_autofree(_player)
	_player.global_position = Vector2(0, 64)

	_inventory = InventoryComponent.new()
	_inventory.name = "InventoryComponent"
	_player.add_child(_inventory)

	_clock = StubClock.new()
	add_child_autofree(_clock)

	# player.tscn sudah punya NeedsComponent; jangan tambah duplikat.
	_needs = _player.get_node("NeedsComponent") as NeedsComponent
	_needs.clock = _clock

	_prof = ProficiencyComponent.new()
	_player.add_child(_prof)
	_prof.clock = _clock

	_death = DeathController.new()
	add_child_autofree(_death)
	_death.setup(_player)


func after_each() -> void:
	_player.queue_free()
	# Loot bag dari tes sebelumnya menempel di root; bersihkan agar hitungan bersih.
	for node in get_tree().get_nodes_in_group(&"loot_bag"):
		node.free()


func test_first_death_spends_a_token_and_drops_loot() -> void:
	_inventory.add_item(ItemCatalog.WOOD, 5)
	_inventory.add_item(ItemCatalog.STONE, 3)
	_player.global_position = Vector2(120, -40)

	_player.stats.get_max_hp()
	_player.stats.set_hp(0.0)

	assert_true(_death.is_dead)
	assert_eq(_death.get_respawns_remaining(), 2)
	assert_eq(_inventory.count_of(ItemCatalog.WOOD), 0, "tas dikosongkan")
	var bag := _death.get_last_loot_bag() as LootBag
	assert_not_null(bag)
	assert_eq(bag.get_total_items(), 8)
	assert_almost_eq(bag.global_position.x, 120.0, 0.01)


func test_player_is_disabled_and_hidden_while_dead() -> void:
	_player.stats.get_max_hp()
	_player.stats.set_hp(0.0)
	assert_eq(_player.process_mode, Node.PROCESS_MODE_DISABLED)
	assert_false(_player.visible)


func test_respawn_restores_position_hp_and_needs() -> void:
	_player.stats.get_max_hp()
	_player.stats.set_hp(0.0)
	_player.global_position = Vector2(900, 900)

	assert_true(_death.respawn())
	assert_false(_death.is_dead)
	assert_almost_eq(_player.global_position.x, 0.0, 0.01)
	assert_almost_eq(_player.global_position.y, 64.0, 0.01)
	assert_almost_eq(_player.stats.current_hp, _player.stats.get_max_hp() * 0.7, 0.01)
	assert_almost_eq(_needs.get_value(NeedsComponent.Need.HUNGER), 60.0, 0.01)
	assert_almost_eq(_needs.get_value(NeedsComponent.Need.THIRST), 60.0, 0.01)
	assert_almost_eq(_needs.get_value(NeedsComponent.Need.FATIGUE), 80.0, 0.01)
	assert_eq(_player.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_true(_player.visible)


func test_fourth_death_is_permanent_game_over() -> void:
	watch_signals(_death)
	_player.stats.get_max_hp()
	for index in 4:
		_player.stats.set_hp(0.0)
		if _death.can_respawn():
			_death.respawn()

	assert_eq(_death.get_respawns_remaining(), -1)
	assert_false(_death.can_respawn())
	assert_signal_emitted(_death, "game_over")
	assert_false(_death.respawn())


func test_two_deaths_leave_two_loot_bags() -> void:
	_inventory.add_item(ItemCatalog.WOOD, 1)
	_player.stats.get_max_hp()
	_player.stats.set_hp(0.0)
	_death.respawn()

	_inventory.add_item(ItemCatalog.STONE, 1)
	_player.stats.set_hp(0.0)

	var bags := 0
	for node in get_tree().get_nodes_in_group(&"loot_bag"):
		if node is LootBag:
			bags += 1
	assert_eq(bags, 2)

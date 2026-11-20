extends GutTest

## Tes CraftingComponent: stasiun, ketersediaan resep, cek/konsumsi bahan atomik,
## faktor waktu craft, aturan equip, pembatalan, overflow, dan sinyal.

const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const CraftingComponentScript = preload("res://src/components/crafting/crafting_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")

const WOODEN_SPEAR: RecipeDefinition = preload("res://src/data/recipes/wooden_spear.tres")
const TORCH: RecipeDefinition = preload("res://src/data/recipes/torch.tres")
const HERBAL_BANDAGE: RecipeDefinition = preload("res://src/data/recipes/herbal_bandage.tres")
const STONE_AXE: RecipeDefinition = preload("res://src/data/recipes/stone_axe.tres")
const STONE_SPEAR: RecipeDefinition = preload("res://src/data/recipes/stone_spear.tres")
const BONE_SPEAR: RecipeDefinition = preload("res://src/data/recipes/bone_spear.tres")
const LEATHER_VEST: RecipeDefinition = preload("res://src/data/recipes/leather_vest.tres")
const COOKED_MEAT: RecipeDefinition = preload("res://src/data/recipes/cooked_meat.tres")


class StubStation extends Node2D:
	var station_type: int = RecipeDefinition.Station.WORKBENCH
	var active: bool = true

	func is_station_active() -> bool:
		return active


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
	crafting.setup(player, inventory, player.stats)
	crafting.input_enabled = false
	player.add_child(crafting)
	crafting.set_process(false)


func after_each() -> void:
	_free_overflow_pickups()


# --- Stasiun ----------------------------------------------------------------

func test_hand_recipes_available_without_station() -> void:
	var available: Array[RecipeDefinition] = crafting.get_available_recipes()
	assert_eq(available.size(), 3, "hanya 3 resep HAND")
	for recipe in available:
		assert_eq(recipe.station, RecipeDefinition.Station.HAND)
	assert_eq(crafting.get_locked_recipes().size(), 10)
	assert_true(crafting.get_stations_in_range().is_empty())


func test_workbench_in_range_unlocks_workbench_recipes() -> void:
	var bench := _station(RecipeDefinition.Station.WORKBENCH, Vector2(64, 0))
	assert_eq(crafting.get_stations_in_range().size(), 1)
	var available: Array[RecipeDefinition] = crafting.get_available_recipes()
	assert_eq(available.size(), 10, "3 HAND + 7 WORKBENCH")
	assert_true(available.has(STONE_AXE))
	assert_false(available.has(COOKED_MEAT), "CAMPFIRE tetap terkunci")
	assert_eq(crafting.get_block_reason(COOKED_MEAT), "Butuh Api Unggun menyala")

	bench.queue_free()


func test_station_out_of_range_is_not_usable() -> void:
	_station(RecipeDefinition.Station.WORKBENCH, Vector2(300, 0))
	assert_true(crafting.get_stations_in_range().is_empty())
	assert_eq(crafting.get_block_reason(STONE_AXE), "Butuh Workbench")


func test_inactive_station_is_not_usable() -> void:
	_station(RecipeDefinition.Station.CAMPFIRE, Vector2(40, 0), false)
	assert_eq(crafting.get_block_reason(COOKED_MEAT), "Butuh Api Unggun menyala")


# --- Bahan ------------------------------------------------------------------

func test_missing_ingredients_block_with_reason() -> void:
	inventory.add_item(ItemCatalog.WOOD, 3)
	inventory.add_item(ItemCatalog.FIBER, 1)

	assert_false(crafting.can_craft(WOODEN_SPEAR))
	assert_eq(crafting.get_block_reason(WOODEN_SPEAR), "Bahan kurang")
	assert_false(crafting.start_craft(WOODEN_SPEAR))
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 3, "bahan tidak dikonsumsi saat gagal mulai")


func test_ingredients_are_consumed_at_completion_not_start() -> void:
	inventory.add_item(ItemCatalog.WOOD, 3)
	inventory.add_item(ItemCatalog.FIBER, 2)
	assert_true(crafting.start_craft(WOODEN_SPEAR))
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 3, "belum dikonsumsi saat mulai")

	crafting.tick(2.0)

	assert_eq(inventory.count_of(ItemCatalog.WOOD), 0)
	assert_eq(inventory.count_of(ItemCatalog.FIBER), 0)


func test_craft_time_scales_with_craft_time_factor() -> void:
	inventory.add_item(ItemCatalog.WOOD, 3)
	inventory.add_item(ItemCatalog.FIBER, 2)
	player.stats.add_modifier(&"test_craft", &"craft_time", StatModifier.Kind.PERCENT, 0.5)

	crafting.start_craft(WOODEN_SPEAR)
	crafting.tick(2.9)
	assert_true(crafting.is_crafting(), "2.0 s x 1.5 = 3.0 s belum selesai di 2.9 s")

	crafting.tick(0.2)
	assert_false(crafting.is_crafting())
	assert_not_null(inventory.get_equipped(ItemDefinition.EquipmentSlot.WEAPON))


func test_weapon_slot_ingredient_upgrades_spear() -> void:
	inventory.equip(ItemCatalog.WOODEN_SPEAR)
	inventory.add_item(ItemCatalog.STONE, 2)
	inventory.add_item(ItemCatalog.FIBER, 2)
	_station(RecipeDefinition.Station.WORKBENCH, Vector2(32, 0))

	assert_true(crafting.can_craft(STONE_SPEAR), "bahan senjata diambil dari slot WEAPON")
	assert_eq(crafting.count_available(ItemCatalog.WOODEN_SPEAR), 1)

	crafting.start_craft(STONE_SPEAR)
	crafting.tick(3.0)

	var weapon := inventory.get_equipped(ItemDefinition.EquipmentSlot.WEAPON)
	assert_not_null(weapon)
	assert_eq(weapon.id, &"stone_spear")
	assert_eq(inventory.count_of(ItemCatalog.STONE), 0)
	assert_eq(inventory.count_of(ItemCatalog.FIBER), 0)


func test_weapon_ingredient_must_match_equipped_weapon() -> void:
	# Stone Spear (28) bukan senjata yang lebih baik dari Bone Spear (30), tetapi
	# bahannya Wooden Spear, jadi satu-satunya alasan adalah bahan yang kurang.
	inventory.equip(ItemCatalog.STONE_SPEAR)
	inventory.add_item(ItemCatalog.BONE, 2)
	inventory.add_item(ItemCatalog.FIBER, 2)
	_station(RecipeDefinition.Station.WORKBENCH, Vector2(32, 0))

	assert_false(crafting.can_craft(BONE_SPEAR))
	assert_eq(crafting.get_block_reason(BONE_SPEAR), "Bahan kurang")


# --- Aturan equip -----------------------------------------------------------

func test_better_weapon_blocks_crafting() -> void:
	# Bone Spear (30 dmg) lebih baik dari Wooden Spear (18 dmg).
	inventory.equip(ItemCatalog.BONE_SPEAR)
	inventory.add_item(ItemCatalog.WOOD, 3)
	inventory.add_item(ItemCatalog.FIBER, 2)

	assert_eq(crafting.get_block_reason(WOODEN_SPEAR), "Sudah punya senjata yang lebih baik")
	assert_false(crafting.can_craft(WOODEN_SPEAR))


func test_equipment_blockers_are_checked_before_missing_ingredients() -> void:
	# Tas kosong: tanpa urutan yang benar, semuanya akan jadi "Bahan kurang".
	assert_true(inventory.is_full() == false)

	inventory.equip(ItemCatalog.BONE_SPEAR)
	assert_eq(crafting.get_block_reason(WOODEN_SPEAR), "Sudah punya senjata yang lebih baik")

	inventory.equip(ItemCatalog.STONE_AXE)
	_station(RecipeDefinition.Station.WORKBENCH, Vector2(32, 0))
	assert_eq(crafting.get_block_reason(STONE_AXE), "Alat sudah dimiliki")

	inventory.equip(ItemCatalog.LEATHER_VEST)
	assert_eq(crafting.get_block_reason(LEATHER_VEST), "Zirah sudah terpasang")

	assert_eq(inventory.count_of(ItemCatalog.WOOD), 0, "bahan memang tidak ada")


func test_missing_ingredients_reported_when_equipment_is_fine() -> void:
	_station(RecipeDefinition.Station.WORKBENCH, Vector2(32, 0))

	assert_true(crafting.get_block_reason(STONE_AXE).is_empty() == false)
	assert_eq(crafting.get_block_reason(STONE_AXE), "Bahan kurang")


func test_station_block_still_wins_over_equipment_and_ingredients() -> void:
	inventory.equip(ItemCatalog.BONE_SPEAR)

	assert_eq(crafting.get_block_reason(COOKED_MEAT), "Butuh Api Unggun menyala")
	assert_eq(crafting.get_block_reason(STONE_SPEAR), "Butuh Workbench")


func test_owned_tool_blocks_crafting() -> void:
	inventory.equip(ItemCatalog.STONE_AXE)
	inventory.add_item(ItemCatalog.WOOD, 2)
	inventory.add_item(ItemCatalog.STONE, 2)
	inventory.add_item(ItemCatalog.FIBER, 1)
	_station(RecipeDefinition.Station.WORKBENCH, Vector2(32, 0))

	assert_eq(crafting.get_block_reason(STONE_AXE), "Alat sudah dimiliki")


func test_equipped_armor_blocks_crafting() -> void:
	inventory.equip(ItemCatalog.LEATHER_VEST)
	inventory.add_item(ItemCatalog.HIDE, 3)
	inventory.add_item(ItemCatalog.FIBER, 3)
	_station(RecipeDefinition.Station.WORKBENCH, Vector2(32, 0))

	assert_eq(crafting.get_block_reason(LEATHER_VEST), "Zirah sudah terpasang")


func test_tool_result_is_equipped_after_craft() -> void:
	inventory.add_item(ItemCatalog.WOOD, 2)
	inventory.add_item(ItemCatalog.STONE, 2)
	inventory.add_item(ItemCatalog.FIBER, 1)
	_station(RecipeDefinition.Station.WORKBENCH, Vector2(32, 0))

	crafting.start_craft(STONE_AXE)
	crafting.tick(2.5)

	assert_true(inventory.has_tool(&"stone_axe"))


# --- Pembatalan -------------------------------------------------------------

func test_movement_cancels_craft_without_consuming() -> void:
	inventory.add_item(ItemCatalog.WOOD, 3)
	inventory.add_item(ItemCatalog.FIBER, 2)
	crafting.input_enabled = true
	watch_signals(crafting)

	crafting.start_craft(WOODEN_SPEAR)
	crafting.tick(0.5)
	Input.action_press(&"move_left")
	crafting.tick(0.1)
	Input.action_release(&"move_left")

	assert_false(crafting.is_crafting())
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 3, "bahan tidak hilang")
	crafting.set_process(false)
	var params: Array = get_signal_parameters(crafting, "craft_cancelled", 0)
	assert_eq(params[1], "Bergerak")


func test_damage_cancels_craft() -> void:
	inventory.add_item(ItemCatalog.WOOD, 3)
	inventory.add_item(ItemCatalog.FIBER, 2)
	watch_signals(crafting)

	crafting.start_craft(WOODEN_SPEAR)
	player.stats.set_hp(player.stats.current_hp - 10.0)
	crafting.tick(0.1)

	assert_false(crafting.is_crafting())
	var params: Array = get_signal_parameters(crafting, "craft_cancelled", 0)
	assert_eq(params[1], "Terkena serangan")


func test_station_loss_cancels_craft() -> void:
	inventory.add_item(ItemCatalog.WOOD, 2)
	inventory.add_item(ItemCatalog.STONE, 2)
	inventory.add_item(ItemCatalog.FIBER, 1)
	var bench := _station(RecipeDefinition.Station.WORKBENCH, Vector2(32, 0))
	watch_signals(crafting)

	crafting.start_craft(STONE_AXE)
	bench.active = false
	crafting.tick(0.1)

	assert_false(crafting.is_crafting())
	var params: Array = get_signal_parameters(crafting, "craft_cancelled", 0)
	assert_eq(params[1], "Stasiun hilang")
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 2)


func test_invalid_recipe_cannot_start() -> void:
	assert_false(crafting.can_craft(null))
	assert_false(crafting.start_craft(null))
	assert_eq(crafting.get_block_reason(null), "Resep tidak dikenal")


# --- Hasil / sinyal ---------------------------------------------------------

func test_craft_emits_started_progress_completed_and_crafted() -> void:
	inventory.add_item(ItemCatalog.WOOD, 3)
	inventory.add_item(ItemCatalog.FIBER, 2)
	watch_signals(crafting)
	watch_signals(inventory)

	crafting.start_craft(WOODEN_SPEAR)
	crafting.tick(1.0)
	crafting.tick(1.0)

	assert_signal_emitted(crafting, "craft_started")
	assert_signal_emitted(crafting, "craft_progress")
	assert_signal_emitted(crafting, "craft_completed")
	assert_signal_emitted(crafting, "crafted")
	var params: Array = get_signal_parameters(crafting, "crafted", 0)
	assert_eq(params[0], WOODEN_SPEAR)
	assert_eq(params[1], 1)


func test_overflow_result_drops_a_pickup() -> void:
	inventory.add_item(ItemCatalog.WOOD, 20)
	inventory.add_item(ItemCatalog.FIBER, 20)
	for index in range(2, inventory.get_capacity()):
		inventory.add_item(ItemCatalog.STONE, 20)
	assert_true(inventory.is_full())

	var before := _pickup_count()
	crafting.start_craft(TORCH)
	crafting.tick(1.5)

	assert_eq(inventory.count_of(ItemCatalog.TORCH), 0, "tas penuh")
	assert_eq(_pickup_count(), before + 1, "hasil meluber jadi ItemPickup")


# --- Helper -----------------------------------------------------------------

func _station(station: int, offset: Vector2, active: bool = true) -> StubStation:
	var node := StubStation.new()
	node.station_type = station
	node.active = active
	node.global_position = player.global_position + offset
	node.add_to_group(&"crafting_station")
	add_child_autofree(node)
	return node


func _pickup_count() -> int:
	var count := 0
	for child in get_tree().root.get_children():
		if child is ItemPickup:
			count += 1
	return count


func _free_overflow_pickups() -> void:
	for child in get_tree().root.get_children():
		if child is ItemPickup:
			child.queue_free()

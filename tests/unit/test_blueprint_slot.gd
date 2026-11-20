extends GutTest

## Tes BlueprintSlot: prompt, biaya, pembangunan, konsumsi atomik, dan
## pembangunan ulang setelah struktur hancur.

const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const InteractorScript = preload("res://src/components/interaction/interactor_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const SLOT_SCENE: PackedScene = preload("res://src/entities/camp/blueprint_slot.tscn")
const CAMPFIRE_DEF: StructureDefinition = preload("res://src/data/camp/campfire.tres")
const WORKBENCH_DEF: StructureDefinition = preload("res://src/data/camp/workbench.tres")

var player: Player
var inventory: InventoryComponentScript
var interactor
var slot: BlueprintSlot


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

	interactor = InteractorScript.new()
	player.add_child(interactor)
	interactor.set_process(false)

	slot = SLOT_SCENE.instantiate() as BlueprintSlot
	slot.definition = CAMPFIRE_DEF
	add_child_autofree(slot)


func after_each() -> void:
	_free_overflow_pickups()
	# Struktur hasil blueprint menjadi anak node tes, bukan slot; bersihkan supaya
	# GUT tidak melaporkan unfreed children.
	for child in get_children():
		if child is CampStructure:
			child.free()


# --- Prompt / biaya ---------------------------------------------------------

func test_prompt_lists_structure_and_cost() -> void:
	assert_eq(slot.get_prompt(interactor), "Bangun Api Unggun (4 Kayu, 3 Batu, 2 Serat)")


func test_hold_time_uses_craft_time_factor() -> void:
	assert_almost_eq(slot.get_hold_time(interactor), 2.5, 0.001)
	player.stats.add_modifier(&"test_build", &"craft_time", StatModifier.Kind.PERCENT, 0.5)
	assert_almost_eq(slot.get_hold_time(interactor), 3.75, 0.001, "2.5 x 1.5")


func test_missing_cost_blocks_with_reason() -> void:
	inventory.add_item(ItemCatalog.WOOD, 4)
	inventory.add_item(ItemCatalog.STONE, 3)

	assert_false(slot.can_interact(interactor))
	assert_eq(slot.get_block_reason(interactor), "Bahan kurang")
	assert_eq(slot.get_hold_time(interactor), 2.5)


func test_interact_without_cost_builds_nothing() -> void:
	inventory.add_item(ItemCatalog.WOOD, 4)

	slot.interact(interactor)

	assert_false(slot.is_built())
	assert_null(slot.get_structure())
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 4, "bahan tidak dikonsumsi")


# --- Pembangunan ------------------------------------------------------------

func test_build_consumes_cost_and_spawns_structure() -> void:
	_give_cost()
	watch_signals(slot)

	assert_true(slot.can_interact(interactor))
	assert_eq(slot.get_block_reason(interactor), "")

	slot.interact(interactor)

	assert_signal_emitted(slot, "built")
	assert_true(slot.is_built())
	var structure := slot.get_structure()
	assert_not_null(structure)
	if structure != null:
		assert_true(structure is Campfire)
		assert_eq(structure.global_position, slot.global_position)
		assert_same(structure.get_definition(), CAMPFIRE_DEF)
		assert_eq(structure.get_current_hp(), 250.0)
	assert_false(slot.get_placeholder().visible, "placeholder disembunyikan")
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 0)
	assert_eq(inventory.count_of(ItemCatalog.STONE), 0)
	assert_eq(inventory.count_of(ItemCatalog.FIBER), 0)
	assert_eq(slot.get_block_reason(interactor), "Sudah dibangun")


func test_destroyed_structure_reopens_the_slot() -> void:
	_give_cost()
	slot.interact(interactor)
	var structure := slot.get_structure()
	assert_not_null(structure)

	structure.take_damage(1000.0, null)

	assert_null(slot.get_structure(), "slot bisa dibangun lagi")
	assert_true(slot.get_placeholder().visible)

	_give_cost()
	slot.interact(interactor)
	assert_not_null(slot.get_structure())
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 0, "biaya dibayar lagi")


func test_workbench_blueprint_produces_active_station() -> void:
	slot.definition = WORKBENCH_DEF
	for amount in WORKBENCH_DEF.build_cost:
		inventory.add_item(amount.item, amount.count)

	slot.interact(interactor)

	var bench := slot.get_structure() as Workbench
	assert_not_null(bench, "workbench terpasang")
	if bench == null:
		return
	assert_true(bench.is_in_group(&"crafting_station"))
	assert_eq(bench.station_type, RecipeDefinition.Station.WORKBENCH)
	assert_true(bench.is_station_active(), "workbench selalu aktif")
	assert_eq(bench.get_current_hp(), 180.0)


func test_slot_without_definition_is_inert() -> void:
	slot.definition = null
	assert_eq(slot.get_prompt(interactor), "")
	assert_eq(slot.get_hold_time(interactor), 0.0)
	assert_eq(slot.get_block_reason(interactor), "")
	slot.interact(interactor)
	assert_false(slot.is_built())


# --- Helper -----------------------------------------------------------------

func _give_cost() -> void:
	for amount in CAMPFIRE_DEF.build_cost:
		inventory.add_item(amount.item, amount.count)


func _free_overflow_pickups() -> void:
	for child in get_tree().root.get_children():
		if child is ItemPickup:
			child.queue_free()

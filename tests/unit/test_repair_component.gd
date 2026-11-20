extends GutTest

## Tes RepairComponent: biaya/HP repair tiap struktur, alasan blokir, progres,
## reset saat lepas/jauh, dan sinyal.

const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")

const CAMPFIRE_DEF: StructureDefinition = preload("res://src/data/camp/campfire.tres")
const WORKBENCH_DEF: StructureDefinition = preload("res://src/data/camp/workbench.tres")
const CHEST_DEF: StructureDefinition = preload("res://src/data/camp/chest.tres")
const TENT_DEF: StructureDefinition = preload("res://src/data/camp/tent.tres")

var player: Player
var inventory: InventoryComponentScript
var repair: RepairComponent
var structure: CampStructure


func before_each() -> void:
	InputSetup.ensure_actions()

	player = PLAYER_SCENE.instantiate() as Player
	player.add_to_group(&"player")
	add_child_autofree(player)
	(player.get_node("NeedsComponent") as NeedsComponent).set_process(false)

	inventory = InventoryComponentScript.new()
	inventory.name = "InventoryComponent"
	inventory.setup(player)
	player.add_child(inventory)
	inventory.set_process(false)

	repair = RepairComponent.new()
	repair.name = "RepairComponent"
	player.add_child(repair)
	repair.set_process(false)


func after_each() -> void:
	Input.action_release(InputSetup.REPAIR)
	_free_overflow_pickups()


# --- Biaya / HP per struktur -------------------------------------------------

func test_campfire_repair_cost_and_hp() -> void:
	_structure(CAMPFIRE_DEF, 200.0)
	_give(CAMPFIRE_DEF)

	_press_and_hold(1.0)

	assert_almost_eq(structure.get_current_hp(), 130.0, 0.001, "50 + 80")
	_assert_costs_consumed(CAMPFIRE_DEF)


func test_workbench_repair_cost_and_hp() -> void:
	_structure(WORKBENCH_DEF, 100.0)
	_give(WORKBENCH_DEF)

	_press_and_hold(1.0)

	assert_almost_eq(structure.get_current_hp(), 150.0, 0.001, "80 + 70")
	_assert_costs_consumed(WORKBENCH_DEF)


func test_chest_repair_cost_and_hp() -> void:
	_structure(CHEST_DEF, 100.0)
	_give(CHEST_DEF)

	_press_and_hold(1.0)

	assert_almost_eq(structure.get_current_hp(), 180.0, 0.001, "100 + 80")
	_assert_costs_consumed(CHEST_DEF)


func test_tent_repair_cost_and_hp() -> void:
	_structure(TENT_DEF, 100.0)
	_give(TENT_DEF)

	_press_and_hold(1.0)

	assert_almost_eq(structure.get_current_hp(), 80.0, 0.001, "20 + 60")
	_assert_costs_consumed(TENT_DEF)


# --- Alasan blokir -----------------------------------------------------------

func test_full_structure_is_blocked() -> void:
	_structure(CAMPFIRE_DEF, 0.0)
	_give(CAMPFIRE_DEF)
	watch_signals(repair)

	_press_and_hold(0.3)

	assert_signal_emitted(repair, "repair_blocked")
	var params: Array = get_signal_parameters(repair, "repair_blocked", 0)
	assert_eq(params[1], "Struktur sudah penuh")
	assert_almost_eq(structure.get_current_hp(), 250.0, 0.001)
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 1, "bahan tidak terpakai")


func test_missing_materials_are_blocked() -> void:
	_structure(CAMPFIRE_DEF, 200.0)
	inventory.add_item(ItemCatalog.WOOD, 1)
	watch_signals(repair)

	_press_and_hold(1.0)

	var params: Array = get_signal_parameters(repair, "repair_blocked", 0)
	assert_eq(params[1], "Bahan kurang")
	assert_almost_eq(structure.get_current_hp(), 50.0, 0.001, "tidak berubah")
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 1)


func test_get_block_reason_matches_hud_text() -> void:
	_structure(CAMPFIRE_DEF, 0.0)
	assert_eq(repair.get_block_reason(structure), "Struktur sudah penuh")

	structure.take_damage(50.0, null)
	assert_eq(repair.get_block_reason(structure), "Bahan kurang")

	_give(CAMPFIRE_DEF)
	assert_eq(repair.get_block_reason(structure), "")


# --- Jangkauan / progres -----------------------------------------------------

func test_structure_out_of_range_has_no_target() -> void:
	_structure(CAMPFIRE_DEF, 50.0, Vector2(200, 0))
	_give(CAMPFIRE_DEF)

	_press_and_hold(0.5)

	assert_null(repair.get_target())
	assert_eq(repair.get_progress_ratio(), 0.0)
	assert_almost_eq(structure.get_current_hp(), 200.0, 0.001)


func test_releasing_r_resets_progress() -> void:
	_structure(CAMPFIRE_DEF, 100.0)
	_give(CAMPFIRE_DEF)

	Input.action_press(InputSetup.REPAIR)
	repair.tick(0.4)
	assert_almost_eq(repair.get_progress_ratio(), 0.4, 0.001)

	Input.action_release(InputSetup.REPAIR)
	repair.tick(0.1)

	assert_eq(repair.get_progress_ratio(), 0.0)
	assert_almost_eq(structure.get_current_hp(), 150.0, 0.001, "belum selesai")
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 1, "bahan belum terpakai")


func test_progress_reaches_one_and_emits_signals() -> void:
	_structure(CAMPFIRE_DEF, 100.0)
	_give(CAMPFIRE_DEF)
	watch_signals(repair)

	_press_and_hold(1.0)

	assert_signal_emitted(repair, "target_changed")
	assert_signal_emitted(repair, "progress_changed")
	assert_signal_emitted(repair, "repair_completed")
	var params: Array = get_signal_parameters(repair, "repair_completed", 0)
	assert_eq(params[0], structure)
	assert_eq(repair.get_progress_ratio(), 0.0, "progres direset setelah selesai")


func test_prompt_mentions_structure_and_cost() -> void:
	_structure(CAMPFIRE_DEF, 100.0)
	repair.tick(0.01)

	assert_eq(repair.get_target_prompt(), "Tahan R: Perbaiki Api Unggun (1 Kayu, 1 Batu)")


# --- Helper -----------------------------------------------------------------

func _structure(def: StructureDefinition, damage: float, offset: Vector2 = Vector2(32, 0)) -> void:
	structure = CampStructure.new()
	structure.definition = def
	add_child_autofree(structure)
	structure.global_position = player.global_position + offset
	if damage > 0.0:
		structure.take_damage(damage, null)
	structure.set_process(false)


func _give(def: StructureDefinition) -> void:
	for amount in def.repair_cost:
		inventory.add_item(amount.item, amount.count)


func _press_and_hold(seconds: float) -> void:
	Input.action_press(InputSetup.REPAIR)
	repair.tick(seconds)
	Input.action_release(InputSetup.REPAIR)


func _assert_costs_consumed(def: StructureDefinition) -> void:
	for amount in def.repair_cost:
		assert_eq(inventory.count_of(amount.item), 0, "bahan %s terpakai" % amount.item.id)


func _free_overflow_pickups() -> void:
	for child in get_tree().root.get_children():
		if child is ItemPickup:
			child.queue_free()

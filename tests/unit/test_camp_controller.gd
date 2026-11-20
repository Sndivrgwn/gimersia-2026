extends GutTest

## Tes CampController: registry struktur, sinyal, dan urutan prioritas aggro.

const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const InteractorScript = preload("res://src/components/interaction/interactor_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const SLOT_SCENE: PackedScene = preload("res://src/entities/camp/blueprint_slot.tscn")
const CAMP_SCENE: PackedScene = preload("res://src/levels/camp/camp_controller.tscn")

var player: Player
var inventory: InventoryComponentScript
var interactor
var camp: CampController


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

	camp = CAMP_SCENE.instantiate() as CampController
	add_child_autofree(camp)
	camp.set_process(false)


func after_each() -> void:
	# Struktur hasil blueprint adalah anak CampController, bukan anak node tes;
	# bersihkan supaya GUT tidak melaporkan unfreed children.
	for structure in camp.get_structures():
		if is_instance_valid(structure):
			structure.free()
	for slot in camp.get_slots():
		var leftover := slot.get_structure()
		if leftover != null and is_instance_valid(leftover):
			leftover.free()


func test_scene_has_four_slots_at_spec_positions() -> void:
	var slots := camp.get_slots()
	assert_eq(slots.size(), 4)

	var expected := {
		&"campfire": Vector2(0, 0),
		&"workbench": Vector2(-96, -32),
		&"chest": Vector2(96, -32),
		&"tent": Vector2(0, -110),
	}
	for slot in slots:
		assert_not_null(slot.definition)
		if slot.definition == null:
			continue
		assert_eq(slot.position, expected.get(slot.definition.id, Vector2.ZERO), "%s posisi" % slot.definition.id)


func test_registry_tracks_built_structures() -> void:
	_give_all()
	watch_signals(camp)

	var slot := _slot_for(&"campfire")
	slot.interact(interactor)

	assert_true(camp.has_built(&"campfire"))
	var structure := camp.get_structure(&"campfire")
	assert_not_null(structure)
	if structure != null:
		assert_eq(structure.get_id(), &"campfire")
	assert_eq(camp.get_structures().size(), 1)
	assert_signal_emitted(camp, "structure_built")
	var params: Array = get_signal_parameters(camp, "structure_built", 0)
	assert_eq(params[0], &"campfire")


func test_destroyed_structure_leaves_the_registry() -> void:
	_give_all()
	var slot := _slot_for(&"campfire")
	slot.interact(interactor)
	var structure := camp.get_structure(&"campfire")
	watch_signals(camp)

	structure.take_damage(1000.0, null)

	assert_false(camp.has_built(&"campfire"))
	assert_eq(camp.get_structures().size(), 0)
	assert_signal_emitted(camp, "structure_destroyed")
	var params: Array = get_signal_parameters(camp, "structure_destroyed", 0)
	assert_eq(params[0], &"campfire")
	assert_true(slot.is_built() == false, "slot bisa dibangun lagi")


func test_structures_are_sorted_by_aggro_priority() -> void:
	_give_all()
	_slot_for(&"tent").interact(interactor)
	_slot_for(&"workbench").interact(interactor)
	_slot_for(&"campfire").interact(interactor)

	var ordered := camp.get_structures_by_priority()
	assert_eq(ordered.size(), 3)
	var ids: Array[StringName] = []
	for structure in ordered:
		ids.append(structure.get_id())
	assert_eq(ids, [&"campfire", &"workbench", &"tent"], "0 -> 1 -> 2")


func test_unknown_id_returns_null() -> void:
	assert_null(camp.get_structure(&"nope"))
	assert_false(camp.has_built(&"nope"))


# --- Helper -----------------------------------------------------------------

func _slot_for(id: StringName) -> BlueprintSlot:
	for slot in camp.get_slots():
		if slot.definition != null and slot.definition.id == id:
			return slot
	return null


func _give_all() -> void:
	inventory.add_item(ItemCatalog.WOOD, 15)
	inventory.add_item(ItemCatalog.STONE, 5)
	inventory.add_item(ItemCatalog.FIBER, 11)
	inventory.add_item(ItemCatalog.BAMBOO, 2)

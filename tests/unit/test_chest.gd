extends GutTest

## Tes Peti: prompt, komponen 24 slot, dan isi yang jatuh saat hancur.

const CHEST_SCENE: PackedScene = preload("res://src/entities/camp/chest/chest.tscn")
const CHEST_DEF: StructureDefinition = preload("res://src/data/camp/chest.tres")

var chest: Chest


func before_each() -> void:
	chest = CHEST_SCENE.instantiate() as Chest
	chest.definition = CHEST_DEF
	add_child_autofree(chest)
	chest.set_process(false)


func after_each() -> void:
	for child in get_children():
		if child is ItemPickup:
			child.free()


func test_is_a_destructible_camp_structure() -> void:
	assert_true(chest.is_in_group(&"camp_structure"))
	assert_eq(chest.get_max_hp(), 200.0)
	assert_eq(chest.get_id(), &"chest")


func test_has_a_24_slot_component() -> void:
	var component := chest.get_component()
	assert_not_null(component)
	assert_eq(component.get_capacity(), 24)


func test_prompt_is_chest_24_slot() -> void:
	assert_eq(chest.get_prompt(null), "Peti (24 slot)")

	var interact := chest.get_node_or_null("Interact") as Interactable
	assert_not_null(interact, "anak Interactable ada")
	if interact != null:
		assert_eq(interact.get_prompt(null), "Peti (24 slot)")
		assert_true(interact.can_interact(null))


func test_interaction_emits_request_for_future_panel() -> void:
	watch_signals(chest)
	chest.on_interacted(null)
	assert_signal_emitted(chest, "interaction_requested")


func test_destroyed_chest_drops_every_stack_as_pickup() -> void:
	var component := chest.get_component()
	component.add_item(ItemCatalog.WOOD, 5)
	component.add_item(ItemCatalog.STONE, 3)

	chest.take_damage(1000.0, null)

	var pickups: Array[ItemPickup] = []
	for child in get_children():
		var pickup := child as ItemPickup
		if pickup != null:
			pickups.append(pickup)

	assert_eq(pickups.size(), 2, "satu pickup per stack")
	var dropped := {}
	for pickup in pickups:
		dropped[pickup.item.id] = pickup.count
	assert_eq(dropped.get(&"wood", 0), 5)
	assert_eq(dropped.get(&"stone", 0), 3)
	assert_true(component.is_empty(), "isi peti dikosongkan setelah drop")
	assert_true(chest.is_queued_for_deletion())

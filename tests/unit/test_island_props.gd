extends GutTest

## Tes Phase C bagian props: cockpit_notes item, EmergencySuitcase sekali pakai,
## dan RiverEdge (efek minum + cooldown per pemain).

const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const InteractorScript = preload("res://src/components/interaction/interactor_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const SUITCASE_SCENE: PackedScene = preload("res://src/entities/props/suitcase/emergency_suitcase.tscn")
const RIVER_SCENE: PackedScene = preload("res://src/entities/props/river_edge/river_edge.tscn")

const NOTES := preload("res://src/data/items/cockpit_notes.tres")
const BANDAGE := preload("res://src/data/items/herbal_bandage.tres")
const WATER := preload("res://src/data/items/boiled_water.tres")


func test_cockpit_notes_definition() -> void:
	assert_eq(NOTES.id, &"cockpit_notes")
	assert_eq(NOTES.display_name, "Catatan Kokpit")
	assert_eq(NOTES.category, ItemDefinition.Category.SPECIAL)
	assert_eq(NOTES.max_stack, 1)
	assert_false(NOTES.description.is_empty())


func test_suitcase_grants_each_item_once() -> void:
	var player := _make_player()
	var inventory := player.get_node("InventoryComponent") as InventoryComponent
	var interactor := player.get_node("InteractorComponent")
	var suitcase := SUITCASE_SCENE.instantiate() as EmergencySuitcase
	add_child_autofree(suitcase)
	watch_signals(suitcase)

	assert_true(suitcase.can_interact(interactor))
	assert_eq(suitcase.get_hold_time(interactor), 1.0)
	suitcase.interact(interactor)

	assert_eq(inventory.count_of(BANDAGE.id), 1)
	assert_eq(inventory.count_of(WATER.id), 1)
	assert_eq(inventory.count_of(NOTES.id), 1)
	assert_true(suitcase.is_looted())
	assert_signal_emitted(suitcase, "looted")

	suitcase.interact(interactor)
	assert_eq(inventory.count_of(NOTES.id), 1, "interaksi kedua tidak memberi apa pun")
	assert_false(suitcase.can_interact(interactor))
	assert_eq(suitcase.get_block_reason(interactor), "Sudah dikosongkan")
	assert_signal_emit_count(suitcase, "looted", 1)


func test_river_drink_effects_and_cooldown() -> void:
	var player := _make_player()
	var needs := player.get_node("NeedsComponent") as NeedsComponent
	var interactor := player.get_node("InteractorComponent")
	var river := RIVER_SCENE.instantiate() as RiverEdge
	add_child_autofree(river)

	needs.set_value(NeedsComponent.Need.THIRST, 40.0)
	needs.set_value(NeedsComponent.Need.HUNGER, 50.0)

	assert_true(river.can_interact(interactor))
	assert_eq(river.get_hold_time(interactor), 1.5)
	river.interact(interactor)

	assert_almost_eq(needs.get_value(NeedsComponent.Need.THIRST), 65.0, 0.001, "+25 Thirst")
	assert_almost_eq(needs.get_value(NeedsComponent.Need.HUNGER), 42.0, 0.001, "-8 Hunger")
	assert_false(river.can_interact(interactor))
	assert_string_contains(river.get_block_reason(interactor), "Tunggu")

	river.interact(interactor)
	assert_almost_eq(needs.get_value(NeedsComponent.Need.THIRST), 65.0, 0.001, "cooldown menolak minum")

	river.advance_cooldowns(15.0)
	assert_true(river.can_interact(interactor))
	assert_eq(river.get_block_reason(interactor), "")


func test_river_cooldown_is_per_interactor() -> void:
	var first := _make_player()
	var second := _make_player()
	var first_interactor := first.get_node("InteractorComponent")
	var second_interactor := second.get_node("InteractorComponent")
	var river := RIVER_SCENE.instantiate() as RiverEdge
	add_child_autofree(river)

	river.interact(first_interactor)
	assert_false(river.can_interact(first_interactor))
	assert_true(river.can_interact(second_interactor), "pemain lain tidak kena cooldown")


func test_river_holds_partial_cooldown() -> void:
	var player := _make_player()
	var interactor := player.get_node("InteractorComponent")
	var river := RIVER_SCENE.instantiate() as RiverEdge
	add_child_autofree(river)

	river.interact(interactor)
	river.advance_cooldowns(10.0)
	assert_almost_eq(river.get_cooldown_remaining(interactor), 5.0, 0.001)
	assert_false(river.can_interact(interactor))
	river.advance_cooldowns(5.0)
	assert_almost_eq(river.get_cooldown_remaining(interactor), 0.0, 0.001)


# --- Helper -----------------------------------------------------------------

func _make_player() -> Player:
	var player := PLAYER_SCENE.instantiate() as Player
	player.add_to_group(&"player")
	add_child_autofree(player)

	var needs := player.get_node("NeedsComponent") as NeedsComponent
	needs.set_process(false)

	var inventory := InventoryComponentScript.new()
	inventory.name = "InventoryComponent"
	inventory.setup(player)
	player.add_child(inventory)
	inventory.set_process(false)

	var interactor := InteractorScript.new()
	interactor.name = "InteractorComponent"
	player.add_child(interactor)
	interactor.set_process(false)

	return player

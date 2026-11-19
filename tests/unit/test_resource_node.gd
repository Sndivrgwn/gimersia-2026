extends GutTest

## Tes Phase B: definisi resource, tool gate, waktu gather terskala stats,
## yield ber-seed, fatigue sekali, depleted, respawn, dan sinyal gathered.

const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const InteractorScript = preload("res://src/components/interaction/interactor_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const RESOURCE_SCENE: PackedScene = preload("res://src/entities/props/resource_node/resource_node.tscn")

const DEFS := {
	"twig": preload("res://src/data/gathering/twig.tres"),
	"tree": preload("res://src/data/gathering/tree.tres"),
	"small_rock": preload("res://src/data/gathering/small_rock.tres"),
	"big_rock": preload("res://src/data/gathering/big_rock.tres"),
	"fiber_bush": preload("res://src/data/gathering/fiber_bush.tres"),
	"berry_bush": preload("res://src/data/gathering/berry_bush.tres"),
	"coconut_palm": preload("res://src/data/gathering/coconut_palm.tres"),
	"bamboo_clump": preload("res://src/data/gathering/bamboo_clump.tres"),
}


class StubClock extends Node:
	signal day_started(day: int)


var player: Player
var needs: NeedsComponent
var inventory: InventoryComponentScript
var interactor
var clock: StubClock


func before_each() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	player.add_to_group(&"player")
	add_child_autofree(player)

	needs = player.get_node("NeedsComponent") as NeedsComponent
	needs.set_process(false)

	inventory = InventoryComponentScript.new()
	inventory.name = "InventoryComponent"
	inventory.setup(player)
	player.add_child(inventory)
	inventory.set_process(false)

	interactor = InteractorScript.new()
	player.add_child(interactor)
	interactor.set_process(false)

	clock = StubClock.new()
	add_child_autofree(clock)


func after_each() -> void:
	_free_overflow_pickups()


# --- Definisi ---------------------------------------------------------------

func test_all_definitions_match_spec() -> void:
	var expected := {
		"twig": [&"wood", 1, 1, 0, 1.0, 0],
		"tree": [&"wood", 3, 3, 1, 2.5, 0],
		"small_rock": [&"stone", 1, 1, 0, 1.5, 0],
		"big_rock": [&"stone", 3, 3, 2, 3.0, 0],
		"fiber_bush": [&"fiber", 2, 2, 0, 1.0, 0],
		"berry_bush": [&"berry", 2, 2, 0, 0.8, 0],
		"coconut_palm": [&"coconut", 1, 2, 0, 1.2, 1],
		"bamboo_clump": [&"bamboo", 2, 2, 0, 1.5, 0],
	}

	for key: String in expected:
		var def: ResourceNodeDefinition = DEFS[key]
		var row: Array = expected[key]
		assert_not_null(def, "%s harus ada" % key)
		if def == null:
			continue
		assert_eq(def.id, StringName(key), "%s: id" % key)
		assert_not_null(def.item, "%s: item" % key)
		if def.item != null:
			assert_eq(def.item.id, row[0], "%s: item id" % key)
		assert_eq(def.yield_min, row[1], "%s: yield_min" % key)
		assert_eq(def.yield_max, row[2], "%s: yield_max" % key)
		assert_eq(def.required_tool, row[3], "%s: required_tool" % key)
		assert_almost_eq(def.gather_time, row[4], 0.001, "%s: gather_time" % key)
		assert_almost_eq(def.fatigue_cost, 2.0, 0.001, "%s: fatigue_cost" % key)
		assert_eq(def.respawn_rule, row[5], "%s: respawn_rule" % key)


# --- Tool gate --------------------------------------------------------------

func test_tree_requires_stone_axe() -> void:
	var node := _node(DEFS["tree"])

	assert_false(node.can_interact(interactor))
	assert_eq(node.get_block_reason(interactor), "Butuh Kapak Batu")

	inventory.equip(ItemCatalog.STONE_AXE)
	assert_true(node.can_interact(interactor))
	assert_eq(node.get_block_reason(interactor), "")


func test_big_rock_requires_stone_pickaxe() -> void:
	var node := _node(DEFS["big_rock"])

	assert_false(node.can_interact(interactor))
	assert_eq(node.get_block_reason(interactor), "Butuh Beliung Batu")

	inventory.equip(ItemCatalog.STONE_PICKAXE)
	assert_true(node.can_interact(interactor))


func test_hand_nodes_need_no_tool() -> void:
	var node := _node(DEFS["twig"])
	assert_true(node.can_interact(interactor))
	assert_eq(node.get_block_reason(interactor), "")


# --- Waktu gather -----------------------------------------------------------

func test_gather_time_scales_with_stats_modifier() -> void:
	var node := _node(DEFS["tree"])
	player.stats.add_modifier(&"test_gather", &"gather_time", StatModifier.Kind.PERCENT, 0.5)

	assert_almost_eq(node.get_hold_time(interactor), 3.75, 0.001, "2.5 s x 1.5")

	player.stats.remove_modifier(&"test_gather")
	assert_almost_eq(node.get_hold_time(interactor), 2.5, 0.001)


func test_prompt_mentions_display_name() -> void:
	var node := _node(DEFS["berry_bush"])
	assert_eq(node.get_prompt(interactor), "Tahan E: Semak Beri")


# --- Panen ----------------------------------------------------------------

func test_interact_adds_items_and_spends_fatigue_once() -> void:
	var node := _node(DEFS["fiber_bush"])
	var cap_before := needs.get_fatigue_cap()

	node.interact(interactor)

	assert_eq(inventory.count_of(ItemCatalog.FIBER), 2)
	assert_almost_eq(needs.get_value(NeedsComponent.Need.FATIGUE), 98.0, 0.001)
	assert_almost_eq(needs.get_fatigue_cap(), cap_before, 0.001, "cap Fatigue tidak disentuh")
	assert_true(node.is_depleted())
	assert_false(node.visible)
	assert_false(node.is_in_group(&"interactable"))
	assert_eq(node.get_block_reason(interactor), "Sudah dipanen")


func test_depleted_node_cannot_be_gathered_twice() -> void:
	var node := _node(DEFS["fiber_bush"])
	node.interact(interactor)
	node.interact(interactor)

	assert_eq(inventory.count_of(ItemCatalog.FIBER), 2, "panen kedua diabaikan")


func test_gathered_signal_reports_definition_amount_and_interactor() -> void:
	var node := _node(DEFS["berry_bush"])
	watch_signals(node)

	node.interact(interactor)

	assert_signal_emitted(node, "gathered")
	var params: Array = get_signal_parameters(node, "gathered", 0)
	assert_eq(params[0], DEFS["berry_bush"])
	assert_eq(params[1], 2)
	assert_eq(params[2], interactor)


func test_coconut_yield_is_between_1_and_2_and_seed_is_deterministic() -> void:
	var first := _seeded_node(DEFS["coconut_palm"], 424242)
	first.interact(interactor)
	var first_amount := inventory.count_of(ItemCatalog.COCONUT)
	assert_between(first_amount, 1, 2)

	inventory.remove_item(ItemCatalog.COCONUT, first_amount)
	var second := _seeded_node(DEFS["coconut_palm"], 424242)
	second.interact(interactor)

	assert_eq(inventory.count_of(ItemCatalog.COCONUT), first_amount, "seed sama -> yield sama")


func test_overflow_drops_item_pickup() -> void:
	for index in inventory.get_capacity():
		inventory.add_item(ItemCatalog.STONE, 20)
	assert_true(inventory.is_full())

	var node := _node(DEFS["twig"])
	var before := _pickup_count()
	node.interact(interactor)
	var after := _pickup_count()

	assert_eq(after, before + 1, "sisa tidak muat dijatuhkan sebagai ItemPickup")
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 0)


# --- Respawn ----------------------------------------------------------------

func test_daily_node_respawns_on_next_morning() -> void:
	var node := _node(DEFS["twig"])
	node.interact(interactor)

	clock.day_started.emit(1)
	assert_true(node.is_depleted(), "hari 1 belum respawn")

	clock.day_started.emit(2)
	assert_false(node.is_depleted())
	assert_true(node.visible)
	assert_true(node.is_in_group(&"interactable"))


func test_coconut_respawns_on_odd_mornings_from_day_3() -> void:
	var node := _node(DEFS["coconut_palm"])
	node.interact(interactor)

	clock.day_started.emit(2)
	assert_true(node.is_depleted(), "hari genap tidak respawn")

	clock.day_started.emit(3)
	assert_false(node.is_depleted())

	inventory.remove_item(ItemCatalog.COCONUT, inventory.count_of(ItemCatalog.COCONUT))
	node.interact(interactor)
	assert_true(node.is_depleted())

	clock.day_started.emit(4)
	assert_true(node.is_depleted(), "hari 4 genap")

	clock.day_started.emit(5)
	assert_false(node.is_depleted())


func test_last_respawn_day_removes_node_permanently() -> void:
	var node := RESOURCE_SCENE.instantiate() as ResourceNode
	node.definition = DEFS["twig"]
	node.last_respawn_day = 4
	node.clock = clock
	add_child_autofree(node)

	node.interact(interactor)
	clock.day_started.emit(4)
	assert_false(node.is_depleted(), "hari 4 masih boleh respawn")

	node.interact(interactor)
	clock.day_started.emit(5)
	assert_true(node.is_queued_for_deletion(), "lewat last_respawn_day -> hilang permanen")


# --- Helper -----------------------------------------------------------------

func _node(def: ResourceNodeDefinition) -> ResourceNode:
	var node := RESOURCE_SCENE.instantiate() as ResourceNode
	node.definition = def
	node.clock = clock
	add_child_autofree(node)
	return node


func _seeded_node(def: ResourceNodeDefinition, seed_value: int) -> ResourceNode:
	var node := RESOURCE_SCENE.instantiate() as ResourceNode
	node.definition = def
	node.clock = clock
	node.rng_seed = seed_value
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

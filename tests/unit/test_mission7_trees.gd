extends GutTest

## Mission 7 / Phase 2: pohon kecil, ekonomi kayu, ChopFeedback.

const SMALL_TREE: ResourceNodeDefinition = preload("res://src/data/gathering/small_tree.tres")
const TREE: ResourceNodeDefinition = preload("res://src/data/gathering/tree.tres")
const NODE_SCENE: PackedScene = preload("res://src/entities/props/resource_node/resource_node.tscn")
const LAYOUT: IslandLayoutConfig = preload("res://src/data/configs/island_layout.tres")
const PROF_CONFIG: ProficiencyConfig = preload("res://src/data/configs/proficiency_config.tres")

class DayClock extends Node:
	signal day_started(day: int)
	var day := 1
	func get_current_day() -> int: return day
	func is_night() -> bool: return false
	func get_time_scale() -> float: return 1.0


func _make_player(with_axe: bool = false) -> Node2D:
	var player := Node2D.new()
	player.name = "Player"
	add_child_autofree(player)
	player.add_to_group(&"player")
	var inv := InventoryComponent.new()
	inv.name = "InventoryComponent"
	player.add_child(inv)
	var needs := NeedsComponent.new()
	needs.name = "NeedsComponent"
	player.add_child(needs)
	inv.needs_component = needs
	var stats := StatsComponent.new()
	stats.name = "StatsComponent"
	player.add_child(stats)
	var interactor := InteractorComponent.new()
	interactor.name = "InteractorComponent"
	player.add_child(interactor)
	if with_axe:
		var axe := ItemCatalog.get_by_id(&"stone_axe")
		assert_not_null(axe, "stone_axe ada di katalog")
		inv.add_item(axe, 1)
		assert_true(inv.equip(axe), "kapak terdaftar sebagai tool")
		assert_true(inv.has_tool(&"stone_axe"), "has_tool stone_axe")
	return player


func _make_node(definition: ResourceNodeDefinition) -> ResourceNode:
	var node := NODE_SCENE.instantiate() as ResourceNode
	node.definition = definition
	add_child_autofree(node)
	return node


# --- 2.1 Definition ---------------------------------------------------------

func test_small_tree_definition() -> void:
	assert_eq(SMALL_TREE.id, &"small_tree")
	assert_eq(SMALL_TREE.item.id, &"wood")
	assert_eq(SMALL_TREE.yield_min, 2)
	assert_eq(SMALL_TREE.yield_max, 2)
	assert_eq(SMALL_TREE.required_tool, ResourceNodeDefinition.RequiredTool.NONE)
	assert_almost_eq(SMALL_TREE.gather_time, 4.0, 0.001)
	assert_almost_eq(SMALL_TREE.fatigue_cost, 3.0, 0.001)
	assert_eq(SMALL_TREE.respawn_rule, ResourceNodeDefinition.RespawnRule.DAILY)
	assert_eq(SMALL_TREE.speed_tool, ResourceNodeDefinition.RequiredTool.AXE)
	assert_almost_eq(SMALL_TREE.speed_factor, 0.5, 0.001)
	assert_true(SMALL_TREE.chop_feedback_enabled)
	assert_true(TREE.chop_feedback_enabled, "pohon besar juga punya chop feedback")


func test_hold_time_hand_and_axe() -> void:
	var node := _make_node(SMALL_TREE)
	var bare := _make_player(false).get_node("InteractorComponent") as InteractorComponent
	var armed := _make_player(true).get_node("InteractorComponent") as InteractorComponent
	assert_almost_eq(node.get_hold_time(bare), 4.0, 0.001, "tangan kosong 4.0 s")
	assert_almost_eq(node.get_hold_time(armed), 2.0, 0.001, "dengan kapak 2.0 s")


func test_tree_still_requires_axe() -> void:
	var node := _make_node(TREE)
	var bare := _make_player(false).get_node("InteractorComponent") as InteractorComponent
	var armed := _make_player(true).get_node("InteractorComponent") as InteractorComponent
	assert_false(node.can_interact(bare))
	assert_true(node.can_interact(armed))
	assert_almost_eq(node.get_hold_time(armed), 2.5, 0.001)


func test_hand_chop_yields_two_wood_and_three_fatigue() -> void:
	var node := _make_node(SMALL_TREE)
	var player := _make_player(false)
	var interactor := player.get_node("InteractorComponent") as InteractorComponent
	var inv := player.get_node("InventoryComponent") as InventoryComponent
	var needs := player.get_node("NeedsComponent") as NeedsComponent

	node.interact(interactor)
	assert_eq(inv.count_of(ItemCatalog.WOOD), 2, "hasil 2 kayu")
	assert_almost_eq(needs.get_value(NeedsComponent.Need.FATIGUE), 97.0, 0.01, "biaya 3 fatigue")
	assert_true(node.is_depleted())


func test_small_tree_gives_strength_xp() -> void:
	var node := _make_node(SMALL_TREE)
	var player := _make_player(false)
	var interactor := player.get_node("InteractorComponent") as InteractorComponent
	var prof := ProficiencyComponent.new()
	prof.config = PROF_CONFIG
	prof.player = player
	prof.inventory = player.get_node("InventoryComponent") as InventoryComponent
	prof.needs = player.get_node("NeedsComponent") as NeedsComponent
	prof.stats = player.get_node("StatsComponent") as StatsComponent
	add_child_autofree(prof)
	watch_signals(prof)
	node.gathered.connect(prof._on_gathered)
	node.interact(interactor)
	assert_signal_emitted_with_parameters(prof, "xp_gained", [ProficiencyComponent.Prof.STRENGTH, PROF_CONFIG.strength_tree_xp])


# --- 2.2 Wood economy -------------------------------------------------------

func test_builder_camp_starter_counts() -> void:
	var builder := IslandBuilder.new()
	builder.layout = LAYOUT
	var entries: Array[Dictionary] = builder.plan()
	var resources := 0
	var small := 0
	for entry in entries:
		if not entry.has("definition"):
			continue
		resources += 1
		if entry["definition"] == SMALL_TREE:
			small += 1
			assert_eq(entry["zone"], IslandZones.Zone.CAMP)
			assert_eq(entry["last_respawn_day"], 4)
			var point: Vector2 = entry["position"]
			var radius := point.length()
			assert_true(radius >= LAYOUT.camp_ring_min - 1.0 and radius <= LAYOUT.camp_ring_max + 1.0, "di ring camp")
	assert_eq(resources, 153, "total resource node setelah tambahan pohon kecil")
	assert_eq(small, 6)
	assert_eq(LAYOUT.camp_twig, 10)
	assert_eq(LAYOUT.camp_small_rock, 8)


# --- 2.3 ChopFeedback -------------------------------------------------------

func test_chop_feedback_shake_and_chips() -> void:
	var node := _make_node(SMALL_TREE)
	var player := _make_player(false)
	var interactor := player.get_node("InteractorComponent") as InteractorComponent
	var feedback := node.get_node("ChopFeedback") as ChopFeedback
	assert_not_null(feedback, "pohon kecil punya ChopFeedback")
	watch_signals(feedback)
	feedback.tick(0.01)

	interactor.target_changed.emit(node)
	interactor.progress_changed.emit(0.4)
	feedback.tick(0.1)
	assert_true(feedback.is_chopping())
	feedback.tick(0.3)
	assert_signal_emitted(feedback, "feedback_event")
	var chips := false
	for child in node.get_parent().get_children():
		if child.name == "ChopChips":
			chips = true
	assert_true(chips, "serpihan muncul tiap 0.25 s")


func test_chop_feedback_stops_on_other_target() -> void:
	var node := _make_node(SMALL_TREE)
	var player := _make_player(false)
	var interactor := player.get_node("InteractorComponent") as InteractorComponent
	var feedback := node.get_node("ChopFeedback") as ChopFeedback
	feedback.tick(0.01)
	interactor.target_changed.emit(node)
	interactor.progress_changed.emit(0.5)
	feedback.tick(0.1)
	assert_true(feedback.is_chopping())
	var other := _make_node(TREE)
	interactor.target_changed.emit(other)
	assert_false(feedback.is_chopping(), "berhenti saat target berubah")


func test_chop_feedback_fall_stump_and_regrow() -> void:
	var node := _make_node(SMALL_TREE)
	var player := _make_player(false)
	var interactor := player.get_node("InteractorComponent") as InteractorComponent
	var feedback := node.get_node("ChopFeedback") as ChopFeedback
	var clock := DayClock.new()
	add_child_autofree(clock)
	node.setup_clock(clock)
	watch_signals(feedback)

	node.interact(interactor)
	feedback.tick(0.1)
	assert_true(feedback.is_fallen(), "pohon tumbang setelah habis")
	assert_signal_emitted(feedback, "feedback_event")
	assert_not_null(feedback.get_stump(), "tunggul tertinggal")
	assert_false(node.is_in_group(Interactable.GROUP), "habis tidak lagi interactable")

	clock.day_started.emit(2)
	feedback.tick(0.1)
	assert_false(feedback.is_fallen(), "tumbuh lagi saat respawn")
	assert_true(node.is_in_group(Interactable.GROUP))


func test_small_tree_permanent_after_day_four() -> void:
	var node := _make_node(SMALL_TREE)
	var clock := DayClock.new()
	add_child_autofree(clock)
	node.last_respawn_day = LAYOUT.camp_starters_last_respawn_day
	node.setup_clock(clock)
	node._set_depleted(true)
	clock.day_started.emit(5)
	assert_true(node.is_depleted(), "starter hilang permanen setelah hari 4")


func test_tree_respawns_daily_before_day_four() -> void:
	var node := _make_node(SMALL_TREE)
	var clock := DayClock.new()
	add_child_autofree(clock)
	node.last_respawn_day = LAYOUT.camp_starters_last_respawn_day
	node.setup_clock(clock)
	node._set_depleted(true)
	clock.day_started.emit(2)
	assert_false(node.is_depleted(), "respawn harian")

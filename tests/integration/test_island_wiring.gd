extends GutTest

const IslandHarness = preload("res://tests/integration/island_harness.gd")

var _harness: IslandHarness


func before_each() -> void:
	_harness = IslandHarness.new()
	_harness.setup(self)


func after_each() -> void:
	if _harness != null:
		_harness.teardown()
		_harness = null


func test_s1_wiring_counts_and_links() -> void:
	# 1. Exactly 1 node in group "player"
	var players := get_tree().get_nodes_in_group(&"player")
	assert_eq(players.size(), 1, "Harus ada tepat 1 node di group 'player'")
	assert_eq(players[0], _harness.player, "Pemain di grup harus sama dengan instance Player")

	# 2. 139 resource nodes under IslandBuilder
	var builder := _harness.island.get_node("IslandBuilder") as Node2D
	assert_not_null(builder, "IslandBuilder harus ada")
	var resource_nodes: Array[Node] = []
	for child in builder.get_children():
		if child is ResourceNode:
			resource_nodes.append(child)
	assert_eq(resource_nodes.size(), 139, "IslandBuilder harus men-spawn 139 ResourceNode")

	# 3. 16 night_spawn_point markers
	var markers := get_tree().get_nodes_in_group(&"night_spawn_point")
	assert_eq(markers.size(), 16, "Harus ada 16 penanda night_spawn_point")

	# 4. 9 RiverEdge nodes
	var river_edges_parent := _harness.island.get_node("RiverEdges")
	assert_not_null(river_edges_parent, "RiverEdges parent harus ada")
	var river_count := 0
	for child in river_edges_parent.get_children():
		if child is RiverEdge:
			river_count += 1
	assert_eq(river_count, 9, "Harus ada 9 RiverEdge")

	# 5. 4 BlueprintSlot nodes under CampController
	assert_not_null(_harness.camp, "CampController harus ada")
	var slots := _harness.camp.get_slots()
	assert_eq(slots.size(), 4, "CampController harus memiliki 4 BlueprintSlot")

	# 6. EmergencySuitcase & SignalBeacon
	var suitcase := _harness.island.get_node("Suitcase") as EmergencySuitcase
	assert_not_null(suitcase, "Suitcase harus ada dan bertipe EmergencySuitcase")

	var beacon := _harness.beacon
	assert_not_null(beacon, "Beacon harus ada dan bertipe SignalBeacon")

	# 7. Interactor resolves get_stats/get_inventory/get_needs non-null
	assert_not_null(_harness.interactor.get_stats(), "InteractorComponent harus menyelesaikan StatsComponent")
	assert_not_null(_harness.interactor.get_inventory(), "InteractorComponent harus menyelesaikan InventoryComponent")
	assert_not_null(_harness.interactor.get_needs(), "InteractorComponent harus menyelesaikan NeedsComponent")

	# 8. CraftingComponent and RepairComponent find inventory
	assert_eq(_harness.crafting.inventory, _harness.inventory, "CraftingComponent harus terhubung ke InventoryComponent")
	assert_eq(_harness.repair.inventory, _harness.inventory, "RepairComponent harus terhubung ke InventoryComponent")

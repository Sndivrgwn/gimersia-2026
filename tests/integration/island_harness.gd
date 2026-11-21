extends RefCounted

## Integration test harness for island.tscn.
## Used via preload; no class_name.

const ISLAND_SCENE := preload("res://src/levels/island/island.tscn")
const CLOCK_SCENE := preload("res://src/core/managers/day_night_manager.tscn")

var gut: GutTest
var island: Node2D
var clock: Node
var player: CharacterBody2D
var stats: StatsComponent
var needs: NeedsComponent
var inventory: InventoryComponent
var interactor: InteractorComponent
var crafting: CraftingComponent
var repair: RepairComponent
var combat: CombatComponent
var proficiency: ProficiencyComponent
var camp: CampController
var quota: FaunaQuota
var spawner: NightSpawner
var death: DeathController
var endgame: EndgameController
var beacon: SignalBeacon
var fauna_parent: Node2D
var anchor: CampAnchor

var _created_clock: bool = false


func setup(test: GutTest) -> void:
	gut = test
	clock = test.get_node_or_null("/root/DayNightManager")
	if clock == null:
		clock = CLOCK_SCENE.instantiate()
		clock.name = "DayNightManager"
		test.get_tree().root.add_child(clock)
		_created_clock = true

	if clock.has_method(&"restart"):
		clock.restart()

	island = ISLAND_SCENE.instantiate()
	test.add_child_autofree(island)

	player = island.get_node("Player") as CharacterBody2D
	stats = player.get_node("StatsComponent") as StatsComponent
	needs = player.get_node("NeedsComponent") as NeedsComponent
	inventory = player.get_node("InventoryComponent") as InventoryComponent
	interactor = player.get_node("InteractorComponent") as InteractorComponent
	crafting = player.get_node("CraftingComponent") as CraftingComponent
	repair = player.get_node("RepairComponent") as RepairComponent
	combat = player.get_node("CombatComponent") as CombatComponent
	proficiency = player.get_node("ProficiencyComponent") as ProficiencyComponent

	camp = island.get_node("CampController") as CampController
	quota = island.get_node("FaunaQuota") as FaunaQuota
	spawner = island.get_node("NightSpawner") as NightSpawner
	death = island.get_node("DeathController") as DeathController
	endgame = island.get_node("EndgameController") as EndgameController
	beacon = island.get_node("Beacon") as SignalBeacon
	fauna_parent = island.get_node("Fauna") as Node2D

	# D1: skenario integrasi memakai base yang sudah ditentukan di lokasi crash.
	anchor = island.get_node_or_null("CampAnchor") as CampAnchor
	if anchor != null and not anchor.is_founded():
		anchor.found(Vector2.ZERO)


func advance_time(delta: float) -> void:
	if delta <= 0.0:
		return

	if clock != null and clock.has_method(&"advance"):
		clock.advance(delta)

	if needs != null:
		needs.tick(delta)
	if crafting != null:
		crafting.tick(delta)
	if repair != null:
		repair.tick(delta)
	if combat != null:
		combat.tick(delta)
	if proficiency != null:
		proficiency.tick(delta)
	if spawner != null:
		spawner.tick(delta)
	if quota != null:
		quota.tick(delta)

	if fauna_parent != null:
		for child in fauna_parent.get_children():
			if child.has_method(&"tick"):
				child.tick(delta)

	if camp != null:
		var campfire := camp.get_structure(&"campfire")
		if campfire != null and campfire.has_method(&"tick"):
			campfire.tick(delta)
		var watch := camp.get_node_or_null("NightWatchController")
		if watch != null and watch.has_method(&"tick"):
			watch.tick(delta)


func jump_to_rescue() -> void:
	if clock == null:
		return
	var guard := 0
	while not clock.rescue_triggered and guard < 40:
		clock.skip_time(clock.get_remaining_seconds() + 0.01)
		guard += 1


func teardown() -> void:
	if _created_clock and clock != null and is_instance_valid(clock):
		clock.get_parent().remove_child(clock)
		clock.queue_free()
		clock = null
		_created_clock = false
	elif clock != null and is_instance_valid(clock) and clock.has_method(&"restart"):
		clock.restart()

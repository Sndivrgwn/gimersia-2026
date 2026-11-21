extends GutTest

## Tes Campfire: fuel siang/malam/time_scale, refuel, status menyala/ember,
## radius cahaya, stasiun crafting, dan bonus rest.

const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const InteractorScript = preload("res://src/components/interaction/interactor_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const CAMPFIRE_SCENE: PackedScene = preload("res://src/entities/camp/campfire/campfire.tscn")
const CAMPFIRE_DEF: StructureDefinition = preload("res://src/data/camp/campfire.tres")


class StubClock extends Node:
	var night: bool = false
	var scale_value: float = 1.0

	func is_night() -> bool:
		return night

	func get_time_scale() -> float:
		return scale_value


var clock: StubClock
var player: Player
var needs: NeedsComponent
var inventory: InventoryComponentScript
var interactor
var campfire: Campfire


func before_each() -> void:
	clock = StubClock.new()
	add_child_autofree(clock)

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

	campfire = CAMPFIRE_SCENE.instantiate() as Campfire
	campfire.definition = CAMPFIRE_DEF
	campfire.clock = clock
	add_child_autofree(campfire)
	campfire.set_process(false)


# --- Status awal ------------------------------------------------------------

func test_starts_lit_with_240_seconds() -> void:
	assert_true(campfire.is_lit())
	assert_almost_eq(campfire.get_fuel(), 240.0, 0.001)
	assert_eq(campfire.get_max_fuel(), 600.0)
	assert_almost_eq(campfire.get_light_radius(), 240.0, 0.001)
	assert_almost_eq(campfire.get_dazzle_radius(), 180.0, 0.001)
	assert_almost_eq(campfire.get_refuel_hold_time(), 0.5, 0.001)


func test_is_a_crafting_station_while_lit() -> void:
	assert_true(campfire.is_in_group(&"crafting_station"))
	assert_true(campfire.is_in_group(&"camp_structure"))
	assert_eq(campfire.station_type, RecipeDefinition.Station.CAMPFIRE)
	assert_true(campfire.is_station_active())


# --- Fuel -------------------------------------------------------------------

func test_day_drain_is_025_per_second() -> void:
	campfire.tick(4.0)
	assert_almost_eq(campfire.get_fuel(), 239.0, 0.001)


func test_night_drain_is_1_per_second() -> void:
	clock.night = true
	campfire.tick(4.0)
	assert_almost_eq(campfire.get_fuel(), 236.0, 0.001)


func test_time_scale_zero_freezes_fuel() -> void:
	clock.scale_value = 0.0
	campfire.tick(4.0)
	assert_almost_eq(campfire.get_fuel(), 240.0, 0.001)


func test_time_scale_two_doubles_drain() -> void:
	clock.scale_value = 2.0
	campfire.tick(4.0)
	assert_almost_eq(campfire.get_fuel(), 238.0, 0.001)


func test_fuel_emits_change_signal() -> void:
	watch_signals(campfire)
	campfire.tick(2.0)
	assert_signal_emitted(campfire, "fuel_changed")
	var params: Array = get_signal_parameters(campfire, "fuel_changed", 0)
	assert_almost_eq(params[0], 239.5, 0.001)


func test_out_of_fuel_becomes_ember_and_stops_being_station() -> void:
	campfire.set_fuel(1.0)
	watch_signals(campfire)

	campfire.tick(4.0)

	assert_eq(campfire.get_fuel(), 0.0)
	assert_false(campfire.is_lit())
	assert_signal_emitted(campfire, "fuel_depleted")
	var lit_params: Array = get_signal_parameters(campfire, "lit_changed", 0)
	assert_eq(lit_params[0], false)
	assert_almost_eq(campfire.get_light_radius(), 80.0, 0.001, "ember 80 px")
	assert_false(campfire.is_station_active(), "api padam bukan stasiun")
	assert_eq(campfire.get_light().texture_scale, 160.0 / 256.0, "texture_scale = radius*2/lebar")


func test_set_fuel_is_clamped_to_max() -> void:
	campfire.set_fuel(9999.0)
	assert_eq(campfire.get_fuel(), 600.0)


# --- Refuel -----------------------------------------------------------------

func test_refuel_at_579_is_allowed_and_caps_at_600() -> void:
	campfire.set_fuel(579.0)
	inventory.add_item(ItemCatalog.WOOD, 2)

	assert_eq(campfire.get_refuel_block_reason(interactor), "")
	assert_true(campfire.can_refuel(interactor))
	assert_true(campfire.refuel(interactor))

	assert_eq(campfire.get_fuel(), 600.0)
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 0, "2 kayu terpakai")


func test_refuel_disabled_at_580() -> void:
	campfire.set_fuel(580.0)
	inventory.add_item(ItemCatalog.WOOD, 2)

	assert_eq(campfire.get_refuel_block_reason(interactor), "Bahan bakar penuh")
	assert_false(campfire.can_refuel(interactor))
	assert_false(campfire.refuel(interactor))
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 2, "kayu tidak terpakai")


func test_refuel_disabled_at_600() -> void:
	campfire.set_fuel(600.0)
	inventory.add_item(ItemCatalog.WOOD, 2)

	assert_eq(campfire.get_refuel_block_reason(interactor), "Bahan bakar penuh")
	assert_false(campfire.refuel(interactor))


func test_refuel_needs_two_wood() -> void:
	campfire.set_fuel(100.0)
	inventory.add_item(ItemCatalog.WOOD, 1)

	assert_eq(campfire.get_refuel_block_reason(interactor), "Butuh 2 Kayu")
	assert_false(campfire.can_refuel(interactor))
	assert_false(campfire.refuel(interactor))
	assert_eq(campfire.get_fuel(), 100.0)
	assert_eq(inventory.count_of(ItemCatalog.WOOD), 1)


func test_refuel_adds_180_seconds_and_relights() -> void:
	campfire.set_fuel(10.0)
	inventory.add_item(ItemCatalog.WOOD, 2)
	watch_signals(campfire)

	campfire.refuel(interactor)

	assert_almost_eq(campfire.get_fuel(), 190.0, 0.001)
	assert_true(campfire.is_lit())


func test_refuel_from_empty_does_not_relight_until_ignited() -> void:
	campfire.set_fuel(0.0)
	inventory.add_item(ItemCatalog.WOOD, 2)
	watch_signals(campfire)

	assert_true(campfire.refuel(interactor))
	assert_false(campfire.is_lit(), "D3: refuel tidak menyalakan api yang sudah mati")
	assert_true(campfire.needs_ignition())

	assert_true(campfire.ignite())
	assert_true(campfire.is_lit())
	var params: Array = get_signal_parameters(campfire, "lit_changed", 0)
	assert_eq(params[0], true)


# --- Rest bonus -------------------------------------------------------------

func test_lit_campfire_sets_rest_override_within_120px() -> void:
	player.global_position = campfire.global_position + Vector2(50, 0)

	campfire.tick(0.25)

	assert_almost_eq(needs.get_idle_regen(), 5.0, 0.001)


func test_rest_override_clears_when_leaving_range() -> void:
	player.global_position = campfire.global_position + Vector2(50, 0)
	campfire.tick(0.25)
	assert_almost_eq(needs.get_idle_regen(), 5.0, 0.001)

	player.global_position = campfire.global_position + Vector2(500, 0)
	campfire.tick(0.25)
	assert_almost_eq(needs.get_idle_regen(), 1.0, 0.001, "kembali ke regen dasar")


func test_rest_override_clears_when_fire_goes_out() -> void:
	player.global_position = campfire.global_position + Vector2(50, 0)
	campfire.tick(0.25)
	assert_almost_eq(needs.get_idle_regen(), 5.0, 0.001)

	campfire.set_fuel(0.0)
	campfire.tick(0.25)
	assert_almost_eq(needs.get_idle_regen(), 1.0, 0.001)


func test_rest_check_is_throttled_to_interval() -> void:
	player.global_position = campfire.global_position + Vector2(50, 0)

	campfire.tick(0.1)
	assert_almost_eq(needs.get_idle_regen(), 1.0, 0.001, "belum 0.25 s")

	campfire.tick(0.15)
	assert_almost_eq(needs.get_idle_regen(), 5.0, 0.001)

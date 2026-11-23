extends GutTest

## Minum di area sungai: zona RIVER + tepinya, efek sama dengan RiverEdge,
## dan komponen hanya ikut grup interactable saat pemain di air/tepi.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const InteractorScript = preload("res://src/components/interaction/interactor_component.gd")


func test_water_detection_covers_river_and_banks() -> void:
	var center := IslandZones.zone_center(IslandZones.Zone.RIVER)
	assert_true(RiverDrinkZone.is_river_water(center), "tengah sungai")
	assert_true(
		RiverDrinkZone.is_river_water(Vector2(IslandZones.RIVER_MIN_X - 10.0, 0.0)),
		"tepi barat masih terhitung air"
	)
	assert_true(
		RiverDrinkZone.is_river_water(Vector2(IslandZones.RIVER_MAX_X + 10.0, 0.0)),
		"tepi timur masih terhitung air"
	)
	assert_false(RiverDrinkZone.is_river_water(Vector2(600.0, 0.0)), "hutan bukan air")
	assert_false(
		RiverDrinkZone.is_river_water(Vector2(IslandZones.RIVER_MIN_X, IslandZones.BEACH_EDGE + 40.0)),
		"selatan pantai bukan sungai"
	)


func test_drink_anywhere_in_river_applies_effects_and_cooldown() -> void:
	var player := _make_player()
	var needs := player.get_node("NeedsComponent") as NeedsComponent
	var interactor := player.get_node("InteractorComponent")
	var zone := _make_zone(player)
	player.global_position = IslandZones.zone_center(IslandZones.Zone.RIVER)
	zone.call(&"_update_active")

	needs.set_value(NeedsComponent.Need.THIRST, 40.0)
	needs.set_value(NeedsComponent.Need.HUNGER, 50.0)

	assert_true(zone.is_active())
	assert_true(zone.is_in_group(Interactable.GROUP), "bisa diinteraksikan di air")
	assert_true(zone.can_interact(interactor))

	zone.interact(interactor)
	assert_almost_eq(needs.get_value(NeedsComponent.Need.THIRST), 65.0, 0.001, "+25 Thirst")
	assert_almost_eq(needs.get_value(NeedsComponent.Need.HUNGER), 42.0, 0.001, "-8 Hunger")
	assert_false(zone.can_interact(interactor))
	assert_string_contains(zone.get_block_reason(interactor), "Tunggu")

	zone.interact(interactor)
	assert_almost_eq(needs.get_value(NeedsComponent.Need.THIRST), 65.0, 0.001, "cooldown menolak minum")
	zone.advance_cooldown(15.0)
	assert_true(zone.can_interact(interactor))


func test_zone_is_inactive_on_land() -> void:
	var player := _make_player()
	var zone := _make_zone(player)
	player.global_position = Vector2.ZERO
	zone.call(&"_update_active")
	assert_false(zone.is_active(), "di base tidak ada prompt minum")
	assert_false(zone.is_in_group(Interactable.GROUP), "tidak mengganggu interaksi darat")

	player.global_position = IslandZones.zone_center(IslandZones.Zone.RIVER)
	zone.call(&"_update_active")
	assert_true(zone.is_active())
	assert_true(zone.is_in_group(Interactable.GROUP))


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


func _make_zone(player: Player) -> RiverDrinkZone:
	var zone := RiverDrinkZone.new()
	zone.name = "RiverDrinkZone"
	player.add_child(zone)
	zone.set_process(false)
	return zone

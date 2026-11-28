extends GutTest

## Fase 3C: Kantung Air Kulit sebagai varian item (penuh <-> kosong).
##
## Pemakaian kantung penuh memberi +25 Thirst / -5 Hunger lalu slot berubah
## menjadi Kantung Air Kosong; isi ulang di sungai menukarnya kembali tanpa
## meminum air. Memakai kantung kosong ditolak.

const InventoryComponentScript = preload("res://src/components/inventory/inventory_component.gd")
const InteractorScript = preload("res://src/components/interaction/interactor_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")


func test_waterskin_data_matches_design_a() -> void:
	var full := ItemCatalog.WATERSKIN
	assert_eq(full.category, ItemDefinition.Category.CONSUMABLE)
	assert_true(full.is_consumable())
	assert_eq(full.max_stack, 1)
	assert_almost_eq(full.consume_effect.thirst, 25.0, 0.001)
	assert_almost_eq(full.consume_effect.hunger, -5.0, 0.001)
	assert_same(full.use_result, ItemCatalog.WATERSKIN_EMPTY)

	var empty := ItemCatalog.WATERSKIN_EMPTY
	assert_eq(empty.id, &"waterskin_empty")
	assert_eq(empty.category, ItemDefinition.Category.SPECIAL)
	assert_eq(empty.max_stack, 1)
	assert_null(empty.consume_effect, "kantung kosong tidak diminum")
	assert_null(empty.use_result)


func test_drinking_turns_full_waterskin_into_empty_one() -> void:
	var harness := _make_harness()

	# 3/3 tegukan: 2 tegukan pertama tetap WATERSKIN (charges 3 -> 2 -> 1), tegukan ke-3 jadi kosong.
	assert_eq(harness["inventory"].get_slot(0).charges, 3, "mulai dengan 3 tegukan")
	assert_true(harness["inventory"].use_slot(0))
	assert_almost_eq(harness["needs"].get_value(NeedsComponent.Need.THIRST), 65.0, 0.001, "+25 Thirst")
	assert_almost_eq(harness["needs"].get_value(NeedsComponent.Need.HUNGER), 45.0, 0.001, "-5 Hunger")
	assert_same(harness["inventory"].get_slot_item(0), ItemCatalog.WATERSKIN, "masih ada 2 tegukan")
	assert_eq(harness["inventory"].get_slot(0).charges, 2)

	assert_true(harness["inventory"].use_slot(0))
	assert_same(harness["inventory"].get_slot_item(0), ItemCatalog.WATERSKIN, "masih ada 1 tegukan")
	assert_eq(harness["inventory"].get_slot(0).charges, 1)

	assert_true(harness["inventory"].use_slot(0))
	assert_same(
		harness["inventory"].get_slot_item(0),
		ItemCatalog.WATERSKIN_EMPTY,
		"setelah 3x minum slot jadi kantung kosong, bukan hilang"
	)
	assert_eq(harness["inventory"].get_slot_count(0), 1)


func test_empty_waterskin_is_not_usable() -> void:
	var harness := _make_harness()
	harness["inventory"].clear()
	assert_eq(harness["inventory"].add_item(ItemCatalog.WATERSKIN_EMPTY), 0)

	assert_false(harness["inventory"].use_slot(0))
	assert_eq(harness["inventory"].count_of(&"waterskin_empty"), 1, "item tidak boleh hilang")
	assert_almost_eq(harness["needs"].get_value(NeedsComponent.Need.THIRST), 40.0, 0.001)


func test_river_refills_empty_waterskin_without_drinking() -> void:
	var harness := _make_harness()
	var interactor: Node = harness["interactor"]
	harness["inventory"].clear()
	harness["inventory"].add_item(ItemCatalog.WATERSKIN_EMPTY)

	var river := RiverEdge.new()
	add_child_autofree(river)

	assert_true(RiverEdge.has_empty_waterskin(interactor))
	assert_eq(river.get_prompt(interactor), RiverEdge.REFILL_PROMPT)
	assert_true(river.can_interact(interactor))

	river.interact(interactor)
	assert_same(harness["inventory"].get_slot_item(0), ItemCatalog.WATERSKIN, "kosong -> penuh")
	assert_almost_eq(
		harness["needs"].get_value(NeedsComponent.Need.THIRST),
		40.0,
		0.001,
		"isi ulang tidak meminum air"
	)
	assert_false(RiverEdge.has_empty_waterskin(interactor))
	assert_false(RiverEdge.refill_waterskin(interactor), "tidak ada kantung kosong lagi")


func test_river_interact_refills_before_drinking() -> void:
	var harness := _make_harness()
	var interactor: Node = harness["interactor"]
	harness["inventory"].clear()
	harness["inventory"].add_item(ItemCatalog.WATERSKIN_EMPTY)

	var river := RiverEdge.new()
	add_child_autofree(river)

	river.interact(interactor)
	assert_same(harness["inventory"].get_slot_item(0), ItemCatalog.WATERSKIN)
	assert_almost_eq(harness["needs"].get_value(NeedsComponent.Need.THIRST), 40.0, 0.001)

	# Interaksi berikutnya tidak menemukan kantung kosong -> minum seperti biasa.
	assert_eq(river.get_prompt(interactor), RiverEdge.PROMPT)
	river.interact(interactor)
	assert_almost_eq(harness["needs"].get_value(NeedsComponent.Need.THIRST), 65.0, 0.001)
	assert_almost_eq(harness["needs"].get_value(NeedsComponent.Need.HUNGER), 42.0, 0.001)
	assert_false(river.can_interact(interactor), "minum tetap kena cooldown")


func test_river_drink_zone_also_refills() -> void:
	var harness := _make_harness()
	var player: Player = harness["player"]
	var interactor: Node = harness["interactor"]
	harness["inventory"].clear()
	harness["inventory"].add_item(ItemCatalog.WATERSKIN_EMPTY)

	var zone := RiverDrinkZone.new()
	zone.name = "RiverDrinkZone"
	player.add_child(zone)
	zone.set_process(false)

	assert_eq(zone.get_prompt(interactor), RiverEdge.REFILL_PROMPT)
	zone.interact(interactor)

	assert_same(harness["inventory"].get_slot_item(0), ItemCatalog.WATERSKIN)
	assert_almost_eq(harness["needs"].get_value(NeedsComponent.Need.THIRST), 40.0, 0.001)
	assert_almost_eq(zone.get_cooldown_remaining(), 0.0, 0.001, "isi ulang tidak memakai cooldown minum")


# --- Helper -----------------------------------------------------------------

func _make_harness() -> Dictionary:
	var player := PLAYER_SCENE.instantiate() as Player
	player.add_to_group(&"player")
	add_child_autofree(player)

	var needs := player.get_node("NeedsComponent") as NeedsComponent
	needs.set_process(false)
	needs.set_value(NeedsComponent.Need.HUNGER, 50.0)
	needs.set_value(NeedsComponent.Need.THIRST, 40.0)
	player.stats.set_hp(60.0)

	var inventory := InventoryComponentScript.new()
	inventory.name = "InventoryComponent"
	inventory.setup(player)
	player.add_child(inventory)
	inventory.set_process(false)
	inventory.add_item(ItemCatalog.WATERSKIN)

	var interactor := InteractorScript.new()
	interactor.name = "InteractorComponent"
	player.add_child(interactor)
	interactor.set_process(false)

	return {
		"player": player,
		"needs": needs,
		"inventory": inventory,
		"interactor": interactor,
	}

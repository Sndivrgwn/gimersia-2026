extends GutTest

## Tes CampStructure: HP, damage, repair, destroyed, HP bar, prioritas aggro.

const CAMPFIRE_DEF: StructureDefinition = preload("res://src/data/camp/campfire.tres")
const WORKBENCH_DEF: StructureDefinition = preload("res://src/data/camp/workbench.tres")
const CHEST_DEF: StructureDefinition = preload("res://src/data/camp/chest.tres")
const TENT_DEF: StructureDefinition = preload("res://src/data/camp/tent.tres")

var structure: CampStructure


func before_each() -> void:
	structure = CampStructure.new()
	structure.definition = CAMPFIRE_DEF
	add_child_autofree(structure)


func test_initial_hp_comes_from_definition() -> void:
	assert_eq(structure.get_max_hp(), 250.0)
	assert_eq(structure.get_current_hp(), 250.0)
	assert_false(structure.is_damaged())
	assert_true(structure.is_in_group(&"camp_structure"))


func test_hp_bar_is_hidden_until_damaged() -> void:
	var bar := structure.get_hp_bar()
	assert_not_null(bar)
	assert_false(bar.visible, "bar tersembunyi saat penuh")

	structure.take_damage(60.0, null)

	assert_eq(structure.get_current_hp(), 190.0)
	assert_true(bar.visible, "bar muncul saat rusak")
	assert_eq(bar.value, 190.0)
	assert_eq(bar.max_value, 250.0)


func test_take_damage_emits_damaged_and_hp_changed() -> void:
	var source := Node.new()
	add_child_autofree(source)
	watch_signals(structure)

	structure.take_damage(80.0, source)

	assert_signal_emitted(structure, "damaged")
	var params: Array = get_signal_parameters(structure, "damaged", 0)
	assert_eq(params[0], 80.0)
	assert_eq(params[1], source)
	var hp_params: Array = get_signal_parameters(structure, "hp_changed", 0)
	assert_eq(hp_params[0], 170.0)
	assert_eq(hp_params[1], 250.0)


func test_repair_heals_and_caps_at_max_hp() -> void:
	structure.take_damage(200.0, null)
	watch_signals(structure)

	var healed := structure.repair(80.0)
	assert_eq(healed, 80.0, "campfire repair +80")
	assert_eq(structure.get_current_hp(), 130.0)
	assert_signal_emitted(structure, "repaired")

	var capped := structure.repair(500.0)
	assert_eq(capped, 120.0, "hanya sampai max HP")
	assert_eq(structure.get_current_hp(), 250.0)
	assert_false(structure.get_hp_bar().visible, "bar hilang lagi saat penuh")


func test_destroyed_at_zero_hp_and_frees_node() -> void:
	watch_signals(structure)

	structure.take_damage(1000.0, null)

	assert_eq(structure.get_current_hp(), 0.0)
	assert_signal_emitted(structure, "destroyed")
	assert_true(structure.is_queued_for_deletion())


func test_aggro_priority_matches_spec() -> void:
	assert_eq(CAMPFIRE_DEF.aggro_priority, 0)
	assert_eq(WORKBENCH_DEF.aggro_priority, 1)
	assert_eq(CHEST_DEF.aggro_priority, 1)
	assert_eq(TENT_DEF.aggro_priority, 2)

	structure.definition = TENT_DEF
	structure.apply_definition()
	assert_eq(structure.get_aggro_priority(), 2)


func test_all_definitions_match_spec() -> void:
	var expected := {
		"campfire": [250.0, 2.5, 0, 80.0, Vector2(0, 0)],
		"workbench": [180.0, 3.0, 1, 70.0, Vector2(-96, -32)],
		"chest": [200.0, 2.5, 1, 80.0, Vector2(96, -32)],
		"tent": [120.0, 4.0, 2, 60.0, Vector2(0, -110)],
	}
	var defs := {
		"campfire": CAMPFIRE_DEF,
		"workbench": WORKBENCH_DEF,
		"chest": CHEST_DEF,
		"tent": TENT_DEF,
	}

	for key: String in expected:
		var def: StructureDefinition = defs[key]
		var row: Array = expected[key]
		assert_not_null(def, "%s harus ada" % key)
		if def == null:
			continue
		assert_eq(def.id, StringName(key))
		assert_almost_eq(def.max_hp, row[0], 0.001, "%s: HP" % key)
		assert_almost_eq(def.build_time, row[1], 0.001, "%s: build_time" % key)
		assert_eq(def.aggro_priority, row[2], "%s: aggro" % key)
		assert_almost_eq(def.repair_hp, row[3], 0.001, "%s: repair_hp" % key)
		assert_eq(def.slot_position, row[4], "%s: slot_position" % key)
		assert_false(def.build_cost.is_empty(), "%s: build_cost" % key)
		assert_false(def.repair_cost.is_empty(), "%s: repair_cost" % key)


func test_build_costs_match_spec() -> void:
	_assert_cost(CAMPFIRE_DEF.build_cost, [[&"wood", 4], [&"stone", 3], [&"fiber", 2]])
	_assert_cost(WORKBENCH_DEF.build_cost, [[&"wood", 5], [&"stone", 2], [&"fiber", 3]])
	_assert_cost(CHEST_DEF.build_cost, [[&"wood", 6], [&"fiber", 2]])
	_assert_cost(TENT_DEF.build_cost, [[&"wood", 6], [&"fiber", 6], [&"bamboo", 2]])


func test_repair_costs_match_spec() -> void:
	_assert_cost(CAMPFIRE_DEF.repair_cost, [[&"wood", 1], [&"stone", 1]])
	_assert_cost(WORKBENCH_DEF.repair_cost, [[&"wood", 1], [&"fiber", 1]])
	_assert_cost(CHEST_DEF.repair_cost, [[&"wood", 2]])
	_assert_cost(TENT_DEF.repair_cost, [[&"wood", 1], [&"fiber", 2]])


func _assert_cost(amounts: Array[ItemAmount], expected: Array) -> void:
	assert_eq(amounts.size(), expected.size())
	for index in mini(amounts.size(), expected.size()):
		var amount := amounts[index]
		var row: Array = expected[index]
		assert_eq(amount.item.id, row[0], "bahan %d id" % index)
		assert_eq(amount.count, row[1], "bahan %d jumlah" % index)

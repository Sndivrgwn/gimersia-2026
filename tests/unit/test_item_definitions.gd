extends GutTest

## Memuat SETIAP file .tres di src/data/items dan memeriksa nilainya terhadap
## spesifikasi §7.1/§7.5. Tes ini yang menjaga file data, bukan kode gameplay.

const ITEM_DIR := "res://src/data/items"

var _definitions: Dictionary = {}


func before_all() -> void:
	for file in DirAccess.get_files_at(ITEM_DIR):
		if not file.ends_with(".tres"):
			continue
		var path := "%s/%s" % [ITEM_DIR, file]
		var definition := load(path) as ItemDefinition
		assert_not_null(definition, "%s harus berupa ItemDefinition" % path)
		if definition == null:
			continue
		assert_false(_definitions.has(definition.id), "id duplikat: %s" % definition.id)
		_definitions[definition.id] = definition


func test_every_item_file_loads() -> void:
	assert_eq(_definitions.size(), 23, "semua item di src/data/items harus termuat")
	assert_eq(ItemCatalog.ALL.size(), 23, "ItemCatalog harus mendaftar semua item")


func test_ids_are_unique_and_stack_is_at_least_one() -> void:
	for id in _definitions:
		var definition: ItemDefinition = _definitions[id]
		assert_eq(definition.id, id)
		assert_false(definition.display_name.is_empty(), "%s harus punya display_name" % id)
		assert_gte(definition.max_stack, 1, "%s butuh max_stack >= 1" % id)


func test_display_names_match_spec() -> void:
	var expected := {
		&"wood": "Kayu",
		&"stone": "Batu",
		&"fiber": "Serat",
		&"bamboo": "Bambu",
		&"bone": "Tulang",
		&"hide": "Kulit",
		&"berry": "Beri",
		&"coconut": "Kelapa",
		&"raw_meat": "Daging Mentah",
		&"cooked_meat": "Daging Matang",
		&"bone_broth": "Kaldu Tulang",
		&"boiled_water": "Air Matang",
		&"herbal_bandage": "Perban Herbal",
		&"waterskin": "Kantung Air Kulit",
		&"signal_flare": "Suar Darurat",
		&"torch": "Obor",
		&"wooden_spear": "Tombak Kayu",
		&"stone_spear": "Tombak Batu",
		&"bone_spear": "Tombak Tulang",
		&"stone_axe": "Kapak Batu",
		&"stone_pickaxe": "Beliung Batu",
		&"leather_vest": "Rompi Kulit",
	}
	for id in expected:
		assert_eq(_definitions[id].display_name, expected[id], "%s" % id)


func test_resources_stack_twenty() -> void:
	for id in [&"wood", &"stone", &"fiber", &"bamboo", &"bone", &"hide"]:
		var definition := _definition(id)
		assert_eq(definition.category, ItemDefinition.Category.RESOURCE, "%s" % id)
		assert_eq(definition.max_stack, 20, "%s" % id)
		assert_null(definition.consume_effect, "%s tidak punya efek konsumsi" % id)
		assert_eq(definition.equipment_slot, ItemDefinition.EquipmentSlot.NONE, "%s" % id)


func test_consumables_match_spec() -> void:
	var berry := _definition(&"berry")
	assert_eq(berry.category, ItemDefinition.Category.CONSUMABLE)
	assert_eq(berry.max_stack, 20)
	assert_almost_eq(berry.consume_effect.hunger, 12.0, 0.001)
	assert_almost_eq(berry.consume_effect.fatigue, 10.0, 0.001)
	assert_almost_eq(berry.consume_effect.thirst, 0.0, 0.001)
	assert_almost_eq(berry.consume_effect.hp, 0.0, 0.001)

	var coconut := _definition(&"coconut")
	assert_almost_eq(coconut.consume_effect.hunger, 10.0, 0.001)
	assert_almost_eq(coconut.consume_effect.thirst, 30.0, 0.001)
	assert_almost_eq(coconut.consume_effect.fatigue, 10.0, 0.001)

	var raw_meat := _definition(&"raw_meat")
	assert_almost_eq(raw_meat.consume_effect.hunger, 15.0, 0.001)
	assert_almost_eq(raw_meat.consume_effect.thirst, -10.0, 0.001)

	var cooked_meat := _definition(&"cooked_meat")
	assert_almost_eq(cooked_meat.consume_effect.hunger, 45.0, 0.001)
	assert_almost_eq(cooked_meat.consume_effect.hp, 15.0, 0.001)

	var bone_broth := _definition(&"bone_broth")
	assert_almost_eq(bone_broth.consume_effect.hunger, 35.0, 0.001)
	assert_almost_eq(bone_broth.consume_effect.thirst, 40.0, 0.001)
	assert_almost_eq(bone_broth.consume_effect.regen_hp_per_second, 1.0, 0.001)
	assert_almost_eq(bone_broth.consume_effect.regen_duration, 20.0, 0.001)

	var boiled_water := _definition(&"boiled_water")
	assert_almost_eq(boiled_water.consume_effect.thirst, 60.0, 0.001)
	assert_almost_eq(boiled_water.consume_effect.hunger, 0.0, 0.001)

	var bandage := _definition(&"herbal_bandage")
	assert_almost_eq(bandage.consume_effect.hp, 35.0, 0.001)

	# Hanya Bone Broth yang membawa HoT.
	assert_almost_eq(berry.consume_effect.regen_hp_per_second, 0.0, 0.001)
	assert_almost_eq(coconut.consume_effect.regen_duration, 0.0, 0.001)


func test_special_items_match_spec() -> void:
	var waterskin := _definition(&"waterskin")
	assert_eq(waterskin.category, ItemDefinition.Category.SPECIAL)
	assert_eq(waterskin.max_stack, 1)

	var flare := _definition(&"signal_flare")
	assert_eq(flare.category, ItemDefinition.Category.SPECIAL)
	assert_eq(flare.max_stack, 1)

	var torch := _definition(&"torch")
	assert_eq(torch.category, ItemDefinition.Category.SPECIAL)
	assert_eq(torch.max_stack, 20)


func test_weapons_match_spec() -> void:
	var wooden := _definition(&"wooden_spear")
	assert_eq(wooden.category, ItemDefinition.Category.WEAPON)
	assert_eq(wooden.equipment_slot, ItemDefinition.EquipmentSlot.WEAPON)
	assert_almost_eq(wooden.weapon_damage, 18.0, 0.001)
	assert_almost_eq(wooden.weapon_range, 75.0, 0.001)

	var stone := _definition(&"stone_spear")
	assert_almost_eq(stone.weapon_damage, 28.0, 0.001)
	assert_almost_eq(stone.weapon_range, 85.0, 0.001)

	var bone := _definition(&"bone_spear")
	assert_almost_eq(bone.weapon_damage, 30.0, 0.001)
	assert_almost_eq(bone.weapon_range, 85.0, 0.001)


func test_tools_and_armor_match_spec() -> void:
	for id in [&"stone_axe", &"stone_pickaxe"]:
		var tool := _definition(id)
		assert_eq(tool.category, ItemDefinition.Category.TOOL, "%s" % id)
		assert_eq(tool.equipment_slot, ItemDefinition.EquipmentSlot.TOOL, "%s" % id)

	var vest := _definition(&"leather_vest")
	assert_eq(vest.category, ItemDefinition.Category.ARMOR)
	assert_eq(vest.equipment_slot, ItemDefinition.EquipmentSlot.ARMOR)
	assert_almost_eq(vest.armor_damage_reduction, 0.20, 0.001)
	assert_almost_eq(vest.armor_max_hp_bonus, 15.0, 0.001)


func test_catalog_has_every_definition() -> void:
	for id in _definitions:
		assert_not_null(ItemCatalog.get_by_id(id), "ItemCatalog harus punya %s" % id)
	assert_eq(ItemCatalog.get_by_id(&"berry"), ItemCatalog.BERRY)
	assert_null(ItemCatalog.get_by_id(&"tidak_ada"))


func _definition(id: StringName) -> ItemDefinition:
	assert_true(_definitions.has(id), "item %s harus ada" % id)
	return _definitions.get(id, null) as ItemDefinition

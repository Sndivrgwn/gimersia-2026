extends GutTest

## Tes data resep: id, hasil, jumlah, stasiun, waktu, dan bahan setiap resep.

const EXPECTED := {
	"wooden_spear": [&"wooden_spear", 1, RecipeDefinition.Station.HAND, 2.0, [[&"wood", 3], [&"fiber", 2]]],
	"torch": [&"torch", 1, RecipeDefinition.Station.HAND, 1.5, [[&"wood", 2], [&"fiber", 1]]],
	"herbal_bandage": [&"herbal_bandage", 1, RecipeDefinition.Station.HAND, 1.5, [[&"fiber", 3], [&"berry", 2]]],
	"stone_axe": [&"stone_axe", 1, RecipeDefinition.Station.WORKBENCH, 2.5, [[&"wood", 2], [&"stone", 2], [&"fiber", 1]]],
	"stone_pickaxe": [&"stone_pickaxe", 1, RecipeDefinition.Station.WORKBENCH, 2.5, [[&"wood", 2], [&"stone", 3], [&"fiber", 1]]],
	"stone_spear": [&"stone_spear", 1, RecipeDefinition.Station.WORKBENCH, 3.0, [[&"wooden_spear", 1], [&"stone", 2], [&"fiber", 2]]],
	"bone_spear": [&"bone_spear", 1, RecipeDefinition.Station.WORKBENCH, 3.0, [[&"wooden_spear", 1], [&"bone", 2], [&"fiber", 2]]],
	"leather_vest": [&"leather_vest", 1, RecipeDefinition.Station.WORKBENCH, 3.0, [[&"hide", 3], [&"fiber", 3]]],
	"waterskin": [&"waterskin", 1, RecipeDefinition.Station.WORKBENCH, 2.5, [[&"hide", 2], [&"fiber", 1]]],
	"signal_flare": [&"signal_flare", 1, RecipeDefinition.Station.WORKBENCH, 4.0, [[&"wood", 5], [&"bone", 3], [&"hide", 2], [&"fiber", 2]]],
	"cooked_meat": [&"cooked_meat", 1, RecipeDefinition.Station.CAMPFIRE, 2.0, [[&"raw_meat", 1]]],
	"boiled_water": [&"boiled_water", 1, RecipeDefinition.Station.CAMPFIRE, 2.0, [[&"bamboo", 1]]],
	"bone_broth": [&"bone_broth", 1, RecipeDefinition.Station.CAMPFIRE, 2.5, [[&"bone", 2], [&"raw_meat", 1]]],
}


func test_all_thirteen_recipes_match_spec() -> void:
	assert_eq(EXPECTED.size(), 13, "spec punya 13 resep")

	for key: String in EXPECTED:
		var path := "res://src/data/recipes/%s.tres" % key
		var recipe := load(path) as RecipeDefinition
		var row: Array = EXPECTED[key]

		assert_not_null(recipe, "%s harus ada" % path)
		if recipe == null:
			continue

		assert_eq(recipe.id, StringName(key), "%s: id" % key)
		assert_not_null(recipe.result, "%s: hasil" % key)
		if recipe.result != null:
			assert_eq(recipe.result.id, row[0], "%s: item hasil" % key)
		assert_eq(recipe.result_count, row[1], "%s: result_count" % key)
		assert_eq(recipe.station, row[2], "%s: stasiun" % key)
		assert_almost_eq(recipe.craft_time, row[3], 0.001, "%s: craft_time" % key)

		var expected_ingredients: Array = row[4]
		assert_eq(recipe.ingredients.size(), expected_ingredients.size(), "%s: jumlah bahan" % key)
		for index in mini(recipe.ingredients.size(), expected_ingredients.size()):
			var amount := recipe.ingredients[index]
			var expected: Array = expected_ingredients[index]
			assert_not_null(amount.item, "%s: bahan %d" % [key, index])
			if amount.item != null:
				assert_eq(amount.item.id, expected[0], "%s: bahan %d id" % [key, index])
			assert_eq(amount.count, expected[1], "%s: bahan %d jumlah" % [key, index])


func test_station_helpers_use_indonesian_names() -> void:
	var hand := load("res://src/data/recipes/wooden_spear.tres") as RecipeDefinition
	var bench := load("res://src/data/recipes/stone_axe.tres") as RecipeDefinition
	var fire := load("res://src/data/recipes/cooked_meat.tres") as RecipeDefinition

	assert_eq(hand.get_station_name(), "Tangan")
	assert_eq(hand.get_station_block_reason(), "")
	assert_eq(bench.get_station_name(), "Workbench")
	assert_eq(bench.get_station_block_reason(), "Butuh Workbench")
	assert_eq(fire.get_station_name(), "Api Unggun")
	assert_eq(fire.get_station_block_reason(), "Butuh Api Unggun menyala")

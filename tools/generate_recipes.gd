extends SceneTree

## Generator satu-off untuk `.tres` resep di `src/data/recipes/`.
##
## Jalankan:
##   godot --headless --path . -s tools/generate_recipes.gd
##
## Script ini membangun RecipeDefinition + ItemAmount lalu menyimpannya lewat
## ResourceSaver, supaya referensi antar-resource (uids) tetap valid.

const OUT_DIR := "res://src/data/recipes"

const RECIPES: Array[Dictionary] = [
	{
		"id": &"wooden_spear", "result": &"wooden_spear", "count": 1,
		"station": RecipeDefinition.Station.HAND, "time": 2.0,
		"ingredients": [[&"wood", 3], [&"fiber", 2]],
	},
	{
		"id": &"torch", "result": &"torch", "count": 1,
		"station": RecipeDefinition.Station.HAND, "time": 1.5,
		"ingredients": [[&"wood", 2], [&"fiber", 1]],
	},
	{
		"id": &"herbal_bandage", "result": &"herbal_bandage", "count": 1,
		"station": RecipeDefinition.Station.HAND, "time": 1.5,
		"ingredients": [[&"fiber", 3], [&"berry", 2]],
	},
	{
		"id": &"stone_axe", "result": &"stone_axe", "count": 1,
		"station": RecipeDefinition.Station.WORKBENCH, "time": 2.5,
		"ingredients": [[&"wood", 2], [&"stone", 2], [&"fiber", 1]],
	},
	{
		"id": &"stone_pickaxe", "result": &"stone_pickaxe", "count": 1,
		"station": RecipeDefinition.Station.WORKBENCH, "time": 2.5,
		"ingredients": [[&"wood", 2], [&"stone", 3], [&"fiber", 1]],
	},
	{
		"id": &"stone_spear", "result": &"stone_spear", "count": 1,
		"station": RecipeDefinition.Station.WORKBENCH, "time": 3.0,
		"ingredients": [[&"wooden_spear", 1], [&"stone", 2], [&"fiber", 2]],
	},
	{
		"id": &"bone_spear", "result": &"bone_spear", "count": 1,
		"station": RecipeDefinition.Station.WORKBENCH, "time": 3.0,
		"ingredients": [[&"wooden_spear", 1], [&"bone", 2], [&"fiber", 2]],
	},
	{
		"id": &"leather_vest", "result": &"leather_vest", "count": 1,
		"station": RecipeDefinition.Station.WORKBENCH, "time": 3.0,
		"ingredients": [[&"hide", 3], [&"fiber", 3]],
	},
	{
		"id": &"waterskin", "result": &"waterskin", "count": 1,
		"station": RecipeDefinition.Station.WORKBENCH, "time": 2.5,
		"ingredients": [[&"hide", 2], [&"fiber", 1]],
	},
	{
		"id": &"signal_flare", "result": &"signal_flare", "count": 1,
		"station": RecipeDefinition.Station.WORKBENCH, "time": 4.0,
		"ingredients": [[&"wood", 5], [&"bone", 3], [&"hide", 2], [&"fiber", 2]],
	},
	{
		"id": &"cooked_meat", "result": &"cooked_meat", "count": 1,
		"station": RecipeDefinition.Station.CAMPFIRE, "time": 2.0,
		"ingredients": [[&"raw_meat", 1]],
	},
	{
		"id": &"boiled_water", "result": &"boiled_water", "count": 1,
		"station": RecipeDefinition.Station.CAMPFIRE, "time": 2.0,
		"ingredients": [[&"bamboo", 1]],
	},
	{
		"id": &"bone_broth", "result": &"bone_broth", "count": 1,
		"station": RecipeDefinition.Station.CAMPFIRE, "time": 2.5,
		"ingredients": [[&"bone", 2], [&"raw_meat", 1]],
	},
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var saved := 0
	for data: Dictionary in RECIPES:
		var recipe := _build(data)
		if recipe.result == null:
			push_error("generate_recipes: item hasil '%s' tidak ditemukan" % data["result"])
			continue
		var path := "%s/%s.tres" % [OUT_DIR, recipe.id]
		var err := ResourceSaver.save(recipe, path)
		if err != OK:
			push_error("generate_recipes: gagal menyimpan %s (err %d)" % [path, err])
			continue
		saved += 1
		print("generate_recipes: %s (%d bahan)" % [path, recipe.ingredients.size()])

	print("generate_recipes: %d resep disimpan." % saved)
	quit(0 if saved == RECIPES.size() else 1)


func _build(data: Dictionary) -> RecipeDefinition:
	var recipe := RecipeDefinition.new()
	recipe.id = data["id"]
	recipe.result = ItemCatalog.get_by_id(data["result"])
	if recipe.result != null:
		recipe.display_name = recipe.result.display_name
	recipe.result_count = data["count"]
	recipe.station = data["station"]
	recipe.craft_time = data["time"]

	var amounts: Array[ItemAmount] = []
	for pair: Array in data["ingredients"]:
		var amount := ItemAmount.new()
		amount.item = ItemCatalog.get_by_id(pair[0])
		if amount.item == null:
			push_error("generate_recipes: bahan '%s' tidak ditemukan" % pair[0])
		amount.count = pair[1]
		amounts.append(amount)
	recipe.ingredients = amounts
	return recipe

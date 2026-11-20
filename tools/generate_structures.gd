extends SceneTree

## Generator satu-off untuk `.tres` struktur camp di `src/data/camp/`.
##
## Jalankan:
##   godot --headless --path . -s tools/generate_structures.gd
##
## Script ini membangun StructureDefinition + ItemAmount dan menyimpannya lewat
## ResourceSaver, supaya referensi scene/item (uids) tetap valid.

const OUT_DIR := "res://src/data/camp"
const CAMPFIRE_SCENE := "res://src/entities/camp/campfire/campfire.tscn"
const WORKBENCH_SCENE := "res://src/entities/camp/workbench/workbench.tscn"
const CHEST_SCENE := "res://src/entities/camp/chest/chest.tscn"
const TENT_SCENE := "res://src/entities/camp/tent/tent.tscn"

const STRUCTURES: Array[Dictionary] = [
	{
		"id": &"campfire", "name": "Api Unggun", "scene": CAMPFIRE_SCENE,
		"hp": 250.0, "build": [[&"wood", 4], [&"stone", 3], [&"fiber", 2]],
		"build_time": 2.5, "aggro": 0,
		"repair": [[&"wood", 1], [&"stone", 1]], "repair_hp": 80.0,
		"pos": Vector2(0, 0),
	},
	{
		"id": &"workbench", "name": "Meja Kerja", "scene": WORKBENCH_SCENE,
		"hp": 180.0, "build": [[&"wood", 5], [&"stone", 2], [&"fiber", 3]],
		"build_time": 3.0, "aggro": 1,
		"repair": [[&"wood", 1], [&"fiber", 1]], "repair_hp": 70.0,
		"pos": Vector2(-96, -32),
	},
	{
		"id": &"chest", "name": "Peti", "scene": CHEST_SCENE,
		"hp": 200.0, "build": [[&"wood", 6], [&"fiber", 2]],
		"build_time": 2.5, "aggro": 1,
		"repair": [[&"wood", 2]], "repair_hp": 80.0,
		"pos": Vector2(96, -32),
	},
	{
		"id": &"tent", "name": "Tenda Daun", "scene": TENT_SCENE,
		"hp": 120.0, "build": [[&"wood", 6], [&"fiber", 6], [&"bamboo", 2]],
		"build_time": 4.0, "aggro": 2,
		"repair": [[&"wood", 1], [&"fiber", 2]], "repair_hp": 60.0,
		"pos": Vector2(0, -110),
	},
]


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var saved := 0
	for data: Dictionary in STRUCTURES:
		var definition := _build(data)
		var path := "%s/%s.tres" % [OUT_DIR, definition.id]
		var err := ResourceSaver.save(definition, path)
		if err != OK:
			push_error("generate_structures: gagal menyimpan %s (err %d)" % [path, err])
			continue
		saved += 1
		var scene_note := "scene OK" if definition.scene != null else "scene belum ada"
		print("generate_structures: %s (%s)" % [path, scene_note])

	print("generate_structures: %d struktur disimpan." % saved)
	quit(0 if saved == STRUCTURES.size() else 1)


func _build(data: Dictionary) -> StructureDefinition:
	var definition := StructureDefinition.new()
	definition.id = data["id"]
	definition.display_name = data["name"]
	definition.max_hp = data["hp"]
	definition.build_time = data["build_time"]
	definition.aggro_priority = data["aggro"]
	definition.repair_hp = data["repair_hp"]
	definition.slot_position = data["pos"]
	definition.build_cost = _amounts(data["build"])
	definition.repair_cost = _amounts(data["repair"])

	var scene_path: String = data["scene"]
	if ResourceLoader.exists(scene_path):
		definition.scene = load(scene_path) as PackedScene
	else:
		push_warning("generate_structures: scene '%s' belum ada." % scene_path)
	return definition


func _amounts(pairs: Array) -> Array[ItemAmount]:
	var amounts: Array[ItemAmount] = []
	for pair: Array in pairs:
		var amount := ItemAmount.new()
		amount.item = ItemCatalog.get_by_id(pair[0])
		if amount.item == null:
			push_error("generate_structures: item '%s' tidak ditemukan" % pair[0])
		amount.count = pair[1]
		amounts.append(amount)
	return amounts

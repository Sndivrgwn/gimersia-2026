extends SceneTree

## Generator satu kali untuk resource tuning combat/fauna.
## Jalankan: GODOT --headless --path . -s tools/generate_combat_data.gd

const TARGETS: Array[Dictionary] = [
	{"path": "res://src/data/configs/combat_config.tres", "script": "res://src/data/resources/combat/combat_config.gd"},
	{"path": "res://src/data/configs/fauna/boar_config.tres", "script": "res://src/data/resources/fauna/boar_config.gd", "boar": true, "loot": [&"raw_meat", &"bone"], "counts": [2, 1]},
	{"path": "res://src/data/configs/fauna/deer_config.tres", "script": "res://src/data/resources/fauna/deer_config.gd", "loot": [&"raw_meat", &"hide"], "counts": [2, 1], "deer": true},
	{"path": "res://src/data/configs/fauna/night_scaling_config.tres", "script": "res://src/data/resources/fauna/night_scaling_config.gd"},
	{"path": "res://src/data/configs/fauna/ember_snuff_config.tres", "script": "res://src/data/resources/fauna/ember_snuff_config.gd"},
]


func _init() -> void:
	for target: Dictionary in TARGETS:
		var resource := _build(target)
		if resource == null:
			continue
		var dir := (target["path"] as String).get_base_dir()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		var code := ResourceSaver.save(resource, target["path"])
		print("%s -> %d" % [target["path"], code])
	quit()


func _build(target: Dictionary) -> Resource:
	var script := load(target["script"] as String) as Script
	if script == null:
		push_error("script tidak ditemukan: %s" % target["script"])
		return null
	var resource := script.new() as Resource
	if resource == null:
		return null
	if target.has("loot"):
		resource.set("loot_ids", target["loot"])
		resource.set("loot_counts", target["counts"])
	if target.has("boar"):
		resource.set("move_speed_night", 150.0)
	if target.has("deer"):
		resource.set("max_hp", 40.0)
		resource.set("move_speed_day", 60.0)
		resource.set("move_speed_night", 60.0)
		resource.set("wander_speed_factor", 1.0)
	return resource

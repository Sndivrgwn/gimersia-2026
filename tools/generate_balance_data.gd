extends SceneTree

## Mission 9: generator resource balance (needs, regen HP, run, sneak, wading).
## Jalankan: GODOT --headless --path . -s tools/generate_balance_data.gd
##
## Semua angka tuning hidup di script Resource; .tres yang dihasilkan hanya
## memakai nilai bawaan supaya bisa diubah dari editor tanpa menyentuh kode.

const TARGETS: Array[Dictionary] = [
	{
		"path": "res://src/data/configs/needs_config.tres",
		"script": "res://src/data/resources/needs/needs_config.gd",
	},
	{
		"path": "res://src/data/configs/health_regen_config.tres",
		"script": "res://src/data/resources/needs/health_regen_config.gd",
	},
	{
		"path": "res://src/data/configs/run_config.tres",
		"script": "res://src/data/resources/run/run_config.gd",
	},
	{
		"path": "res://src/data/configs/sneak_config.tres",
		"script": "res://src/data/resources/movement/sneak_config.gd",
	},
	{
		"path": "res://src/data/configs/wading_config.tres",
		"script": "res://src/data/resources/movement/wading_config.gd",
	},
]


func _init() -> void:
	for target: Dictionary in TARGETS:
		var script := load(target["script"] as String) as Script
		if script == null:
			push_error("generate_balance_data: script tidak ditemukan: %s" % target["script"])
			continue
		var resource := script.new() as Resource
		if resource == null:
			continue
		var dir := (target["path"] as String).get_base_dir()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		var code := ResourceSaver.save(resource, target["path"])
		print("%s -> %d" % [target["path"], code])
	quit()

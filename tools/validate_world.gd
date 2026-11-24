extends SceneTree

## CLI validator dunia AUTHORED (Mission 13 blok H).
## Jalankan:
##   GODOT --headless --path . -s tools/validate_world.gd -- res://path/world.tscn
##
## Tanpa argumen memakai WorldConfig.authored_scene_path. Exit code 0 bila tidak
## ada ERROR, 1 bila ada ERROR (atau scene tidak bisa dimuat).
##
## Logika ada di WorldValidator.validate_scene() supaya tes memanggil fungsi yang
## sama tanpa menjalankan proses baru.

const CONFIG_PATH := "res://src/data/configs/world/world_config.tres"


func _init() -> void:
	quit(run(OS.get_cmdline_user_args()))


func run(args: PackedStringArray) -> int:
	var config: WorldConfig = load(CONFIG_PATH)
	if config == null:
		config = WorldConfig.new()
	var path := config.authored_scene_path
	for argument in args:
		if not argument.begins_with("-"):
			path = argument
			break
	var result := WorldValidator.validate_scene(path, config)
	print(result["report"])
	return int(result["exit_code"])

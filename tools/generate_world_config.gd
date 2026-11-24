extends SceneTree

## Generator blok F (Mission 13): world core.
## Jalankan: GODOT --headless --path . -s tools/generate_world_config.gd
##
## Menulis ulang: res://src/data/configs/world/world_config.tres
## Semua nilai di sini invented (lihat laporan blok F).

const PATH := "res://src/data/configs/world/world_config.tres"
const DIR := "res://src/data/configs/world"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))

	var config := WorldConfig.new()
	config.mode = WorldConfig.Mode.FORMULA
	config.authored_scene_path = "res://src/levels/worlds/sample_island/world.tscn"
	config.fallback_to_formula = true
	config.cell_size = 32.0
	config.min_spawn_points = 8
	config.min_spawn_distance = 1100.0
	config.min_corridor_width = 96.0
	config.base_clearance_extra = 50.0
	config.reachability_required_ratio = 0.98
	config.warn_node_ratio = 0.5
	config.polygon_vertex_limit = 2000
	config.min_forest_area = 1000000.0
	config.overlay_cell_px = 64

	var error := ResourceSaver.save(config, PATH)
	if error == OK:
		print("generate_world_config: %s (mode %d, cell %.0f px, spawn min %d)" % [
			PATH, config.mode, config.cell_size, config.min_spawn_points
		])
	else:
		push_error("generate_world_config gagal menulis %s (error %d)" % [PATH, error])
	quit()

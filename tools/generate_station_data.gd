extends SceneTree

## Mission 10: menulis src/data/configs/station_config.tres (tuning stasiun).
## Jalankan: GODOT --headless --path . -s tools/generate_station_data.gd

const CONFIG_PATH := "res://src/data/configs/station_config.tres"
const ConfigScript = preload("res://src/data/resources/camp/station_config.gd")


func _init() -> void:
	var config := ConfigScript.new()
	config.open_hold_time = 0.1
	config.use_range = 140.0
	config.panel_close_distance = 160.0
	config.bag_tab_hand_only = true
	config.campfire_opens_panel = true
	var err := ResourceSaver.save(config, CONFIG_PATH)
	if err != OK:
		printerr("generate_station_data: gagal menulis %s" % CONFIG_PATH)
		quit(1)
		return
	print("generate_station_data: %s diperbarui" % CONFIG_PATH)
	quit(0)

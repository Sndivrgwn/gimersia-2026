extends SceneTree

## Generator Fase 3A: rasa kamera (look-ahead, zoom) + margin batas pulau.
## Jalankan: GODOT --headless --path . -s tools/generate_camera_feel_config.gd
##
## Menulis ulang: res://src/data/configs/camera_feel_config.tres

const PATH := "res://src/data/configs/camera_feel_config.tres"


func _init() -> void:
	var config := CameraFeelConfig.new()
	config.look_ahead_px = 11.0
	config.follow_speed = 3.2
	config.day_zoom = 3.0
	config.night_zoom = 2.75
	config.zoom_time = 1.4
	config.camera_limit_margin = 0.0

	var error := ResourceSaver.save(config, PATH)
	if error == OK:
		print("generate_camera_feel_config: %s (look-ahead %.0f px, zoom %.2f/%.2f)" % [
			PATH, config.look_ahead_px, config.day_zoom, config.night_zoom
		])
	else:
		push_error("generate_camera_feel_config gagal menulis %s (error %d)" % [PATH, error])
	quit()

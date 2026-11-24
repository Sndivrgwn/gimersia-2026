extends SceneTree

## Generator Fase 2: ambang jarak panah base dan penanda tas jatuh.
## Jalankan: GODOT --headless --path . -s tools/generate_compass_config.gd
##
## Menulis ulang: res://src/data/configs/compass_config.tres

const PATH := "res://src/data/configs/compass_config.tres"


func _init() -> void:
	var config := CompassConfig.new()
	config.camp_arrow_distance = 600.0
	config.loot_arrow_distance = 40.0

	var error := ResourceSaver.save(config, PATH)
	if error == OK:
		print("generate_compass_config: %s (base %.0f px, tas %.0f px)" % [
			PATH, config.camp_arrow_distance, config.loot_arrow_distance
		])
	else:
		push_error("generate_compass_config gagal menulis %s (error %d)" % [PATH, error])
	quit()

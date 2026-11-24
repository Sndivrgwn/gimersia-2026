extends SceneTree

## Generator Fase 1C: angka cahaya pemain.
## Jalankan: GODOT --headless --path . -s tools/generate_player_light.gd
##
## Menulis ulang: res://src/data/configs/player_light_config.tres

const PATH := "res://src/data/configs/player_light_config.tres"
## Dibaca lewat ItemCatalog supaya generator ini tidak terdaftar sebagai pemilik
## `torch.tres` (file itu diedit tangan).
const ITEM_CATALOG := preload("res://src/data/resources/items/item_catalog.gd")


func _init() -> void:
	var config := PlayerLightConfig.new()
	config.player_radius = 110.0
	config.torch_radius = 190.0
	config.day_energy = 0.0
	config.night_energy = 1.0
	config.torch_energy_bonus = 0.0
	config.color = Color(1.0, 0.86, 0.62, 1.0)
	config.torch_item = ITEM_CATALOG.TORCH

	var error := ResourceSaver.save(config, PATH)
	if error == OK:
		print("generate_player_light: %s (pemain %.0f px, obor %.0f px)" % [
			PATH, config.player_radius, config.torch_radius
		])
	else:
		push_error("generate_player_light gagal menulis %s (error %d)" % [PATH, error])
	quit()

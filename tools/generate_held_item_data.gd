extends SceneTree

## Mission 10: menulis src/data/configs/held_item_config.tres.
## Jalankan: GODOT --headless --path . -s tools/generate_held_item_data.gd

const CONFIG_PATH := "res://src/data/configs/held_item_config.tres"
const ConfigScript = preload("res://src/data/resources/items/held_item_config.gd")


func _init() -> void:
	var config := ConfigScript.new()
	var err := ResourceSaver.save(config, CONFIG_PATH)
	if err != OK:
		printerr("generate_held_item_data: gagal menulis %s" % CONFIG_PATH)
		quit(1)
		return
	print("generate_held_item_data: %s diperbarui" % CONFIG_PATH)
	quit(0)

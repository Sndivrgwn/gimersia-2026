extends SceneTree

## Generator satu kali: menulis `src/data/configs/proficiency_config.tres`.
## Jalankan SETELAH `--import` supaya class_name ProficiencyConfig dikenal:
##   godot --headless --path . -s tools/generate_proficiency_data.gd
## Angka default diambil dari script resource (yang menyalin spec V8 §7.6).

const TARGET := "res://src/data/configs/proficiency_config.tres"


func _init() -> void:
	var config := ProficiencyConfig.new()
	config.resource_path = TARGET
	var error := ResourceSaver.save(config, TARGET)
	if error != OK:
		push_error("Gagal menyimpan %s (error %d)" % [TARGET, error])
		quit(1)
		return
	print("ProficiencyConfig ditulis: ", TARGET)
	quit(0)

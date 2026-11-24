extends SceneTree

## Generator src/data/configs/environment/sun_config.tres (Mission 13).
## Jalankan: GODOT --headless --path . -s tools/generate_sun_config.gd
##
## Durasi sapuan diambil dari DayNightVisualConfig bawaan supaya fajar/senja
## selesai tepat saat fase berganti, bukan angka yang ditulis dua kali.

const OUTPUT_PATH := "res://src/data/configs/environment/sun_config.tres"
const VISUAL_CONFIG_PATH := "res://src/data/configs/environment/day_night_visual_default.tres"


func _init() -> void:
	var visual := load(VISUAL_CONFIG_PATH) as DayNightVisualConfig
	var seconds := visual.get_transition_duration() if visual != null else 60.0

	var config := SunConfig.new()
	config.sweep_enabled = true
	# set() menghindari cek tipe enum ganda (SunConfig.Side vs Side) di @tool.
	config.set("dawn_side", SunConfig.Side.RIGHT)
	config.dawn_sweep_seconds = seconds
	config.dusk_sweep_seconds = seconds
	config.softness = 0.35
	config.warm_rim_strength = 0.25
	config.sun_arc_enabled = true

	var error := ResourceSaver.save(config, OUTPUT_PATH)
	if error != OK:
		printerr("generate_sun_config: gagal menyimpan %s (error %d)" % [OUTPUT_PATH, error])
		quit(1)
		return
	print("generate_sun_config: %s (sapuan %s dtk)" % [OUTPUT_PATH, str(seconds)])
	quit(0)

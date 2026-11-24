extends SceneTree

## Generator src/data/configs/environment/clock_format.tres (Mission 12).
## Jalankan: GODOT --headless --path . -s tools/generate_clock_format.gd
##
## Nilai di bawah = bawaan skrip ClockFormatConfig, jadi file .tres hanya
## menyimpan skrip. Ubah angka di sini (lalu jalankan ulang) atau langsung di
## inspector .tres; tidak ada angka jam yang ditulis di kode UI.

const OUTPUT_PATH := "res://src/data/configs/environment/clock_format.tres"


func _init() -> void:
	var config := ClockFormatConfig.new()
	config.day_start_hour = 6.0
	config.night_start_hour = 18.0
	config.use_24h = true
	config.minute_step = 1
	config.period_names = PackedStringArray(["Pagi", "Siang", "Sore", "Malam"])
	config.period_start_hours = PackedFloat32Array([5.0, 10.0, 15.0, 18.0])
	config.show_period_label = true
	config.show_remaining_at_night = true
	config.show_remaining_by_day = false
	config.sleep_toast = true

	DirAccess.make_dir_recursive_absolute(OUTPUT_PATH.get_base_dir())
	var error := ResourceSaver.save(config, OUTPUT_PATH)
	if error != OK:
		printerr("generate_clock_format: gagal menyimpan %s (error %d)" % [OUTPUT_PATH, error])
		quit(1)
		return
	print("generate_clock_format: %s (terbit %.2f, terbenam %.2f)" % [
		OUTPUT_PATH, config.day_start_hour, config.night_start_hour
	])
	quit(0)

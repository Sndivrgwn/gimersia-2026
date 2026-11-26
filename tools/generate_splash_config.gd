extends SceneTree

## Generator konfigurasi layar pembuka (splash screen).
## Jalankan: GODOT --headless --path . -s tools/generate_splash_config.gd
## Menulis ulang src/data/configs/ui/splash_config.tres.

const OUTPUT_PATH := "res://src/data/configs/ui/splash_config.tres"


func _init() -> void:
	var config := SplashConfig.new()
	config.enabled = true
	config.background_color = Color(0.0, 0.0, 0.0, 1.0)
	config.logo_max_size_ratio = 0.5
	config.skip_enabled = true
	config.skip_min_seconds = 0.4
	config.show_loading_bar = true
	config.loading_label = "Memuat..."
	config.bar_smooth_speed = 1.5
	config.min_total_seconds = 2.0
	config.max_wait_seconds = 15.0
	config.next_scene_path = "res://src/ui/menus/main_menu.tscn"
	config.preload_paths = PackedStringArray(["res://src/levels/island/island.tscn"])
	config.skip_if_already_shown = true
	config.dev_skip = false

	var studio := SplashEntry.new()
	studio.asset_key = &"ui_splash_studio"
	studio.fallback_text = "NAMA STUDIO"
	studio.fallback_font_size = 48
	studio.hold_seconds = 1.6
	studio.fade_in = 0.6
	studio.fade_out = 0.6

	var game := SplashEntry.new()
	game.asset_key = &"ui_logo"
	game.fallback_text = "NAMA GAME"
	game.fallback_font_size = 64
	game.hold_seconds = 1.8
	game.fade_in = 0.6
	game.fade_out = 0.6

	config.entries = [studio, game]

	DirAccess.make_dir_recursive_absolute(OUTPUT_PATH.get_base_dir())
	var error := ResourceSaver.save(config, OUTPUT_PATH)
	if error != OK:
		printerr("generate_splash_config: gagal menyimpan %s (error %d)" % [OUTPUT_PATH, error])
		quit(1)
		return
	print("generate_splash_config: %s (%d entri)" % [OUTPUT_PATH, config.entries.size()])
	quit(0)

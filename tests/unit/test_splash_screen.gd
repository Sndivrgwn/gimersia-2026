extends GutTest

## Mission 14 (Block J): unit test SplashScreen + validasi splash_config.tres,
## slot aset, dan cue audio. Memakai stub loader & stub scene change (tidak
## pernah memanggil change_scene asli).

const SPLASH_SCENE: PackedScene = preload("res://src/ui/menus/splash_screen.tscn")
const CONFIG_PATH := "res://src/data/configs/ui/splash_config.tres"
const ASSET_REGISTRY_PATH := "res://src/data/assets/asset_registry.tres"
const AUDIO_REGISTRY_PATH := "res://src/data/audio/audio_registry.tres"


class StubLoader extends RefCounted:
	var existing_paths: Dictionary = {}
	var requested: Array[String] = []
	var state_by_path: Dictionary = {}
	var progress_by_path: Dictionary = {}
	var packed_by_path: Dictionary = {}

	func exists(path: String) -> bool:
		return bool(existing_paths.get(path, true))

	func request(path: String) -> int:
		requested.append(path)
		if not state_by_path.has(path):
			state_by_path[path] = ResourceLoader.THREAD_LOAD_IN_PROGRESS
		return OK

	func status(path: String) -> Dictionary:
		return {
			"state": int(state_by_path.get(path, ResourceLoader.THREAD_LOAD_IN_PROGRESS)),
			"progress": float(progress_by_path.get(path, 0.0)),
		}

	func get_packed(path: String) -> PackedScene:
		return packed_by_path.get(path, null) as PackedScene


class TestSplashScreen extends SplashScreen:
	var changed_packed: Array[PackedScene] = []
	var changed_direct: Array[String] = []
	var direct_return_code: int = OK
	var texture_stubs: Dictionary = {}
	var overlay_present_at_change: bool = false

	func _change_scene(packed: PackedScene) -> void:
		var tree := get_tree()
		overlay_present_at_change = tree != null and tree.root.get_node_or_null("IrisOverlay") != null
		changed_packed.append(packed)

	func _change_scene_direct(path: String) -> int:
		changed_direct.append(path)
		return direct_return_code

	func _lookup_ui_texture(key: StringName) -> Texture2D:
		if texture_stubs.has(key):
			return texture_stubs[key] as Texture2D
		return null


var _saved_env_skip: String = ""


func before_each() -> void:
	SplashScreen.shown_this_session = false
	_saved_env_skip = OS.get_environment(SplashScreen.ENV_SKIP)
	OS.set_environment(SplashScreen.ENV_SKIP, "")


func after_each() -> void:
	SplashScreen.shown_this_session = false
	OS.set_environment(SplashScreen.ENV_SKIP, _saved_env_skip)
	var tree := get_tree()
	if tree != null and tree.root != null:
		for child in tree.root.get_children():
			if child is IrisOverlay and is_instance_valid(child):
				child.free()


func _make_texture(w: int, h: int) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.6, 0.9, 1.0))
	return ImageTexture.create_from_image(img)


func _spawn_splash(cfg: SplashConfig, stub_loader: StubLoader, textures: Dictionary = {}) -> TestSplashScreen:
	var node := SPLASH_SCENE.instantiate()
	node.set_script(TestSplashScreen)
	var splash := node as TestSplashScreen
	splash.config = cfg
	splash.loader = stub_loader
	splash.texture_stubs = textures
	add_child_autofree(splash)
	return splash


func _short_config() -> SplashConfig:
	var cfg := SplashConfig.new()
	cfg.enabled = true
	cfg.skip_enabled = true
	cfg.skip_min_seconds = 0.2
	cfg.min_total_seconds = 0.5
	cfg.max_wait_seconds = 10.0
	cfg.logo_max_size_ratio = 0.5
	cfg.next_scene_path = "res://src/ui/menus/main_menu.tscn"
	cfg.preload_paths = PackedStringArray(["res://src/levels/island/island.tscn"])
	var e := SplashEntry.new()
	e.asset_key = &"ui_splash_studio"
	e.fallback_text = "STUDIO TEST"
	e.fallback_font_size = 48
	e.fade_in = 0.2
	e.hold_seconds = 0.4
	e.fade_out = 0.2
	cfg.entries = [e]
	return cfg


func test_default_config_builds_and_shows_fallback_without_art() -> void:
	var stub := StubLoader.new()
	var splash := _spawn_splash(null, stub)
	splash._process(0.1)

	var logo := splash.get_node("Center/LogoTexture") as TextureRect
	var fallback := splash.get_node("Center/FallbackLabel") as Label
	var bg_tex := splash.get_node("BackgroundTexture") as TextureRect

	assert_false(logo.visible, "tanpa art TextureRect disembunyikan")
	assert_true(fallback.visible, "tanpa art Label fallback tampil")
	assert_eq(fallback.text, "NAMA STUDIO")
	assert_false(bg_tex.visible, "background texture sembunyi saat ui_splash_bg kosong")
	assert_true(stub.requested.has("res://src/ui/menus/main_menu.tscn"))
	assert_true(stub.requested.has("res://src/levels/island/island.tscn"))


func test_texture_stub_shows_logo_scales_on_resize_and_shows_background() -> void:
	var stub := StubLoader.new()
	var cfg := _short_config()
	cfg.logo_max_size_ratio = 0.5
	var textures := {
		&"ui_splash_studio": _make_texture(64, 32),
		&"ui_splash_bg": _make_texture(64, 32),
	}
	var splash := _spawn_splash(cfg, stub, textures)
	splash._process(0.1)

	var logo := splash.get_node("Center/LogoTexture") as TextureRect
	var fallback := splash.get_node("Center/FallbackLabel") as Label
	var bg_tex := splash.get_node("BackgroundTexture") as TextureRect

	assert_true(logo.visible, "art tampil di LogoTexture")
	assert_false(fallback.visible, "fallback sembunyi saat art ada")
	assert_true(bg_tex.visible, "background texture tampil saat ui_splash_bg ada")

	var expected_size := splash.get_viewport().get_visible_rect().size * 0.5
	assert_almost_eq(logo.custom_minimum_size.x, expected_size.x, 1.0)
	assert_almost_eq(logo.custom_minimum_size.y, expected_size.y, 1.0)

	# Ubah rasio lalu panggil resize hook untuk memastikan ukuran dihitung ulang.
	cfg.logo_max_size_ratio = 0.25
	splash._update_logo_bounds()
	assert_almost_eq(logo.custom_minimum_size.x, splash.get_viewport().get_visible_rect().size.x * 0.25, 1.0)


func test_skip_inputs_key_mouse_joypad_and_ui_cancel() -> void:
	var events: Array[InputEvent] = []
	var key := InputEventKey.new()
	key.pressed = true
	key.echo = false
	key.keycode = KEY_SPACE
	events.append(key)

	var mouse := InputEventMouseButton.new()
	mouse.pressed = true
	mouse.button_index = MOUSE_BUTTON_LEFT
	events.append(mouse)

	var joy := InputEventJoypadButton.new()
	joy.pressed = true
	joy.button_index = JOY_BUTTON_A
	events.append(joy)

	var cancel := InputEventAction.new()
	cancel.action = &"ui_cancel"
	cancel.pressed = true
	events.append(cancel)

	for ev in events:
		var stub := StubLoader.new()
		var cfg := _short_config()
		cfg.skip_min_seconds = 0.1
		var splash := _spawn_splash(cfg, stub)
		splash._process(0.15)
		assert_eq(splash.get_sequencer().state(), SplashSequencer.State.PLAYING)
		splash._input(ev)
		assert_eq(splash.get_sequencer().state(), SplashSequencer.State.WAITING_LOAD, "input skip memindahkan ke WAITING_LOAD")


func test_switch_occurs_once_with_packed_scene_and_does_not_touch_clock() -> void:
	var clock := get_node_or_null("/root/DayNightManager")
	var clock_scale_before := float(clock.get_time_scale()) if (clock != null and clock.has_method(&"get_time_scale")) else -1.0

	var stub := StubLoader.new()
	var dummy_packed := PackedScene.new()
	var cfg := _short_config()
	stub.packed_by_path[cfg.next_scene_path] = dummy_packed

	var splash := _spawn_splash(cfg, stub)
	stub.state_by_path[cfg.next_scene_path] = ResourceLoader.THREAD_LOAD_LOADED
	stub.progress_by_path[cfg.next_scene_path] = 1.0

	splash._process(0.5)
	splash._process(0.5)
	splash._process(0.5)

	assert_eq(splash.changed_packed.size(), 1, "pindah scene tepat sekali")
	assert_eq(splash.changed_packed[0], dummy_packed)
	assert_true(SplashScreen.shown_this_session)

	if clock != null and clock.has_method(&"get_time_scale"):
		assert_almost_eq(float(clock.get_time_scale()), clock_scale_before, 0.001, "DayNightManager time_scale tidak berubah")


func test_dev_skip_env_var_and_shown_this_session_skip_sequence() -> void:
	var dummy := PackedScene.new()

	# 1) dev_skip
	var stub1 := StubLoader.new()
	var cfg1 := _short_config()
	cfg1.dev_skip = true
	cfg1.min_total_seconds = 10.0
	stub1.state_by_path[cfg1.next_scene_path] = ResourceLoader.THREAD_LOAD_LOADED
	stub1.packed_by_path[cfg1.next_scene_path] = dummy
	var s1 := _spawn_splash(cfg1, stub1)
	s1._process(0.016)
	assert_eq(s1.changed_packed.size(), 1, "dev_skip langsung pindah setelah load selesai")

	# 2) env var GIMERSIA_SKIP_SPLASH=1
	SplashScreen.shown_this_session = false
	OS.set_environment(SplashScreen.ENV_SKIP, "1")
	var stub2 := StubLoader.new()
	var cfg2 := _short_config()
	cfg2.min_total_seconds = 10.0
	stub2.state_by_path[cfg2.next_scene_path] = ResourceLoader.THREAD_LOAD_LOADED
	stub2.packed_by_path[cfg2.next_scene_path] = dummy
	var s2 := _spawn_splash(cfg2, stub2)
	s2._process(0.016)
	assert_eq(s2.changed_packed.size(), 1, "env GIMERSIA_SKIP_SPLASH=1 langsung pindah")
	OS.set_environment(SplashScreen.ENV_SKIP, "")

	# 3) shown_this_session = true
	SplashScreen.shown_this_session = true
	var stub3 := StubLoader.new()
	var cfg3 := _short_config()
	cfg3.skip_if_already_shown = true
	cfg3.min_total_seconds = 10.0
	stub3.state_by_path[cfg3.next_scene_path] = ResourceLoader.THREAD_LOAD_LOADED
	stub3.packed_by_path[cfg3.next_scene_path] = dummy
	var s3 := _spawn_splash(cfg3, stub3)
	s3._process(0.016)
	assert_eq(s3.changed_packed.size(), 1, "shown_this_session langsung pindah")


func test_load_failure_calls_direct_change_and_shows_error_if_that_fails() -> void:
	var stub := StubLoader.new()
	var cfg := _short_config()
	stub.state_by_path[cfg.next_scene_path] = ResourceLoader.THREAD_LOAD_FAILED
	var splash := _spawn_splash(cfg, stub)
	splash.direct_return_code = ERR_CANT_OPEN
	splash._process(0.016)

	assert_eq(splash.changed_packed.size(), 0)
	assert_eq(splash.changed_direct, [cfg.next_scene_path])
	var fallback := splash.get_node("Center/FallbackLabel") as Label
	assert_true(fallback.visible)
	assert_eq(fallback.text, SplashScreen.ERROR_TEXT)


func test_generated_config_and_registries_match_spec() -> void:
	var cfg := load(CONFIG_PATH) as SplashConfig
	assert_not_null(cfg, "splash_config.tres harus bisa dimuat")
	assert_true(cfg.enabled)
	assert_eq(cfg.entries.size(), 2)
	assert_eq(cfg.entries[0].asset_key, &"ui_splash_studio")
	assert_eq(cfg.entries[0].fallback_text, "NAMA STUDIO")
	assert_eq(cfg.entries[0].fallback_font_size, 48)
	assert_almost_eq(cfg.entries[0].hold_seconds, 1.6, 0.001)
	assert_almost_eq(cfg.entries[0].fade_in, 0.6, 0.001)
	assert_almost_eq(cfg.entries[0].fade_out, 0.6, 0.001)
	assert_eq(cfg.entries[1].asset_key, &"ui_logo")
	assert_eq(cfg.entries[1].fallback_text, "NAMA GAME")
	assert_eq(cfg.entries[1].fallback_font_size, 64)
	assert_almost_eq(cfg.entries[1].hold_seconds, 1.8, 0.001)
	assert_almost_eq(cfg.logo_max_size_ratio, 0.5, 0.001)
	assert_true(cfg.skip_enabled)
	assert_almost_eq(cfg.skip_min_seconds, 0.4, 0.001)
	assert_true(cfg.show_loading_bar)
	assert_eq(cfg.loading_label, "Memuat...")
	assert_almost_eq(cfg.bar_smooth_speed, 1.5, 0.001)
	assert_almost_eq(cfg.min_total_seconds, 2.0, 0.001)
	assert_almost_eq(cfg.max_wait_seconds, 15.0, 0.001)
	assert_eq(cfg.next_scene_path, "res://src/ui/menus/main_menu.tscn")
	assert_eq(cfg.preload_paths, PackedStringArray(["res://src/levels/island/island.tscn"]))
	assert_true(cfg.skip_if_already_shown)
	assert_false(cfg.dev_skip)
	assert_true(cfg.transition_enabled)
	assert_almost_eq(cfg.transition_duration, 0.8, 0.001)
	assert_almost_eq(cfg.transition_softness, 0.03, 0.001)
	assert_almost_eq(cfg.transition_hold_before, 0.15, 0.001)
	assert_almost_eq(cfg.transition_start_radius, 0.0, 0.001)
	assert_eq(cfg.transition_ease, SplashConfig.TransitionEase.EASE_OUT)
	assert_true(cfg.transition_block_input)

	var assets := load(ASSET_REGISTRY_PATH) as AssetRegistry
	assert_not_null(assets)
	assert_not_null(assets.get_slot(&"ui_splash_studio"), "slot ui_splash_studio ada di registry")
	assert_not_null(assets.get_slot(&"ui_splash_bg"), "slot ui_splash_bg ada di registry")
	var logo_slot := assets.get_slot(&"ui_logo")
	assert_not_null(logo_slot)
	assert_true(logo_slot.used_by.contains("splash_screen.tscn"), "ui_logo menyebut splash_screen.tscn")

	var audio := load(AUDIO_REGISTRY_PATH) as AudioRegistry
	assert_not_null(audio)
	var found_sting := false
	for cue in audio.cues:
		if cue != null and cue.key == &"ui_splash_sting":
			found_sting = true
			break
	assert_true(found_sting, "audio_registry memuat ui_splash_sting")


func test_iris_overlay_mounts_before_change_blocks_input_and_frees_itself() -> void:
	var clock := get_node_or_null("/root/DayNightManager")
	var clock_scale_before := float(clock.get_time_scale()) if (clock != null and clock.has_method(&"get_time_scale")) else -1.0

	var stub := StubLoader.new()
	var dummy := PackedScene.new()
	var cfg := _short_config()
	cfg.transition_enabled = true
	cfg.transition_hold_before = 0.05
	cfg.transition_duration = 0.1
	cfg.transition_block_input = true
	stub.packed_by_path[cfg.next_scene_path] = dummy
	stub.state_by_path[cfg.next_scene_path] = ResourceLoader.THREAD_LOAD_LOADED
	stub.progress_by_path[cfg.next_scene_path] = 1.0

	var splash := _spawn_splash(cfg, stub)
	var counts := [0, 0]
	splash.transition_started.connect(func() -> void: counts[0] += 1)
	splash.transition_finished.connect(func() -> void: counts[1] += 1)

	splash._process(0.5)
	splash._process(0.5)

	assert_eq(splash.changed_packed.size(), 1, "pindah scene tepat sekali")
	assert_true(splash.overlay_present_at_change, "IrisOverlay terpasang di root sebelum _change_scene")
	assert_eq(counts[0], 1)

	var overlay := get_tree().root.get_node_or_null("IrisOverlay") as IrisOverlay
	assert_not_null(overlay)
	assert_eq(overlay.layer, IrisOverlay.OVERLAY_LAYER)
	assert_eq(overlay.get_mask_rect().mouse_filter, Control.MOUSE_FILTER_STOP, "input dikunci selama transisi")

	# Menekan tombol selama transisi tidak boleh memicu pindah scene kedua.
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_SPACE
	splash._input(key)
	assert_eq(splash.changed_packed.size(), 1)

	# Tunggu 1 frame supaya start_after_next_frame() memanggil start(), lalu jalankan sampai selesai.
	await get_tree().process_frame
	assert_true(overlay.is_started())
	overlay._process(0.05)
	overlay._process(0.15)

	assert_eq(counts[1], 1)
	assert_eq(overlay.get_mask_rect().mouse_filter, Control.MOUSE_FILTER_IGNORE, "input dilepas setelah selesai")
	await get_tree().process_frame
	assert_null(get_tree().root.get_node_or_null("IrisOverlay"), "overlay menghapus dirinya sendiri")

	if clock != null and clock.has_method(&"get_time_scale"):
		assert_almost_eq(float(clock.get_time_scale()), clock_scale_before, 0.001, "time_scale tidak berubah")


func test_no_overlay_on_disabled_dev_skip_env_skip_or_load_failure() -> void:
	var dummy := PackedScene.new()

	# 1) transition_enabled = false
	var stub1 := StubLoader.new()
	var cfg1 := _short_config()
	cfg1.transition_enabled = false
	stub1.packed_by_path[cfg1.next_scene_path] = dummy
	stub1.state_by_path[cfg1.next_scene_path] = ResourceLoader.THREAD_LOAD_LOADED
	var s1 := _spawn_splash(cfg1, stub1)
	s1._process(0.6)
	s1._process(0.6)
	assert_false(s1.overlay_present_at_change, "transition_enabled=false tanpa overlay")
	assert_null(get_tree().root.get_node_or_null("IrisOverlay"))

	# 2) dev_skip = true
	SplashScreen.shown_this_session = false
	var stub2 := StubLoader.new()
	var cfg2 := _short_config()
	cfg2.dev_skip = true
	stub2.packed_by_path[cfg2.next_scene_path] = dummy
	stub2.state_by_path[cfg2.next_scene_path] = ResourceLoader.THREAD_LOAD_LOADED
	var s2 := _spawn_splash(cfg2, stub2)
	s2._process(0.016)
	assert_false(s2.overlay_present_at_change, "dev_skip tanpa overlay")
	assert_null(get_tree().root.get_node_or_null("IrisOverlay"))

	# 3) env GIMERSIA_SKIP_SPLASH=1
	SplashScreen.shown_this_session = false
	OS.set_environment(SplashScreen.ENV_SKIP, "1")
	var stub3 := StubLoader.new()
	var cfg3 := _short_config()
	stub3.packed_by_path[cfg3.next_scene_path] = dummy
	stub3.state_by_path[cfg3.next_scene_path] = ResourceLoader.THREAD_LOAD_LOADED
	var s3 := _spawn_splash(cfg3, stub3)
	s3._process(0.016)
	assert_false(s3.overlay_present_at_change, "env skip tanpa overlay")
	assert_null(get_tree().root.get_node_or_null("IrisOverlay"))
	OS.set_environment(SplashScreen.ENV_SKIP, "")

	# 4) gagal muat
	SplashScreen.shown_this_session = false
	var stub4 := StubLoader.new()
	var cfg4 := _short_config()
	stub4.state_by_path[cfg4.next_scene_path] = ResourceLoader.THREAD_LOAD_FAILED
	var s4 := _spawn_splash(cfg4, stub4)
	s4._process(0.016)
	assert_false(s4.overlay_present_at_change, "gagal muat tanpa overlay")
	assert_null(get_tree().root.get_node_or_null("IrisOverlay"))

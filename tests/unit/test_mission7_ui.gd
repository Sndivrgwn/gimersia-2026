extends GutTest

## Mission 7 / Phase 3: settings, pause, help, hints.

const JUICE: JuiceConfig = preload("res://src/data/configs/juice_config.tres")

class StubClock extends Node:
	var scale := 1.0
	var night := false
	func get_time_scale() -> float: return scale
	func set_time_scale(value: float) -> void: scale = value
	func is_night() -> bool: return night
	func get_current_day() -> int: return 1

class StubBlocker extends Node:
	var showing := false
	func is_showing() -> bool: return showing


func before_each() -> void:
	_clear_settings_file()


func after_each() -> void:
	_clear_settings_file()


func _clear_settings_file() -> void:
	var path := ProjectSettings.globalize_path(SettingsService.SAVE_PATH)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _make_settings() -> SettingsService:
	var service := SettingsService.new()
	add_child_autofree(service)
	return service


# --- 3.1 Settings -----------------------------------------------------------

func test_settings_defaults_and_clamp() -> void:
	var service := _make_settings()
	assert_almost_eq(service.get_juice_intensity(), 1.0, 0.001)
	assert_true(service.is_screenshake_enabled())
	assert_true(service.are_hints_enabled())
	watch_signals(service)
	service.set_value(&"juice_intensity", 9.0)
	assert_almost_eq(service.get_juice_intensity(), 1.5, 0.001, "clamp 0..1.5")
	assert_signal_emitted(service, "changed")
	service.set_value(&"hints_enabled", false)
	assert_false(service.are_hints_enabled())


func test_settings_save_load_and_corrupt_file() -> void:
	var service := _make_settings()
	service.set_value(&"juice_intensity", 0.4)
	service.set_value(&"screenshake_enabled", false)
	var reloaded := SettingsService.new()
	add_child_autofree(reloaded)
	assert_almost_eq(reloaded.get_juice_intensity(), 0.4, 0.001, "tersimpan ke disk")
	assert_false(reloaded.is_screenshake_enabled())

	var file := FileAccess.open(SettingsService.SAVE_PATH, FileAccess.WRITE)
	file.store_string("rusak total")
	file.close()
	var recovered := SettingsService.new()
	add_child_autofree(recovered)
	assert_almost_eq(recovered.get_juice_intensity(), 1.0, 0.001, "file rusak -> default")


func test_combat_feedback_honors_settings() -> void:
	var service := _make_settings()
	service.set_value(&"juice_intensity", 0.5)
	service.set_value(&"screenshake_enabled", false)

	var player := Node2D.new()
	add_child_autofree(player)
	var camera := Camera2D.new()
	add_child_autofree(camera)
	var feedback := CombatFeedback.new()
	feedback.config = JUICE
	feedback.player = player
	feedback.camera = camera
	feedback.settings = service
	player.add_child(feedback)

	feedback.notify_hit(null, 10.0, false)
	feedback.tick(0.001)
	assert_eq(camera.offset, Vector2.ZERO, "shake dimatikan lewat settings")
	assert_true(feedback.is_hit_stopped())
	feedback.tick(0.1)
	assert_false(feedback.is_hit_stopped(), "hit-stop 0.05 x 0.5 = 0.025 s")


# --- 3.2 Pause --------------------------------------------------------------

func test_pause_guards_and_clock_restore() -> void:
	var clock := StubClock.new()
	clock.scale = 2.0
	add_child_autofree(clock)
	var menu := PauseMenu.new()
	menu.clock = clock
	add_child_autofree(menu)
	var blocker := StubBlocker.new()
	add_child_autofree(blocker)
	menu.blockers = [blocker]

	blocker.showing = true
	assert_false(menu.can_open(), "panel aktif menghalangi pause")
	assert_false(menu.open())
	assert_false(get_tree().paused)

	blocker.showing = false
	assert_true(menu.open())
	assert_true(menu.is_open())
	assert_true(get_tree().paused, "tree di-pause")
	assert_almost_eq(clock.scale, 0.0, 0.001, "jam dibekukan")
	assert_almost_eq(menu.get_previous_time_scale(), 2.0, 0.001)

	menu.close()
	assert_false(get_tree().paused)
	assert_almost_eq(clock.scale, 2.0, 0.001, "night watch x2 dipulihkan")


func test_pause_toggle_signal_and_main_menu() -> void:
	var clock := StubClock.new()
	add_child_autofree(clock)
	var menu := PauseMenu.new()
	menu.clock = clock
	add_child_autofree(menu)
	watch_signals(menu)
	menu.toggle()
	assert_true(menu.is_open())
	menu.toggle()
	assert_false(menu.is_open())
	assert_signal_emitted(menu, "resumed")
	menu.open()
	menu.request_main_menu()
	assert_false(menu.is_open(), "main menu menutup pause dulu")


# --- 3.3 / 3.4 Panels -------------------------------------------------------

func test_settings_panel_drives_service() -> void:
	var service := _make_settings()
	var panel := SettingsPanel.new()
	add_child_autofree(panel)
	panel.setup(service)
	panel.get_slider().value = 0.3
	assert_almost_eq(service.get_juice_intensity(), 0.3, 0.001)
	panel.get_screenshake_toggle().button_pressed = false
	assert_false(service.is_screenshake_enabled())
	panel.get_hints_toggle().button_pressed = false
	assert_false(service.are_hints_enabled())
	assert_eq(panel.get_slider().tooltip_text, "")
	panel.open()
	assert_true(panel.is_open())
	watch_signals(panel)
	panel.close()
	assert_signal_emitted(panel, "closed")


func test_help_panel_toggle() -> void:
	var panel := HelpPanel.new()
	add_child_autofree(panel)
	assert_false(panel.is_open())
	panel.toggle()
	assert_true(panel.is_open())
	assert_string_contains(panel.get_text(), "WASD")
	assert_string_contains(panel.get_text(), "P - pause")
	panel.toggle()
	assert_false(panel.is_open())


# --- 3.5 Hints --------------------------------------------------------------

func _make_hints(settings: SettingsService = null) -> HintManager:
	var manager := HintManager.new()
	manager.settings = settings
	add_child_autofree(manager)
	# Tes ini fokus ke API hint; hint base otomatis dimatikan.
	manager._base_checked = true
	return manager


func test_hint_shows_once_and_hides_after_five_seconds() -> void:
	var manager := _make_hints()
	watch_signals(manager)
	manager.trigger(&"gather")
	assert_true(manager.is_showing())
	assert_eq(manager.get_current(), &"gather")
	assert_signal_emitted(manager, "hint_shown")

	manager.trigger(&"gather")
	assert_eq(manager.get_queue_size(), 0, "hint sama tidak diulang")
	manager.tick(HintManager.SHOW_TIME + 0.1)
	assert_false(manager.is_showing())
	manager.trigger(&"gather")
	assert_false(manager.is_showing(), "sekali per run")


func test_hint_queue_order() -> void:
	var manager := _make_hints()
	manager.trigger(&"gather")
	manager.trigger(&"dusk")
	manager.trigger(&"repair")
	assert_eq(manager.get_queue_size(), 2)
	manager.tick(HintManager.SHOW_TIME + 0.1)
	assert_eq(manager.get_current(), &"dusk")
	manager.tick(HintManager.SHOW_TIME + 0.1)
	assert_eq(manager.get_current(), &"repair")


func test_hint_reset_and_disabled() -> void:
	var manager := _make_hints()
	manager.trigger(&"gather")
	manager.tick(HintManager.SHOW_TIME + 0.1)
	manager.reset()
	assert_false(manager.has_shown(&"gather"))
	manager.trigger(&"gather")
	assert_true(manager.is_showing(), "reset -> boleh tampil lagi")

	var service := _make_settings()
	service.set_value(&"hints_enabled", false)
	var quiet := _make_hints(service)
	quiet.trigger(&"dusk")
	assert_false(quiet.is_showing(), "hints off tidak menampilkan apa pun")

extends GutTest

const ScreenFade := preload("res://src/ui/fx/screen_fade.gd")
const UiMotion := preload("res://src/ui/fx/ui_motion.gd")

## Mission 9 polish: fade, gerak UI, vignette, ambience, penunjuk camp,
## layar penuh, dan binding gamepad.

const VIGNETTE_PATH := "res://src/ui/fx/low_hp_vignette.gd"
const AMBIENT_PATH := "res://src/levels/components/environment/ambient_life.gd"


func before_each() -> void:
	InputSetup.ensure_actions()


func test_fade_is_disabled_in_headless() -> void:
	assert_true(ScreenFade.is_visual_disabled(), "tes berjalan headless")


func test_fade_without_tree_still_calls_back() -> void:
	var called := [false]
	ScreenFade.fade_out_then(null, func() -> void: called[0] = true)
	assert_true(called[0], "callback tetap dipanggil agar alur scene tidak macet")


func test_ui_motion_is_instant_and_sets_value() -> void:
	var bar := ProgressBar.new()
	add_child_autofree(bar)
	bar.max_value = 100.0
	bar.value = 10.0
	UiMotion.tween_bar(bar, 75.0)
	assert_almost_eq(bar.value, 75.0, 0.001, "headless: nilai langsung tepat")


func test_ui_motion_pop_in_makes_control_visible() -> void:
	var panel := PanelContainer.new()
	add_child_autofree(panel)
	panel.visible = false
	UiMotion.pop_in(panel)
	assert_true(panel.visible)
	assert_almost_eq(panel.modulate.a, 1.0, 0.001)


func test_vignette_strength_is_clamped() -> void:
	var vignette: CanvasLayer = load(VIGNETTE_PATH).new()
	add_child_autofree(vignette)
	vignette.call(&"_set_strength", 5.0)
	assert_almost_eq(vignette.call(&"get_strength"), vignette.get(&"max_strength"), 0.001)
	vignette.call(&"_set_strength", -2.0)
	assert_almost_eq(vignette.call(&"get_strength"), 0.0, 0.001)


func test_ambient_life_toggles_with_night() -> void:
	var ambient: Node2D = load(AMBIENT_PATH).new()
	add_child_autofree(ambient)
	await wait_physics_frames(1)
	ambient.call(&"_apply_night", true)
	assert_true(ambient.call(&"is_night_mode"), "malam: kunang-kunang aktif")
	ambient.call(&"_apply_night", false)
	assert_false(ambient.call(&"is_night_mode"), "siang: kunang-kunang mati")


func test_camp_arrow_glyphs() -> void:
	var arrow: CanvasLayer = load("res://src/ui/hud/compass/camp_arrow.gd").new()
	add_child_autofree(arrow)
	assert_eq(arrow.call(&"_glyph", Vector2.RIGHT), "→")
	assert_eq(arrow.call(&"_glyph", Vector2.DOWN), "↓")
	assert_eq(arrow.call(&"_glyph", Vector2.LEFT), "←")
	assert_eq(arrow.call(&"_glyph", Vector2.UP), "↑")


func test_settings_fullscreen_roundtrip() -> void:
	var service := SettingsService.new()
	add_child_autofree(service)
	service.set_value(&"fullscreen", true)
	assert_true(service.is_fullscreen())
	service.set_value(&"fullscreen", false)
	assert_false(service.is_fullscreen())


func test_gamepad_bindings_registered() -> void:
	var has_axis := false
	for event in InputMap.action_get_events(InputSetup.MOVE_LEFT):
		if event is InputEventJoypadMotion:
			has_axis = true
	assert_true(has_axis, "stik kiri menggerakkan pemain")

	var has_button := false
	for event in InputMap.action_get_events(InputSetup.INTERACT):
		if event is InputEventJoypadButton:
			has_button = true
	assert_true(has_button, "tombol A berinteraksi")


func test_hint_channel_shows_one_prompt_at_a_time() -> void:
	var manager := HintManager.new()
	add_child_autofree(manager)
	manager.show_text(&"opening_0", "Satu", 2.0)
	manager.show_text(&"opening_1", "Dua", 2.0)
	assert_true(manager.is_showing())
	assert_eq(manager.get_current(), &"opening_0")
	assert_eq(manager.get_queue_size(), 1, "prompt kedua mengantre, tidak menimpa")
	assert_eq(manager.get_text(&"opening_0"), "Satu")
	manager.skip_current()
	assert_eq(manager.get_current(), &"opening_1")


func test_opening_sequence_uses_shared_hint_channel() -> void:
	var host := Node.new()
	add_child_autofree(host)
	var manager := HintManager.new()
	manager.name = "HintManager"
	host.add_child(manager)
	var opening: Node = load("res://src/ui/hud/hints/opening_sequence.gd").new()
	opening.call(&"reset_played")
	host.add_child(opening)
	await wait_process_frames(2)
	assert_true(opening.call(&"is_running"), "urutan pembuka berjalan")
	assert_eq(manager.get_current(), &"opening_0", "memakai saluran HintManager")


func test_camp_arrow_is_anchored_to_viewport() -> void:
	var arrow: CanvasLayer = load("res://src/ui/hud/compass/camp_arrow.gd").new()
	add_child_autofree(arrow)
	var label: Label = arrow.call(&"get_label") as Label
	assert_almost_eq(label.anchor_left, 1.0, 0.001, "menempel kanan viewport")
	assert_almost_eq(label.anchor_right, 1.0, 0.001)


func test_death_slow_mo_respects_screenshake_setting() -> void:
	var service := SettingsService.new()
	add_child_autofree(service)
	var host := Node.new()
	add_child_autofree(host)
	var fx: Node = load("res://src/ui/fx/death_fx.gd").new()
	host.add_child(fx)
	service.set_value(&"screenshake_enabled", true)
	assert_true(fx.call(&"is_slow_mo_enabled"))
	service.set_value(&"screenshake_enabled", false)
	assert_false(fx.call(&"is_slow_mo_enabled"), "setelan shake mematikan slow-mo")


func test_opening_prompts_outrank_gameplay_hints() -> void:
	var manager := HintManager.new()
	add_child_autofree(manager)
	manager.show_text(&"opening_0", "Intro", 2.0)
	manager.trigger(&"gather")
	assert_eq(manager.get_current(), &"opening_0", "intro sedang tampil")
	manager.show_text(&"opening_1", "Intro 2", 2.0)
	manager.skip_current()
	assert_eq(manager.get_current(), &"opening_1", "prompt pembuka mengalahkan antrean gameplay")
	manager.skip_current()
	assert_eq(manager.get_current(), &"gather", "hint gameplay tetap tampil setelah intro")


func test_opening_step_is_not_cut_by_gather_hint() -> void:
	var host := Node.new()
	add_child_autofree(host)
	var manager := HintManager.new()
	manager.name = "HintManager"
	host.add_child(manager)
	var opening: Node = load("res://src/ui/hud/hints/opening_sequence.gd").new()
	opening.call(&"reset_played")
	host.add_child(opening)
	await wait_process_frames(2)
	assert_eq(manager.get_current(), &"opening_0")

	manager.trigger(&"gather")
	manager.skip_current()
	assert_eq(manager.get_current(), &"opening_1", "gather tidak memotong langkah intro")

	manager.skip_current()
	assert_eq(manager.get_current(), &"opening_2")
	manager.skip_current()
	assert_eq(manager.get_current(), &"gather", "setelah intro, hint gameplay jalan")

extends GutTest

## Mission 7 / Phase 5: recap, flash, banner, survival HUD.

class StubClock extends Node:
	var night := true
	var day := 3
	var remaining := 90.0
	func is_night() -> bool: return night
	func get_current_day() -> int: return day
	func get_phase_duration() -> float: return 120.0
	func get_time_scale() -> float: return 1.0
	func set_time_scale(value: float) -> void: pass

class StubEndgame extends Node:
	var rescue := true
	func is_rescue_active() -> bool: return rescue


class StubSpawner extends Node:
	var hostile := 2
	func get_hostile_count() -> int: return hostile


func test_recap_text_and_visibility() -> void:
	var hud := RespawnRecapHUD.new()
	add_child_autofree(hud)
	assert_eq(hud.format_recap([]), "Tidak ada debuff")
	var changes := [{"prof": 0, "from_level": 4, "to_level": 3}]
	hud.show_recap(changes)
	assert_true(hud.is_showing())
	assert_string_contains(hud.get_text(), "Kekuatan Lv 4 -> 3")
	hud.tick(RespawnRecapHUD.SHOW_TIME + 0.1)
	assert_false(hud.is_showing(), "toast hilang setelah 8 s")


func test_proficiency_rows_flash_red_three_seconds() -> void:
	var hud := ProficiencyHUD.new()
	add_child_autofree(hud)
	hud.flash_rows([{"prof": 1, "from_level": 3, "to_level": 2}])
	assert_true(hud.is_row_flashing(1))
	hud.tick(1.0)
	assert_true(hud.is_row_flashing(1))
	hud.tick(2.5)
	assert_false(hud.is_row_flashing(1), "flash 3 s")


func test_night_banner_texts_and_skip_dawn() -> void:
	var banner := NightBanner.new()
	add_child_autofree(banner)
	banner.show_night(4)
	assert_string_contains(banner.get_text(), "Malam 4 dimulai")
	assert_false(banner.get_text().contains("Ember Snuff"), "ember snuff dari malam 5")
	banner.show_night(5)
	assert_string_contains(banner.get_text(), "Ember Snuff aktif")
	banner.show_dawn(3)
	assert_string_contains(banner.get_text(), "Fajar hari 3 - kamu selamat dari malam 2")
	banner.tick(NightBanner.SHOW_TIME + 0.1)
	assert_false(banner.is_showing())

	var endgame := StubEndgame.new()
	add_child_autofree(endgame)
	banner.endgame = endgame
	banner.show_night(7)
	var before := banner.get_text()
	banner._on_day_started(7)
	assert_eq(banner.get_text(), before, "banner rescue menang, fajar dilewati")


func test_survival_hud_values_and_day_hidden() -> void:
	var clock := StubClock.new()
	add_child_autofree(clock)
	var spawner := StubSpawner.new()
	add_child_autofree(spawner)
	var scaling := NightScalingConfig.new()
	var hud := NightSurvivalHUD.new()
	hud.clock = clock
	hud.spawner = spawner
	hud.scaling = scaling
	add_child_autofree(hud)

	hud.set_day(3)
	hud.set_remaining(90.0)
	hud.tick(0.016)
	assert_true(hud.visible, "tampil saat malam")
	assert_string_contains(hud.get_text(), "Malam 3")
	assert_string_contains(hud.get_text(), "Bertahan 01:30")
	assert_string_contains(hud.get_text(), "Musuh 2/%d" % scaling.get_max_enemies(3))
	assert_almost_eq(hud.get_progress_ratio(), 0.75, 0.01)

	clock.night = false
	hud.tick(0.016)
	assert_false(hud.visible, "sembunyi saat siang")

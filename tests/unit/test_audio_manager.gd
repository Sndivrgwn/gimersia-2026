extends GutTest

## Verifikasi AudioManager, bus layout, ketersediaan aset Prioritas 1,
## crossfade ambience hutan <-> pantai (ocean + wind), dan fauna sengaja kosong.


func _audio() -> Node:
	return get_node_or_null("/root/AudioManager")


func test_autoload_and_buses_exist() -> void:
	var audio := _audio()
	assert_not_null(audio, "AudioManager autoload harus aktif")
	for bus_name in [&"Master", &"Music", &"SFX", &"Ambience", &"UI"]:
		assert_ne(AudioServer.get_bus_index(bus_name), -1, "Bus %s harus ada" % String(bus_name))


func test_all_priority_one_cues_have_audio() -> void:
	var audio := _audio()
	var p1_cues := [
		&"campfire_loop",
		&"craft_done",
		&"gathering_chop_hit",
		&"gathering_tree_fall",
		&"item_pickup",
		&"player_attack_swing",
		&"player_death",
		&"player_footstep_sand",
		&"player_hit_flesh",
		&"player_hurt",
		&"ambience_night",
		&"ui_click",
	]
	for key in p1_cues:
		assert_true(audio.has_cue_audio(key), "Cue P1 %s harus punya file .ogg" % String(key))


func test_fauna_cues_remain_empty_as_requested() -> void:
	var audio := _audio()
	for key in [&"boar_alert", &"boar_hurt", &"boar_death", &"deer_alert_snort", &"deer_hurt", &"deer_death"]:
		assert_false(audio.has_cue_audio(key), "Cue fauna %s harus kosong dulu" % String(key))


func test_ambience_crossfade_forest_to_beach_ocean_and_wind() -> void:
	var audio := _audio()
	assert_true(audio.has_cue_audio(&"ambience_day"), "ambience_day (forest) harus ada")
	assert_true(audio.has_cue_audio(&"ambience_beach_ocean"), "ambience_beach_ocean harus ada")
	assert_true(audio.has_cue_audio(&"ambience_beach_wind"), "ambience_beach_wind harus ada")

	# Siang di hutan -> hanya ambience_day
	audio.set_ambience_state(IslandZones.Zone.FOREST, false, true)
	assert_gt(audio.get_ambience_current(&"ambience_day"), 0.5)
	assert_almost_eq(audio.get_ambience_current(&"ambience_beach_ocean"), 0.0, 0.001)
	assert_almost_eq(audio.get_ambience_current(&"ambience_beach_wind"), 0.0, 0.001)

	# Pindah ke pantai -> target berubah ke ocean + wind, forest turun ke 0
	audio.set_ambience_state(IslandZones.Zone.SOUTH_BEACH, false, false)
	assert_almost_eq(audio.get_ambience_target(&"ambience_day"), 0.0, 0.001)
	assert_gt(audio.get_ambience_target(&"ambience_beach_ocean"), 0.5)
	assert_gt(audio.get_ambience_target(&"ambience_beach_wind"), 0.3)

	# Simulasi setengah transisi -> crossfade bertahap (tidak langsung lompat)
	audio._tick_ambience(0.5)
	assert_gt(audio.get_ambience_current(&"ambience_day"), 0.0)
	assert_gt(audio.get_ambience_current(&"ambience_beach_ocean"), 0.0)
	assert_gt(audio.get_ambience_current(&"ambience_beach_wind"), 0.0)

	# Simulasi selesai transisi
	audio._tick_ambience(3.0)
	assert_almost_eq(audio.get_ambience_current(&"ambience_day"), 0.0, 0.001)
	assert_almost_eq(audio.get_ambience_current(&"ambience_beach_ocean"), audio.get_ambience_target(&"ambience_beach_ocean"), 0.001)
	assert_almost_eq(audio.get_ambience_current(&"ambience_beach_wind"), audio.get_ambience_target(&"ambience_beach_wind"), 0.001)

	audio.stop_ambience(true)


func test_play_missing_cue_is_safe_noop() -> void:
	var audio := _audio()
	var player = audio.play(&"cue_yang_tidak_ada")
	assert_null(player, "Cue tanpa file harus mengembalikan null tanpa error")


func test_pause_menu_emits_paused_and_resumed() -> void:
	var menu := PauseMenu.new()
	add_child_autofree(menu)
	watch_signals(menu)
	assert_true(menu.open())
	assert_signal_emitted(menu, &"paused")
	menu.close()
	assert_signal_emitted(menu, &"resumed")

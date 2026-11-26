extends GutTest

## Mission 13: sapuan fajar/senja.
## Fungsi murni SunSweep (mask, rim, ratio, plan), overlay di scene
## DayNightVisual, satu CanvasModulate, arc matahari, dan nilai SunConfig.

const VISUAL_SCENE: PackedScene = preload("res://src/levels/components/environment/day_night_visual.tscn")
const SUN_CONFIG: SunConfig = preload("res://src/data/configs/environment/sun_config.tres")
const RIGHT := SunConfig.Side.RIGHT
const LEFT := SunConfig.Side.LEFT

const DAY_COLOR := Color(1.0, 0.96, 0.88, 1.0)
const EVENING_COLOR := Color(1.0, 0.68, 0.45, 1.0)
const NIGHT_COLOR := Color(0.34, 0.42, 0.66, 1.0)


# --- mask -------------------------------------------------------------------

func test_dawn_from_right_lights_the_right_side_first() -> void:
	assert_almost_eq(SunSweep.mask(0.0, RIGHT, 0.0, 0.9), 0.0, 0.001, "belum ada cahaya")
	assert_almost_eq(SunSweep.mask(0.5, RIGHT, 0.0, 0.9), 1.0, 0.001, "kanan sudah terang")
	assert_almost_eq(SunSweep.mask(0.5, RIGHT, 0.0, 0.1), 0.0, 0.001, "kiri masih gelap")
	assert_almost_eq(SunSweep.mask(1.0, RIGHT, 0.0, 0.0), 1.0, 0.001, "akhirnya seluruh layar")


func test_dawn_from_left_is_mirrored() -> void:
	assert_almost_eq(SunSweep.mask(0.5, LEFT, 0.0, 0.1), 1.0, 0.001, "kiri sudah terang")
	assert_almost_eq(SunSweep.mask(0.5, LEFT, 0.0, 0.9), 0.0, 0.001, "kanan masih gelap")
	assert_almost_eq(SunSweep.mask(0.0, LEFT, 0.0, 0.5), 0.0, 0.001, "awal transisi: tengah layar gelap")


func test_dusk_uses_the_opposite_side_of_dawn() -> void:
	assert_eq(SUN_CONFIG.dusk_side(), LEFT, "fajar dari kanan -> senja dari kiri")
	assert_eq(SUN_CONFIG.side_for(true), RIGHT, "transisi malam->pagi = fajar")
	assert_eq(SUN_CONFIG.side_for(false), LEFT, "transisi siang->malam = senja")
	# Senja: bagian yang dilewati front justru menjadi gelap.
	var dusk := SunSweep.plan(SUN_CONFIG, false, 30.0, 60.0, DAY_COLOR, EVENING_COLOR, NIGHT_COLOR)
	assert_true(bool(dusk["sweep"]), "sapuan aktif")
	assert_eq(int(dusk["side"]), LEFT)
	assert_almost_eq(float(dusk["progress"]), 0.5, 0.001, "setengah jalan setelah 30 s dari 60 s")


func test_softness_controls_the_band_edges() -> void:
	# Front di x = 0.5 untuk progress 0.5 dari kanan; tepi selebar 0.2.
	assert_almost_eq(SunSweep.mask(0.5, RIGHT, 0.2, 0.3), 0.0, 0.001, "tepi luar band")
	assert_almost_eq(SunSweep.mask(0.5, RIGHT, 0.2, 0.5), 1.0, 0.001, "tepi dalam band")
	assert_almost_eq(SunSweep.mask(0.5, RIGHT, 0.2, 0.4), 0.5, 0.01, "tengah band = setengah terang")
	assert_lt(SunSweep.mask(0.5, RIGHT, 0.2, 0.35), SunSweep.mask(0.5, RIGHT, 0.2, 0.45), "naik monoton")
	assert_almost_eq(SunSweep.rim(0.5, RIGHT, 0.2, 0.5), 1.0, 0.001, "pita hangat tepat di front")
	assert_almost_eq(SunSweep.rim(0.5, RIGHT, 0.2, 0.1), 0.0, 0.001, "jauh dari front")


# --- ratio & plan -----------------------------------------------------------

func test_ratio_only_darkens_and_is_clamped() -> void:
	var result := SunSweep.ratio(Color(1.0, 0.8, 0.5), Color(0.5, 1.2, 0.2))
	assert_almost_eq(result.r, 0.5, 0.001)
	assert_almost_eq(result.g, 1.0, 0.001, "kanal target > 1 dijepit ke 1")
	assert_almost_eq(result.b, 0.4, 0.001)
	for channel in [result.r, result.g, result.b]:
		assert_lte(channel, 1.0, "multiply tidak boleh mencerahkan")
	var zero := SunSweep.ratio(Color(0.0, 0.0, 0.0), Color(0.5, 0.5, 0.5))
	assert_almost_eq(zero.r, 1.0, 0.001, "kanal nol tidak bisa digelapkan")


func test_plan_uses_the_brighter_endpoint_and_the_target_ratio() -> void:
	var dusk := SunSweep.plan(SUN_CONFIG, false, 30.0, 60.0, DAY_COLOR, EVENING_COLOR, NIGHT_COLOR)
	assert_eq(dusk["color"], DAY_COLOR, "CanvasModulate memakai endpoint terang")
	var target := DayLightCurve.blend_through(DAY_COLOR, EVENING_COLOR, NIGHT_COLOR, 0.5)
	assert_eq(dusk["target"], target, "target = blend seragam lama")
	assert_eq(dusk["ratio"], SunSweep.ratio(DAY_COLOR, target))

	var dawn := SunSweep.plan(SUN_CONFIG, true, 30.0, 60.0, NIGHT_COLOR, Color(0.95, 0.8, 0.68, 1.0), DAY_COLOR)
	assert_eq(dawn["color"], DAY_COLOR, "fajar: endpoint terang adalah siang")
	assert_eq(int(dawn["side"]), RIGHT)


func test_plan_falls_back_to_the_uniform_transition_when_disabled() -> void:
	var disabled := SunConfig.new()
	disabled.sweep_enabled = false
	var plan := SunSweep.plan(disabled, false, 30.0, 60.0, DAY_COLOR, EVENING_COLOR, NIGHT_COLOR)
	assert_false(bool(plan["sweep"]), "tanpa sapuan")
	assert_eq(plan["color"], DayLightCurve.blend_through(DAY_COLOR, EVENING_COLOR, NIGHT_COLOR, 0.5),
		"warna = blend seragam lama")
	assert_eq(plan["ratio"], Color.WHITE)
	assert_eq(plan["color"], plan["target"])


func test_plan_without_config_is_the_old_behaviour() -> void:
	var plan := SunSweep.plan(null, true, 10.0, 60.0, NIGHT_COLOR, Color.WHITE, DAY_COLOR)
	assert_false(bool(plan["sweep"]))
	var progress := DayLightCurve.transition_progress(10.0, 60.0)
	assert_eq(plan["color"], DayLightCurve.blend_through(NIGHT_COLOR, Color.WHITE, DAY_COLOR, progress))


# --- Scene wiring -----------------------------------------------------------

func test_overlay_exists_below_the_hud_and_there_is_one_canvas_modulate() -> void:
	var visual := VISUAL_SCENE.instantiate() as DayNightVisual
	add_child_autofree(visual)
	await wait_frames(1)

	var overlay := visual.get_node_or_null("SunSweepOverlay") as SunSweepOverlay
	assert_not_null(overlay, "overlay sapuan ada di scene")
	assert_eq(overlay.layer, SunSweepOverlay.LAYER)
	assert_lt(overlay.layer, 10, "di bawah layer HUD (TimeHUD = 10)")
	assert_gt(overlay.layer, SunOverlay.LAYER, "di atas gradien matahari")
	assert_false(overlay.is_sweeping(), "mulai tanpa sapuan")

	var modulators := 0
	for node in visual.find_children("*", "CanvasModulate", true, false):
		modulators += 1
	assert_eq(modulators, 1, "DayNightVisual tetap punya tepat satu CanvasModulate")
	assert_null(overlay.get_node_or_null("CanvasModulate"), "overlay tidak menambah CanvasModulate")

	var island := FileAccess.get_file_as_string("res://src/levels/island/island.tscn")
	assert_false(island.contains("type=\"CanvasModulate\""), "island.tscn hanya meng-instance DayNightVisual")
	var visual_scene := FileAccess.get_file_as_string("res://src/levels/components/environment/day_night_visual.tscn")
	assert_eq(visual_scene.count("type=\"CanvasModulate\""), 1, "satu CanvasModulate di seluruh island")


class StubManager extends Node:
	signal phase_changed(phase: int)
	var night := false
	var remaining := 30.0
	var progress := 0.5

	func is_night() -> bool:
		return night

	func get_remaining_seconds() -> float:
		return remaining

	func get_phase_progress() -> float:
		return progress


func test_transition_sweeps_and_falls_back_when_disabled() -> void:
	var visual := VISUAL_SCENE.instantiate() as DayNightVisual
	add_child_autofree(visual)
	await wait_frames(1)
	var manager := StubManager.new()
	add_child_autofree(manager)
	visual.set("_manager", manager)

	var overlay := visual.get_node("SunSweepOverlay") as SunSweepOverlay
	var modulate := visual.get_node("CanvasModulate") as CanvasModulate
	var config := visual.visual_config
	var day := config.get_effective_color(DayNightVisualConfig.Atmosphere.DAY)

	# Senja (siang -> malam) setengah jalan: sapuan aktif, modulate = siang.
	visual.call(&"_update_visuals")
	assert_true(overlay.is_sweeping(), "transisi menyapu")
	assert_eq(modulate.color, Color(day.r, day.g, day.b, 1.0), "CanvasModulate = endpoint terang")
	assert_almost_eq(overlay.get_mask_value(0.9), 0.0, 0.05, "front senja masuk dari kiri")
	assert_almost_eq(overlay.get_mask_value(0.1), 1.0, 0.05, "kiri sudah gelap")

	# Sapuan dimatikan: overlay bersih dan warna kembali ke blend seragam.
	var disabled := SunConfig.new()
	disabled.sweep_enabled = false
	visual.sun_config = disabled
	visual.call(&"_update_visuals")
	assert_false(overlay.is_sweeping(), "nonaktif: overlay tidak menyentuh layar")
	var target := DayLightCurve.blend_through(
		day,
		config.get_effective_color(DayNightVisualConfig.Atmosphere.EVENING),
		config.get_effective_color(DayNightVisualConfig.Atmosphere.NIGHT),
		0.5
	)
	assert_eq(modulate.color, Color(target.r, target.g, target.b, 1.0), "warna = fade lama")


func test_overlay_applies_and_clears_the_mask() -> void:
	var overlay := SunSweepOverlay.new()
	add_child_autofree(overlay)
	await wait_frames(1)
	overlay.apply(0.5, RIGHT, 0.1, 0.25, Color(0.5, 0.5, 0.5, 1.0))
	assert_true(overlay.is_sweeping())
	assert_almost_eq(overlay.get_mask_value(0.95), 1.0, 0.02, "kanan sudah dilewati")
	assert_almost_eq(overlay.get_mask_value(0.05), 0.0, 0.02, "kiri belum dilewati")
	overlay.clear()
	assert_false(overlay.is_sweeping())


# --- SunArc & config --------------------------------------------------------

func test_sun_arc_rises_on_the_dawn_side() -> void:
	var start := SunArc.arc_position(0.0, RIGHT)
	var noon := SunArc.arc_position(0.5, RIGHT)
	var end := SunArc.arc_position(1.0, RIGHT)
	assert_almost_eq(start.x, 1.0, 0.001, "terbit di kanan")
	assert_almost_eq(start.y, 1.0, 0.001, "di dasar busur")
	assert_almost_eq(noon.x, 0.5, 0.001)
	assert_almost_eq(noon.y, 0.0, 0.001, "tengah fase di puncak")
	assert_almost_eq(end.x, 0.0, 0.001, "turun di kiri")
	assert_almost_eq(SunArc.arc_position(0.0, LEFT).x, 0.0, 0.001, "sisi fajar kiri dicerminkan")


func test_sun_config_values() -> void:
	assert_true(SUN_CONFIG.sweep_enabled)
	assert_eq(SUN_CONFIG.dawn_side, RIGHT)
	assert_almost_eq(SUN_CONFIG.dawn_sweep_seconds, 60.0, 0.001, "= transition_duration visual")
	assert_almost_eq(SUN_CONFIG.dusk_sweep_seconds, 60.0, 0.001)
	assert_almost_eq(SUN_CONFIG.softness, 0.35, 0.001)
	assert_almost_eq(SUN_CONFIG.warm_rim_strength, 0.25, 0.001)
	assert_true(SUN_CONFIG.sun_arc_enabled)


func test_dusk_and_dawn_have_no_color_jump_at_phase_boundaries() -> void:
	var visual_cfg := DayNightVisualConfig.new()
	var day := visual_cfg.get_effective_color(DayNightVisualConfig.Atmosphere.DAY)
	var evening := visual_cfg.get_effective_color(DayNightVisualConfig.Atmosphere.EVENING)
	var morning := visual_cfg.get_effective_color(DayNightVisualConfig.Atmosphere.MORNING)
	var night := visual_cfg.get_effective_color(DayNightVisualConfig.Atmosphere.NIGHT)

	# Senja (DAY -> NIGHT): darken_swept = true, tidak loncat di awal maupun akhir.
	var dusk_start := SunSweep.plan(SUN_CONFIG, false, 60.0, 60.0, day, evening, night)
	var dusk_mid := SunSweep.plan(SUN_CONFIG, false, 30.0, 60.0, day, evening, night)
	var dusk_end := SunSweep.plan(SUN_CONFIG, false, 0.05, 60.0, day, evening, night)
	assert_true(bool(dusk_start["darken_swept"]))
	assert_true(bool(dusk_end["darken_swept"]))

	# Tengah senja: sisi kiri (sudah dilewati front) lebih gelap daripada sisi kanan.
	var mid_left := SunSweep.screen_color(dusk_mid, SUN_CONFIG.softness, SUN_CONFIG.warm_rim_strength, 0.0)
	var mid_right := SunSweep.screen_color(dusk_mid, SUN_CONFIG.softness, SUN_CONFIG.warm_rim_strength, 1.0)
	assert_lt(DayLightCurve.luminance(mid_left), DayLightCurve.luminance(mid_right), "senja menggelapkan sisi yang dilewati front")

	# Awal senja = DAY, 0.05s sebelum malam = NIGHT di seluruh lebar layar (tanpa loncat).
	for x in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var c_start := SunSweep.screen_color(dusk_start, SUN_CONFIG.softness, SUN_CONFIG.warm_rim_strength, x)
		var c_end := SunSweep.screen_color(dusk_end, SUN_CONFIG.softness, SUN_CONFIG.warm_rim_strength, x)
		assert_almost_eq(c_start.r, day.r, 0.02, "awal senja mulus dari DAY (x=%.2f)" % x)
		assert_almost_eq(c_start.g, day.g, 0.02)
		assert_almost_eq(c_start.b, day.b, 0.02)
		assert_almost_eq(c_end.r, night.r, 0.02, "akhir senja mulus ke NIGHT (x=%.2f)" % x)
		assert_almost_eq(c_end.g, night.g, 0.02)
		assert_almost_eq(c_end.b, night.b, 0.02)

	# Fajar (NIGHT -> DAY): darken_swept = false, mulus dari NIGHT ke DAY.
	var dawn_start := SunSweep.plan(SUN_CONFIG, true, 60.0, 60.0, night, morning, day)
	var dawn_end := SunSweep.plan(SUN_CONFIG, true, 0.05, 60.0, night, morning, day)
	assert_false(bool(dawn_start["darken_swept"]))
	for x in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var d_start := SunSweep.screen_color(dawn_start, SUN_CONFIG.softness, SUN_CONFIG.warm_rim_strength, x)
		var d_end := SunSweep.screen_color(dawn_end, SUN_CONFIG.softness, SUN_CONFIG.warm_rim_strength, x)
		assert_almost_eq(d_start.r, night.r, 0.02, "awal fajar mulus dari NIGHT (x=%.2f)" % x)
		assert_almost_eq(d_end.r, day.r, 0.02, "akhir fajar mulus ke DAY (x=%.2f)" % x)

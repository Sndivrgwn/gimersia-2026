extends GutTest

## Mission 14 (J8): unit test murni untuk IrisTransition (tanpa scene, delta nyata).


func _cfg(ease_mode: int = SplashConfig.TransitionEase.EASE_OUT) -> SplashConfig:
	var cfg := SplashConfig.new()
	cfg.transition_enabled = true
	cfg.transition_hold_before = 0.2
	cfg.transition_duration = 0.8
	cfg.transition_start_radius = 0.0
	cfg.transition_ease = ease_mode
	return cfg


func test_radius_is_zero_during_hold_then_rises_monotonically_to_one() -> void:
	var cfg := _cfg(SplashConfig.TransitionEase.EASE_OUT)
	var tr := IrisTransition.new()
	var finished_count := [0]
	tr.finished.connect(func() -> void: finished_count[0] += 1)
	tr.setup(cfg)

	assert_almost_eq(tr.radius(), 0.0, 0.0001)
	assert_false(tr.is_finished())

	# Selama hold (0.2 s), radius tetap 0.
	tr.tick(0.1)
	assert_almost_eq(tr.radius(), 0.0, 0.0001, "tengah hold = 0")
	tr.tick(0.09)
	assert_almost_eq(tr.radius(), 0.0, 0.0001, "akhir hold = 0")

	# Naik monoton hingga tepat 1.0 di akhir.
	var prev := tr.radius()
	for _i in 20:
		tr.tick(0.05)
		var cur := tr.radius()
		assert_gte(cur, prev, "radius tidak pernah turun")
		assert_lte(cur, 1.0, "radius ter-clamp <= 1.0")
		prev = cur

	assert_almost_eq(tr.radius(), 1.0, 0.0001, "tepat 1.0 di akhir")
	assert_true(tr.is_finished())
	assert_eq(finished_count[0], 1, "signal finished tepat sekali")

	# Tick tambahan tidak memancarkan finished lagi.
	tr.tick(0.5)
	assert_eq(finished_count[0], 1)


func test_all_ease_curves_are_valid_clamped_and_monotonic() -> void:
	for mode in [
		SplashConfig.TransitionEase.LINEAR,
		SplashConfig.TransitionEase.EASE_OUT,
		SplashConfig.TransitionEase.EASE_IN_OUT,
	]:
		var cfg := _cfg(mode)
		cfg.transition_hold_before = 0.0
		cfg.transition_duration = 1.0
		cfg.transition_start_radius = 0.1
		var tr := IrisTransition.new()
		tr.setup(cfg)
		var prev := 0.0
		for _i in 20:
			tr.tick(0.05)
			var r := tr.radius()
			assert_gte(r, prev)
			assert_gte(r, 0.0)
			assert_lte(r, 1.0)
			prev = r
		assert_almost_eq(tr.radius(), 1.0, 0.0001)
		assert_true(tr.is_finished())

	# Cek pembeda kurva di t = 0.5: EASE_OUT > LINEAR (0.5).
	var lin := IrisTransition.new()
	var cfg_lin := _cfg(SplashConfig.TransitionEase.LINEAR)
	cfg_lin.transition_hold_before = 0.0
	cfg_lin.transition_duration = 1.0
	lin.setup(cfg_lin)
	lin.tick(0.5)

	var out := IrisTransition.new()
	var cfg_out := _cfg(SplashConfig.TransitionEase.EASE_OUT)
	cfg_out.transition_hold_before = 0.0
	cfg_out.transition_duration = 1.0
	out.setup(cfg_out)
	out.tick(0.5)

	assert_almost_eq(lin.radius(), 0.5, 0.001)
	assert_gt(out.radius(), lin.radius(), "EASE_OUT lebih besar di tengah daripada LINEAR")


func test_max_radius_px_covers_corners_for_multiple_aspects() -> void:
	# 16:9 (1280x720) -> sqrt(640^2 + 360^2)
	var r_16_9 := IrisTransition.max_radius_px(Vector2(1280.0, 720.0))
	assert_almost_eq(r_16_9, Vector2(640.0, 360.0).length(), 0.01)
	# 4:3 (1024x768) -> sqrt(512^2 + 384^2) = 640.0
	var r_4_3 := IrisTransition.max_radius_px(Vector2(1024.0, 768.0))
	assert_almost_eq(r_4_3, 640.0, 0.01)
	# Potret (720x1280) -> sama dengan 16:9
	var r_portrait := IrisTransition.max_radius_px(Vector2(720.0, 1280.0))
	assert_almost_eq(r_portrait, Vector2(360.0, 640.0).length(), 0.01)


func test_reset_restarts_from_zero_and_can_finish_again() -> void:
	var cfg := _cfg(SplashConfig.TransitionEase.LINEAR)
	cfg.transition_hold_before = 0.1
	cfg.transition_duration = 0.4
	var tr := IrisTransition.new()
	var finished_count := [0]
	tr.finished.connect(func() -> void: finished_count[0] += 1)
	tr.setup(cfg)

	tr.tick(0.6)
	assert_true(tr.is_finished())
	assert_eq(finished_count[0], 1)

	tr.reset()
	assert_almost_eq(tr.elapsed(), 0.0, 0.0001)
	assert_almost_eq(tr.radius(), 0.0, 0.0001)
	assert_false(tr.is_finished())

	tr.tick(0.6)
	assert_true(tr.is_finished())
	assert_eq(finished_count[0], 2)

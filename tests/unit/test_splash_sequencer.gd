extends GutTest

## Mission 14 (Block J): unit test murni untuk SplashSequencer (tanpa scene,
## hanya delta nyata).


func _entry(hold: float = 1.0, fade_in: float = 0.5, fade_out: float = 0.5) -> SplashEntry:
	var item := SplashEntry.new()
	item.asset_key = &"ui_splash_studio"
	item.fallback_text = "STUDIO"
	item.fallback_font_size = 48
	item.hold_seconds = hold
	item.fade_in = fade_in
	item.fade_out = fade_out
	return item


func _config(entries: Array[SplashEntry]) -> SplashConfig:
	var cfg := SplashConfig.new()
	cfg.enabled = true
	cfg.entries = entries
	cfg.skip_enabled = true
	cfg.skip_min_seconds = 0.4
	cfg.bar_smooth_speed = 1.5
	cfg.min_total_seconds = 2.0
	cfg.max_wait_seconds = 15.0
	return cfg


func test_alpha_ramps_and_entry_signals_in_order() -> void:
	var cfg := _config([_entry(1.0, 0.5, 0.5), _entry(0.8, 0.4, 0.4)])
	cfg.min_total_seconds = 0.0
	var seq := SplashSequencer.new()
	var events: Array[String] = []
	seq.entry_started.connect(func(i: int) -> void: events.append("start:%d" % i))
	seq.entry_finished.connect(func(i: int) -> void: events.append("end:%d" % i))
	seq.finished.connect(func(f: bool) -> void: events.append("done:%s" % str(f)))
	seq.setup(cfg)

	assert_eq(seq.state(), SplashSequencer.State.PLAYING)
	assert_eq(seq.entry_index(), 0)
	assert_almost_eq(seq.entry_alpha(), 0.0, 0.001, "awal fade_in = 0")

	seq.tick(0.25)
	assert_almost_eq(seq.entry_alpha(), 0.5, 0.001, "tengah fade_in = 0.5")
	seq.tick(0.25)
	assert_almost_eq(seq.entry_alpha(), 1.0, 0.001, "akhir fade_in = 1.0")
	seq.tick(0.5)
	assert_almost_eq(seq.entry_alpha(), 1.0, 0.001, "selama hold = 1.0")
	seq.tick(0.75)
	assert_almost_eq(seq.entry_alpha(), 0.5, 0.001, "tengah fade_out = 0.5")

	# Masuk entri ke-2 (batas 2.0 s, sisa 0.2 s di fade_in 0.4 s -> alpha 0.5).
	seq.tick(0.45)
	assert_eq(seq.entry_index(), 1)
	assert_almost_eq(seq.entry_alpha(), 0.5, 0.01, "transisi ke entri kedua")

	# Selesaikan entri ke-2 tanpa load_done -> harus menunggu di WAITING_LOAD.
	seq.tick(2.0)
	assert_eq(seq.state(), SplashSequencer.State.WAITING_LOAD)
	assert_false(seq.is_finished())
	assert_eq(events, ["start:0", "end:0", "start:1", "end:1"])

	seq.notify_load_done(true)
	assert_eq(seq.state(), SplashSequencer.State.DONE)
	assert_true(seq.is_finished())
	assert_false(seq.failed())
	assert_eq(events, ["start:0", "end:0", "start:1", "end:1", "done:false"])

	# Sinyal finished hanya terpancar sekali.
	seq.tick(1.0)
	seq.notify_load_done(true)
	assert_eq(events.size(), 5)


func test_skip_respects_min_seconds_and_flag() -> void:
	var cfg := _config([_entry(2.0, 0.5, 0.5)])
	cfg.skip_min_seconds = 0.5
	cfg.min_total_seconds = 0.0
	var seq := SplashSequencer.new()
	seq.setup(cfg)

	seq.tick(0.2)
	seq.skip()
	assert_eq(seq.state(), SplashSequencer.State.PLAYING, "skip sebelum skip_min_seconds diabaikan")

	seq.tick(0.35)
	seq.skip()
	assert_eq(seq.state(), SplashSequencer.State.WAITING_LOAD, "skip setelah skip_min_seconds pindah ke WAITING_LOAD")

	# Saat skip_enabled = false, skip selalu diabaikan.
	var no_skip_cfg := _config([_entry(2.0, 0.5, 0.5)])
	no_skip_cfg.skip_enabled = false
	var seq2 := SplashSequencer.new()
	seq2.setup(no_skip_cfg)
	seq2.tick(1.0)
	seq2.skip()
	assert_eq(seq2.state(), SplashSequencer.State.PLAYING)


func test_min_total_seconds_is_respected_after_skip_and_load_done() -> void:
	var cfg := _config([_entry(2.0, 0.5, 0.5)])
	cfg.skip_min_seconds = 0.4
	cfg.min_total_seconds = 2.0
	var seq := SplashSequencer.new()
	seq.setup(cfg)

	seq.tick(0.5)
	seq.notify_load_done(true)
	seq.skip()
	assert_eq(seq.state(), SplashSequencer.State.WAITING_LOAD, "tahan sampai min_total_seconds tercapai")

	seq.tick(1.0)
	assert_eq(seq.state(), SplashSequencer.State.WAITING_LOAD, "elapsed 1.5 < 2.0")
	seq.tick(0.6)
	assert_eq(seq.state(), SplashSequencer.State.DONE, "elapsed >= 2.0 -> DONE")
	assert_false(seq.failed())


func test_load_failure_and_max_wait_timeout_finish_with_failed_true() -> void:
	var cfg := _config([_entry(2.0, 0.5, 0.5)])
	var seq := SplashSequencer.new()
	var fail_flags: Array[bool] = []
	seq.finished.connect(func(f: bool) -> void: fail_flags.append(f))
	seq.setup(cfg)
	seq.tick(0.2)
	seq.notify_load_done(false)
	assert_true(seq.is_finished())
	assert_true(seq.failed())
	assert_eq(fail_flags, [true])

	var cfg_timeout := _config([_entry(0.5, 0.2, 0.2)])
	cfg_timeout.max_wait_seconds = 3.0
	var seq2 := SplashSequencer.new()
	var timeout_flags: Array[bool] = []
	seq2.finished.connect(func(f: bool) -> void: timeout_flags.append(f))
	seq2.setup(cfg_timeout)
	seq2.tick(2.5)
	assert_false(seq2.is_finished())
	seq2.tick(0.6)
	assert_true(seq2.is_finished())
	assert_true(seq2.failed())
	assert_eq(timeout_flags, [true])


func test_progress_is_smoothed_monotonic_and_caps_below_one_until_done() -> void:
	var cfg := _config([_entry(2.0, 0.5, 0.5)])
	cfg.bar_smooth_speed = 1.0
	cfg.min_total_seconds = 5.0
	var seq := SplashSequencer.new()
	seq.setup(cfg)

	seq.notify_load_progress(0.8)
	seq.tick(0.2)
	var p1 := seq.progress_displayed()
	assert_almost_eq(p1, 0.2, 0.001, "smoothed dengan bar_smooth_speed * delta")

	# Nilai lebih kecil tidak boleh menurunkan progress_displayed.
	seq.notify_load_progress(0.1)
	seq.tick(0.2)
	var p2 := seq.progress_displayed()
	assert_gte(p2, p1, "monoton naik")

	# Real progress 1.0 sebelum load_done tetap tertahan < 1.0.
	seq.notify_load_progress(1.0)
	seq.tick(2.0)
	assert_lt(seq.progress_displayed(), 1.0, "belum 1.0 sebelum notify_load_done(true)")

	seq.notify_load_done(true)
	seq.tick(0.5)
	assert_almost_eq(seq.progress_displayed(), 1.0, 0.001, "mencapai 1.0 setelah load_done(true)")


func test_empty_entries_and_disabled_config_wait_only_for_load() -> void:
	var empty_cfg := _config([])
	empty_cfg.min_total_seconds = 5.0
	var seq_empty := SplashSequencer.new()
	var started_count := 0
	seq_empty.entry_started.connect(func(_i: int) -> void: started_count += 1)
	seq_empty.setup(empty_cfg)
	assert_eq(seq_empty.state(), SplashSequencer.State.WAITING_LOAD)
	seq_empty.tick(0.1)
	assert_eq(started_count, 0)
	seq_empty.notify_load_done(true)
	assert_true(seq_empty.is_finished())
	assert_false(seq_empty.failed())

	var disabled_cfg := _config([_entry(2.0, 0.5, 0.5)])
	disabled_cfg.enabled = false
	var seq_disabled := SplashSequencer.new()
	seq_disabled.setup(disabled_cfg)
	assert_eq(seq_disabled.state(), SplashSequencer.State.WAITING_LOAD)
	seq_disabled.notify_load_done(true)
	assert_true(seq_disabled.is_finished())
	assert_false(seq_disabled.failed())

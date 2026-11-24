extends GutTest

## Fase 1A/1B di scene island: baris tujuan harian dan panel rekap fajar.
## Dijalankan lewat `island_harness` yang sama dengan tes integrasi lain.

const IslandHarness = preload("res://tests/integration/island_harness.gd")

var _harness: IslandHarness


func before_each() -> void:
	_harness = IslandHarness.new()
	_harness.setup(self)


func after_each() -> void:
	if _harness != null:
		_harness.teardown()
		_harness = null


func test_daily_goal_line_lists_today_goals() -> void:
	var hud := _harness.island.get_node_or_null("DailyGoalHUD")
	assert_not_null(hud, "DailyGoalHUD terpasang di island")
	var text: String = hud.get_text()
	assert_true(text.begins_with("Hari 1:"), "baris tujuan menyebut hari: %s" % text)
	assert_string_contains(text, "bangun api unggun")
	assert_string_contains(text, "kumpulkan 4 Kayu")
	assert_string_contains(text, "petakan base")


func test_goal_line_moves_to_next_day() -> void:
	var hud := _harness.island.get_node_or_null("DailyGoalHUD")
	assert_not_null(hud, "DailyGoalHUD terpasang di island")
	_skip_phase()
	_skip_phase()
	assert_eq(int(_harness.clock.get_current_day()), 2, "sudah hari 2")
	hud.refresh()
	var text: String = hud.get_text()
	assert_true(text.begins_with("Hari 2:"), "baris berganti ke hari 2: %s" % text)
	assert_string_contains(text, "buat Kapak Batu")
	assert_false(text.contains("bangun api unggun"), "tujuan hari 1 tidak tersisa")


func test_dawn_recap_shows_previous_day() -> void:
	var recap := _harness.island.get_node_or_null("DawnRecapHUD")
	assert_not_null(recap, "DawnRecapHUD terpasang di island")
	assert_false(recap.is_open(), "tidak ada rekap di hari 1")
	_skip_phase()
	_skip_phase()
	assert_true(recap.is_open(), "rekap muncul saat fajar hari 2")
	assert_eq(recap.get_title_text(), "Hari 1 selesai")
	assert_string_contains(recap.get_body_text(), "resource")


func _skip_phase() -> void:
	_harness.clock.skip_time(float(_harness.clock.get_remaining_seconds()) + 0.01)

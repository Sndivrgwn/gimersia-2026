extends GutTest

## Fase 5: layar Game Over / Victory menampilkan ringkasan run dari
## `DailyRunStats.get_totals()`, dan timing babi yang tadinya konstanta pindah
## ke `BoarConfig` (audit angka ke `.tres`).

const DEATH_SCENE: PackedScene = preload("res://src/ui/menus/death_screen.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://src/ui/menus/game_over_screen.tscn")
const ENDGAME_HUD_SCRIPT: Script = preload("res://src/ui/hud/endgame/endgame_hud.gd")


func test_from_totals_formats_every_counter() -> void:
	var text := RunSummary.from_totals({
		"days": 4,
		"resources": 42,
		"kills_boar": 3,
		"kills_other": 1,
		"base_damage": 87.6,
		"structures_destroyed": 2,
	}, 5)

	assert_string_contains(text, "Hari bertahan: 5", "hari berjalan ikut dihitung")
	assert_string_contains(text, "Sumber daya: 42")
	assert_string_contains(text, "Babi dibunuh: 3")
	assert_string_contains(text, "Hewan lain: 1")
	assert_string_contains(text, "Kerusakan base: 88", "dibulatkan")
	assert_string_contains(text, "Struktur hancur: 2")


func test_from_totals_handles_missing_keys_and_never_goes_negative() -> void:
	var text := RunSummary.from_totals({}, 0)
	assert_string_contains(text, "Hari bertahan: 0")
	assert_string_contains(text, "Sumber daya: 0")

	var negative := RunSummary.from_totals({
		"days": -2, "resources": -5, "kills_boar": -1,
		"kills_other": -1, "base_damage": -10.0, "structures_destroyed": -1,
	}, 0)
	assert_string_contains(negative, "Hari bertahan: 0")
	assert_string_contains(negative, "Sumber daya: 0")
	assert_string_contains(negative, "Kerusakan base: 0")


func test_death_screen_shows_run_summary() -> void:
	var stats := _stats_with_record()
	var screen := DEATH_SCENE.instantiate() as DeathScreen
	add_child_autofree(screen)

	screen.show_death(2)
	var text: String = screen.get_detail_text()
	assert_string_contains(text, "Sisa Kesempatan Respawn: 2 / 3")
	assert_string_contains(text, RunSummary.TITLE)
	assert_string_contains(text, "Sumber daya: 9")


func test_game_over_screen_shows_run_summary() -> void:
	var stats := _stats_with_record()
	var screen := GAME_OVER_SCENE.instantiate() as GameOverScreen
	add_child_autofree(screen)

	screen.show_game_over()
	var text: String = screen.get_detail_text()
	assert_string_contains(text, "Tidak ada kesempatan respawn tersisa.")
	assert_string_contains(text, RunSummary.TITLE)
	assert_string_contains(text, "Sumber daya: 9")
	assert_string_contains(text, "Struktur hancur: 0")


func test_victory_panel_appends_run_summary() -> void:
	var stats := _stats_with_record()
	var hud := ENDGAME_HUD_SCRIPT.new() as EndgameHUD
	add_child_autofree(hud)

	hud.call(&"_on_victory")
	var text: String = hud.get_victory_text()
	assert_string_contains(text, "Suar darurat menyala")
	assert_string_contains(text, RunSummary.TITLE)
	assert_string_contains(text, "Sumber daya: 9")


func test_boar_timings_come_from_config() -> void:
	var config := BoarConfig.new()
	assert_almost_eq(config.bite_hold_time, 0.22, 0.001, "lama state BITE")
	assert_almost_eq(config.dash_recover_time, 0.3, 0.001, "lama state RECOVER")
	assert_almost_eq(config.dash_knockback_distance, 60.0, 0.001, "knockback dash")

	# Scene babi memakai BoarConfig yang sama, bukan konstanta script.
	var scene: PackedScene = load("res://src/entities/fauna/wild_boar/wild_boar.tscn")
	var boar := scene.instantiate() as WildBoar
	assert_true(boar.config is BoarConfig, "boar.tscn harus memakai BoarConfig")
	boar.free()


func _stats_with_record() -> DailyRunStats:
	var stats := DailyRunStats.new()
	add_child_autofree(stats)
	stats.record_gather(9)
	stats.finish_day()
	return stats

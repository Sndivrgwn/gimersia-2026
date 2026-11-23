extends GutTest

## Tes Tenda: syarat tidur + alasannya, satu kali skip_time, Needs bereaksi,
## dan prompt yang berubah siang/malam.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const TENT_SCENE: PackedScene = preload("res://src/entities/camp/tent/tent.tscn")
const TENT_DEF: StructureDefinition = preload("res://src/data/camp/tent.tres")


class StubClock extends Node:
	signal time_skipped(seconds: float)

	var day: bool = true
	var remaining: float = 300.0
	var elapsed: float = 0.0
	var skip_calls: int = 0
	var last_skip: float = 0.0

	func is_day() -> bool:
		return day

	func is_night() -> bool:
		return not day

	func get_remaining_seconds() -> float:
		return remaining

	func get_total_elapsed_seconds() -> float:
		return elapsed

	func skip_time(seconds: float) -> void:
		skip_calls += 1
		last_skip = seconds
		elapsed += seconds
		remaining = maxf(remaining - seconds, 0.0)
		time_skipped.emit(seconds)


class StubWatch extends Node:
	var active: bool = false
	var toggles: int = 0
	var block_reason: String = "Butuh Api Unggun menyala"

	func is_active() -> bool:
		return active

	func get_start_block_reason() -> String:
		return block_reason

	func toggle() -> bool:
		toggles += 1
		active = not active
		return true


var clock: StubClock
var player: Player
var needs: NeedsComponent
var tent: Tent


func before_each() -> void:
	clock = StubClock.new()
	add_child_autofree(clock)

	player = PLAYER_SCENE.instantiate() as Player
	var player_needs := player.get_node("NeedsComponent") as NeedsComponent
	player_needs.clock = clock
	add_child_autofree(player)
	needs = player_needs
	needs.set_process(false)

	tent = TENT_SCENE.instantiate() as Tent
	tent.definition = TENT_DEF
	tent.clock = clock
	add_child_autofree(tent)


# --- Syarat tidur -----------------------------------------------------------

func test_can_sleep_by_day() -> void:
	assert_true(tent.can_sleep())
	assert_eq(tent.get_sleep_block_reason(), "")


func test_cannot_sleep_at_night() -> void:
	clock.day = false
	clock.remaining = 300.0

	assert_false(tent.can_sleep())
	assert_eq(tent.get_sleep_block_reason(), "Hanya bisa tidur di siang hari")
	assert_eq(tent.get_block_reason(null), "Hanya bisa tidur di siang hari")


func test_cannot_sleep_with_60_seconds_or_less_of_day() -> void:
	clock.remaining = 60.0
	assert_eq(tent.get_sleep_block_reason(), "Waktu siang kurang dari 60 detik")
	assert_false(tent.can_sleep())

	clock.remaining = 61.0
	assert_eq(tent.get_sleep_block_reason(), "")


func test_cooldown_uses_game_time_since_last_sleep() -> void:
	assert_true(tent.sleep(null))
	assert_true(tent.has_slept())
	clock.remaining = 300.0

	assert_eq(tent.get_sleep_block_reason(), "Tenda masih perlu istirahat")

	clock.elapsed = tent.get_last_sleep_time() + 60.0
	assert_eq(tent.get_sleep_block_reason(), "", "60 detik game sejak tidur")


# --- Efek tidur -------------------------------------------------------------

func test_sleep_calls_skip_time_once_and_needs_reacts() -> void:
	needs.set_value(NeedsComponent.Need.FATIGUE, 40.0)
	var hunger_before := needs.get_value(NeedsComponent.Need.HUNGER)

	assert_true(tent.sleep(null))

	assert_eq(clock.skip_calls, 1, "Tenda hanya memanggil skip_time sekali")
	assert_almost_eq(clock.last_skip, 45.0, 0.001)
	assert_almost_eq(needs.get_value(NeedsComponent.Need.FATIGUE), 100.0, 0.001, "Fatigue penuh")
	# Mission 9 (R4): drain sekarang dikali pengali balance NeedsConfig.
	var config := needs.get_config()
	assert_almost_eq(
		needs.get_value(NeedsComponent.Need.HUNGER),
		hunger_before - 0.16 * 45.0 * config.hunger_drain_scale(1),
		0.01,
		"Hunger ikut terkuras lewat time_skipped"
	)


func test_sleep_is_ignored_when_blocked() -> void:
	clock.day = false

	assert_false(tent.sleep(null))
	assert_eq(clock.skip_calls, 0, "tidak ada skip saat diblokir")


func test_hold_time_is_1_5_seconds() -> void:
	assert_almost_eq(tent.get_hold_time(null), 1.5, 0.001)
	assert_almost_eq(tent.config.hold_time, 1.5, 0.001)


# --- Malam / Jaga Malam -----------------------------------------------------

func test_prompt_changes_with_phase() -> void:
	assert_eq(tent.get_prompt(null), "Tahan E: Tidur")

	clock.day = false
	assert_eq(tent.get_prompt(null), "Tahan E: Jaga Malam")


func test_night_action_toggles_night_watch() -> void:
	var watch := StubWatch.new()
	add_child_autofree(watch)
	tent.night_watch = watch
	clock.day = false

	assert_eq(tent.get_block_reason(null), "Butuh Api Unggun menyala")
	tent.perform_action(null)
	assert_eq(watch.toggles, 1, "E di malam meneruskan ke NightWatchController")
	assert_eq(tent.get_prompt(null), "Tahan E: Berhenti Jaga Malam")

	watch.active = true
	assert_eq(tent.get_block_reason(null), "", "watch aktif selalu bisa dimatikan")


func test_night_without_watch_controller_blocks_with_sleep_reason() -> void:
	clock.day = false
	assert_eq(tent.get_block_reason(null), "Hanya bisa tidur di siang hari")
	assert_eq(tent.get_hold_time(null), 0.0)

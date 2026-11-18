extends GutTest

## Tes NeedsComponent (Bagian 1.D / §7 Needs).
##
## Komponen memakai stub clock dan stub player supaya tes deterministik:
## tidak ada frame nyata, waktu digerakkan lewat tick() dan time_skipped.
## StatsComponent asli dipakai agar efek tier terverifikasi lewat getter nyata.

const NeedsComponentScript = preload("res://src/components/needs/needs_component.gd")
const StatsComponentScript = preload("res://src/components/stats/stats_component.gd")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const NEEDS_DEBUG_SCRIPT = preload("res://scenes/practice/needs_debug.gd")
const STATS_HUD_SCENE: PackedScene = preload("res://src/ui/hud/stats/stats_hud.tscn")


class StubClock extends Node:
	signal time_skipped(seconds: float)

	var scale: float = 1.0
	var night: bool = false

	func get_time_scale() -> float:
		return scale

	func is_night() -> bool:
		return night

	func skip(seconds: float) -> void:
		time_skipped.emit(seconds)


class StubPlayer extends Node:
	signal sprint_state_changed(is_sprinting: bool)

	var can_sprint: bool = true

	func set_sprinting(value: bool) -> void:
		sprint_state_changed.emit(value)


var clock: StubClock
var player: StubPlayer
var stats: StatsComponentScript
var needs: NeedsComponentScript


func before_each() -> void:
	clock = StubClock.new()
	add_child_autofree(clock)

	player = StubPlayer.new()
	add_child_autofree(player)

	stats = StatsComponentScript.new()
	add_child_autofree(stats)

	needs = NeedsComponentScript.new()
	needs.setup(clock, stats, player)
	add_child_autofree(needs)
	needs.set_process(false)


# --- Nilai awal & API -------------------------------------------------------

func test_starts_full_and_normal() -> void:
	for need in [NeedsComponentScript.Need.HUNGER, NeedsComponentScript.Need.THIRST, NeedsComponentScript.Need.FATIGUE]:
		assert_almost_eq(needs.get_value(need), 100.0, 0.001)
		assert_eq(needs.get_tier(need), NeedsComponentScript.Tier.NORMAL)
	assert_true(player.can_sprint)


func test_values_clamp_to_range() -> void:
	needs.set_value(NeedsComponentScript.Need.HUNGER, -10.0)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.HUNGER), 0.0, 0.001)

	needs.set_value(NeedsComponentScript.Need.THIRST, 250.0)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.THIRST), 100.0, 0.001)

	needs.add(NeedsComponentScript.Need.FATIGUE, -500.0)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.FATIGUE), 0.0, 0.001)

	needs.add(NeedsComponentScript.Need.FATIGUE, 1000.0)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.FATIGUE), 100.0, 0.001)


# --- Drain pasif ------------------------------------------------------------

func test_day_drain_rates() -> void:
	clock.night = false
	needs.tick(10.0)

	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.HUNGER), 98.4, 0.001)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.THIRST), 97.6, 0.001)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.FATIGUE), 100.0, 0.001)


func test_night_drain_rates() -> void:
	clock.night = true
	needs.tick(10.0)

	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.HUNGER), 98.0, 0.001)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.THIRST), 98.2, 0.001)


func test_time_scale_zero_stops_drain_and_two_doubles_it() -> void:
	clock.scale = 0.0
	needs.tick(10.0)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.HUNGER), 100.0, 0.001)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.THIRST), 100.0, 0.001)

	clock.scale = 2.0
	needs.tick(10.0)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.HUNGER), 96.8, 0.001)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.THIRST), 95.2, 0.001)


func test_tiny_ticks_accumulate() -> void:
	# 240 Hz: satu frame hanya 0.16 * 0.001 = 0.00016, di bawah toleransi
	# is_equal_approx di nilai 100. Nilai tetap harus tersimpan dan menumpuk.
	var frames := 600
	var frame_delta := 0.001
	for _frame in frames:
		needs.tick(frame_delta)

	assert_almost_eq(
		needs.get_value(NeedsComponentScript.Need.HUNGER),
		100.0 - 0.16 * float(frames) * frame_delta,
		0.001
	)
	assert_almost_eq(
		needs.get_value(NeedsComponentScript.Need.THIRST),
		100.0 - 0.24 * float(frames) * frame_delta,
		0.001
	)


# --- Tidur / time_skipped ---------------------------------------------------

func test_time_skipped_drains_and_clamps_at_one() -> void:
	needs.set_value(NeedsComponentScript.Need.HUNGER, 50.0)
	needs.set_value(NeedsComponentScript.Need.THIRST, 0.5)

	clock.night = false
	clock.skip(1000.0)

	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.HUNGER), 1.0, 0.001)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.THIRST), 0.5, 0.001)


func test_time_skipped_uses_night_rate() -> void:
	clock.night = true
	clock.skip(45.0)

	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.HUNGER), 100.0 - 0.20 * 45.0, 0.001)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.THIRST), 100.0 - 0.18 * 45.0, 0.001)


# --- Tier & modifier --------------------------------------------------------

func test_hunger_tiers_at_25_and_0() -> void:
	assert_almost_eq(stats.get_move_speed(), 160.0, 0.001)

	needs.set_value(NeedsComponentScript.Need.HUNGER, 26.0)
	assert_eq(needs.get_tier(NeedsComponentScript.Need.HUNGER), NeedsComponentScript.Tier.NORMAL)
	assert_almost_eq(stats.get_move_speed(), 160.0, 0.001)

	needs.set_value(NeedsComponentScript.Need.HUNGER, 25.0)
	assert_eq(needs.get_tier(NeedsComponentScript.Need.HUNGER), NeedsComponentScript.Tier.LOW)
	assert_almost_eq(stats.get_move_speed(), 160.0 * 0.85, 0.001)
	assert_almost_eq(stats.get_attack_damage(), 8.0 * 0.85, 0.001)

	needs.set_value(NeedsComponentScript.Need.HUNGER, 0.0)
	assert_eq(needs.get_tier(NeedsComponentScript.Need.HUNGER), NeedsComponentScript.Tier.ZERO)
	assert_almost_eq(stats.get_move_speed(), 160.0 * 0.85, 0.001, "efek LOW tetap berlaku di ZERO")
	assert_almost_eq(stats.get_attack_damage(), 8.0 * 0.85, 0.001)

	needs.set_value(NeedsComponentScript.Need.HUNGER, 100.0)
	assert_almost_eq(stats.get_move_speed(), 160.0, 0.001, "modifier tier lama harus dihapus")


func test_thirst_tiers_use_sprint_drain_and_attack_speed() -> void:
	needs.set_value(NeedsComponentScript.Need.THIRST, 25.0)
	assert_almost_eq(stats.get_sprint_fatigue_drain_factor(), 1.30, 0.001)
	assert_almost_eq(stats.get_attack_speed(), 1.2 * 0.80, 0.001)

	needs.set_value(NeedsComponentScript.Need.THIRST, 0.0)
	assert_almost_eq(stats.get_sprint_fatigue_drain_factor(), 1.30, 0.001)
	assert_almost_eq(stats.get_attack_speed(), 1.2 * 0.80, 0.001)

	needs.set_value(NeedsComponentScript.Need.THIRST, 100.0)
	assert_almost_eq(stats.get_sprint_fatigue_drain_factor(), 1.0, 0.001)
	assert_almost_eq(stats.get_attack_speed(), 1.2, 0.001)


func test_fatigue_tiers_stack_with_thirst() -> void:
	needs.set_value(NeedsComponentScript.Need.THIRST, 20.0)
	needs.set_value(NeedsComponentScript.Need.FATIGUE, 25.0)
	assert_almost_eq(stats.get_move_speed(), 160.0 * 0.80, 0.001)
	assert_almost_eq(stats.get_gather_time_factor(), 1.30, 0.001)

	needs.set_value(NeedsComponentScript.Need.FATIGUE, 0.0)
	assert_almost_eq(stats.get_move_speed(), 160.0 * 0.55, 0.001, "ZERO menimpa move speed LOW")
	assert_almost_eq(stats.get_attack_speed(), 1.2 * 0.30, 0.001, "attack speed -20% dan -50% menumpuk")
	assert_almost_eq(stats.get_gather_time_factor(), 1.30, 0.001, "gather time ZERO sama dengan LOW")


# --- HP saat ZERO -----------------------------------------------------------

func test_zero_tier_hp_loss_stacks() -> void:
	needs.set_value(NeedsComponentScript.Need.HUNGER, 0.0)
	needs.set_value(NeedsComponentScript.Need.THIRST, 0.0)
	assert_almost_eq(stats.current_hp, 100.0, 0.001)

	clock.scale = 1.0
	needs.tick(1.0)
	assert_almost_eq(stats.current_hp, 96.5, 0.001, "1.5 + 2.0 HP per detik")

	needs.tick(2.0)
	assert_almost_eq(stats.current_hp, 89.5, 0.001)


func test_hunger_zero_alone_loses_1_5_hp_per_second() -> void:
	needs.set_value(NeedsComponentScript.Need.HUNGER, 0.0)
	stats.set_hp(100.0)

	needs.tick(2.0)
	assert_almost_eq(stats.current_hp, 97.0, 0.001)


func test_no_hp_loss_when_scale_is_zero() -> void:
	needs.set_value(NeedsComponentScript.Need.HUNGER, 0.0)
	stats.set_hp(100.0)

	clock.scale = 0.0
	needs.tick(10.0)
	assert_almost_eq(stats.current_hp, 100.0, 0.001)


# --- Sprint -----------------------------------------------------------------

func test_sprint_drain_uses_stats_factor() -> void:
	stats.add_modifier(&"tes", &"sprint_fatigue_drain", StatModifier.Kind.PERCENT, 0.5)
	assert_almost_eq(stats.get_sprint_fatigue_drain_factor(), 1.5, 0.001)

	player.set_sprinting(true)
	needs.tick(2.0)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.FATIGUE), 100.0 - 2.5 * 1.5 * 2.0, 0.001)

	player.set_sprinting(false)
	needs.tick(2.0)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.FATIGUE), 92.5, 0.001)


func test_can_sprint_locks_at_25() -> void:
	assert_true(player.can_sprint)

	needs.set_value(NeedsComponentScript.Need.FATIGUE, 26.0)
	assert_true(player.can_sprint, "di atas 25 masih boleh sprint")

	needs.set_value(NeedsComponentScript.Need.FATIGUE, 25.0)
	assert_false(player.can_sprint, "tepat 25 terkunci")

	needs.set_value(NeedsComponentScript.Need.FATIGUE, 0.0)
	assert_false(player.can_sprint)

	needs.set_value(NeedsComponentScript.Need.FATIGUE, 40.0)
	assert_true(player.can_sprint, "di atas 25 terbuka lagi")


# --- Jalan ------------------------------------------------------------------

func test_walking_drains_fatigue_slowly() -> void:
	var mover := CharacterBody2D.new()
	add_child_autofree(mover)
	needs.setup(clock, stats, mover)

	mover.velocity = Vector2(120.0, 0.0)
	needs.tick(10.0)
	assert_almost_eq(
		needs.get_value(NeedsComponentScript.Need.FATIGUE), 100.0 - 0.08 * 10.0, 0.01,
		"jalan 10 detik hanya mengurangi 0.8"
	)

	mover.velocity = Vector2.ZERO
	needs.tick(10.0)
	assert_almost_eq(
		needs.get_value(NeedsComponentScript.Need.FATIGUE), 99.2, 0.01,
		"diam di tempat tidak mengurangi Fatigue"
	)


func test_walk_drain_is_much_slower_than_sprint() -> void:
	var config := needs.get_config()

	assert_almost_eq(config.fatigue_walk_drain, 0.08, 0.0001)
	assert_almost_eq(config.fatigue_sprint_drain, 2.5, 0.0001)
	assert_gt(
		config.fatigue_sprint_drain, config.fatigue_walk_drain * 20.0,
		"sprint minimal 20x lebih cepat daripada jalan"
	)

	# Jalan semenit hanya menghabiskan beberapa poin.
	var mover := CharacterBody2D.new()
	add_child_autofree(mover)
	needs.setup(clock, stats, mover)

	mover.velocity = Vector2(120.0, 0.0)
	needs.tick(60.0)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.FATIGUE), 95.2, 0.01)


# --- Sinyal -----------------------------------------------------------------

func test_signals_emit_once_per_change() -> void:
	watch_signals(needs)

	needs.set_value(NeedsComponentScript.Need.HUNGER, 50.0)
	assert_signal_emit_count(needs, "value_changed", 1)
	assert_signal_emit_count(needs, "tier_changed", 0)

	needs.set_value(NeedsComponentScript.Need.HUNGER, 50.0)
	assert_signal_emit_count(needs, "value_changed", 1, "nilai sama tidak memancarkan sinyal")

	needs.set_value(NeedsComponentScript.Need.HUNGER, 25.0)
	assert_signal_emit_count(needs, "value_changed", 2)
	assert_signal_emit_count(needs, "tier_changed", 1)

	needs.set_value(NeedsComponentScript.Need.HUNGER, 25.0)
	assert_signal_emit_count(needs, "tier_changed", 1, "tier sama tidak memancarkan sinyal")


func test_real_player_sprint_emits_and_drains_fatigue() -> void:
	var real_player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(real_player)

	var real_needs := real_player.get_node_or_null("NeedsComponent") as NeedsComponentScript
	assert_not_null(real_needs, "player.tscn harus punya NeedsComponent")
	if real_needs == null:
		return
	real_needs.set_process(false)

	var states: Array[bool] = []
	real_player.sprint_state_changed.connect(
		func(is_sprinting: bool) -> void: states.append(is_sprinting)
	)

	Input.action_press(&"sprint")
	Input.action_press(&"move_right")
	await get_tree().physics_frame
	await get_tree().physics_frame

	assert_gt(states.size(), 0, "sprint_state_changed harus terpancar dari Player asli")
	if states.is_empty():
		Input.action_release(&"sprint")
		Input.action_release(&"move_right")
		return
	assert_true(states[0], "Shift + gerak harus masuk state sprint")

	var before := real_needs.get_value(NeedsComponentScript.Need.FATIGUE)
	real_needs.tick(1.0)
	assert_almost_eq(
		real_needs.get_value(NeedsComponentScript.Need.FATIGUE),
		before - 2.5 * real_player.stats.get_sprint_fatigue_drain_factor(),
		0.01
	)

	Input.action_release(&"sprint")
	Input.action_release(&"move_right")


# --- Debug keys practice + StatsHUD -----------------------------------------

func test_debug_keys_cycle_needs_and_stats_hud_follows() -> void:
	var real_player := PLAYER_SCENE.instantiate() as Player
	real_player.add_to_group(&"player")
	add_child_autofree(real_player)

	var needs := real_player.get_node_or_null("NeedsComponent") as NeedsComponentScript
	assert_not_null(needs, "player.tscn harus punya NeedsComponent")
	if needs == null:
		return
	needs.set_process(false)

	var debug_node := NEEDS_DEBUG_SCRIPT.new()
	add_child_autofree(debug_node)

	var hud := STATS_HUD_SCENE.instantiate()
	add_child_autofree(hud)
	var stats_label := hud.get_node("Root/Panel/Margin/VBox/StatsLabel") as Label
	var tier_label := hud.get_node("Root/Panel/Margin/VBox/TierLabel") as Label

	# Default mati: tombol tidak boleh mengubah apa pun.
	_press_key(debug_node, KEY_X)
	assert_almost_eq(
		needs.get_value(NeedsComponentScript.Need.HUNGER), 100.0, 0.001,
		"debug off: X harus diabaikan"
	)

	_press_key(debug_node, KEY_F1)
	_press_key(debug_node, KEY_X)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.HUNGER), 25.0, 0.001)
	assert_string_contains(tier_label.text, "HUNGER LOW")
	assert_string_contains(stats_label.text, "Attack dmg   6.8")
	assert_string_contains(stats_label.text, "Move speed   136")

	_press_key(debug_node, KEY_X)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.HUNGER), 0.0, 0.001)
	assert_string_contains(tier_label.text, "HUNGER ZERO")
	assert_string_contains(stats_label.text, "Attack dmg   6.8", "efek LOW tetap saat ZERO")

	_press_key(debug_node, KEY_C)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.THIRST), 25.0, 0.001)
	assert_string_contains(tier_label.text, "THIRST LOW")
	assert_string_contains(stats_label.text, "Attack speed 0.96/s")
	assert_string_contains(stats_label.text, "Sprint drain x1.30")

	_press_key(debug_node, KEY_V)
	_press_key(debug_node, KEY_V)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.FATIGUE), 0.0, 0.001)
	assert_string_contains(tier_label.text, "FATIGUE ZERO")
	assert_string_contains(stats_label.text, "Move speed   64", "hunger -15% + fatigue -45%")
	assert_string_contains(stats_label.text, "Attack speed 0.36/s")
	assert_string_contains(stats_label.text, "Gather time  x1.30")
	assert_false(real_player.can_sprint, "Fatigue ZERO mengunci sprint")

	_press_key(debug_node, KEY_B)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.HUNGER), 100.0, 0.001)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.THIRST), 100.0, 0.001)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.FATIGUE), 100.0, 0.001)
	assert_string_contains(tier_label.text, "HUNGER NORMAL")
	assert_string_contains(stats_label.text, "Move speed   160")
	assert_true(real_player.can_sprint, "refill membuka kembali sprint")


## Kirim event tombol langsung ke _unhandled_input (tanpa OS input).
func _press_key(target: Node, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	target._unhandled_input(event)


func test_spend_fatigue_only_drains_fatigue() -> void:
	needs.spend_fatigue(1.2)
	needs.spend_fatigue(2.0)

	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.FATIGUE), 96.8, 0.001)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.HUNGER), 100.0, 0.001)
	assert_almost_eq(needs.get_value(NeedsComponentScript.Need.THIRST), 100.0, 0.001)

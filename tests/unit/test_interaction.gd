extends GutTest

## Tes framework interaksi (Phase A): action, pemilihan target terdekat,
## hold/release/out-of-range, no auto-chain, blocked, delta nyata, dan HUD.

const InteractorScript = preload("res://src/components/interaction/interactor_component.gd")
const HUD_SCENE: PackedScene = preload("res://src/ui/hud/interaction/interaction_hud.tscn")

const ACTION := &"interact"


class FakeInteractable extends Interactable:
	var hold_time := 1.0
	var allowed := true
	var block_reason := ""
	var prompt := "Uji"
	var calls := 0
	var last_interactor: Node

	func get_prompt(_interactor: Node) -> String:
		return prompt

	func get_hold_time(_interactor: Node) -> float:
		return hold_time

	func can_interact(_interactor: Node) -> bool:
		return allowed

	func get_block_reason(_interactor: Node) -> String:
		return block_reason

	func interact(interactor: Node) -> void:
		calls += 1
		last_interactor = interactor


var body: Node2D
var interactor
var fake: FakeInteractable
var _clock_scale_to_restore := -1.0


func before_each() -> void:
	InputSetup.ensure_actions()
	Input.action_release(ACTION)

	body = Node2D.new()
	add_child_autofree(body)

	interactor = InteractorScript.new()
	body.add_child(interactor)
	interactor.set_process(false)

	fake = FakeInteractable.new()
	body.add_child(fake)


func after_each() -> void:
	Input.action_release(ACTION)
	if _clock_scale_to_restore >= 0.0:
		var clock := get_node_or_null("/root/DayNightManager")
		if clock != null:
			clock.set_time_scale(_clock_scale_to_restore)
		_clock_scale_to_restore = -1.0


# --- Action -----------------------------------------------------------------

func test_interact_action_registered_with_e() -> void:
	assert_true(InputMap.has_action(ACTION))

	var has_e := false
	for event in InputMap.action_get_events(ACTION):
		var key_event := event as InputEventKey
		if key_event != null and key_event.physical_keycode == KEY_E:
			has_e = true
	assert_true(has_e, "interact harus memakai tombol E")


# --- Pemilihan target -------------------------------------------------------

func test_picks_nearest_interactable_in_range() -> void:
	var far := FakeInteractable.new()
	far.position = Vector2(200.0, 0.0)
	body.add_child(far)
	fake.position = Vector2(20.0, 0.0)

	interactor._process(0.2)
	assert_eq(interactor.get_target(), fake, "target terdekat dalam range")


func test_ignores_interactable_outside_range() -> void:
	fake.position = Vector2(200.0, 0.0)

	interactor._process(0.2)
	assert_null(interactor.get_target(), "di luar interaction_range 64 px")


func test_range_comes_from_config() -> void:
	fake.position = Vector2(120.0, 0.0)

	var config := InteractionConfig.new()
	config.interaction_range = 200.0
	interactor.config = config

	interactor._process(0.2)
	assert_eq(interactor.get_target(), fake, "range dibaca dari config")


# --- Hold / release ---------------------------------------------------------

func test_hold_completes_and_calls_interact_once() -> void:
	fake.hold_time = 0.3
	watch_signals(interactor)
	interactor._process(0.2)

	Input.action_press(ACTION)
	interactor._process(0.1)
	interactor._process(0.1)
	assert_almost_eq(interactor.get_progress_ratio(), 0.66, 0.02)
	assert_eq(fake.calls, 0, "belum selesai")

	interactor._process(0.1)
	assert_eq(fake.calls, 1)
	assert_eq(fake.last_interactor, interactor)
	assert_signal_emitted(interactor, "interaction_completed")


func test_release_before_completion_cancels() -> void:
	fake.hold_time = 1.0
	interactor._process(0.2)

	Input.action_press(ACTION)
	interactor._process(0.1)
	assert_almost_eq(interactor.get_progress_ratio(), 0.1, 0.001)

	watch_signals(interactor)
	Input.action_release(ACTION)
	interactor._process(0.1)

	assert_eq(fake.calls, 0)
	assert_almost_eq(interactor.get_progress_ratio(), 0.0, 0.001)
	assert_signal_emitted(interactor, "interaction_cancelled")


func test_completion_requires_release_before_another_hold() -> void:
	fake.hold_time = 0.1
	interactor._process(0.2)

	Input.action_press(ACTION)
	interactor._process(0.1)
	assert_eq(fake.calls, 1)

	# Masih menahan E: tidak boleh auto-chain.
	interactor._process(0.5)
	interactor._process(0.5)
	assert_eq(fake.calls, 1, "harus lepas dulu")

	Input.action_release(ACTION)
	interactor._process(0.1)
	Input.action_press(ACTION)
	interactor._process(0.1)
	assert_eq(fake.calls, 2)


func test_target_lost_out_of_range_resets_and_cancels() -> void:
	fake.hold_time = 1.0
	interactor._process(0.2)

	Input.action_press(ACTION)
	interactor._process(0.1)
	watch_signals(interactor)

	fake.position = Vector2(500.0, 0.0)
	interactor._process(0.2)

	assert_null(interactor.get_target())
	assert_almost_eq(interactor.get_progress_ratio(), 0.0, 0.001)
	assert_eq(fake.calls, 0)
	assert_signal_emitted(interactor, "target_changed")
	assert_signal_emitted(interactor, "interaction_cancelled")


func test_cancel_resets_progress() -> void:
	fake.hold_time = 1.0
	interactor._process(0.2)
	Input.action_press(ACTION)
	interactor._process(0.3)

	watch_signals(interactor)
	interactor.cancel()

	assert_almost_eq(interactor.get_progress_ratio(), 0.0, 0.001)
	assert_signal_emitted(interactor, "interaction_cancelled")


# --- Blokir -----------------------------------------------------------------

func test_blocked_target_does_not_progress_and_emits_once() -> void:
	fake.hold_time = 1.0
	fake.allowed = false
	fake.block_reason = "Butuh Kapak Batu"
	interactor._process(0.2)

	watch_signals(interactor)
	Input.action_press(ACTION)
	interactor._process(0.1)
	interactor._process(0.1)
	interactor._process(0.1)

	assert_eq(fake.calls, 0)
	assert_almost_eq(interactor.get_progress_ratio(), 0.0, 0.001)
	assert_signal_emit_count(interactor, "interaction_blocked", 1, "alasan sama tidak diulang")

	var params: Array = get_signal_parameters(interactor, "interaction_blocked", 0)
	assert_eq(params[0], fake)
	assert_eq(params[1], "Butuh Kapak Batu")


func test_blocked_emits_again_after_becoming_valid_and_blocked_again() -> void:
	fake.hold_time = 1.0
	fake.allowed = false
	fake.block_reason = "Butuh Beliung Batu"
	interactor._process(0.2)

	Input.action_press(ACTION)
	interactor._process(0.1)

	watch_signals(interactor)
	fake.allowed = true
	interactor._process(0.1)

	fake.allowed = false
	interactor._process(0.1)

	assert_signal_emit_count(interactor, "interaction_blocked", 1, "blokir baru setelah sempat valid")


# --- Waktu nyata ------------------------------------------------------------

func test_progress_uses_real_delta_not_game_time_scale() -> void:
	var clock := get_node_or_null("/root/DayNightManager")
	assert_not_null(clock, "autoload DayNightManager harus ada")
	if clock == null:
		return

	_clock_scale_to_restore = clock.get_time_scale()
	clock.set_time_scale(2.0)

	fake.hold_time = 1.0
	interactor._process(0.2)
	Input.action_press(ACTION)
	interactor._process(0.1)

	assert_almost_eq(
		interactor.get_progress_ratio(), 0.1, 0.001,
		"progres memakai delta nyata, bukan waktu game x2"
	)


# --- HUD --------------------------------------------------------------------

func test_hud_follows_prompt_progress_and_block_reason() -> void:
	fake.hold_time = 1.0
	fake.prompt = "Tahan E: Panen Beri"

	var hud := HUD_SCENE.instantiate()
	hud.interactor = interactor
	add_child_autofree(hud)

	var panel := hud.get_node("Root/Panel") as Control
	var prompt := hud.get_node("Root/Panel/Margin/VBox/Prompt") as Label
	var bar := hud.get_node("Root/Panel/Margin/VBox/Bar") as ProgressBar
	var blocked := hud.get_node("Root/Panel/Margin/VBox/Blocked") as Label

	assert_false(panel.visible, "tanpa target HUD tersembunyi")

	interactor._process(0.2)
	assert_true(panel.visible)
	assert_eq(prompt.text, "Tahan E: Panen Beri")

	Input.action_press(ACTION)
	interactor._process(0.25)
	assert_almost_eq(bar.value, 0.25, 0.01)
	assert_true(bar.visible)

	fake.allowed = false
	fake.block_reason = "Butuh Kapak Batu"
	interactor._process(0.1)
	assert_true(blocked.visible)
	assert_eq(blocked.text, "Butuh Kapak Batu")

	fake.allowed = true
	fake.position = Vector2(500.0, 0.0)
	interactor._process(0.2)
	assert_false(panel.visible, "target hilang -> HUD tersembunyi")

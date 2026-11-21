extends GutTest

## Phase 5 (D5): feedback combat visual, tanpa ubah balance.

class StubClock extends Node:
	var night: bool = true
	func is_night() -> bool: return night
	func get_current_day() -> int: return 1
	func get_time_scale() -> float: return 1.0

class StubPlayer extends Node2D:
	var stats: StatsComponent
	var receiver: PlayerDamageReceiver
	var facing_direction := Vector2.RIGHT
	var knockback_multiplier := 1.0
	func _init() -> void:
		stats = StatsComponent.new()
		stats.name = "StatsComponent"
		add_child(stats)
		receiver = PlayerDamageReceiver.new()
		receiver.name = "PlayerDamageReceiver"
		add_child(receiver)
	var combat: CombatComponent

const JUICE: JuiceConfig = preload("res://src/data/configs/juice_config.tres")
const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")
const CHEST_DEF: StructureDefinition = preload("res://src/data/camp/chest.tres")


func _make_feedback(with_camera: bool = true) -> Array:
	var player := StubPlayer.new()
	add_child_autofree(player)
	player.global_position = Vector2(100.0, 100.0)
	var feedback := CombatFeedback.new()
	feedback.config = JUICE
	feedback.player = player
	player.add_child(feedback)
	var camera: Camera2D = null
	if with_camera:
		camera = Camera2D.new()
		add_child_autofree(camera)
		feedback.camera = camera
	return [feedback, player, camera]


func test_config_defaults() -> void:
	assert_almost_eq(JUICE.intensity, 1.0, 0.001)
	assert_true(JUICE.screenshake_enabled)
	assert_almost_eq(JUICE.hit_stop_light, 0.05, 0.001)
	assert_almost_eq(JUICE.hit_stop_heavy, 0.09, 0.001)
	assert_almost_eq(JUICE.player_lunge, 6.0, 0.001)
	assert_almost_eq(JUICE.manual_swing_buffer, 0.15, 0.001)


func test_light_hit_feedback_decays() -> void:
	var setup := _make_feedback()
	var feedback := setup[0] as CombatFeedback
	var camera := setup[2] as Camera2D
	watch_signals(feedback)

	feedback.notify_hit(null, 10.0, false)
	assert_eq(feedback.get_last_kind(), &"hit")
	assert_true(feedback.is_hit_stopped())
	assert_signal_emitted(feedback, "feedback_event")
	feedback.tick(0.001)
	assert_ne(camera.offset, Vector2.ZERO, "camera shake harus menggeser offset")
	assert_ne(feedback.get_squash_scale(), Vector2.ONE)

	feedback.tick(1.0)
	assert_eq(camera.offset, Vector2.ZERO, "shake harus kembali nol")
	assert_eq(feedback.get_squash_scale(), Vector2.ONE)


func test_heavy_hit_bigger_then_light() -> void:
	var setup := _make_feedback()
	var feedback := setup[0] as CombatFeedback
	feedback.notify_hit(null, 20.0, false)
	var light_stop := JUICE.hit_stop_light
	feedback.tick(1.0)
	feedback.notify_hit(null, 20.0, true)
	assert_eq(feedback.get_last_kind(), &"heavy_hit")
	assert_true(feedback.is_hit_stopped())
	assert_gt(JUICE.hit_stop_heavy, light_stop, "heavy memakai durasi lebih lama")


func test_screenshake_toggle_and_intensity() -> void:
	var setup := _make_feedback()
	var feedback := setup[0] as CombatFeedback
	var quiet := JUICE.duplicate() as JuiceConfig
	quiet.screenshake_enabled = false
	feedback.config = quiet
	feedback.notify_hit(null, 10.0, false)
	feedback.tick(0.001)
	assert_eq(feedback.get_shake_offset(), Vector2.ZERO, "toggle mati mematikan shake")

	var boosted := JUICE.duplicate() as JuiceConfig
	boosted.intensity = 2.0
	feedback.config = boosted
	feedback.notify_hit(null, 10.0, true)
	assert_true(feedback.is_hit_stopped())


func test_hit_freezes_fauna() -> void:
	var setup := _make_feedback()
	var feedback := setup[0] as CombatFeedback
	var clock := StubClock.new()
	add_child_autofree(clock)
	var player := StubPlayer.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	var boar := BOAR_SCENE.instantiate() as WildBoar
	boar.clock = clock
	boar.player = player
	add_child_autofree(boar)
	boar.ensure_ready()

	feedback.notify_hit(boar, 10.0, false)
	assert_true(boar.is_frozen(), "hit-stop lokal membekukan fauna")
	boar.tick(0.01)
	boar.tick(0.2)
	assert_false(boar.is_frozen())


func test_knockback_ignored_during_dash() -> void:
	var clock := StubClock.new()
	add_child_autofree(clock)
	var player := StubPlayer.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2(200.0, 0.0)
	var boar := BOAR_SCENE.instantiate() as WildBoar
	boar.clock = clock
	boar.player = player
	add_child_autofree(boar)
	boar.global_position = Vector2(0.0, 0.0)
	boar.ensure_ready()

	boar.global_position = Vector2(20.0, 0.0)
	boar.state = WildBoar.State.WANDER
	assert_true(boar.is_knocked_back() == false, "belum ada knockback")
	boar.apply_knockback(Vector2.RIGHT, 40.0, 0.2)
	assert_true(boar.is_knocked_back(), "knockback diterima saat tidak dash")

	boar.state = WildBoar.State.DASH_TELEGRAPH
	boar.apply_knockback(Vector2.RIGHT, 40.0, 0.2)
	assert_true(boar.is_knockback_ignored())


func test_death_sequence_then_free_and_single_loot() -> void:
	var clock := StubClock.new()
	add_child_autofree(clock)
	var player := StubPlayer.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	var boar := BOAR_SCENE.instantiate() as WildBoar
	boar.clock = clock
	boar.player = player
	boar.death_sequence_time = 0.2
	add_child_autofree(boar)
	boar.global_position = Vector2(0.0, 0.0)
	boar.ensure_ready()
	watch_signals(boar)

	var parent := boar.get_parent()
	boar.get_health().take_damage(999.0, null)
	assert_signal_emitted(boar, "died")
	assert_true(boar.is_queued_for_deletion(), "fauna dibebaskan langsung (tanpa geser timing kuota)")
	await get_tree().process_frame
	var corpse: Node = null
	for child in parent.get_children():
		if child.name == "FaunaCorpse":
			corpse = child
	assert_not_null(corpse, "jasad visual terpisah dibuat untuk animasi mati")
	await get_tree().create_timer(0.4).timeout
	assert_false(is_instance_valid(corpse), "jasad visual hilang setelah animasi")


func test_telegraph_line_created_and_cleared() -> void:
	var clock := StubClock.new()
	add_child_autofree(clock)
	var player := StubPlayer.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2(200.0, 0.0)
	var boar := BOAR_SCENE.instantiate() as WildBoar
	boar.clock = clock
	boar.player = player
	add_child_autofree(boar)
	boar.global_position = Vector2(0.0, 0.0)
	boar.ensure_ready()

	boar.tick(0.1)
	assert_not_null(boar.get_telegraph_line(), "garis telegraph muncul saat dash ditelegraphkan")
	boar.tick(2.0)
	assert_null(boar.get_telegraph_line(), "garis dibersihkan saat dash dimulai")


func test_swing_buffer_queues_and_fires() -> void:
	var player := StubPlayer.new()
	add_child_autofree(player)
	var combat := CombatComponent.new()
	combat.player = player
	combat.swing_buffer_time = 0.15
	combat.ignore_ui_guard = true
	player.add_child(combat)
	await get_tree().process_frame

	combat.swing_manual(Vector2.RIGHT)
	assert_gt(combat.get_cooldown(), 0.0, "ayunan pertama memakai cooldown")
	combat.swing_buffer_time = 2.0
	combat.queue_manual_swing(Vector2.RIGHT)
	assert_eq(combat.get_buffered_aim(), Vector2.RIGHT)
	combat.tick(1.0)
	assert_eq(combat.get_buffered_aim(), Vector2.ZERO, "buffer dikonsumsi setelah cooldown habis")
	assert_gt(combat.get_cooldown(), 0.0, "ayunan buffered benar-benar memakai cooldown")


func test_fence_structure_tolerated_by_group_consumers() -> void:
	var fence := CampStructure.new()
	fence.definition = CHEST_DEF
	add_child_autofree(fence)
	assert_true(fence.is_in_group(&"camp_structure"))
	assert_true(fence.has_method(&"take_damage"))
	assert_true(fence.has_method(&"repair"))

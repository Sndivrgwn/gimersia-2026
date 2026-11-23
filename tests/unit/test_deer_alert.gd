extends GutTest

## Mission 9 fase 4: rusa waspada dulu sebelum kabur, dan jongkok memperkecil
## radius deteksinya.

class StubPlayer extends Node2D:
	var stealth: float = 1.0

	func get_stealth_multiplier() -> float:
		return stealth


const DEER_SCENE: PackedScene = preload("res://src/entities/fauna/island_deer/island_deer.tscn")


func _setup(deer_position: Vector2) -> Array:
	var player := StubPlayer.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2.ZERO
	var deer := DEER_SCENE.instantiate() as IslandDeer
	add_child_autofree(deer)
	deer.player = player
	deer.global_position = deer_position
	deer.ensure_ready()
	return [deer, player]


func test_deer_alerts_before_it_flees() -> void:
	# 155 px: di luar radius kabur 130, di dalam radius waspada 162.5.
	var setup := _setup(Vector2(155.0, 0.0))
	var deer := setup[0] as IslandDeer
	watch_signals(deer)
	deer.tick(0.1)
	assert_true(deer.is_alerted(), "rusa berhenti waspada dulu")
	assert_false(deer.is_fleeing())
	assert_eq(deer.get_state(), IslandDeer.State.ALERT)
	assert_signal_emitted(deer, "alerted")


func test_alert_signal_fires_once_per_alert() -> void:
	var setup := _setup(Vector2(155.0, 0.0))
	var deer := setup[0] as IslandDeer
	watch_signals(deer)
	deer.tick(0.1)
	deer.tick(0.1)
	assert_eq(get_signal_emit_count(deer, "alerted"), 1)


func test_deer_flees_when_inside_trigger_radius() -> void:
	var setup := _setup(Vector2(120.0, 0.0))
	var deer := setup[0] as IslandDeer
	deer.tick(0.1)
	assert_true(deer.is_fleeing())
	assert_eq(deer.get_state(), IslandDeer.State.FLEE)


func test_sneaking_player_can_get_closer_before_alert() -> void:
	# Stealth 0.6 -> radius kabur 78, radius waspada 97.5.
	var setup := _setup(Vector2(95.0, 0.0))
	var deer := setup[0] as IslandDeer
	var player := setup[1] as StubPlayer
	player.stealth = 0.6
	deer.tick(0.1)
	assert_true(deer.is_alerted())
	assert_false(deer.is_fleeing(), "jarak 95 px aman dari rusa saat jongkok")


func test_sneaking_player_still_flees_when_too_close() -> void:
	var setup := _setup(Vector2(70.0, 0.0))
	var deer := setup[0] as IslandDeer
	var player := setup[1] as StubPlayer
	player.stealth = 0.6
	deer.tick(0.1)
	assert_true(deer.is_fleeing(), "70 px masih di dalam radius kabur 78")


func test_effective_detect_radius_follows_stealth() -> void:
	var setup := _setup(Vector2(400.0, 0.0))
	var deer := setup[0] as IslandDeer
	var player := setup[1] as StubPlayer
	assert_almost_eq(deer.get_effective_detect_radius(), 130.0, 0.01)
	player.stealth = 0.6
	assert_almost_eq(deer.get_effective_detect_radius(), 78.0, 0.01)


func test_deer_returns_to_wander_when_player_leaves() -> void:
	var setup := _setup(Vector2(155.0, 0.0))
	var deer := setup[0] as IslandDeer
	var player := setup[1] as StubPlayer
	deer.tick(0.1)
	assert_true(deer.is_alerted())
	player.global_position = Vector2(2000.0, 0.0)
	deer.tick(0.1)
	assert_false(deer.is_alerted())
	assert_eq(deer.get_state(), IslandDeer.State.WANDER)


func test_alert_mark_is_visible_only_while_alerted() -> void:
	var setup := _setup(Vector2(155.0, 0.0))
	var deer := setup[0] as IslandDeer
	var player := setup[1] as StubPlayer
	deer.tick(0.1)
	assert_true(deer.is_alert_mark_visible(), "tanda \"!\" muncul saat waspada")
	assert_eq(deer.get_alert_mark().text, "!")
	player.global_position = Vector2(2000.0, 0.0)
	deer.tick(0.1)
	assert_false(deer.is_alert_mark_visible(), "tanda hilang saat pemain pergi")


func test_alert_mark_hides_when_fleeing() -> void:
	var setup := _setup(Vector2(120.0, 0.0))
	var deer := setup[0] as IslandDeer
	deer.tick(0.1)
	assert_true(deer.is_fleeing())
	assert_false(deer.is_alert_mark_visible(), "tidak ada \"!\" saat sudah kabur")


func test_alert_uses_idle_art() -> void:
	assert_eq(VisualStateMap.deer_state(IslandDeer.State.ALERT, false), &"idle")

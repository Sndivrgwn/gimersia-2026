extends GutTest

class StubClock extends Node:
	signal day_started(day: int)
	signal rescue_started
	var day: int = 1

	func is_night() -> bool:
		return false

	func get_current_day() -> int:
		return day

	func get_time_scale() -> float:
		return 1.0


var _clock: StubClock
var _parent: Node2D
var _quota: FaunaQuota


func before_each() -> void:
	_clock = StubClock.new()
	add_child_autofree(_clock)

	var player := Node2D.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2.ZERO

	for index in 4:
		var marker := Marker2D.new()
		marker.add_to_group(&"night_spawn_point")
		add_child_autofree(marker)
		marker.global_position = Vector2(900.0 + 200.0 * index, 0.0)

	_parent = Node2D.new()
	add_child_autofree(_parent)
	_quota = FaunaQuota.new()
	_quota.clock = _clock
	_quota.fauna_parent = _parent
	_quota.rng.seed = 7
	add_child_autofree(_quota)


func _boars() -> Array[WildBoar]:
	var result: Array[WildBoar] = []
	for child in _parent.get_children():
		if child is WildBoar:
			result.append(child)
	return result


func _kill_all_boars() -> void:
	for boar in _boars():
		boar.get_health().take_damage(9999.0, null)
	# D5: fauna menyelesaikan animasi mati 0.25 s sebelum dibebaskan.
	await get_tree().create_timer(0.35).timeout


func test_initial_quota_is_two_boars_and_three_deer() -> void:
	assert_eq(_quota.get_boar_count(), 2)
	assert_eq(_quota.get_deer_count(), 3)


func test_no_midday_respawn() -> void:
	await _kill_all_boars()
	assert_eq(_quota.get_boar_count(), 0)
	_quota.tick(120.0)
	assert_eq(_quota.get_boar_count(), 0)


func test_dawn_rule_tops_up_and_resets_survivors() -> void:
	await _kill_all_boars()
	_quota._on_day_started(2)
	assert_eq(_quota.get_boar_count(), 2)
	for boar in _boars():
		assert_eq(boar.get_temperament(), FaunaBase.Temperament.NEUTRAL)
		assert_eq(boar.get_damage_multiplier(), 1.0)


func test_rescue_guarantees_two_boars_and_respawns_after_45s() -> void:
	await _kill_all_boars()
	_quota._on_rescue_started()
	assert_eq(_quota.get_boar_count(), 2)
	assert_true(_quota.guarantee_deer_at_rescue == false)

	var boar := _boars()[0]
	boar.get_health().take_damage(9999.0, null)
	await get_tree().process_frame
	_quota.tick(44.0)
	assert_eq(_quota.get_boar_count(), 1)
	_quota.tick(1.0)
	assert_eq(_quota.get_boar_count(), 2)
	assert_eq(_quota.get_extra_respawns_left(), 3)


func test_spawn_position_prefers_markers_at_least_600px_away() -> void:
	var point: Vector2 = _quota.get_spawn_position()
	assert_gte(point.distance_to(Vector2.ZERO), 600.0)

func test_spawn_position_keeps_60px_clear_of_player_and_fauna() -> void:
	for offset in [2000.0, 2100.0]:
		var marker := Marker2D.new()
		marker.add_to_group(&"night_spawn_point")
		add_child_autofree(marker)
		marker.global_position = Vector2(offset, 300.0)
	var point: Vector2 = _quota.get_spawn_position()
	assert_gte(point.distance_to(Vector2.ZERO), 60.0, "jauh dari pemain")
	for child in _parent.get_children():
		if child is FaunaBase:
			assert_gte(point.distance_to((child as Node2D).global_position), 60.0, "jauh dari badan fauna")

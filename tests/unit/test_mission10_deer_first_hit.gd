extends GutTest

## Mission 10 Phase 4: simulasi first-hit rusa dengan badan rusa sungguhan dan
## stub pemain yang bergerak pada kecepatan nyata.
## Angka: tangan kosong 45 px / 8 damage, Tombak Kayu 75 px / 18 damage,
## rusa 40 HP, sneak 0.55 x 160 = 88 px/s, sprint 240 px/s.

const DEER_SCENE: PackedScene = preload("res://src/entities/fauna/island_deer/island_deer.tscn")
const DELTA := 1.0 / 60.0
const SNEAK_SPEED := 88.0
const SPRINT_SPEED := 240.0
const BARE_RANGE := 45.0
const BARE_DAMAGE := 8.0
const SPEAR_RANGE := 75.0
const SPEAR_DAMAGE := 18.0


class StubClock extends Node:
	func is_night() -> bool:
		return false

	func get_current_day() -> int:
		return 1

	func get_time_scale() -> float:
		return 1.0


class StubPlayer extends Node2D:
	var stealth: float = 1.0

	func get_stealth_multiplier() -> float:
		return stealth


var _clock: StubClock


func before_each() -> void:
	_clock = StubClock.new()
	add_child_autofree(_clock)


func _spawn(start_distance: float, stealth: float) -> Array:
	var player := StubPlayer.new()
	player.stealth = stealth
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2(start_distance, 0.0)
	var deer := DEER_SCENE.instantiate() as IslandDeer
	deer.player = player
	deer.clock = _clock
	add_child_autofree(deer)
	deer.global_position = Vector2.ZERO
	deer.ensure_ready()
	deer._wander_pause = 9999.0
	return [deer, player]


func _simulate(start_distance: float, move_speed: float, stealth: float, attack_range: float, damage: float) -> Dictionary:
	var setup := _spawn(start_distance, stealth)
	var deer := setup[0] as IslandDeer
	var player := setup[1] as StubPlayer
	var hit := false
	var hit_time := -1.0
	var hit_distance := -1.0
	var state_at_hit := -1
	var frames := int(10.0 / DELTA)
	for index in frames:
		if not hit:
			var to := deer.global_position - player.global_position
			if to.length() > 0.001:
				player.global_position += to.normalized() * move_speed * DELTA
		deer.tick(DELTA)
		var distance := player.global_position.distance_to(deer.global_position)
		if not hit and distance <= attack_range:
			state_at_hit = deer.get_state()
			deer.get_health().take_damage(damage, player)
			hit = true
			hit_time = float(index + 1) * DELTA
			hit_distance = distance
			break
	return {
		"hit": hit,
		"time": hit_time,
		"distance": hit_distance,
		"state": state_at_hit,
		"deer_state": deer.get_state(),
		"attackable": deer.get_health().get_current_hp() < deer.get_health().get_max_hp(),
	}


func test_s1_bare_hands_sneaking_from_300px_lands_first_hit() -> void:
	var result := _simulate(300.0, SNEAK_SPEED, 0.6, BARE_RANGE, BARE_DAMAGE)
	assert_true(result["hit"], "serangan tangan kosong mendarat")
	assert_lte(result["distance"], BARE_RANGE, "mendarat di dalam jangkauan 45 px")
	assert_true(result["attackable"], "damage benar-benar masuk")
	assert_lt(result["time"], 5.0, "third: waktu first-hit: %.2f s" % result["time"])


func test_s2_wooden_spear_sneaking_from_300px_lands_first_hit() -> void:
	var result := _simulate(300.0, SNEAK_SPEED, 0.6, SPEAR_RANGE, SPEAR_DAMAGE)
	assert_true(result["hit"], "Tombak Kayu mendarat")
	assert_lte(result["distance"], SPEAR_RANGE, "mendarat di dalam jangkauan 75 px")
	assert_lt(result["time"], 5.0, "waktu first-hit: %.2f s" % result["time"])


func test_s3_sprinting_from_200px_lands_hit_during_alert_or_startle() -> void:
	var result := _simulate(200.0, SPRINT_SPEED, 1.0, BARE_RANGE, BARE_DAMAGE)
	assert_true(result["hit"], "sprint mengejar mendarat")
	var state: int = result["state"]
	assert_true(
		state == IslandDeer.State.ALERT or state == IslandDeer.State.STARTLE,
		"hit mendarat saat ALERT/STARTLE, bukan setelah FLEE"
	)
	assert_eq(result["deer_state"], IslandDeer.State.FLEE, "damage langsung memicu FLEE")


func test_s4_second_hit_only_inside_the_hit_stun_window() -> void:
	var setup := _spawn(60.0, 1.0)
	var deer := setup[0] as IslandDeer
	var player := setup[1] as StubPlayer
	deer.tick(DELTA)
	deer.get_health().take_damage(BARE_DAMAGE, player)
	assert_eq(deer.get_state(), IslandDeer.State.FLEE)
	assert_almost_eq(deer.get_hit_stun_remaining(), 0.35, 0.001)
	var start := deer.global_position
	deer.tick(0.2)
	assert_lt(deer.global_position.distance_to(start), 1.0, "terpaku selama hit-stun")
	deer.get_health().take_damage(BARE_DAMAGE, player)
	assert_almost_eq(deer.get_health().get_current_hp(), 24.0, 0.01, "hit kedua bisa masuk")
	deer.tick(0.3)
	var after_stun := deer.global_position
	deer.tick(1.0)
	assert_gt(deer.global_position.distance_to(after_stun), 1.0, "setelah stun rusa berlari")


func test_s5_flee_ends_and_tired_deer_is_catchable() -> void:
	var setup := _spawn(120.0, 1.0)
	var deer := setup[0] as IslandDeer
	var player := setup[1] as StubPlayer
	# Jangan sampai despawn karena jarak; yang diuji adalah habisnya durasi kabur.
	deer.config.flee_despawn_distance = 999999.0
	deer.begin_flee(player.global_position, deer._deer_config().flee_duration)
	deer.state = IslandDeer.State.FLEE
	deer.get_health().take_damage(BARE_DAMAGE, player)
	var elapsed := 0.0
	while elapsed < deer._deer_config().flee_duration + 0.1:
		deer.tick(DELTA)
		elapsed += DELTA
	assert_eq(deer.get_state(), IslandDeer.State.WANDER, "kabur habis -> mengembara lagi")
	player.global_position = deer.global_position + Vector2(30.0, 0.0)
	var before := deer.get_health().get_current_hp()
	player.global_position = deer.global_position + Vector2(BARE_RANGE - 1.0, 0.0)
	deer.get_health().take_damage(BARE_DAMAGE, player)
	assert_lt(deer.get_health().get_current_hp(), before, "rusa lelah masih bisa dipukul")


# --- State / ramp -----------------------------------------------------------

func test_alert_timer_then_startle_timer() -> void:
	var setup := _spawn(155.0, 1.0)
	var deer := setup[0] as IslandDeer
	deer.tick(0.1)
	assert_eq(deer.get_state(), IslandDeer.State.ALERT)
	deer.tick(0.45)
	assert_eq(deer.get_state(), IslandDeer.State.STARTLE)
	assert_almost_eq(deer.get_startle_remaining(), 0.9, 0.02)
	deer.tick(0.9)
	assert_eq(deer.get_state(), IslandDeer.State.FLEE)


func test_flee_speed_ramps_from_zero_to_full() -> void:
	var setup := _spawn(100.0, 1.0)
	var deer := setup[0] as IslandDeer
	var player := setup[1] as StubPlayer
	deer.begin_flee(player.global_position, deer._deer_config().flee_duration)
	assert_almost_eq(deer.get_current_flee_speed(), 0.0, 0.01, "t=0 masih 0")
	deer.tick(0.25)
	assert_almost_eq(deer.get_current_flee_speed(), 175.0 * 0.5, 2.0, "t=0.25 setengah")
	deer.tick(0.25)
	assert_almost_eq(deer.get_current_flee_speed(), 175.0, 2.0, "t=0.5 penuh")


func test_damage_in_wander_alert_and_startle_all_flee_with_stun() -> void:
	for state in [IslandDeer.State.WANDER, IslandDeer.State.ALERT, IslandDeer.State.STARTLE]:
		var setup := _spawn(400.0, 1.0)
		var deer := setup[0] as IslandDeer
		deer.state = state
		deer.get_health().take_damage(BARE_DAMAGE, null)
		assert_eq(deer.get_state(), IslandDeer.State.FLEE, "state %d -> FLEE" % state)
		assert_almost_eq(deer.get_hit_stun_remaining(), 0.35, 0.001)
		assert_eq(deer.get_health().get_current_hp(), 32.0)


func test_calm_return_clears_provoke() -> void:
	var setup := _spawn(120.0, 1.0)
	var deer := setup[0] as IslandDeer
	deer.begin_flee(Vector2(1000.0, 1000.0), 0.2)
	deer.state = IslandDeer.State.FLEE
	deer.tick(0.3)
	assert_eq(deer.get_state(), IslandDeer.State.WANDER)
	assert_false(deer.is_provoked(), "kembali tenang setelah kabur")

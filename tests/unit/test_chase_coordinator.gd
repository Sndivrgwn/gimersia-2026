extends GutTest

## Mission 16 (L3): unit test ChaseCoordinator dan perilaku kelompok WildBoar.

const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")


class StubClock extends Node:
	var night: bool = true
	var day: int = 1
	var scale: float = 1.0

	func is_night() -> bool:
		return night

	func get_current_day() -> int:
		return day

	func get_time_scale() -> float:
		return scale


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


# --- Pure ChaseCoordinator tests --------------------------------------------

func test_coordinator_slots_spread_evenly_and_stay_stable() -> void:
	var coord := ChaseCoordinator.new()
	var cfg := BoarConfig.new()
	cfg.approach_slot_count = 5
	coord.setup(cfg)

	for id in range(1, 6):
		coord.register(id)

	var angles: Array[float] = []
	for id in range(1, 6):
		angles.append(coord.slot_angle(id))

	# Semua 5 sudut unik dan terpisah minimal (TAU / 5) - epsilon.
	for i in angles.size():
		for j in range(i + 1, angles.size()):
			var diff := absf(angle_difference(angles[i], angles[j]))
			assert_gte(diff, TAU / 5.0 - 0.01, "sudut slot tersebar merata")

	# Stabil antar tick & walau satu musuh keluar.
	coord.tick(0.5)
	coord.unregister(3)
	assert_almost_eq(coord.slot_angle(1), angles[0], 0.0001, "sudut slot tidak jitter")
	assert_almost_eq(coord.slot_angle(5), angles[4], 0.0001)


func test_coordinator_tokens_limit_release_and_timeout() -> void:
	var coord := ChaseCoordinator.new()
	var cfg := BoarConfig.new()
	cfg.max_simultaneous_attackers = 2
	coord.setup(cfg)
	coord.token_timeout_seconds = 1.0

	assert_true(coord.request_attack_token(1))
	assert_true(coord.request_attack_token(2))
	assert_false(coord.request_attack_token(3), "melebihi max_simultaneous_attackers ditolak")
	assert_eq(coord.active_token_count(), 2)

	# Unregister (musuh mati) melepas token.
	coord.unregister(1)
	assert_eq(coord.active_token_count(), 1)
	assert_true(coord.request_attack_token(3), "musuh berikutnya dapat token")

	# Timeout otomatis melepas token yang tertahan lama.
	coord.tick(1.1)
	assert_eq(coord.active_token_count(), 0, "token otomatis dilepas saat timeout")


func test_coordinator_separation_zero_without_neighbors_and_clamped() -> void:
	var coord := ChaseCoordinator.new()
	var cfg := BoarConfig.new()
	cfg.separation_radius_px = 48.0
	cfg.separation_weight = 1.2
	coord.setup(cfg)

	assert_eq(coord.separation(Vector2.ZERO, []), Vector2.ZERO, "nol tanpa tetangga")
	assert_eq(coord.separation(Vector2.ZERO, [Vector2(100.0, 0.0)]), Vector2.ZERO, "nol di luar radius")

	var push := coord.separation(Vector2.ZERO, [
		Vector2(5.0, 0.0), Vector2(4.0, 1.0), Vector2(6.0, -1.0), Vector2(3.0, 0.0),
	])
	assert_gt(push.length(), 0.0)
	assert_lte(push.length(), cfg.separation_weight + 0.001, "gaya separation ter-clamp")
	assert_lt(push.x, 0.0, "menjauh dari tetangga di kanan")


func test_coordinator_same_seed_is_deterministic() -> void:
	var a := ChaseCoordinator.new()
	var b := ChaseCoordinator.new()
	var cfg := BoarConfig.new()
	a.setup(cfg)
	b.setup(cfg)
	a.set_seed(42)
	b.set_seed(42)
	for _i in 5:
		assert_almost_eq(a.next_cooldown(), b.next_cooldown(), 0.0001)
		assert_almost_eq(a.next_reaction_delay(), b.next_reaction_delay(), 0.0001)


# --- Multi-boar behavior & regression tests ---------------------------------

func test_five_boars_spread_around_player_limit_attackers_and_never_leak_tokens() -> void:
	var clock := StubClock.new()
	add_child_autofree(clock)
	var player := StubPlayer.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2.ZERO

	var coord := ChaseCoordinator.new()
	coord.set_seed(123)

	var boars: Array[WildBoar] = []
	for i in 5:
		var boar := BOAR_SCENE.instantiate() as WildBoar
		boar.clock = clock
		boar.player = player
		boar.coordinator = coord
		add_child_autofree(boar)
		# Mulai dari gugus yang sama di kanan pemain.
		boar.global_position = Vector2(210.0 + float(i) * 8.0, float(i - 2) * 4.0)
		boar.ensure_ready()
		boar.set_physics_process(false)
		boars.append(boar)

	var max_simultaneous_seen := 0
	for _step in 60:
		for boar in boars:
			boar.tick(0.05)
		max_simultaneous_seen = maxi(max_simultaneous_seen, coord.active_token_count())

	assert_lte(max_simultaneous_seen, 2, "maksimal max_simultaneous_attackers (2) menyerang serentak")

	# Sebaran sudut di sekitar pemain: tidak berbaris di satu garis (ambang karangan: > 0.3 rad).
	var min_angle_diff := TAU
	var max_angle_diff := 0.0
	for i in boars.size():
		for j in range(i + 1, boars.size()):
			var a1 := (boars[i].global_position - player.global_position).angle()
			var a2 := (boars[j].global_position - player.global_position).angle()
			var diff := absf(angle_difference(a1, a2))
			min_angle_diff = minf(min_angle_diff, diff)
			max_angle_diff = maxf(max_angle_diff, diff)
	assert_gt(max_angle_diff, 0.3, "kelompok 5 babi menyebar, tidak satu garis conga line")

	# Tidak saling menumpuk (jarak minimum antar babi terjaga).
	for i in boars.size():
		for j in range(i + 1, boars.size()):
			assert_gte(boars[i].global_position.distance_to(boars[j].global_position), 20.0, "babi tidak menumpuk")

	# Matikan semua babi -> semua token & registrasi bersih (0 bocor).
	for boar in boars:
		boar.death_sequence_time = 0.0
		boar.get_health().take_damage(999.0, player)
	assert_eq(coord.active_token_count(), 0, "tidak ada token bocor setelah semua musuh mati")
	assert_eq(coord.registered_count(), 0, "semua musuh ter-unregister")


func test_dash_locks_direction_and_smart_chase_false_restores_legacy() -> void:
	var clock := StubClock.new()
	add_child_autofree(clock)
	var player := StubPlayer.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2.ZERO

	var boar := BOAR_SCENE.instantiate() as WildBoar
	boar.clock = clock
	boar.player = player
	add_child_autofree(boar)
	boar.global_position = Vector2(180.0, 0.0)
	boar.ensure_ready()
	boar.set_physics_process(false)

	# Balance tidak berubah: HP 80, bite 12, dash 20.
	assert_almost_eq(boar.get_health().get_max_hp(), 80.0, 0.01)
	assert_almost_eq(boar.config_boar().bite_damage, 12.0, 0.01)
	assert_almost_eq(boar.config_boar().dash_player_damage, 20.0, 0.01)

	# Windup -> pindah pemain ke atas -> dash tetap lurus ke kiri (tidak melacak pemain).
	boar.tick(0.01)
	assert_eq(boar.get_state(), WildBoar.State.DASH_TELEGRAPH)
	player.global_position = Vector2(0.0, -250.0)
	boar.tick(0.85)
	assert_eq(boar.get_state(), WildBoar.State.DASH)
	var y_before := boar.global_position.y
	boar.tick(0.1)
	assert_almost_eq(boar.global_position.y, y_before, 1.0, "arah dash terkunci, tidak berbelok mengejar pemain")

	# time_scale = 0 membekukan AI.
	clock.scale = 0.0
	var pos_frozen := boar.global_position
	boar.tick(0.5)
	assert_eq(boar.global_position, pos_frozen, "time_scale = 0 membekukan gerak")

	# smart_chase_enabled = false memakai jalur lama tanpa coordinator.
	var legacy_cfg := BoarConfig.new()
	legacy_cfg.smart_chase_enabled = false
	var legacy := BOAR_SCENE.instantiate() as WildBoar
	legacy.config = legacy_cfg
	legacy.clock = clock
	legacy.player = player
	add_child_autofree(legacy)
	legacy.global_position = Vector2(200.0, -250.0)
	legacy.ensure_ready()
	legacy.set_physics_process(false)
	clock.scale = 1.0
	legacy.tick(0.05)
	assert_null(legacy.coordinator, "smart_chase_enabled = false tidak membuat koordinator")

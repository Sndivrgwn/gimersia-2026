class_name ChaseCoordinator
extends RefCounted

## Mission 16 (L3): koordinator murni untuk kejar & serang kelompok musuh.
## Menangani slot pendekatan stabil (flank/surround), batas penyerang serentak
## (attack token + auto-timeout), tujuan circling, dan gaya separation.
## Tanpa akses scene; hanya delta nyata dan RNG yang bisa di-seed.

const DEFAULT_TOKEN_TIMEOUT := 4.5

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var separation_radius_px: float = 48.0
var separation_weight: float = 1.2
var max_simultaneous_attackers: int = 2
var circle_radius_px: float = 140.0
var approach_slot_count: int = 5
var attack_cooldown_min: float = 1.2
var attack_cooldown_max: float = 2.2
var reaction_delay_max: float = 0.35
var token_timeout_seconds: float = DEFAULT_TOKEN_TIMEOUT

## enemy_id (int) -> slot_index (int)
var _slots: Dictionary = {}
## enemy_id (int) -> hold_elapsed (float)
var _tokens: Dictionary = {}
## Sudut orbit lembut untuk musuh yang sedang mengitari target.
var _orbit_phase: float = 0.0


func setup(cfg: BoarConfig) -> void:
	if cfg == null:
		return
	separation_radius_px = maxf(cfg.separation_radius_px, 0.0)
	separation_weight = maxf(cfg.separation_weight, 0.0)
	max_simultaneous_attackers = maxi(cfg.max_simultaneous_attackers, 1)
	circle_radius_px = maxf(cfg.circle_radius_px, 24.0)
	approach_slot_count = maxi(cfg.approach_slot_count, 2)
	attack_cooldown_min = maxf(cfg.attack_cooldown_min, 0.0)
	attack_cooldown_max = maxf(cfg.attack_cooldown_max, attack_cooldown_min)
	reaction_delay_max = maxf(cfg.reaction_delay_max, 0.0)


func set_seed(seed_value: int) -> void:
	rng.seed = seed_value


func register(enemy_id: int) -> void:
	if _slots.has(enemy_id):
		return
	var slot_count := maxi(approach_slot_count, 2)
	var counts: Array[int] = []
	counts.resize(slot_count)
	for i in slot_count:
		counts[i] = 0
	for existing_slot in _slots.values():
		var idx := int(existing_slot) % slot_count
		counts[idx] += 1
	var best_slot := 0
	var best_count := counts[0]
	for i in range(1, slot_count):
		if counts[i] < best_count:
			best_count = counts[i]
			best_slot = i
	_slots[enemy_id] = best_slot


func unregister(enemy_id: int) -> void:
	_slots.erase(enemy_id)
	_tokens.erase(enemy_id)


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	_orbit_phase = fmod(_orbit_phase + delta * 0.45, TAU)
	var expired: Array[int] = []
	for enemy_id in _tokens.keys():
		var held := float(_tokens[enemy_id]) + delta
		if token_timeout_seconds > 0.0 and held >= token_timeout_seconds:
			expired.append(int(enemy_id))
		else:
			_tokens[enemy_id] = held
	for enemy_id in expired:
		_tokens.erase(enemy_id)


## Sudut pendekatan stabil (radian, 0..TAU) yang tersebar merata di antara musuh aktif.
func slot_angle(enemy_id: int) -> float:
	if not _slots.has(enemy_id):
		register(enemy_id)
	var slot_count := maxi(approach_slot_count, 2)
	var idx := int(_slots[enemy_id]) % slot_count
	return (float(idx) / float(slot_count)) * TAU


func request_attack_token(enemy_id: int) -> bool:
	if not _slots.has(enemy_id):
		register(enemy_id)
	if _tokens.has(enemy_id):
		return true
	if _tokens.size() >= max_simultaneous_attackers:
		return false
	_tokens[enemy_id] = 0.0
	return true


func release_attack_token(enemy_id: int) -> void:
	_tokens.erase(enemy_id)


func has_attack_token(enemy_id: int) -> bool:
	return _tokens.has(enemy_id)


func active_token_count() -> int:
	return _tokens.size()


func registered_count() -> int:
	return _slots.size()


## Offset tujuan relatif terhadap `target_pos`: slot flank bila punya token,
## atau titik mengitari pada `circle_radius_px` bila sedang menunggu giliran.
func desired_offset(enemy_id: int, target_pos: Vector2, own_pos: Vector2, contact_radius: float = 30.0) -> Vector2:
	var base_angle := slot_angle(enemy_id)
	if has_attack_token(enemy_id):
		var dist := own_pos.distance_to(target_pos)
		var slot_dist := maxf(contact_radius, 12.0)
		# Saat jauh, dekati sudut slot flank-nya; saat dekat, tutup jarak langsung.
		if dist > slot_dist * 1.4:
			return Vector2.from_angle(base_angle) * slot_dist
		return Vector2.from_angle(base_angle) * (slot_dist * 0.6)
	# Belum punya token: mengitari di jarak circle_radius_px.
	var orbit_angle := fmod(base_angle + _orbit_phase, TAU)
	return Vector2.from_angle(orbit_angle) * circle_radius_px


## Gaya penolakan terbatas (ter-clamp ke <= separation_weight); nol bila tanpa tetangga dekat.
func separation(own_pos: Vector2, neighbor_positions: Array) -> Vector2:
	if separation_radius_px <= 0.0 or separation_weight <= 0.0 or neighbor_positions.is_empty():
		return Vector2.ZERO
	var push := Vector2.ZERO
	var radius := separation_radius_px
	for raw in neighbor_positions:
		if not (raw is Vector2):
			continue
		var neighbor: Vector2 = raw
		var diff := own_pos - neighbor
		var dist := diff.length()
		if dist >= radius:
			continue
		var dir := diff / dist if dist > 0.0001 else Vector2.RIGHT
		var strength := clampf(1.0 - dist / radius, 0.0, 1.0)
		push += dir * strength
	if push.length_squared() <= 0.000001:
		return Vector2.ZERO
	var weighted := push * separation_weight
	if weighted.length() > separation_weight:
		weighted = weighted.normalized() * separation_weight
	return weighted


func next_cooldown() -> float:
	if is_equal_approx(attack_cooldown_min, attack_cooldown_max):
		return attack_cooldown_min
	return rng.randf_range(attack_cooldown_min, attack_cooldown_max)


func next_reaction_delay() -> float:
	if reaction_delay_max <= 0.0:
		return 0.0
	return rng.randf_range(0.0, reaction_delay_max)

class_name WildBoar
extends FaunaBase

## Babi hutan (spesifikasi §7.3). Siang NEUTRAL (mengembara sampai diprovokasi),
## malam HOSTILE. Bisa menggigit, menyerbu (dash), dan menyerang struktur camp.

signal dash_ended(hit: bool)

enum State { WANDER, CHASE, BITE, DASH_TELEGRAPH, DASH, RECOVER, FLEE }

const DEFAULT_RAID_CONFIG: RaidConfig = preload("res://src/data/configs/fauna/raid_config.tres")
const CAMP_CENTER := Vector2.ZERO
const RECOVER_TIME := 0.3
## Spesifikasi §7.2: knockback dash 60 px (durasi 0.2 s di CombatConfig).
const DASH_KNOCKBACK_DISTANCE := 60.0

## Mission 9: mode raid + tanda raider (ditulis RaidDirector secara additive).
@export var raid_config: RaidConfig = DEFAULT_RAID_CONFIG
var is_raider: bool = false

var state: int = State.WANDER

var _bite_cooldown: float = 0.0
var _dash_cooldown: float = 0.0
var _telegraph_remaining: float = 0.0
## Anggaran waktu dash (Mission 9 fase 4): dash yang terhalang dinding/pagar tidak
## boleh macet di state DASH selamanya.
var _dash_remaining: float = 0.0
var _recover_remaining: float = 0.0
var _dash_target: Vector2 = Vector2.ZERO
var _dash_hit: bool = false
var _telegraph_line: Line2D
var _telegraph_label: Label


func _ready() -> void:
	super()
	ensure_ready()
	temperament = Temperament.HOSTILE if (forced_hostile or _is_night()) else Temperament.NEUTRAL


func visual_key() -> StringName:
	return &"wild_boar"


func config_boar() -> BoarConfig:
	return config as BoarConfig


# --- Raid (Mission 9) -------------------------------------------------------

## Tandai boar sebagai raider (menyerang struktur) atau bukan.
func set_raider(value: bool) -> void:
	is_raider = value
	if not value:
		raid_camp = false


func get_raid_mode() -> int:
	if raid_config == null:
		raid_config = DEFAULT_RAID_CONFIG
	return raid_config.mode


## Struktur boleh diserang: ALWAYS (perilaku lama) atau raider di EVENT_ONLY.
func can_attack_structures() -> bool:
	var mode := get_raid_mode()
	if mode == RaidConfig.Mode.OFF:
		return false
	if mode == RaidConfig.Mode.ALWAYS:
		return true
	return is_raider


func get_state() -> int:
	return state


func _update_behavior(delta: float) -> void:
	var boar := config_boar()
	if boar == null:
		_wander(delta)
		return

	_bite_cooldown = maxf(_bite_cooldown - delta * get_attack_speed_factor(), 0.0)
	_dash_cooldown = maxf(_dash_cooldown - delta, 0.0)

	var target := _find_player()
	_update_temperament(delta, target)

	if state == State.DASH_TELEGRAPH:
		_tick_telegraph(delta, boar)
		return
	if state == State.DASH:
		_tick_dash(delta, boar)
		return
	if state == State.RECOVER:
		_recover_remaining -= delta
		move_in_direction(Vector2.ZERO, 0.0, delta)
		if _recover_remaining <= 0.0:
			state = State.CHASE
		return

	_update_raid_flag(target, boar)
	var chosen := _choose_target(target, boar)

	if chosen == null:
		state = State.WANDER
		_wander(delta)
		return

	var chosen_position := (chosen as Node2D).global_position
	var distance := global_position.distance_to(chosen_position)

	# D2: pagar yang utuh menghalangi serangan ke target di belakangnya.
	var blocker := _blocking_fence(chosen_position)
	if blocker != null:
		if blocker.distance_to_point(global_position) <= boar.bite_range and _bite_cooldown <= 0.0:
			_bite(blocker, boar)
			return
		state = State.CHASE
		face(blocker.global_position - global_position)
		move_in_direction(blocker.global_position - global_position, get_move_speed(), delta)
		return

	if distance <= boar.bite_range and _bite_cooldown <= 0.0:
		_bite(chosen, boar)
		return

	if distance >= boar.dash_min_distance and distance <= boar.dash_max_distance and _dash_cooldown <= 0.0:
		_begin_telegraph(chosen_position, boar)
		return

	state = State.CHASE
	face(chosen_position - global_position)
	# Mission 9: jangan menekan pemain; berhenti di jarak kontak.
	if chosen == target and distance <= get_contact_distance_to_player():
		move_in_direction(Vector2.ZERO, 0.0, delta)
		return
	move_in_direction(chosen_position - global_position, get_move_speed(), delta)


# --- Decision ---------------------------------------------------------------

## Temperament diturunkan tiap tick, tidak sticky: HOSTILE hanya malam atau
## `forced_hostile` debug. Provoke adalah flag terpisah (lihat
## `can_be_auto_targeted()`), berakhir lepas leash atau `provoke_calm_seconds`
## tanpa hit yang bertukar.
func _update_temperament(delta: float, target: Node) -> void:
	var boar := config_boar()
	if _provoked:
		tick_provoke(delta)
		var out_of_leash := target is Node2D and boar != null \
			and global_position.distance_to((target as Node2D).global_position) > boar.leash_radius
		var calm := boar != null and get_provoke_elapsed() >= boar.provoke_calm_seconds
		if out_of_leash or calm or target == null:
			_calm_down()

	var was_hostile := temperament == Temperament.HOSTILE
	var next_hostility := Temperament.HOSTILE if (forced_hostile or _is_night()) else Temperament.NEUTRAL
	temperament = next_hostility
	if was_hostile and next_hostility != Temperament.HOSTILE:
		_calm_down()


## Kembali tenang: provoke hilang, tanpa target, state WANDER.
func _calm_down() -> void:
	_clear_telegraph()
	clear_provoke()
	reset_provoke_calm()
	raid_camp = false
	state = State.WANDER
	_telegraph_remaining = 0.0
	_recover_remaining = 0.0
	_dash_target = Vector2.ZERO
	_dash_hit = false
	if _visual != null:
		_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _update_raid_flag(target: Node, boar: BoarConfig) -> void:
	if not can_be_auto_targeted():
		raid_camp = false
		return
	# Mission 9: EVENT_ONLY hanya raider yang menyerang struktur; OFF tidak pernah.
	var mode := get_raid_mode()
	if mode != RaidConfig.Mode.ALWAYS:
		raid_camp = is_raider and can_attack_structures()
		return
	if nearest_structure() == null:
		raid_camp = false
		return
	var center := CampAnchor.center_of(self)
	if global_position.distance_to(center) > boar.raid_clear_radius:
		raid_camp = false
		return
	if target == null or not (target is Node2D):
		return
	var target_position := (target as Node2D).global_position
	if global_position.distance_to(target_position) > boar.detect_radius * get_detection_multiplier(target):
		return
	if target_position.distance_to(center) <= boar.raid_camp_radius:
		raid_camp = true
	elif state == State.CHASE and global_position.distance_to(center) <= boar.raid_camp_radius:
		raid_camp = true


## Prioritas: pemain <= 140 px, lalu struktur (bila raid_camp), lalu pemain
## yang terdeteksi, kalau tidak null (mengembara).
func _choose_target(target: Node, boar: BoarConfig) -> Node:
	var player_node := target as Node2D
	if player_node != null and _player_alive() and can_be_auto_targeted():
		var distance := global_position.distance_to(player_node.global_position)
		if distance <= boar.camp_player_radius:
			return target
	if raid_camp and can_attack_structures():
		var structure := nearest_structure()
		if structure != null:
			return structure
	if player_node != null and _player_alive():
		var distance := global_position.distance_to(player_node.global_position)
		if distance <= boar.detect_radius * get_detection_multiplier(target) and can_be_auto_targeted():
			return target
	return null


func _player_alive() -> bool:
	var target := _find_player()
	if target == null:
		return false
	var stats := target.get_node_or_null("StatsComponent") as StatsComponent
	if stats == null:
		return true
	return stats.current_hp > 0.0


# --- Attacks ----------------------------------------------------------------

func _bite(target: Node, boar: BoarConfig) -> void:
	state = State.BITE
	move_in_direction(Vector2.ZERO, 0.0, 0.0)
	_bite_cooldown = boar.bite_cooldown
	_deal_damage(target, boar.bite_damage, boar.bite_damage, Vector2.ZERO, 0.0)
	state = State.CHASE


func _begin_telegraph(locked_position: Vector2, boar: BoarConfig) -> void:
	state = State.DASH_TELEGRAPH
	_telegraph_remaining = boar.dash_telegraph
	_dash_target = locked_position
	_dash_hit = false
	move_in_direction(Vector2.ZERO, 0.0, 0.0)
	if _visual != null:
		_visual.modulate = Color(1.5, 0.5, 0.5, 1.0)
	_show_telegraph(locked_position)


## D5: garis merah ke titik dash + label "!".
func _show_telegraph(target_position: Vector2) -> void:
	_clear_telegraph()
	_telegraph_line = Line2D.new()
	_telegraph_line.name = "TelegraphLine"
	_telegraph_line.width = 2.0
	_telegraph_line.default_color = Color(1.0, 0.2, 0.2, 0.7)
	_telegraph_line.z_index = -1
	_telegraph_line.points = PackedVector2Array([Vector2.ZERO, target_position - global_position])
	add_child(_telegraph_line)

	_telegraph_label = Label.new()
	_telegraph_label.name = "TelegraphMark"
	_telegraph_label.text = "!"
	_telegraph_label.position = Vector2(-4.0, -46.0)
	add_child(_telegraph_label)


func get_telegraph_line() -> Line2D:
	return _telegraph_line if is_instance_valid(_telegraph_line) else null


func _clear_telegraph() -> void:
	if _telegraph_line != null and is_instance_valid(_telegraph_line):
		_telegraph_line.queue_free()
	_telegraph_line = null
	if _telegraph_label != null and is_instance_valid(_telegraph_label):
		_telegraph_label.queue_free()
	_telegraph_label = null
	if _visual != null:
		_visual.position = Vector2.ZERO


func _tick_telegraph(delta: float, boar: BoarConfig) -> void:
	_telegraph_remaining -= delta
	move_in_direction(Vector2.ZERO, 0.0, delta)
	if _telegraph_label != null and is_instance_valid(_telegraph_label):
		_telegraph_label.modulate.a = 0.5 + 0.5 * sin(_telegraph_remaining * 18.0)
	if _telegraph_line != null and is_instance_valid(_telegraph_line):
		_telegraph_line.modulate.a = 0.4 + 0.4 * absf(sin(_telegraph_remaining * 12.0))
	if _visual != null:
		_visual.position = Vector2(rng.randf_range(-2.0, 2.0), rng.randf_range(-2.0, 2.0))
	if _telegraph_remaining > 0.0:
		return
	_clear_telegraph()
	state = State.DASH
	_dash_remaining = maxf(_dash_target.distance_to(global_position) / maxf(boar.dash_speed, 1.0), 0.05) * 2.0 + 0.1
	_dash_cooldown = boar.dash_cooldown_night if _is_night() else boar.dash_cooldown_day
	if _visual != null:
		_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _tick_dash(delta: float, boar: BoarConfig) -> void:
	_dash_remaining = maxf(_dash_remaining - delta, 0.0)
	var offset := _dash_target - global_position
	if offset.length_squared() > 0.0001:
		face(offset)
	# Mission 9 fase 4: langkah memakai delta eksplisit lewat move_and_collide,
	# bukan velocity + move_and_slide (yang memakai delta fisika mesin). Jarak
	# dash jadi sama di frame lambat maupun di tes, dan dinding tetap dihormati.
	var step := maxf(boar.dash_speed, 0.0) * delta
	var arrived := offset.length() <= maxf(step, 6.0)
	if not arrived:
		move_and_collide(offset.normalized() * step)
		offset = _dash_target - global_position
	if _dash_hit:
		return
	# Tabrakan jarak: pemain atau struktur terdekat dalam radius dash.
	var hit_target := _dash_contact(boar)
	if hit_target == null:
		if arrived or offset.length() <= 6.0 or _dash_remaining <= 0.0:
			_finish_dash()
		return
	_dash_hit = true
	if hit_target.has_method(&"receive_hit"):
		var push_dir := Vector2.ZERO
		if hit_target is Node2D:
			push_dir = (hit_target as Node2D).global_position - global_position
		_deal_damage(
			hit_target,
			boar.dash_player_damage,
			boar.dash_structure_damage,
			push_dir,
			DASH_KNOCKBACK_DISTANCE
		)
	else:
		_deal_damage(hit_target, boar.dash_player_damage, boar.dash_structure_damage, Vector2.ZERO, 0.0)
	# Jangan lewat `_finish_dash()` di sini: fungsi itu memancarkan
	# `dash_ended(false)`, sehingga satu tabrakan mengirim dua sinyal.
	move_in_direction(Vector2.ZERO, 0.0, 0.0)
	state = State.RECOVER
	_recover_remaining = RECOVER_TIME
	dash_ended.emit(true)


func _dash_contact(boar: BoarConfig) -> Node:
	if not can_be_auto_targeted():
		return null
	var target := _find_player()
	if target is Node2D and _player_alive():
		if global_position.distance_to((target as Node2D).global_position) <= boar.dash_hit_radius:
			return _fence_or(target, boar)
	if not can_attack_structures():
		return null
	var structure := nearest_structure()
	if structure != null and global_position.distance_to(structure.global_position) <= boar.dash_hit_radius:
		return _fence_or(structure, boar)
	return null


## Bila garis ke target terpotong pagar, dash mengenai pagar (bila dekat).
func _fence_or(target: Node, boar: BoarConfig) -> Node:
	if not (target is Node2D):
		return target
	var blocker := _blocking_fence((target as Node2D).global_position)
	if blocker == null:
		return target
	if global_position.distance_to(blocker.global_position) <= boar.dash_hit_radius:
		return blocker
	return null


func _fence_segments() -> Array:
	var tree := get_tree()
	if tree == null:
		return []
	return tree.get_nodes_in_group(FenceSegment.SEGMENT_GROUP)


func _blocking_fence(to: Vector2) -> FenceSegment:
	return FenceGeometry.first_blocking_segment(global_position, to, _fence_segments())


func _finish_dash() -> void:
	move_in_direction(Vector2.ZERO, 0.0, 0.0)
	if state == State.DASH:
		state = State.CHASE
		dash_ended.emit(false)


func _deal_damage(target: Node, player_damage: float, structure_damage: float, knockback_dir: Vector2, knockback: float) -> void:
	if target == null:
		return
	if target.has_method(&"receive_hit") or target.get_node_or_null(DAMAGE_RECEIVER_NAME) != null:
		reset_provoke_calm()
	var scaled_player := player_damage * get_damage_multiplier()
	var scaled_structure := structure_damage * get_damage_multiplier()

	if target.has_method(&"receive_hit"):
		target.receive_hit(scaled_player, self, knockback_dir, knockback)
		return
	var receiver := target.get_node_or_null(DAMAGE_RECEIVER_NAME) as PlayerDamageReceiver
	if receiver != null:
		receiver.receive_hit(scaled_player, self, knockback_dir, knockback)
		return
	if target.has_method(&"take_damage"):
		target.take_damage(scaled_structure, self)


# --- Overrides --------------------------------------------------------------

func _on_provoked(_source: Node) -> void:
	# Temperament tidak lagi diubah di sini: diturunkan tiap tick.
	# Provoke tetap membuat boar agresif lewat `can_be_auto_targeted()`.
	pass


func is_knockback_ignored() -> bool:
	return state == State.DASH or state == State.DASH_TELEGRAPH


func reset_night_scaling() -> void:
	super()
	_provoked = false
	raid_camp = false
	temperament = Temperament.HOSTILE if (forced_hostile or _is_night()) else Temperament.NEUTRAL

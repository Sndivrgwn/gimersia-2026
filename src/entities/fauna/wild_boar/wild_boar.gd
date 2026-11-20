class_name WildBoar
extends FaunaBase

## Babi hutan (spesifikasi §7.3). Siang NEUTRAL (mengembara sampai diprovokasi),
## malam HOSTILE. Bisa menggigit, menyerbu (dash), dan menyerang struktur camp.

signal dash_ended(hit: bool)

enum State { WANDER, CHASE, BITE, DASH_TELEGRAPH, DASH, RECOVER, FLEE }

const CAMP_CENTER := Vector2.ZERO
const RECOVER_TIME := 0.3
## Spesifikasi §7.2: knockback dash 60 px (durasi 0.2 s di CombatConfig).
const DASH_KNOCKBACK_DISTANCE := 60.0

var state: int = State.WANDER

var _bite_cooldown: float = 0.0
var _dash_cooldown: float = 0.0
var _telegraph_remaining: float = 0.0
var _recover_remaining: float = 0.0
var _dash_target: Vector2 = Vector2.ZERO
var _dash_hit: bool = false


func _ready() -> void:
	super()
	ensure_ready()
	temperament = Temperament.HOSTILE if _is_night() else Temperament.NEUTRAL


func config_boar() -> BoarConfig:
	return config as BoarConfig


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
	_update_temperament(target)

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

	if distance <= boar.bite_range and _bite_cooldown <= 0.0:
		_bite(chosen, boar)
		return

	if distance >= boar.dash_min_distance and distance <= boar.dash_max_distance and _dash_cooldown <= 0.0:
		_begin_telegraph(chosen_position, boar)
		return

	state = State.CHASE
	face(chosen_position - global_position)
	move_in_direction(chosen_position - global_position, get_move_speed(), delta)


# --- Decision ---------------------------------------------------------------

func _update_temperament(target: Node) -> void:
	if _is_night():
		temperament = Temperament.HOSTILE
		return
	# Siang: hanya provoked yang agresif; lepas leash -> NEUTRAL lagi.
	if _provoked and target is Node2D and global_position.distance_to((target as Node2D).global_position) > config_boar().leash_radius:
		_provoked = false
		raid_camp = false
		temperament = Temperament.NEUTRAL


func _update_raid_flag(target: Node, boar: BoarConfig) -> void:
	if nearest_structure() == null:
		raid_camp = false
		return
	if global_position.length() > boar.raid_clear_radius:
		raid_camp = false
		return
	if target == null or not (target is Node2D):
		return
	var target_position := (target as Node2D).global_position
	if global_position.distance_to(target_position) > boar.detect_radius:
		return
	if target_position.length() <= boar.raid_camp_radius:
		raid_camp = true
	elif state == State.CHASE and global_position.length() <= boar.raid_camp_radius:
		raid_camp = true


## Prioritas: pemain <= 140 px, lalu struktur (bila raid_camp), lalu pemain
## yang terdeteksi, kalau tidak null (mengembara).
func _choose_target(target: Node, boar: BoarConfig) -> Node:
	var player_node := target as Node2D
	if player_node != null and _player_alive():
		var distance := global_position.distance_to(player_node.global_position)
		if distance <= boar.camp_player_radius:
			return target
	if raid_camp:
		var structure := nearest_structure()
		if structure != null:
			return structure
	if player_node != null and _player_alive():
		var distance := global_position.distance_to(player_node.global_position)
		if distance <= boar.detect_radius and can_be_auto_targeted():
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


func _tick_telegraph(delta: float, boar: BoarConfig) -> void:
	_telegraph_remaining -= delta
	move_in_direction(Vector2.ZERO, 0.0, delta)
	if _telegraph_remaining > 0.0:
		return
	state = State.DASH
	_dash_cooldown = boar.dash_cooldown_night if _is_night() else boar.dash_cooldown_day
	if _visual != null:
		_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _tick_dash(delta: float, boar: BoarConfig) -> void:
	var offset := _dash_target - global_position
	if offset.length() <= 6.0:
		_finish_dash()
		return
	move_in_direction(offset, boar.dash_speed, delta)
	if _dash_hit:
		return
	# Tabrakan jarak: pemain atau struktur terdekat dalam radius dash.
	var hit_target := _dash_contact(boar)
	if hit_target == null:
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
	_finish_dash()
	state = State.RECOVER
	_recover_remaining = RECOVER_TIME
	dash_ended.emit(true)


func _dash_contact(boar: BoarConfig) -> Node:
	var target := _find_player()
	if target is Node2D and _player_alive():
		if global_position.distance_to((target as Node2D).global_position) <= boar.dash_hit_radius:
			return target
	var structure := nearest_structure()
	if structure != null and global_position.distance_to(structure.global_position) <= boar.dash_hit_radius:
		return structure
	return null


func _finish_dash() -> void:
	move_in_direction(Vector2.ZERO, 0.0, 0.0)
	if state == State.DASH:
		state = State.CHASE
		dash_ended.emit(false)


func _deal_damage(target: Node, player_damage: float, structure_damage: float, knockback_dir: Vector2, knockback: float) -> void:
	if target == null:
		return
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
	if not _is_night():
		temperament = Temperament.NEUTRAL


func reset_night_scaling() -> void:
	super()
	_provoked = false
	raid_camp = false
	temperament = Temperament.HOSTILE if _is_night() else Temperament.NEUTRAL

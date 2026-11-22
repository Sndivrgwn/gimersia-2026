class_name IslandDeer
extends FaunaBase

## Rusa pulau: selalu PASSIVE, tidak menyerang. Kabur 175 px/s selama 5 detik
## saat pemain dalam 130 px atau setelah terkena serangan.

enum State { WANDER, FLEE }

const AWAY_MARGIN := 32.0

var state: int = State.WANDER


func _ready() -> void:
	super()
	ensure_ready()
	temperament = Temperament.PASSIVE


func get_state() -> int:
	return state


func visual_key() -> StringName:
	return &"island_deer"


func _update_behavior(delta: float) -> void:
	var target := _find_player()
	if target is Node2D:
		var distance := global_position.distance_to((target as Node2D).global_position)
		if distance <= _deer_config().flee_trigger_radius:
			begin_flee((target as Node2D).global_position, _deer_config().flee_duration)
			state = State.FLEE
			_tick_flee(delta)
			return
	state = State.WANDER
	_wander(delta)


func _deer_config() -> DeerConfig:
	var deer := config as DeerConfig
	return deer if deer != null else DeerConfig.new()


func _on_provoked(source: Node) -> void:
	var from := global_position
	if source is Node2D:
		from = (source as Node2D).global_position
	begin_flee(from, _deer_config().flee_duration)
	state = State.FLEE


func _tick_flee(delta: float) -> void:
	state = State.FLEE
	var deer := _deer_config()
	_flee_remaining = maxf(_flee_remaining - delta, 0.0)
	_flee_elapsed += delta
	var target := _find_player()
	var far_enough := target is Node2D and global_position.distance_to((target as Node2D).global_position) >= config.flee_despawn_distance
	if far_enough or _flee_elapsed >= config.flee_despawn_timeout:
		despawn()
		return
	move_in_direction(_flee_direction, deer.flee_speed, delta)
	if _flee_remaining <= 0.0:
		state = State.WANDER

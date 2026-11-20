extends GutTest

class StubPlayer extends Node2D:
	var knockback_multiplier: float = 1.0
	var applied: Array[Vector2] = []

	func apply_knockback(direction: Vector2, distance: float, _duration: float) -> void:
		applied.append(direction.normalized() * distance)


var _player: StubPlayer
var _stats: StatsComponent
var _receiver: PlayerDamageReceiver


func before_each() -> void:
	_player = StubPlayer.new()
	_stats = StatsComponent.new()
	_stats.name = "StatsComponent"
	_player.add_child(_stats)
	add_child_autofree(_player)

	_receiver = PlayerDamageReceiver.new()
	_player.add_child(_receiver)
	_receiver.rng.seed = 1
	_receiver.setup(_player)


func test_hit_applies_damage_reduction() -> void:
	_stats.add_modifier(&"test", &"damage_reduction", StatModifier.Kind.PERCENT, 0.25)
	var before: float = _stats.current_hp
	var applied := _receiver.receive_hit(20.0, null)
	assert_true(applied)
	assert_eq(_stats.current_hp, before - 15.0)


func test_dodge_deals_zero_damage() -> void:
	_stats.add_modifier(&"test", &"dodge", StatModifier.Kind.PERCENT, 0.5)
	_receiver.rng.seed = 0
	watch_signals(_receiver)
	var before: float = _stats.current_hp
	var applied := _receiver.receive_hit(20.0, null)
	assert_false(applied)
	assert_eq(_stats.current_hp, before)
	assert_signal_emit_count(_receiver, "dodged", 1)


func test_dead_player_is_ignored() -> void:
	_stats.get_max_hp()
	_stats.set_hp(0.0)
	assert_false(_receiver.receive_hit(20.0, null))


func test_knockback_uses_player_multiplier() -> void:
	_player.knockback_multiplier = 0.5
	_receiver.receive_hit(10.0, null, Vector2.RIGHT, 60.0)
	assert_eq(_player.applied.size(), 1)
	assert_almost_eq(_player.applied[0].x, 30.0, 0.01)

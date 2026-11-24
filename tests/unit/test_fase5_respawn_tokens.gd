extends GutTest

## Fase 5: jumlah token respawn adalah setting run (`PlayerBaseStats`), bukan
## hanya konstanta di DeathController. Tes ini menjaga jalur konfigurasinya.

var _player: Player
var _death: DeathController


func before_each() -> void:
	_player = preload("res://src/entities/player/player.tscn").instantiate() as Player
	add_child_autofree(_player)

	var base := PlayerBaseStats.new()
	base.max_respawn_tokens = 5
	_player.stats.base_stats = base

	_death = DeathController.new()
	add_child_autofree(_death)
	_death.setup(_player)


func after_each() -> void:
	_player.queue_free()


func test_respawn_tokens_follow_base_stats() -> void:
	assert_eq(_death.get_respawns_remaining(), 5)


func test_zero_tokens_is_allowed_and_clamped() -> void:
	var base := PlayerBaseStats.new()
	base.max_respawn_tokens = 0
	_player.stats.base_stats = base

	var death := DeathController.new()
	add_child_autofree(death)
	death.setup(_player)
	assert_eq(death.get_respawns_remaining(), 0)


func test_negative_tokens_clamp_to_zero() -> void:
	var base := PlayerBaseStats.new()
	base.max_respawn_tokens = -2
	_player.stats.base_stats = base

	var death := DeathController.new()
	add_child_autofree(death)
	death.setup(_player)
	assert_eq(death.get_respawns_remaining(), 0)

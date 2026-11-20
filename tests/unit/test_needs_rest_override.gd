extends GutTest

## Tes override idle regen di NeedsComponent (bonus rest Campfire):
## menaikkan regen ke 5/s, sumber tertinggi menang, dibersihkan dengan benar,
## dan tetap dibatasi plafon Fatigue.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")

var player: Player
var needs: NeedsComponent


func before_each() -> void:
	player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	needs = player.get_node("NeedsComponent") as NeedsComponent
	needs.set_process(false)
	needs.set_value(NeedsComponent.Need.FATIGUE, 50.0)


func test_base_idle_regen_is_one_per_second() -> void:
	assert_almost_eq(needs.get_idle_regen(), 1.0, 0.001)

	needs.tick(1.0)

	assert_almost_eq(needs.get_value(NeedsComponent.Need.FATIGUE), 51.0, 0.001)


func test_override_raises_idle_regen_to_five_per_second() -> void:
	needs.set_idle_regen_override(&"campfire", 5.0)
	assert_almost_eq(needs.get_idle_regen(), 5.0, 0.001)

	needs.tick(1.0)

	assert_almost_eq(needs.get_value(NeedsComponent.Need.FATIGUE), 55.0, 0.001)


func test_clearing_override_restores_base_regen() -> void:
	needs.set_idle_regen_override(&"campfire", 5.0)
	needs.clear_idle_regen_override(&"campfire")

	assert_almost_eq(needs.get_idle_regen(), 1.0, 0.001)

	needs.tick(1.0)

	assert_almost_eq(needs.get_value(NeedsComponent.Need.FATIGUE), 51.0, 0.001)


func test_highest_override_wins_and_others_are_independent() -> void:
	needs.set_idle_regen_override(&"campfire", 5.0)
	needs.set_idle_regen_override(&"tent", 3.0)
	assert_almost_eq(needs.get_idle_regen(), 5.0, 0.001)

	needs.set_idle_regen_override(&"tent", 8.0)
	assert_almost_eq(needs.get_idle_regen(), 8.0, 0.001)

	needs.clear_idle_regen_override(&"tent")
	assert_almost_eq(needs.get_idle_regen(), 5.0, 0.001)


func test_override_never_beats_the_fatigue_cap() -> void:
	var cap := needs.get_fatigue_cap()
	needs.set_value(NeedsComponent.Need.FATIGUE, 99.5)
	needs.set_idle_regen_override(&"campfire", 5.0)

	needs.tick(1.0)

	assert_almost_eq(needs.get_value(NeedsComponent.Need.FATIGUE), cap, 0.001)
	assert_almost_eq(needs.get_fatigue_cap(), cap, 0.001, "override tidak mengubah plafon")


func test_override_does_not_apply_while_moving() -> void:
	needs.set_idle_regen_override(&"campfire", 5.0)
	player.velocity = Vector2(100, 0)

	needs.tick(1.0)

	assert_almost_eq(
		needs.get_value(NeedsComponent.Need.FATIGUE), 50.0 - 0.08, 0.001,
		"jalan memakai fatigue_walk_drain, bukan regen"
	)

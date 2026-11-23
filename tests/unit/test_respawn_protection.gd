extends GutTest

## Mission 9 Phase 3.1/3.2: beku saat mati, perlindungan respawn, dan fauna yang
## berhenti mengejar pemain yang terlindungi.

const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")


class StubClock extends Node:
	var night: bool = false
	var scale_value: float = 1.0

	func is_night() -> bool:
		return night

	func is_day() -> bool:
		return not night

	func get_current_day() -> int:
		return 1

	func get_time_scale() -> float:
		return scale_value

	func set_time_scale(value: float) -> void:
		scale_value = value

	func restart() -> void:
		pass


var clock: StubClock
var freezer: FreezeController
var player: Player
var receiver: PlayerDamageReceiver


func before_each() -> void:
	clock = StubClock.new()
	add_child_autofree(clock)
	freezer = FreezeController.new()
	freezer.clock = clock
	add_child_autofree(freezer)
	player = PLAYER_SCENE.instantiate() as Player
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.set_physics_process(false)
	player.global_position = Vector2(2000.0, 2000.0)
	# Di island.tscn receiver adalah anak Player; scene player sendiri belum punya.
	receiver = PlayerDamageReceiver.new()
	receiver.name = "PlayerDamageReceiver"
	player.add_child(receiver)
	receiver.set_process(false)


func after_each() -> void:
	get_tree().paused = false


# --- Perlindungan -----------------------------------------------------------

func test_protected_player_takes_no_damage_or_knockback() -> void:
	var hp_before := receiver.get_stats().current_hp
	receiver.start_protection(5.0)
	assert_true(receiver.is_protected())
	assert_false(receiver.receive_hit(20.0, self, Vector2.RIGHT, 60.0))
	assert_almost_eq(receiver.get_stats().current_hp, hp_before, 0.001)
	assert_false(player.is_knocked_back(), "tanpa knockback saat terlindungi")


func test_protection_expires_after_the_real_time_duration() -> void:
	receiver.start_protection(1.0)
	receiver.tick(0.5)
	assert_true(receiver.is_protected())
	receiver.tick(0.6)
	assert_false(receiver.is_protected(), "habis setelah 1 dtk nyata")


func test_protection_shows_blink_flag_and_clears_it() -> void:
	receiver.start_protection(2.0)
	receiver.tick(0.05)
	receiver.tick(0.05)
	var visual := player.get_node("Visual") as CanvasItem
	assert_lt(visual.modulate.a, 1.0, "visual berkedip saat terlindungi")
	receiver.stop_protection()
	assert_almost_eq(visual.modulate.a, 1.0, 0.001, "alpha dipulihkan")


func test_protection_ends_on_attack_only_when_configured() -> void:
	var config := receiver.run_config.duplicate() as RunConfig
	config.protection_ends_on_attack = false
	receiver.run_config = config
	receiver.start_protection(5.0)
	receiver._on_attack_dealt(self, 5.0)
	assert_true(receiver.is_protected(), "bawaan: menyerang tidak membatalkan")

	config.protection_ends_on_attack = true
	receiver._on_attack_dealt(self, 5.0)
	assert_false(receiver.is_protected())


func test_boar_ignores_and_drops_a_protected_player() -> void:
	var boar := BOAR_SCENE.instantiate() as WildBoar
	boar.clock = clock
	boar.player = player
	boar.rng.seed = 3
	player.global_position = boar.global_position + Vector2(60.0, 0.0)
	add_child_autofree(boar)
	boar.set_physics_process(false)
	boar.forced_hostile = true
	boar.ensure_ready()
	boar._wander_pause = 999.0
	boar.tick(0.05)
	var hp_before := receiver.get_stats().current_hp
	receiver.start_protection(5.0)
	boar.tick(0.05)
	boar.tick(0.05)
	assert_almost_eq(receiver.get_stats().current_hp, hp_before, 0.001, "babi tidak menggigit")
	assert_ne(boar.get_state(), WildBoar.State.BITE)


func test_protected_flag_can_be_ignored_by_enemies() -> void:
	var config := receiver.run_config.duplicate() as RunConfig
	config.protection_ignored_by_enemies = false
	receiver.run_config = config
	receiver.start_protection(5.0)
	var fauna := FaunaBase.new()
	assert_false(fauna._player_is_protected(player), "flag false: fauna tetap mengejar")
	fauna.free()


# --- HP kelaparan tetap masuk -------------------------------------------------

func test_zero_tier_hp_loss_is_not_blocked_by_protection() -> void:
	var needs := player.get_node("NeedsComponent") as NeedsComponent
	needs.set_process(false)
	needs.setup(clock, receiver.get_stats(), player)
	needs.set_value(NeedsComponent.Need.HUNGER, 0.0)
	needs.set_value(NeedsComponent.Need.THIRST, 0.0)
	receiver.start_protection(30.0)
	var hp_before := receiver.get_stats().current_hp
	needs.tick(10.0)
	assert_lt(receiver.get_stats().current_hp, hp_before, "kerusakan kelaparan menembus perlindungan")


# --- Kematian ---------------------------------------------------------------

func test_death_freezes_the_game_and_respawn_releases_it() -> void:
	var death := DeathController.new()
	death.setup(player)
	add_child_autofree(death)
	var stats := receiver.get_stats()
	stats.set_hp(0.0)
	assert_true(death.is_dead)
	assert_true(freezer.is_frozen(), "layar mati membekukan game")
	assert_almost_eq(clock.get_time_scale(), 0.0, 0.001)

	assert_true(death.respawn())
	assert_false(freezer.is_frozen(), "respawn melepas beku")
	assert_almost_eq(clock.get_time_scale(), 1.0, 0.001)
	assert_true(receiver.is_protected(), "perlindungan mulai saat beku dilepas")


func test_pause_and_death_overlap_keeps_the_freeze() -> void:
	var death := DeathController.new()
	death.setup(player)
	add_child_autofree(death)
	var menu := PauseMenu.new()
	menu.clock = clock
	add_child_autofree(menu)
	assert_true(menu.open())
	receiver.get_stats().set_hp(0.0)
	assert_true(freezer.is_frozen())
	menu.close()
	assert_true(freezer.is_frozen(), "kematian masih menahan beku")
	assert_true(death.respawn())
	assert_false(freezer.is_frozen())

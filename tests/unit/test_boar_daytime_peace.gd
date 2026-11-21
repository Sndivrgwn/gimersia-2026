extends GutTest

## Phase 1: siang hari boar tidak boleh agresif tanpa diprovokasi.

class StubClock extends Node:
	var night: bool = false
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


const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")
const CHEST_DEF: StructureDefinition = preload("res://src/data/camp/chest.tres")
const GATHER_DEBUG_SCRIPT: Script = preload("res://src/levels/island/gather_debug.gd")


func _setup(night: bool = false, player_distance: float = 200.0) -> Array:
	var clock := StubClock.new()
	add_child_autofree(clock)
	clock.night = night
	var player := StubPlayer.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2(player_distance, 0.0)
	var boar := BOAR_SCENE.instantiate() as WildBoar
	boar.clock = clock
	boar.player = player
	add_child_autofree(boar)
	boar.global_position = Vector2.ZERO
	boar.ensure_ready()
	return [boar, player, clock]


func _add_structure(at: Vector2) -> CampStructure:
	var structure := CampStructure.new()
	structure.definition = CHEST_DEF
	add_child_autofree(structure)
	structure.global_position = at
	return structure


func _tick_for(boar: WildBoar, seconds: float) -> void:
	var steps := int(round(seconds / 0.1))
	for _index in steps:
		boar.tick(0.1)


func _assert_not_aggressive(boar: WildBoar) -> void:
	assert_ne(boar.get_state(), WildBoar.State.CHASE, "boar siang tidak boleh CHASE")
	assert_ne(boar.get_state(), WildBoar.State.BITE, "boar siang tidak boleh BITE")
	assert_ne(boar.get_state(), WildBoar.State.DASH_TELEGRAPH, "boar siang tidak boleh DASH_TELEGRAPH")
	assert_ne(boar.get_state(), WildBoar.State.DASH, "boar siang tidak boleh DASH")


# H1: cabang camp-aggro "player <= 140 px" hanya untuk HOSTILE/provoked.
func test_h1_day_camp_radius_never_aggros_unprovoked() -> void:
	var structure := _add_structure(Vector2(40.0, 0.0))
	for distance in [0.0, 100.0, 139.0, 141.0, 300.0]:
		var setup := _setup(false, distance)
		var boar := setup[0] as WildBoar
		var player := setup[1] as StubPlayer
		watch_signals(player.receiver)
		_tick_for(boar, 10.0)
		_assert_not_aggressive(boar)
		assert_eq(boar.get_state(), WildBoar.State.WANDER, "jarak %.0f: boar harus mengembara" % distance)
		assert_false(boar.raid_camp, "jarak %.0f: raid_camp harus false" % distance)
		assert_signal_not_emitted(player.receiver, "damaged")
		assert_eq(structure.get_current_hp(), structure.max_hp, "struktur tidak boleh rusak siang")


# H2: raid_camp tidak boleh aktif siang tanpa provoke.
func test_h2_day_boar_never_raids_structures_unprovoked() -> void:
	var setup := _setup(false, 80.0)
	var boar := setup[0] as WildBoar
	var structure := _add_structure(Vector2(20.0, 0.0))
	boar.raid_camp = true
	var hp_before := structure.get_current_hp()
	_tick_for(boar, 10.0)
	assert_false(boar.raid_camp, "raid_camp harus dimatikan untuk boar yang tidak auto-targetable")
	assert_eq(structure.get_current_hp(), hp_before, "struktur tidak boleh menerima damage siang")
	_assert_not_aggressive(boar)


# H3: HOSTILE malam harus NEUTRAL lagi setelah fajar, provoke hilang, state WANDER.
func test_h3_dawn_clears_night_hostility() -> void:
	var setup := _setup(true, 120.0)
	var boar := setup[0] as WildBoar
	var clock := setup[2] as StubClock
	boar.tick(0.1)
	assert_eq(boar.get_temperament(), FaunaBase.Temperament.HOSTILE)
	boar.provoke(null)
	assert_true(boar.is_provoked())

	clock.night = false
	boar.tick(0.1)
	assert_eq(boar.get_temperament(), FaunaBase.Temperament.NEUTRAL, "fajar harus menurunkan temperament")
	assert_false(boar.is_provoked(), "provoke harus hilang saat fajar")
	assert_eq(boar.get_state(), WildBoar.State.WANDER, "state harus WANDER setelah fajar")
	assert_false(boar.raid_camp)


# H3b: HOSTILE malam yang tidak sempat flee juga kembali NEUTRAL (reset_night_scaling).
func test_h3_reset_night_scaling_is_neutral_by_day() -> void:
	var setup := _setup(true, 120.0)
	var boar := setup[0] as WildBoar
	var clock := setup[2] as StubClock
	clock.night = false
	boar.reset_night_scaling()
	assert_eq(boar.get_temperament(), FaunaBase.Temperament.NEUTRAL)
	assert_false(boar.is_provoked())
	_assert_not_aggressive(boar)


# H4: boar yang di-spawn siang (FaunaQuota) NEUTRAL dan tidak agresif.
func test_h4_day_spawned_boar_is_neutral() -> void:
	var setup := _setup(false, 300.0)
	var boar := setup[0] as WildBoar
	assert_eq(boar.get_temperament(), FaunaBase.Temperament.NEUTRAL)
	_tick_for(boar, 5.0)
	_assert_not_aggressive(boar)
	assert_false(boar.can_be_auto_targeted())


# H5: guard UI pada ayunan manual dan ayunan tanpa target tidak memprovokasi apa pun.
func test_h5_manual_swing_guard_and_no_target_swing() -> void:
	var setup := _setup(false, 300.0)
	var boar := setup[0] as WildBoar
	var player := setup[1] as StubPlayer
	var combat := CombatComponent.new()
	combat.player = player
	add_child_autofree(combat)

	var hovered := Control.new()
	add_child_autofree(hovered)
	combat.hovered_control_override = hovered
	assert_false(combat.is_manual_input_allowed(), "kursor di atas Control harus memblokir ayunan manual")

	combat.hovered_control_override = null
	combat.ignore_ui_guard = true
	combat.swing_manual(Vector2.RIGHT)
	assert_false(boar.is_provoked(), "ayunan di luar jangkauan tidak boleh memprovokasi")


# H6: boar yang diprovokasi menjadi tenang lagi setelah provoke_calm_seconds tanpa hit.
func test_h6_provoked_boar_calms_after_config_seconds() -> void:
	var setup := _setup(false, 250.0)
	var boar := setup[0] as WildBoar
	var calm_config := BoarConfig.new()
	calm_config.provoke_calm_seconds = 0.5
	boar.config = calm_config

	boar.provoke(null)
	assert_true(boar.is_provoked())
	_tick_for(boar, 0.6)
	assert_false(boar.is_provoked(), "provoke harus berakhir setelah provoke_calm_seconds tanpa hit")
	_assert_not_aggressive(boar)


# H6b: provoke juga berakhir saat pemain lepas leash.
func test_h6_leash_ends_provoke() -> void:
	var setup := _setup(false, 100.0)
	var boar := setup[0] as WildBoar
	var player := setup[1] as StubPlayer
	boar.provoke(null)
	player.global_position = Vector2(1200.0, 0.0)
	boar.tick(0.1)
	assert_false(boar.is_provoked())


# 1.3: debug label fauna bisa dinyalakan/dimatikan dan mengikuti fauna.
func test_fauna_labels_toggle_creates_labels() -> void:
	var root := Node2D.new()
	add_child_autofree(root)
	var debug := GATHER_DEBUG_SCRIPT.new() as Node
	root.add_child(debug)

	_setup(false, 300.0)
	debug.call(&"set_fauna_labels_enabled", true)
	debug.call(&"refresh_fauna_labels")
	assert_true(debug.call(&"is_fauna_labels_enabled"))
	assert_gt(debug.call(&"get_fauna_label_count"), 0, "label fauna harus dibuat")
	debug.call(&"set_fauna_labels_enabled", false)
	assert_eq(debug.call(&"get_fauna_label_count"), 0)

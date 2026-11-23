extends GutTest

## Mission 9 Phase 1: raid sebagai event, pemilihan raider, siklus hidup tanda
## raider, mode EVENT_ONLY/ALWAYS/OFF, peringatan, dan batas populasi.

class StubClock extends Node:
	signal day_started(day: int)
	signal night_started(day: int)
	signal rescue_started

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
const RAID_CONFIG: RaidConfig = preload("res://src/data/configs/fauna/raid_config.tres")

var _clock: StubClock
var _parent: Node2D
var _director: RaidDirector
var _player: StubPlayer


func before_each() -> void:
	_clock = StubClock.new()
	add_child_autofree(_clock)
	_parent = Node2D.new()
	add_child_autofree(_parent)
	_player = StubPlayer.new()
	_player.add_to_group(&"player")
	add_child_autofree(_player)
	_player.global_position = Vector2(900.0, 0.0)
	_director = RaidDirector.new()
	_director.config = RAID_CONFIG.duplicate() as RaidConfig
	_director.clock = _clock
	_director.fauna_parent = _parent
	_director.rng.seed = 11
	add_child_autofree(_director)


func _start_night(day: int) -> void:
	_clock.day = day
	_clock.night = true
	_clock.night_started.emit(day)


func _boar(position: Vector2, hostile: bool = true) -> WildBoar:
	var boar := BOAR_SCENE.instantiate() as WildBoar
	boar.player = _player
	_parent.add_child(boar)
	boar.global_position = position
	boar.ensure_ready()
	boar.set_physics_process(false)
	boar.forced_hostile = hostile
	if hostile:
		boar.set_temperament(FaunaBase.Temperament.HOSTILE)
	return boar


# --- Jadwal -----------------------------------------------------------------

func test_night_one_schedules_one_raid_inside_first_delays() -> void:
	_start_night(1)
	assert_eq(_director.get_schedule_size(), 1)
	var times := _director.get_raid_times()
	assert_gte(times[0], RAID_CONFIG.first_raid_delay_min)
	assert_lte(times[0], RAID_CONFIG.first_raid_delay_max)


func test_extra_raids_are_separated_by_the_configured_gap() -> void:
	_director.config.raids_per_night = [3, 3, 3, 3, 3, 3, 3]
	_start_night(1)
	var times := _director.get_raid_times()
	assert_eq(times.size(), 3)
	var gap := maxf(RAID_CONFIG.raid_gap_min, RAID_CONFIG.raid_duration)
	assert_almost_eq(times[1] - times[0], gap, 0.01)
	assert_almost_eq(times[2] - times[1], gap, 0.01)


func test_pressure_multiplier_scales_and_rounds_raid_count() -> void:
	_director.config.global_pressure_multiplier = 2.5
	_start_night(1)
	assert_eq(_director.get_schedule_size(), 3, "1 x 2.5 dibulatkan ke 3")


func test_pressure_multiplier_can_remove_raids() -> void:
	_director.config.global_pressure_multiplier = 0.0
	_start_night(3)
	assert_eq(_director.get_schedule_size(), 0)


func test_off_mode_never_schedules_raids() -> void:
	_director.config.mode = RaidConfig.Mode.OFF
	_start_night(1)
	assert_eq(_director.get_schedule_size(), 0)
	assert_eq(_director.trigger_raid_now(), 0)


func test_no_raid_is_scheduled_at_dawn() -> void:
	_start_night(2)
	assert_gt(_director.get_schedule_size(), 0)
	_clock.night = false
	_clock.day_started.emit(2)
	assert_eq(_director.get_schedule_size(), 0)
	assert_false(_director.is_active())


func test_day_raids_stay_disabled() -> void:
	_director.config.day_raids_enabled = true
	_clock.day = 2
	_clock.day_started.emit(2)
	assert_eq(_director.get_schedule_size(), 0, "fajar tidak menjadwalkan raid")


# --- Peringatan -------------------------------------------------------------

func test_warning_fires_warning_seconds_before_the_raid() -> void:
	_start_night(1)
	watch_signals(_director)
	var raid_time: float = _director.get_raid_times()[0]
	var warning_at := raid_time - RAID_CONFIG.warning_seconds
	var elapsed := 0.0
	while elapsed < warning_at - 0.5:
		_director.tick(0.5)
		elapsed += 0.5
		assert_signal_not_emitted(_director, "raid_warning")
	_director.tick(1.0)
	assert_signal_emit_count(_director, "raid_warning", 1)
	assert_signal_emit_count(_director, "raid_started", 0)


func test_raid_starts_at_the_scheduled_time() -> void:
	_start_night(1)
	_boar(Vector2(50.0, 0.0))
	watch_signals(_director)
	var raid_time: float = _director.get_raid_times()[0]
	var elapsed := 0.0
	while elapsed < raid_time + 0.5:
		_director.tick(0.5)
		elapsed += 0.5
	assert_signal_emit_count(_director, "raid_started", 1)
	assert_true(_director.is_raid_active())


# --- Pemilihan raider -------------------------------------------------------

func test_raiders_are_chosen_nearest_to_the_base_center_first() -> void:
	_director.config.raiders_per_raid = [1, 1, 1, 1, 1, 1, 1]
	var far := _boar(Vector2(300.0, 0.0))
	var near := _boar(Vector2(100.0, 0.0))
	var mid := _boar(Vector2(200.0, 0.0))
	_start_night(1)
	assert_eq(_director.trigger_raid_now(), 1)
	assert_true(near.is_raider, "boar terdekat jadi raider")
	assert_false(far.is_raider)
	assert_false(mid.is_raider)


func test_raider_flag_lifecycle() -> void:
	var boar := _boar(Vector2(80.0, 0.0))
	_start_night(1)
	watch_signals(_director)
	_director.trigger_raid_now()
	assert_true(boar.is_raider)
	_director.tick(RAID_CONFIG.raid_duration + 0.5)
	assert_false(boar.is_raider, "tanda raider dilepas saat raid selesai")
	assert_false(_director.is_raid_active())
	assert_signal_emit_count(_director, "raid_ended", 1)
	assert_true(is_instance_valid(boar), "raider tetap hidup setelah raid")


func test_raid_ends_when_all_raiders_are_gone() -> void:
	var boar := _boar(Vector2(80.0, 0.0))
	_start_night(1)
	_director.trigger_raid_now()
	assert_true(boar.is_raider)
	boar.free()
	_director.tick(0.1)
	assert_false(_director.is_raid_active(), "raid bubar saat semua raider hilang")


# --- Integrasi struktur -----------------------------------------------------

func _structure() -> CampStructure:
	var structure := CampStructure.new()
	structure.definition = StructureDefinition.new()
	structure.definition.max_hp = 120.0
	structure.definition.aggro_priority = 0
	add_child_autofree(structure)
	structure.apply_definition()
	structure.global_position = Vector2(20.0, 0.0)
	return structure


func test_structures_take_no_damage_before_the_raid_starts() -> void:
	var structure := _structure()
	var boar := _boar(Vector2(60.0, 0.0))
	_start_night(1)
	_player.global_position = Vector2(120.0, 0.0)
	var hp_before := structure.get_current_hp()
	_director.tick(1.0)
	assert_eq(structure.get_current_hp(), hp_before, "belum raid: struktur aman")
	assert_false(boar.is_raider)


func test_only_raiders_damage_structures_in_event_only_mode() -> void:
	var structure := _structure()
	var raider := _boar(Vector2(60.0, 0.0))
	var bystander := _boar(Vector2(-60.0, 0.0))
	_player.global_position = Vector2(400.0, 0.0)
	_director.trigger_raid_now()
	assert_true(raider.is_raider or bystander.is_raider)
	var hp_before := structure.get_current_hp()
	if raider.is_raider:
		raider.tick(0.01)
		assert_lt(structure.get_current_hp(), hp_before, "raider menyerang struktur")
	elif bystander.is_raider:
		bystander.tick(0.01)
		assert_lt(structure.get_current_hp(), hp_before)


func test_non_raider_boar_ignores_structures_but_still_chases_player() -> void:
	var structure := _structure()
	var boar := _boar(Vector2(60.0, 0.0))
	_player.global_position = Vector2(70.0, 40.0)
	var hp_before := structure.get_current_hp()
	var player_hp := _player.stats.current_hp
	boar.tick(0.01)
	assert_eq(structure.get_current_hp(), hp_before, "bukan raider: struktur aman")
	assert_lt(_player.stats.current_hp, player_hp, "tetap mengejar dan menggigit pemain")


func test_always_mode_restores_the_old_raid_rule() -> void:
	var boar := _boar(Vector2(60.0, 0.0))
	boar.raid_config = RaidConfig.new()
	boar.raid_config.mode = RaidConfig.Mode.ALWAYS
	_player.global_position = Vector2(80.0, 20.0)
	_structure()
	boar.tick(0.01)
	assert_true(boar.raid_camp, "ALWAYS: boar hostile dekat camp raid seperti dulu")


func test_off_mode_blocks_structure_attacks_even_for_raiders() -> void:
	var structure := _structure()
	var boar := _boar(Vector2(60.0, 0.0))
	boar.raid_config = RaidConfig.new()
	boar.raid_config.mode = RaidConfig.Mode.OFF
	_player.global_position = Vector2(400.0, 0.0)
	boar.set_raider(true)
	var hp_before := structure.get_current_hp()
	boar.tick(0.01)
	assert_false(boar.raid_camp)
	assert_eq(structure.get_current_hp(), hp_before)


# --- Batas populasi ---------------------------------------------------------

func test_night_spawner_uses_the_configured_hostile_cap() -> void:
	var spawner := NightSpawner.new()
	spawner.fauna_parent = _parent
	spawner.raid_config = RAID_CONFIG.duplicate() as RaidConfig
	spawner.raid_config.night_active_hostile_cap = [2, 3, 3, 4, 5, 6, 8]
	add_child_autofree(spawner)
	spawner._on_night_started(1)
	assert_eq(spawner.get_hostile_cap(), 2)


func test_empty_cap_array_falls_back_to_the_spec_table() -> void:
	var spawner := NightSpawner.new()
	spawner.fauna_parent = _parent
	spawner.raid_config = RAID_CONFIG.duplicate() as RaidConfig
	spawner.raid_config.night_active_hostile_cap = []
	add_child_autofree(spawner)
	spawner._on_night_started(1)
	assert_eq(spawner.get_hostile_cap(), 3, "tabel spec: 3 hostile malam 1")


func test_spawn_interval_multiplier_is_applied() -> void:
	var spawner := NightSpawner.new()
	spawner.fauna_parent = _parent
	spawner.raid_config = RAID_CONFIG.duplicate() as RaidConfig
	spawner.raid_config.spawn_interval_multiplier = 0.5
	add_child_autofree(spawner)
	spawner._on_night_started(1)
	assert_almost_eq(spawner.get_spawn_interval(), 45.0 * 0.5, 0.01)


func test_raid_director_asks_the_spawner_for_missing_raiders_up_to_the_cap() -> void:
	var spawner := NightSpawner.new()
	spawner.fauna_parent = _parent
	spawner.raid_config = RAID_CONFIG.duplicate() as RaidConfig
	spawner.raid_config.night_active_hostile_cap = [5, 5, 5, 5, 5, 5, 5]
	add_child_autofree(spawner)
	_director.spawner = spawner
	_director.config.raiders_per_raid = [3, 3, 3, 3, 3, 3, 3]
	_start_night(1)
	assert_eq(_director.trigger_raid_now(), 3)
	assert_eq(_parent.get_child_count(), 3)


func test_fauna_quota_uses_the_configured_day_caps() -> void:
	var quota := FaunaQuota.new()
	quota.fauna_parent = _parent
	quota.clock = _clock
	add_child_autofree(quota)
	assert_eq(quota.get_day_boar_cap(), 2)
	assert_eq(quota.get_day_deer_cap(), 3)
	quota.raid_config = RAID_CONFIG.duplicate() as RaidConfig
	quota.raid_config.day_boar_cap = 4
	quota.raid_config.day_deer_cap = 5
	assert_eq(quota.get_day_boar_cap(), 4)
	assert_eq(quota.get_day_deer_cap(), 5)


func test_boar_count_above_the_cap_is_not_culled_at_night_start() -> void:
	var spawner := NightSpawner.new()
	spawner.fauna_parent = _parent
	spawner.raid_config = RAID_CONFIG.duplicate() as RaidConfig
	spawner.raid_config.night_active_hostile_cap = [1, 1, 1, 1, 1, 1, 1]
	add_child_autofree(spawner)
	var boars: Array[WildBoar] = []
	for index in 3:
		boars.append(_boar(Vector2(40.0 * index, 0.0)))
	spawner._on_night_started(1)
	assert_eq(_parent.get_child_count(), 4, "3 boar awal + 1 spawn malam, tidak ada yang dicull")
	for boar in boars:
		assert_true(is_instance_valid(boar))

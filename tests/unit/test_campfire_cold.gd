extends GutTest

## Mission 9 Phase 2: api unggun dibangun COLD, dinyalakan lewat QTE gesek batu.
## Semua yang bergantung pada status menyala harus tetap bekerja saat dingin.

const CAMPFIRE_SCENE: PackedScene = preload("res://src/entities/camp/campfire/campfire.tscn")
const CAMPFIRE_DEF: StructureDefinition = preload("res://src/data/camp/campfire.tres")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")
const FIRE_STARTER_SCRIPT := preload("res://src/components/crafting/fire_starter_controller.gd")
const HINT_MANAGER_SCRIPT := preload("res://src/ui/hud/hints/hint_manager.gd")


class StubClock extends Node:
	signal night_started(day: int)
	signal day_started(day: int)

	var night: bool = false
	var scale_value: float = 1.0

	func is_night() -> bool:
		return night

	func get_current_day() -> int:
		return 1

	func get_time_scale() -> float:
		return scale_value


var clock: StubClock
var campfire: Campfire


func before_each() -> void:
	clock = StubClock.new()
	add_child_autofree(clock)
	campfire = _cold_fire()


func _cold_fire() -> Campfire:
	var fire := CAMPFIRE_SCENE.instantiate() as Campfire
	fire.definition = CAMPFIRE_DEF
	fire.clock = clock
	add_child_autofree(fire)
	fire.set_process(false)
	return fire


func _player_with_stone() -> Player:
	var player := PLAYER_SCENE.instantiate() as Player
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.set_physics_process(false)
	var inventory := InventoryComponent.new()
	inventory.name = "InventoryComponent"
	player.add_child(inventory)
	inventory.setup(player)
	inventory.set_process(false)
	inventory.add_item(ItemCatalog.STONE, 5)
	var starter := FIRE_STARTER_SCRIPT.new() as FireStarterController
	starter.name = "FireStarterController"
	player.add_child(starter)
	starter.set_process(false)
	return player


# --- Dibangun dingin --------------------------------------------------------

func test_built_campfire_starts_cold_with_stored_fuel() -> void:
	assert_false(campfire.is_lit(), "bangunan hanya menaruh dasar api")
	assert_true(campfire.is_cold())
	assert_true(campfire.has_been_lit == false, "belum pernah menyala")
	assert_almost_eq(campfire.get_fuel(), 240.0, 0.001, "bahan bakar tersimpan saat dibangun")
	assert_true(campfire.needs_ignition())
	assert_false(campfire.is_station_active(), "memasak terkunci saat dingin")


func test_never_lit_campfire_has_no_light_at_all() -> void:
	assert_almost_eq(campfire.get_light_radius(), 0.0, 0.001)
	assert_not_null(campfire.get_light())
	assert_false(campfire.get_light().visible, "tanpa cahaya sebelum pernah menyala")


func test_fuel_does_not_drain_while_cold() -> void:
	campfire.tick(60.0)
	assert_almost_eq(campfire.get_fuel(), 240.0, 0.001)


func test_prompts_match_the_build_flow() -> void:
	var refuel := campfire.get_node("Refuel") as CampfireRefuel
	assert_eq(refuel.get_prompt(null), "Tahan E: Gesek Batu", "dingin dengan bahan bakar")
	campfire.set_fuel(0.0)
	assert_eq(refuel.get_prompt(null), "Tahan E: Isi Bahan Bakar", "dingin tanpa bahan bakar")


func test_qte_lights_the_cold_campfire() -> void:
	var player := _player_with_stone()
	campfire.global_position = Vector2.ZERO
	player.global_position = Vector2(16.0, 0.0)
	var starter := player.get_node("FireStarterController") as FireStarterController
	starter.roll_override = 0.0
	assert_true(starter.start(campfire), "QTE bisa dimulai dengan batu")
	starter.set_marker(0.5)
	starter.strike()
	assert_true(campfire.is_lit(), "gesek batu berhasil menyalakan api")
	assert_true(campfire.has_been_lit)
	assert_almost_eq(campfire.get_fuel(), 240.0, 0.001, "bahan bakar tidak berubah karena build")
	assert_almost_eq(campfire.get_light_radius(), 240.0, 0.001)


func test_ember_only_after_the_first_light() -> void:
	assert_almost_eq(campfire.get_light_radius(), 0.0, 0.001)
	campfire.ignite()
	assert_true(campfire.is_lit())
	campfire.set_fuel(0.0)
	assert_false(campfire.is_lit())
	assert_almost_eq(campfire.get_light_radius(), 80.0, 0.001, "ember setelah pernah menyala")
	assert_true(campfire.get_light().visible)


func test_start_lit_true_restores_the_old_behavior() -> void:
	var fire := CAMPFIRE_SCENE.instantiate() as Campfire
	fire.definition = CAMPFIRE_DEF
	fire.clock = clock
	var config := fire.config.duplicate() as CampfireConfig
	config.start_lit = true
	fire.config = config
	add_child_autofree(fire)
	fire.set_process(false)
	assert_true(fire.is_lit())
	assert_true(fire.has_been_lit)
	assert_almost_eq(fire.get_fuel(), 240.0, 0.001)
	assert_almost_eq(fire.get_light_radius(), 240.0, 0.001)


# --- Semua yang bergantung status menyala -----------------------------------

func test_cooking_station_is_locked_while_cold() -> void:
	assert_eq(campfire.station_type, RecipeDefinition.Station.CAMPFIRE)
	assert_false(campfire.is_station_active())


func test_night_watch_is_refused_while_cold() -> void:
	clock.night = true
	var watch := NightWatchController.new()
	watch.clock = clock
	watch.input_enabled = false
	add_child_autofree(watch)
	assert_eq(watch.get_start_block_reason(), NightWatchController.REASON_NO_FIRE)
	assert_false(watch.start())


func test_rest_bonus_is_off_while_cold() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.set_physics_process(false)
	player.global_position = Vector2(20.0, 0.0)
	var needs := player.get_node("NeedsComponent") as NeedsComponent
	needs.set_process(false)
	campfire.tick(campfire.config.rest_check_interval + 0.01)
	assert_almost_eq(needs.get_idle_regen(), needs.get_config().fatigue_idle_regen, 0.001)


func test_dazzle_is_off_while_cold() -> void:
	var boar := WildBoar.new()
	boar.player = null
	add_child_autofree(boar)
	boar.global_position = campfire.global_position + Vector2(40.0, 0.0)
	boar.ensure_ready()
	boar._update_dazzle()
	assert_almost_eq(boar.get_speed_factor(), 1.0, 0.001, "api dingin tidak menyilaukan")


func test_hint_fires_when_the_campfire_is_built_cold() -> void:
	var hints := HINT_MANAGER_SCRIPT.new() as Node
	add_child_autofree(hints)
	hints.tick(0.05)
	assert_true(hints.has_shown(&"campfire_cold"), "hint api dingin langsung muncul")
	assert_string_contains(hints.get_text(&"campfire_cold"), "zona hijau")

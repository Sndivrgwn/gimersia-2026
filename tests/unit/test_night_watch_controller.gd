extends GutTest

## Tes NightWatchController: syarat mulai, ON/OFF clock, dan semua alasan stop.

const CAMPFIRE_SCENE: PackedScene = preload("res://src/entities/camp/campfire/campfire.tscn")
const CAMPFIRE_DEF: StructureDefinition = preload("res://src/data/camp/campfire.tres")
const WORKBENCH_DEF: StructureDefinition = preload("res://src/data/camp/workbench.tres")


class StubClock extends Node:
	signal night_ended(day: int)

	var night: bool = true
	var watch: bool = false
	var watch_calls: int = 0

	func is_night() -> bool:
		return night

	func is_day() -> bool:
		return not night

	func set_night_watch(active: bool) -> void:
		watch = active
		watch_calls += 1

	func get_time_scale() -> float:
		return 2.0 if watch else 1.0


var clock: StubClock
var campfire: Campfire
var controller: NightWatchController


func before_each() -> void:
	InputSetup.ensure_actions()

	clock = StubClock.new()
	add_child_autofree(clock)

	campfire = CAMPFIRE_SCENE.instantiate() as Campfire
	campfire.definition = CAMPFIRE_DEF
	campfire.clock = clock
	add_child_autofree(campfire)
	campfire.set_process(false)
	# Mission 9 (R4): bangunan baru COLD, tes jaga malam butuh api menyala.
	campfire.ignite()

	controller = NightWatchController.new()
	controller.clock = clock
	add_child_autofree(controller)
	controller.set_process(false)


func after_each() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	Input.action_release(&"move_down")


# --- Syarat mulai -----------------------------------------------------------

func test_cannot_start_by_day() -> void:
	clock.night = false

	assert_eq(controller.get_start_block_reason(), "Hanya saat malam")
	assert_false(controller.can_start())
	assert_false(controller.start())
	assert_false(clock.watch)


func test_cannot_start_without_lit_campfire() -> void:
	clock.night = true
	campfire.set_fuel(0.0)

	assert_eq(controller.get_start_block_reason(), "Butuh Api Unggun menyala")
	assert_false(controller.start())


func test_start_turns_on_clock_night_watch() -> void:
	clock.night = true
	watch_signals(controller)

	assert_true(controller.can_start())
	assert_true(controller.start())

	assert_true(controller.is_active())
	assert_true(clock.watch)
	assert_signal_emitted(controller, "watch_started")


func test_toggle_off_calls_set_night_watch_false() -> void:
	controller.start()
	watch_signals(controller)

	controller.toggle()

	assert_false(controller.is_active())
	assert_false(clock.watch)
	var params: Array = get_signal_parameters(controller, "watch_stopped", 0)
	assert_eq(params[0], "Dimatikan")


# --- Alasan stop ------------------------------------------------------------

func test_movement_stops_watch() -> void:
	controller.start()
	watch_signals(controller)

	Input.action_press(&"move_up")
	controller.tick(0.1)

	assert_false(controller.is_active())
	assert_false(clock.watch)
	var params: Array = get_signal_parameters(controller, "watch_stopped", 0)
	assert_eq(params[0], "Bergerak")


func test_fire_running_out_stops_watch() -> void:
	controller.start()
	watch_signals(controller)

	campfire.set_fuel(0.0)

	assert_false(controller.is_active())
	assert_false(clock.watch)
	var params: Array = get_signal_parameters(controller, "watch_stopped", 0)
	assert_eq(params[0], "Api padam")


func test_structure_damage_stops_watch() -> void:
	var structure := CampStructure.new()
	structure.definition = WORKBENCH_DEF
	add_child_autofree(structure)
	controller.start()
	watch_signals(controller)

	structure.take_damage(10.0, null)

	assert_false(controller.is_active())
	var params: Array = get_signal_parameters(controller, "watch_stopped", 0)
	assert_eq(params[0], "Struktur diserang")


func test_dawn_stops_watch() -> void:
	controller.start()
	watch_signals(controller)

	clock.night = false
	controller.tick(0.1)

	assert_false(controller.is_active())
	assert_false(clock.watch)
	var params: Array = get_signal_parameters(controller, "watch_stopped", 0)
	assert_eq(params[0], "Fajar")


func test_night_ended_signal_stops_watch() -> void:
	controller.start()
	watch_signals(controller)

	clock.night_ended.emit(2)

	assert_false(controller.is_active())
	var params: Array = get_signal_parameters(controller, "watch_stopped", 0)
	assert_eq(params[0], "Fajar")

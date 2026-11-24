extends GutTest

## Mission 9 Phase 3.1: FreezeController berbasis alasan, skala waktu dipulihkan
## persis, dan tumpang tindih pause + death.

class StubClock extends Node:
	var scale_value: float = 1.0

	func get_time_scale() -> float:
		return scale_value

	func set_time_scale(value: float) -> void:
		scale_value = value


class TickProbe extends Node:
	var ticks: int = 0

	func _process(_delta: float) -> void:
		ticks += 1


var clock: StubClock
var freezer: FreezeController


func before_each() -> void:
	clock = StubClock.new()
	add_child_autofree(clock)
	freezer = FreezeController.new()
	freezer.clock = clock
	add_child_autofree(freezer)


func after_each() -> void:
	get_tree().paused = false


func test_request_and_release_single_reason() -> void:
	assert_true(freezer.request(&"death"))
	assert_true(freezer.is_frozen())
	assert_true(get_tree().paused)
	assert_almost_eq(clock.get_time_scale(), 0.0, 0.001)
	freezer.release(&"death")
	assert_false(freezer.is_frozen())
	assert_false(get_tree().paused)
	assert_almost_eq(clock.get_time_scale(), 1.0, 0.001)


func test_duplicate_reason_is_idempotent() -> void:
	assert_true(freezer.request(&"pause"))
	assert_false(freezer.request(&"pause"))
	assert_eq(freezer.get_reason_count(), 1)
	freezer.release(&"pause")
	assert_false(freezer.is_frozen())


func test_night_watch_scale_two_is_restored() -> void:
	clock.scale_value = 2.0
	freezer.request(&"death")
	freezer.release(&"death")
	assert_almost_eq(clock.get_time_scale(), 2.0, 0.001)


func test_final_dawn_scale_zero_is_restored() -> void:
	clock.scale_value = 0.0
	freezer.request(&"pause")
	freezer.release(&"pause")
	assert_almost_eq(clock.get_time_scale(), 0.0, 0.001)


func test_releasing_one_reason_keeps_the_freeze() -> void:
	freezer.request(FreezeController.REASON_DEATH)
	freezer.request(FreezeController.REASON_PAUSE)
	assert_eq(freezer.get_reason_count(), 2)
	freezer.release(FreezeController.REASON_PAUSE)
	assert_true(freezer.is_frozen(), "masih mati: tetap beku")
	assert_true(get_tree().paused)
	freezer.release(FreezeController.REASON_DEATH)
	assert_false(freezer.is_frozen())


func test_nodes_do_not_tick_while_frozen() -> void:
	var probe := TickProbe.new()
	add_child_autofree(probe)
	freezer.request(&"death")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(probe.ticks, 0, "tidak ada tick selama beku")
	freezer.release(&"death")
	await get_tree().process_frame
	assert_gt(probe.ticks, 0, "tick kembali setelah beku dilepas")


func test_find_controller_uses_the_game_freeze_group() -> void:
	assert_eq(FreezeController.find_controller(self), freezer)

extends GutTest

class StubClock extends Node:
	signal day_started(day: int)
	signal rescue_started

	var rescue_triggered: bool = false
	var max_days: int = 7

	func get_max_days() -> int:
		return max_days

	func trigger_day(day: int) -> void:
		day_started.emit(day)

	func trigger_rescue() -> void:
		rescue_triggered = true
		rescue_started.emit()


var _clock: StubClock
var _player: Node2D
var _beacon: SignalBeacon
var _endgame: EndgameController


func before_each() -> void:
	_clock = StubClock.new()
	add_child_autofree(_clock)

	_player = Node2D.new()
	_player.add_to_group(&"player")
	add_child_autofree(_player)
	_player.global_position = Vector2(0, 64)

	_beacon = SignalBeacon.new()
	_beacon.clock = _clock
	add_child_autofree(_beacon)
	_beacon.global_position = Vector2(0, 2100)

	_endgame = EndgameController.new()
	add_child_autofree(_endgame)
	_endgame.setup(_clock, _player, _beacon)


func test_banner_only_on_the_final_day() -> void:
	watch_signals(_endgame)
	_clock.trigger_day(3)
	assert_signal_not_emitted(_endgame, "banner_shown")
	_clock.trigger_day(7)
	assert_signal_emitted(_endgame, "banner_shown")


func test_rescue_signal_marks_beacon_ready() -> void:
	watch_signals(_endgame)
	_clock.trigger_rescue()
	assert_signal_emitted(_endgame, "rescue_ready")
	assert_true(_endgame.is_rescue_active())


func test_beacon_direction_and_distance() -> void:
	_player.global_position = Vector2(0, 100)
	var direction := _endgame.get_beacon_direction()
	assert_almost_eq(direction.y, 1.0, 0.01)
	assert_almost_eq(_endgame.get_beacon_distance(), 2000.0, 0.01)


func test_beacon_victory_is_forwarded() -> void:
	_clock.rescue_triggered = true
	var inventory := InventoryComponent.new()
	add_child_autofree(inventory)
	inventory.add_item(ItemCatalog.SIGNAL_FLARE, 1)
	_beacon.inventory = inventory

	watch_signals(_endgame)
	_beacon.interact(null)
	assert_signal_emitted(_endgame, "victory")

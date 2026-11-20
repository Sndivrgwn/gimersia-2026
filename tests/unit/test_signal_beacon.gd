extends GutTest

class StubClock extends Node:
	var rescue_triggered: bool = false


var _beacon: SignalBeacon
var _inventory: InventoryComponent
var _clock: StubClock


func before_each() -> void:
	_beacon = SignalBeacon.new()
	add_child_autofree(_beacon)

	_inventory = InventoryComponent.new()
	add_child_autofree(_inventory)

	_clock = StubClock.new()
	add_child_autofree(_clock)
	_beacon.clock = _clock
	_beacon.inventory = _inventory


func test_blocked_before_rescue() -> void:
	_inventory.add_item(ItemCatalog.SIGNAL_FLARE, 1)
	assert_false(_beacon.can_interact(null))
	assert_eq(_beacon.get_block_reason(null), SignalBeacon.BLOCK_NO_RESCUE)


func test_blocked_without_flare() -> void:
	_clock.rescue_triggered = true
	assert_false(_beacon.can_interact(null))
	assert_eq(_beacon.get_block_reason(null), SignalBeacon.BLOCK_NO_FLARE)


func test_hold_e_requires_flare_and_rescue() -> void:
	_clock.rescue_triggered = true
	_inventory.add_item(ItemCatalog.SIGNAL_FLARE, 1)
	assert_true(_beacon.can_interact(null))
	assert_eq(_beacon.get_hold_time(null), 1.5)
	assert_eq(_beacon.get_prompt(null), SignalBeacon.PROMPT)


func test_interact_emits_victory_once() -> void:
	_clock.rescue_triggered = true
	_inventory.add_item(ItemCatalog.SIGNAL_FLARE, 1)
	watch_signals(_beacon)
	_beacon.interact(null)
	_beacon.interact(null)
	assert_signal_emit_count(_beacon, "victory_triggered", 1)

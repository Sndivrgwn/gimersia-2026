extends GutTest

## Tes StatusEffectsComponent: regen HP, refresh tanpa menumpuk, time scale,
## berhenti saat mati, dan format teks HUD.

const BOILED_WATER: ItemDefinition = preload("res://src/data/items/boiled_water.tres")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")

var _island: Node2D
var _player: Player
var _stats: StatsComponent
var _inventory: InventoryComponent
var _status: StatusEffectsComponent
var _clock: ClockStub
var _death: DeathStub


func before_each() -> void:
	_island = Node2D.new()
	add_child_autofree(_island)
	_death = DeathStub.new()
	_death.name = "DeathController"
	_island.add_child(_death)

	_player = PLAYER_SCENE.instantiate() as Player
	_island.add_child(_player)
	_stats = _player.get_node("StatsComponent") as StatsComponent
	_stats.set_hp(50.0)

	_inventory = InventoryComponent.new()
	_inventory.name = "InventoryComponent"
	_inventory.setup(_player)
	_player.add_child(_inventory)

	_clock = ClockStub.new()
	_status = StatusEffectsComponent.new()
	_status.clock = _clock
	_player.add_child(_status)


func after_each() -> void:
	pass


func test_heals_over_time() -> void:
	_status.apply(&"kaldu", "Kaldu", 1.0, 20.0)
	assert_true(_status.is_active(&"kaldu"))
	_status.tick(1.0)
	assert_almost_eq(_stats.current_hp, 51.0, 0.001)
	_status.tick(2.0)
	assert_almost_eq(_stats.current_hp, 53.0, 0.001)
	assert_true(_status.is_active(&"kaldu"))


func test_ends_after_duration() -> void:
	_status.apply(&"kaldu", "Kaldu", 1.0, 2.0)
	watch_signals(_status)
	_status.tick(2.0)
	assert_false(_status.is_active(&"kaldu"))
	assert_signal_emitted(_status, "effect_ended")


func test_refresh_does_not_stack() -> void:
	_status.apply(&"kaldu", "Kaldu", 1.0, 20.0)
	_status.tick(10.0)
	assert_almost_eq(_status.get_remaining(&"kaldu"), 10.0, 0.001)
	_status.apply(&"kaldu", "Kaldu", 1.0, 20.0)
	assert_almost_eq(_status.get_remaining(&"kaldu"), 20.0, 0.001)
	assert_eq(_status.get_effects().size(), 1)


func test_time_scale_zero_pauses_and_two_accelerates() -> void:
	_status.apply(&"kaldu", "Kaldu", 1.0, 20.0)
	_clock.scale = 0.0
	_status.tick(1.0)
	assert_almost_eq(_status.get_remaining(&"kaldu"), 20.0, 0.001)
	assert_almost_eq(_stats.current_hp, 50.0, 0.001)

	_clock.scale = 2.0
	_status.tick(1.0)
	assert_almost_eq(_status.get_remaining(&"kaldu"), 18.0, 0.001)
	assert_almost_eq(_stats.current_hp, 52.0, 0.001)


func test_death_stops_effect() -> void:
	_status.apply(&"kaldu", "Kaldu", 1.0, 20.0)
	_death.died.emit(2)
	assert_false(_status.is_active(&"kaldu"))


func test_hud_text_format() -> void:
	_status.apply(&"kaldu", "Kaldu", 1.0, 12.0)
	var effects := _status.get_effects()
	assert_eq(effects.size(), 1)
	assert_eq(_status.format_effect(effects[0]), "Kaldu +1 HP/s 12s")


func test_item_used_starts_effect() -> void:
	var effect := ItemEffect.new()
	effect.regen_hp_per_second = 1.0
	effect.regen_duration = 20.0
	var item := ItemDefinition.new()
	item.id = &"bone_broth"
	item.display_name = "Kaldu Tulang"
	item.consume_effect = effect
	_inventory.item_used.emit(item, 0)
	assert_true(_status.is_active(&"bone_broth"))


# --- Stubs ------------------------------------------------------------------

class ClockStub:
	extends Node
	var scale: float = 1.0

	func get_time_scale() -> float:
		return scale


class DeathStub:
	extends Node
	signal died(respawns_remaining: int)
	signal respawned

extends GutTest

## Tes untuk dua seam additive P1c: hit modifier CombatComponent dan pengali
## regen override NeedsComponent.

class Target extends Node2D:
	var health: HealthComponent

	func _init() -> void:
		health = HealthComponent.new()
		health.name = "HealthComponent"
		add_child(health)
		health.setup(100.0)

	func can_be_auto_targeted() -> bool:
		return false


var _player: Player
var _combat: CombatComponent


func before_each() -> void:
	_player = preload("res://src/entities/player/player.tscn").instantiate() as Player
	add_child_autofree(_player)
	var inventory := InventoryComponent.new()
	inventory.name = "InventoryComponent"
	_player.add_child(inventory)

	_combat = CombatComponent.new()
	_player.add_child(_combat)
	_combat.setup(_player)
	_combat.ignore_ui_guard = true


func test_hit_modifiers_apply_in_registration_order() -> void:
	var target := Target.new()
	add_child_autofree(target)
	target.global_position = Vector2(30, 0)

	_combat.register_hit_modifier(&"b", func(damage: float, _t: Node) -> float: return damage * 3.0)
	_combat.register_hit_modifier(&"a", func(damage: float, _t: Node) -> float: return damage + 2.0)
	_combat.swing_manual(Vector2.RIGHT)

	# urutan: 8 * 3 + 2 = 26
	assert_almost_eq(target.health.get_current_hp(), 100.0 - 26.0, 0.01)


func test_unregister_restores_plain_damage() -> void:
	var target := Target.new()
	add_child_autofree(target)
	target.global_position = Vector2(30, 0)

	_combat.register_hit_modifier(&"boost", func(damage: float, _t: Node) -> float: return damage * 2.0)
	_combat.unregister_hit_modifier(&"boost")
	assert_eq(_combat.get_hit_modifier_count(), 0)
	_combat.swing_manual(Vector2.RIGHT)
	assert_almost_eq(target.health.get_current_hp(), 100.0 - _combat.get_attack_damage(), 0.01)


func test_idle_regen_multiplier_ignores_base_regen() -> void:
	var needs := NeedsComponent.new()
	add_child_autofree(needs)
	needs.set_idle_regen_multiplier(&"prof_second_wind", 1.25)
	assert_almost_eq(needs.get_idle_regen(), needs.get_config().fatigue_idle_regen, 0.01)

	needs.set_idle_regen_override(&"campfire", 5.0)
	assert_almost_eq(needs.get_idle_regen(), 6.25, 0.01)

	needs.clear_idle_regen_multiplier(&"prof_second_wind")
	assert_almost_eq(needs.get_idle_regen(), 5.0, 0.01)

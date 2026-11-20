extends GutTest

class Target extends Node2D:
	var health: HealthComponent
	var auto_ok: bool = false
	var provoke_calls: int = 0
	var flashes: int = 0

	func _init() -> void:
		health = HealthComponent.new()
		health.name = "HealthComponent"
		add_child(health)
		health.setup(80.0)

	func can_be_auto_targeted() -> bool:
		return auto_ok

	func provoke(_source: Node) -> void:
		provoke_calls += 1
		auto_ok = true

	func flash_hit() -> void:
		flashes += 1


var _player: Player
var _combat: CombatComponent
var _inventory: InventoryComponent


func before_each() -> void:
	_player = preload("res://src/entities/player/player.tscn").instantiate() as Player
	add_child_autofree(_player)
	_player.global_position = Vector2.ZERO
	_inventory = InventoryComponent.new()
	_inventory.name = "InventoryComponent"
	_player.add_child(_inventory)
	_combat = CombatComponent.new()
	_combat.ignore_ui_guard = true
	_player.add_child(_combat)
	_combat.setup(_player)


func _target(position: Vector2 = Vector2(30.0, 0.0)) -> Target:
	var target := Target.new()
	add_child_autofree(target)
	target.global_position = position
	return target


func test_auto_attack_ignores_neutral_target() -> void:
	var target := _target()
	_combat.tick(0.01)
	assert_eq(target.health.get_current_hp(), 80.0)


func test_auto_attack_hits_hostile_and_spends_fatigue() -> void:
	var target := _target()
	target.auto_ok = true
	watch_signals(_combat)
	var fatigue_before: float = _player.get_node("NeedsComponent").get_value(NeedsComponent.Need.FATIGUE)
	_combat.tick(0.01)
	assert_eq(target.health.get_current_hp(), 72.0)
	assert_eq(_player.get_node("NeedsComponent").get_value(NeedsComponent.Need.FATIGUE), fatigue_before - 1.2)
	assert_signal_emit_count(_combat, "hit_dealt", 1)
	assert_eq(target.flashes, 1)


func test_manual_swing_provokes_neutral_target() -> void:
	var target := _target()
	_combat.swing_manual(Vector2.RIGHT)
	assert_eq(target.provoke_calls, 1)
	assert_eq(target.health.get_current_hp(), 72.0)
	assert_true(target.can_be_auto_targeted())


func test_manual_swing_respects_cone_and_range() -> void:
	var behind := _target(Vector2(-30.0, 0.0))
	_combat.swing_manual(Vector2.RIGHT)
	assert_eq(behind.health.get_current_hp(), 80.0)

	var far := _target(Vector2(200.0, 0.0))
	_combat.tick(1.0)
	_combat.swing_manual(Vector2.RIGHT)
	assert_eq(far.health.get_current_hp(), 80.0)


func test_manual_and_auto_share_cooldown() -> void:
	var target := _target()
	target.auto_ok = true
	_combat.tick(0.01)
	assert_eq(target.health.get_current_hp(), 72.0)
	_combat.tick(0.1)
	assert_eq(target.health.get_current_hp(), 72.0, "masih cooldown")
	_combat.tick(0.9)
	assert_eq(target.health.get_current_hp(), 64.0)


func test_manual_swing_without_target_still_uses_cooldown() -> void:
	_combat.swing_manual(Vector2.RIGHT)
	assert_gt(_combat.get_cooldown_remaining(), 0.0)
	var target := _target()
	target.auto_ok = true
	_combat.tick(0.1)
	assert_eq(target.health.get_current_hp(), 80.0)


func test_weapon_damage_and_range() -> void:
	assert_eq(_combat.get_attack_damage(), 8.0)
	assert_eq(_combat.get_attack_range(), 45.0)

	_inventory.equip(ItemCatalog.WOODEN_SPEAR)
	assert_eq(_combat.get_attack_damage(), 18.0)
	assert_eq(_combat.get_attack_range(), 75.0)

	_inventory.equip(ItemCatalog.STONE_SPEAR)
	assert_eq(_combat.get_attack_damage(), 28.0)
	assert_eq(_combat.get_attack_range(), 85.0)


func test_bone_spear_applies_bleed() -> void:
	_inventory.equip(ItemCatalog.BONE_SPEAR)
	var target := _target(Vector2(60.0, 0.0))
	_combat.swing_manual(Vector2.RIGHT)
	assert_eq(target.health.get_current_hp(), 50.0)
	assert_true(target.health.is_bleeding())
	target.health.tick(1.0)
	assert_eq(target.health.get_current_hp(), 48.0)


func test_dead_player_is_ignored() -> void:
	var target := _target()
	target.auto_ok = true
	_player.stats.get_max_hp()
	_player.stats.set_hp(0.0)
	_combat.tick(0.01)
	assert_eq(target.health.get_current_hp(), 80.0)

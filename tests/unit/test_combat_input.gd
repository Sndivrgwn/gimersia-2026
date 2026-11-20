extends GutTest

class Target extends Node2D:
	var health: HealthComponent

	func _init() -> void:
		health = HealthComponent.new()
		health.name = "HealthComponent"
		add_child(health)
		health.setup(80.0)

	func can_be_auto_targeted() -> bool:
		return false

	func provoke(_source: Node) -> void:
		pass


class StubBagPanel extends Node:
	var open: bool = false

	func is_open() -> bool:
		return open


var _player: Player
var _combat: CombatComponent
var _target: Target
var _panel: StubBagPanel


func before_each() -> void:
	InputSetup.ensure_actions()
	# Bersihkan status "just pressed" yang bisa tertinggal dari tes sebelumnya.
	Input.action_release(InputSetup.ATTACK_SPACE)
	Input.action_release(InputSetup.ATTACK_CLICK)
	await get_tree().process_frame
	_player = preload("res://src/entities/player/player.tscn").instantiate() as Player
	add_child_autofree(_player)
	_player.global_position = Vector2.ZERO
	var inventory := InventoryComponent.new()
	inventory.name = "InventoryComponent"
	_player.add_child(inventory)

	_combat = CombatComponent.new()
	_player.add_child(_combat)
	_combat.setup(_player)
	_combat.ignore_ui_guard = false

	_target = Target.new()
	add_child_autofree(_target)
	_target.global_position = Vector2(30.0, 0.0)

	_panel = StubBagPanel.new()
	_panel.name = "BagPanel"
	add_child_autofree(_panel)


func after_each() -> void:
	Input.action_release(InputSetup.ATTACK_SPACE)
	Input.action_release(InputSetup.ATTACK_CLICK)


func test_attack_actions_are_registered() -> void:
	assert_true(InputMap.has_action(InputSetup.ATTACK_SPACE))
	assert_true(InputMap.has_action(InputSetup.ATTACK_CLICK))

	var space := _find_key(InputSetup.ATTACK_SPACE)
	assert_true(space, "Space terdaftar untuk attack_space")

	var mouse_button := -1
	for event in InputMap.action_get_events(InputSetup.ATTACK_CLICK):
		var mouse_event := event as InputEventMouseButton
		if mouse_event != null:
			mouse_button = mouse_event.button_index
	assert_eq(mouse_button, MOUSE_BUTTON_LEFT, "klik kiri terdaftar untuk attack_click")


func test_guard_blocks_while_bag_panel_is_open() -> void:
	_panel.open = true
	assert_false(_combat.is_manual_input_allowed())
	_panel.open = false
	assert_true(_combat.is_manual_input_allowed())


func test_guard_blocks_while_a_control_is_hovered() -> void:
	var control := Control.new()
	add_child_autofree(control)
	_combat.hovered_control_override = control
	assert_false(_combat.is_manual_input_allowed())
	_combat.hovered_control_override = null
	assert_true(_combat.is_manual_input_allowed())


func test_ignore_ui_guard_bypasses_both_checks() -> void:
	_panel.open = true
	_combat.ignore_ui_guard = true
	assert_true(_combat.is_manual_input_allowed())
	_combat.ignore_ui_guard = false


func test_open_bag_panel_blocks_a_space_swing() -> void:
	_panel.open = true
	Input.action_press(InputSetup.ATTACK_SPACE)
	_combat.tick(0.01)
	Input.action_release(InputSetup.ATTACK_SPACE)
	assert_eq(_target.health.get_current_hp(), 80.0, "ayunan diblokir panel")


func test_space_swing_hits_when_panel_is_closed() -> void:
	_panel.open = false
	_player.facing_direction = Vector2.RIGHT
	Input.action_press(InputSetup.ATTACK_SPACE)
	_combat.tick(0.01)
	Input.action_release(InputSetup.ATTACK_SPACE)
	assert_eq(_target.health.get_current_hp(), 72.0, "ayunan jalan saat panel tertutup")


func test_manual_swing_without_target_still_uses_cooldown() -> void:
	var cooldown: float = _player.stats.get_attack_cooldown()
	_combat.swing_manual(Vector2.RIGHT)
	assert_almost_eq(_combat.get_cooldown_remaining(), cooldown, 0.001)
	_combat.tick(cooldown * 0.5)
	assert_almost_eq(_combat.get_cooldown_remaining(), cooldown * 0.5, 0.01)
	_combat.tick(cooldown * 0.5)
	assert_almost_eq(_combat.get_cooldown_remaining(), 0.0, 0.01)


func _find_key(action: StringName) -> bool:
	for event in InputMap.action_get_events(action):
		var key_event := event as InputEventKey
		if key_event != null and key_event.physical_keycode == KEY_SPACE:
			return true
	return false

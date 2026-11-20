class_name CombatComponent
extends Node

## Serangan pemain: auto-attack untuk target HOSTILE/PROVOKED dan ayunan
## manual (klik kiri / Space) yang memprovokasi fauna netral.
##
## Semua target dicari lewat grup &"damageable" dan jarak, tanpa physics query.
## Cooldown dipakai bersama oleh auto dan manual; manual didahulukan.
## Input dibaca dengan polling action (InputSetup), bukan _unhandled_input.

signal hit_dealt(target: Node, damage: float)
signal swing(aim_direction: Vector2, hit_count: int)
signal enemy_killed(target: Node)

const DEFAULT_CONFIG: CombatConfig = preload("res://src/data/configs/combat_config.tres")
const DAMAGEABLE_GROUP := &"damageable"
const SLASH_VISIBLE_TIME := 0.1
const BAG_PANEL_NAME := "BagPanel"

@export var combat_config: CombatConfig = DEFAULT_CONFIG
@export var player: Node
@export var stats: StatsComponent
@export var inventory: InventoryComponent
@export var needs: NeedsComponent
@export var damage_receiver: PlayerDamageReceiver

## Untuk tes: lewati guard UI.
@export var ignore_ui_guard: bool = false
## Untuk tes: kontrol yang dianggap sedang di-hover / panel tas yang dianggap terbuka.
var hovered_control_override: Control
var bag_panel_override: Node

var _cooldown: float = 0.0
var _slash: Polygon2D
var _slash_timer: float = 0.0
var _bound: bool = false


func _ready() -> void:
	_bind()
	InputSetup.ensure_actions()


func _process(delta: float) -> void:
	tick(delta)


func setup(p_player: Node) -> void:
	player = p_player
	_bound = false
	_bind()


# --- Read API ---------------------------------------------------------------

func get_cooldown_remaining() -> float:
	return _cooldown


func get_attack_range() -> float:
	var weapon := _weapon()
	if weapon != null and weapon.weapon_range > 0.0:
		return weapon.weapon_range
	return combat_config.bare_range if combat_config != null else 45.0


func get_attack_damage() -> float:
	if stats == null:
		return 0.0
	var weapon := _weapon()
	if weapon != null and weapon.weapon_damage > 0.0:
		return stats.get_attack_damage(weapon.weapon_damage)
	return stats.get_attack_damage()


func get_cone_angle() -> float:
	return combat_config.cone_angle_degrees if combat_config != null else 90.0


# --- Tick -------------------------------------------------------------------

func tick(delta: float) -> void:
	_bind()
	_cooldown = maxf(_cooldown - delta, 0.0)
	_tick_slash(delta)

	if _cooldown > 0.0:
		return

	var aim := _read_manual_aim()
	if aim != Vector2.ZERO:
		swing_manual(aim)
		return

	if stats != null and stats.current_hp <= 0.0:
		return
	_auto_attack()


# --- Internal ---------------------------------------------------------------

func _bind() -> void:
	if _bound:
		return
	if player == null:
		player = get_parent()
	if player != null:
		if stats == null:
			stats = player.get_node_or_null("StatsComponent") as StatsComponent
		if inventory == null:
			inventory = player.get_node_or_null("InventoryComponent") as InventoryComponent
		if needs == null:
			needs = player.get_node_or_null("NeedsComponent") as NeedsComponent
	_cooldown = 0.0
	_bound = true


func _weapon() -> ItemDefinition:
	if inventory == null:
		return null
	return inventory.get_equipped(ItemDefinition.EquipmentSlot.WEAPON)


## Arah ayunan manual, atau ZERO bila tidak ada input.
func _read_manual_aim() -> Vector2:
	if not _manual_allowed():
		return Vector2.ZERO

	if Input.is_action_just_pressed(InputSetup.ATTACK_SPACE):
		return _facing()

	if Input.is_action_just_pressed(InputSetup.ATTACK_CLICK) and player is Node2D:
		var origin := (player as Node2D).global_position
		var aim := (player as Node2D).get_global_mouse_position() - origin
		if aim.length_squared() > 0.0001:
			return aim.normalized()
		return _facing()
	return Vector2.ZERO


func _manual_allowed() -> bool:
	if ignore_ui_guard:
		return true
	return is_manual_input_allowed()


## Guard klik manual: kursor di atas Control apa pun, atau BagPanel terbuka.
func is_manual_input_allowed() -> bool:
	if ignore_ui_guard:
		return true
	if get_hovered_control() != null:
		return false
	var panel := get_bag_panel()
	if panel != null and panel.has_method(&"is_open") and bool(panel.is_open()):
		return false
	return true


## Kontrol yang sedang di-hover (bisa dioverride tes).
func get_hovered_control() -> Control:
	if hovered_control_override != null and is_instance_valid(hovered_control_override):
		return hovered_control_override
	var viewport := get_viewport()
	if viewport == null:
		return null
	return viewport.gui_get_hovered_control()


func get_bag_panel() -> Node:
	if bag_panel_override != null and is_instance_valid(bag_panel_override):
		return bag_panel_override
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.find_child(BAG_PANEL_NAME, true, false)


func _bag_panel_open() -> bool:
	var panel := get_bag_panel()
	if panel == null:
		return false
	if panel.has_method(&"is_open"):
		return bool(panel.is_open())
	return false


func _facing() -> Vector2:
	if player != null and "facing_direction" in player:
		var facing: Vector2 = player.facing_direction
		if facing.length_squared() > 0.0001:
			return facing.normalized()
	return Vector2.DOWN


## Ayunan manual (klik/Space memanggil ini). Publik supaya tes bisa
## menggerakkannya tanpa event input.
func swing_manual(aim: Vector2) -> void:
	var target := _nearest_in_cone(aim)
	_cooldown = _attack_cooldown()
	if target == null:
		swing.emit(aim, 0)
		_show_slash(aim)
		return
	_provoke(target)
	var hits := 1 if _hit(target) else 0
	swing.emit(aim, hits)
	_show_slash(aim)


func _auto_attack() -> void:
	var target := _nearest(true)
	if target == null:
		return
	_cooldown = _attack_cooldown()
	_hit(target)


func _attack_cooldown() -> float:
	if stats == null:
		return 0.0
	return stats.get_attack_cooldown()


func _nearest(require_auto: bool) -> Node:
	var origin := _origin()
	var best: Node = null
	var best_distance := get_attack_range()
	for node in get_tree().get_nodes_in_group(DAMAGEABLE_GROUP):
		if node == null or not is_instance_valid(node):
			continue
		if node == player:
			continue
		var health := _health_of(node)
		if health == null or health.is_dead():
			continue
		if require_auto and not _can_auto_target(node):
			continue
		var entity := node as Node2D
		if entity == null:
			continue
		var distance := origin.distance_to(entity.global_position)
		if distance <= best_distance:
			best = node
			best_distance = distance
	return best


func _nearest_in_cone(aim: Vector2) -> Node:
	var origin := _origin()
	var best: Node = null
	var best_distance := get_attack_range()
	var min_dot := cos(deg_to_rad(get_cone_angle() * 0.5))
	for node in get_tree().get_nodes_in_group(DAMAGEABLE_GROUP):
		if node == null or not is_instance_valid(node) or node == player:
			continue
		var health := _health_of(node)
		if health == null or health.is_dead():
			continue
		var entity := node as Node2D
		if entity == null:
			continue
		var offset := entity.global_position - origin
		var distance := offset.length()
		if distance > best_distance:
			continue
		if distance > 0.001 and aim.normalized().dot(offset / distance) < min_dot:
			continue
		best = node
		best_distance = distance
	return best


func _can_auto_target(node: Node) -> bool:
	if node.has_method(&"can_be_auto_targeted"):
		return bool(node.can_be_auto_targeted())
	# Damageable generik (stub tes / struktur masa depan) selalu boleh.
	return true


func _provoke(node: Node) -> void:
	if node.has_method(&"provoke"):
		node.provoke(player)


func _hit(target: Node) -> bool:
	var health := _health_of(target)
	if health == null:
		return false
	var damage := get_attack_damage()
	health.take_damage(damage, player)
	hit_dealt.emit(target, damage)

	if needs != null and combat_config != null:
		needs.spend_fatigue(combat_config.fatigue_cost_per_hit)

	_apply_bleed(health)
	_flash(target)
	_show_damage_text(target, damage)
	_connect_killed(target, health)
	return true


func _apply_bleed(health: HealthComponent) -> void:
	var weapon := _weapon()
	if weapon == null or combat_config == null:
		return
	if not combat_config.bleed_weapon_ids.has(weapon.id):
		return
	health.apply_bleed(combat_config.bleed_dps, combat_config.bleed_duration, player)


func _connect_killed(target: Node, health: HealthComponent) -> void:
	if health.died.is_connected(_on_target_died):
		return
	health.died.connect(_on_target_died.bind(target))


func _on_target_died(_source: Node, target: Node) -> void:
	enemy_killed.emit(target)


func _flash(target: Node) -> void:
	if target.has_method(&"flash_hit"):
		target.flash_hit()


func _show_damage_text(target: Node, damage: float) -> void:
	var tree := get_tree()
	var entity := target as Node2D
	if tree == null or tree.current_scene == null or entity == null:
		return
	FloatingText.spawn(
		tree.current_scene,
		entity.global_position + Vector2(0.0, -20.0),
		"-%d" % int(round(damage)),
		Color(1.0, 0.95, 0.6, 1.0)
	)


func _health_of(node: Node) -> HealthComponent:
	var health := node.get_node_or_null("HealthComponent") as HealthComponent
	return health


func _origin() -> Vector2:
	if player is Node2D:
		return (player as Node2D).global_position
	return Vector2.ZERO


# --- Visual placeholder -----------------------------------------------------

func _show_slash(aim: Vector2) -> void:
	if _slash == null:
		_slash = Polygon2D.new()
		_slash.name = "SlashArc"
		_slash.color = Color(1.0, 0.95, 0.7, 0.45)
		_slash.z_index = 5
		var range_px := get_attack_range()
		var points := PackedVector2Array([Vector2.ZERO])
		var steps := 8
		for index in steps + 1:
			var angle := deg_to_rad(-get_cone_angle() * 0.5 + get_cone_angle() * float(index) / float(steps))
			points.append(Vector2(cos(angle), sin(angle)) * range_px)
		_slash.polygon = points
		add_child(_slash)
	_slash.rotation = aim.angle()
	_slash.visible = true
	_slash_timer = SLASH_VISIBLE_TIME


func _tick_slash(delta: float) -> void:
	if _slash == null or not _slash.visible:
		return
	_slash_timer -= delta
	if _slash_timer <= 0.0:
		_slash.visible = false

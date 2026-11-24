class_name PlayerVisual
extends VisualDriver

## Driver animasi pemain: idle/walk/sprint/attack/hurt/death + arah hadap.

const HURT_TIME := 0.25
const ATTACK_TIME := 0.2

var _hurt_remaining: float = 0.0
var _attack_remaining: float = 0.0
var _dead: bool = false


func bind() -> void:
	if owner_node == null:
		return
	var combat := owner_node.get_node_or_null("CombatComponent")
	if combat != null and combat.has_signal(&"swing") and not combat.swing.is_connected(_on_swing):
		combat.swing.connect(_on_swing)
	var receiver := owner_node.get_node_or_null("PlayerDamageReceiver")
	if receiver != null and receiver.has_signal(&"damaged") and not receiver.damaged.is_connected(_on_damaged):
		receiver.damaged.connect(_on_damaged)
	var death := sibling("DeathController")
	if death != null:
		if death.has_signal(&"died") and not death.died.is_connected(_on_died):
			death.died.connect(_on_died)
		if death.has_signal(&"respawned") and not death.respawned.is_connected(_on_respawned):
			death.respawned.connect(_on_respawned)


func step(delta: float) -> void:
	_hurt_remaining = maxf(_hurt_remaining - delta, 0.0)
	_attack_remaining = maxf(_attack_remaining - delta, 0.0)

	var moving := owner_velocity().length_squared() > 1.0
	var state := VisualStateMap.player_state(
		_dead,
		_hurt_remaining > 0.0,
		_attack_remaining > 0.0,
		moving,
		_is_sprinting()
	)
	push(state, owner_facing(_last_dir))


func is_dead() -> bool:
	return _dead


# --- Internal ---------------------------------------------------------------

func _is_sprinting() -> bool:
	if owner_node != null and owner_node.has_method(&"is_sprinting"):
		return bool(owner_node.call(&"is_sprinting"))
	return false


func _on_swing(_aim: Vector2, _hits: int) -> void:
	_attack_remaining = ATTACK_TIME


func _on_damaged(_amount: float, _source: Node) -> void:
	_hurt_remaining = HURT_TIME


func _on_died(_respawns_remaining: int) -> void:
	_dead = true


func _on_respawned() -> void:
	_dead = false
	_hurt_remaining = 0.0
	_attack_remaining = 0.0

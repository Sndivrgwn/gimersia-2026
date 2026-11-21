class_name CombatFeedback
extends Node

## D5: juice visual (hit-stop lokal, shake, flash, squash, particles, event).
## Tidak mengubah balance apa pun.

signal feedback_event(kind: StringName, position: Vector2)

const DEFAULT_CONFIG: JuiceConfig = preload("res://src/data/configs/juice_config.tres")

@export var config: JuiceConfig = DEFAULT_CONFIG
@export var combat: CombatComponent
@export var receiver: PlayerDamageReceiver
@export var camera: Camera2D
@export var player: Node2D
@export var settings: SettingsService

var _hit_stop: float = 0.0
var _shake_time: float = 0.0
var _shake_duration: float = 0.0
var _shake_strength: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _flash_time: float = 0.0
var _squash_time: float = 0.0
var _last_kind: StringName = &""
var _last_target_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	if player == null:
		player = get_parent() as Node2D
	_resolve_combat()
	_resolve_receiver()
	if combat != null:
		combat.swing_buffer_time = config.manual_swing_buffer
		if not combat.hit_dealt.is_connected(_on_hit_dealt):
			combat.hit_dealt.connect(_on_hit_dealt)
		if not combat.enemy_killed.is_connected(_on_enemy_killed):
			combat.enemy_killed.connect(_on_enemy_killed)
		if not combat.swing.is_connected(_on_swing):
			combat.swing.connect(_on_swing)
	if receiver != null:
		if not receiver.damaged.is_connected(_on_receiver_damaged):
			receiver.damaged.connect(_on_receiver_damaged)
		if not receiver.dodged.is_connected(_on_dodged):
			receiver.dodged.connect(_on_dodged)


func _process(delta: float) -> void:
	tick(delta)


# --- API --------------------------------------------------------------------

func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	_hit_stop = maxf(_hit_stop - delta, 0.0)
	_flash_time = maxf(_flash_time - delta, 0.0)
	_squash_time = maxf(_squash_time - delta, 0.0)
	if _shake_time > 0.0:
		_shake_time = maxf(_shake_time - delta, 0.0)
		_shake_offset = _shake_vector()
	else:
		_shake_offset = Vector2.ZERO
	_apply_camera_offset()


## Dipakai tes dan hook Heavy Strike.
func notify_hit(target: Node, damage: float, heavy: bool = false) -> void:
	var position := (target as Node2D).global_position if target is Node2D else Vector2.ZERO
	_last_target_position = position
	_last_kind = &"heavy_hit" if heavy else &"hit"
	_hit_stop = (config.hit_stop_heavy if heavy else config.hit_stop_light) * _intensity()
	_start_shake(
		config.shake_heavy if heavy else config.shake_light,
		config.shake_heavy_time if heavy else config.shake_light_time
	)
	_flash_time = config.flash_time
	_squash_time = config.squash_time
	if target != null and target.has_method(&"freeze_for"):
		target.freeze_for(_hit_stop)
	_spawn_burst(position, config.hit_spark_count, Color(1.0, 0.85, 0.4, 1.0))
	feedback_event.emit(_last_kind, position)


func get_shake_offset() -> Vector2:
	return _shake_offset


func is_hit_stopped() -> bool:
	return _hit_stop > 0.0


func get_last_kind() -> StringName:
	return _last_kind


func get_squash_scale() -> Vector2:
	if _squash_time <= 0.0 or config.squash_time <= 0.0:
		return Vector2.ONE
	var ratio := _squash_time / config.squash_time
	return Vector2.ONE.lerp(config.squash_scale, ratio)


func get_flash_alpha() -> float:
	if _flash_time <= 0.0 or config.flash_time <= 0.0:
		return 0.0
	return _flash_time / config.flash_time


# --- Internal ---------------------------------------------------------------

func _on_hit_dealt(target: Node, damage: float) -> void:
	var heavy := combat != null and combat.has_method(&"was_last_hit_heavy") and combat.was_last_hit_heavy()
	notify_hit(target, damage, heavy)


func _on_enemy_killed(target: Node) -> void:
	_last_kind = &"kill"
	var position := (target as Node2D).global_position if target is Node2D else Vector2.ZERO
	_start_shake(config.shake_kill, config.shake_kill_time)
	_spawn_burst(position, config.kill_burst_count, Color(1.0, 0.4, 0.3, 1.0))
	feedback_event.emit(&"kill", position)


func _on_swing(_aim: Vector2, _hits: int) -> void:
	if player == null:
		return
	var visual := player.get_node_or_null("Visual") as Node2D
	if visual == null:
		return
	var tween := create_tween()
	visual.position = Vector2.ZERO
	tween.tween_property(visual, "position", Vector2(config.player_lunge, 0.0), config.player_lunge_time)
	tween.tween_property(visual, "position", Vector2.ZERO, config.player_lunge_time)


func _on_receiver_damaged(_amount: float, _source: Node) -> void:
	_last_kind = &"player_hurt"
	_start_shake(config.shake_player_hurt, config.shake_player_hurt_time)
	feedback_event.emit(&"player_hurt", player.global_position if player != null else Vector2.ZERO)


func _on_dodged(_source: Node) -> void:
	_last_kind = &"dodge"
	feedback_event.emit(&"dodge", player.global_position if player != null else Vector2.ZERO)


func _start_shake(strength: float, duration: float) -> void:
	if not _screenshake_enabled():
		_shake_time = 0.0
		_shake_strength = 0.0
		return
	_shake_strength = strength * _intensity()
	_shake_duration = duration
	_shake_time = duration


func _shake_vector() -> Vector2:
	if _shake_duration <= 0.0:
		return Vector2.ZERO
	var ratio := _shake_time / _shake_duration
	var amount := _shake_strength * ratio
	return Vector2(randf_range(-amount, amount), randf_range(-amount, amount))


func _apply_camera_offset() -> void:
	var target := camera
	if target == null:
		var viewport := get_viewport()
		if viewport != null:
			target = viewport.get_camera_2d()
	if target == null:
		return
	target.offset = _shake_offset


func _spawn_burst(position: Vector2, count: int, color: Color) -> void:
	if count <= 0 or not is_inside_tree():
		return
	var particles := CPUParticles2D.new()
	particles.name = "FeedbackBurst"
	particles.one_shot = true
	particles.emitting = true
	particles.amount = count
	particles.lifetime = 0.35
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 90.0
	particles.gravity = Vector2(0.0, 200.0)
	particles.color = color
	particles.position = position
	var host := get_parent() as Node2D
	if host == null:
		particles.queue_free()
		return
	host.add_child(particles)
	particles.finished.connect(particles.queue_free)


## Mission 7: pengaturan pemain menimpa JuiceConfig bila SettingsService ada.
func _settings() -> SettingsService:
	if settings == null:
		settings = SettingsService.find_service(self)
	return settings


func _intensity() -> float:
	var base := config.intensity
	var service := _settings()
	if service != null:
		return base * service.get_juice_intensity()
	return base


func _screenshake_enabled() -> bool:
	var service := _settings()
	if service != null:
		return config.screenshake_enabled and service.is_screenshake_enabled()
	return config.screenshake_enabled


func _resolve_combat() -> void:
	if combat != null:
		return
	if player == null:
		return
	combat = player.get_node_or_null("CombatComponent") as CombatComponent


func _resolve_receiver() -> void:
	if receiver != null:
		return
	if player == null:
		return
	receiver = player.get_node_or_null("PlayerDamageReceiver") as PlayerDamageReceiver

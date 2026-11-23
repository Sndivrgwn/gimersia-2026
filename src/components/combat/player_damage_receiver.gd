class_name PlayerDamageReceiver
extends Node

## Penerima serangan untuk Player: dodge roll, damage reduction, knockback,
## dan umpan balik teks. Dipasang sebagai anak Player di island.tscn.
##
## HP tetap milik StatsComponent (set_hp()); komponen ini tidak menulis
## current_hp langsung.

signal dodged(source: Node)
signal damaged(amount: float, source: Node)
## Mission 9: perlindungan respawn (detik nyata).
signal protection_started(seconds: float)
signal protection_ended

const DEFAULT_CONFIG: CombatConfig = preload("res://src/data/configs/combat_config.tres")
const DEFAULT_RUN_CONFIG: RunConfig = preload("res://src/data/configs/run_config.tres")
const PROTECTED_ALPHA := 0.3
const FLOATING_TEXT_SCENE_PATH := "res://src/ui/feedback/floating_text.tscn"
const DODGE_COLOR := Color(0.7, 0.95, 1.0, 1.0)

@export var combat_config: CombatConfig = DEFAULT_CONFIG
## Mission 9: tuning perlindungan respawn (detik nyata, kedip visual).
@export var run_config: RunConfig = DEFAULT_RUN_CONFIG
## Opsional; diisi otomatis dari parent.
@export var player: Node
@export var stats: StatsComponent

## Bisa diganti tes dengan RNG ber-seed.
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _floating_scene: PackedScene

var _protection_remaining: float = 0.0
var _blink_time: float = 0.0
var _visual: CanvasItem


func _ready() -> void:
	_bind()


func _process(delta: float) -> void:
	tick(delta)


func setup(p_player: Node) -> void:
	player = p_player
	_bind()


func get_stats() -> StatsComponent:
	return stats


## Terima satu serangan. True bila damage benar-benar masuk (bukan dodge).
func receive_hit(
	raw: float,
	source: Node,
	knockback_dir: Vector2 = Vector2.ZERO,
	knockback_distance: float = 0.0
) -> bool:
	_bind()
	if stats == null:
		return false
	# Mission 9: selama perlindungan respawn tidak ada damage, knockback, atau teks.
	if is_protected():
		return false
	# Pastikan cache/HP sudah terinisialisasi sebelum membaca current_hp.
	stats.get_max_hp()
	# Pemain dengan HP <= 0 diabaikan musuh (kematian menyusul di misi lain).
	if stats.current_hp <= 0.0:
		return false
	if raw < 0.0:
		raw = 0.0

	if rng.randf() < stats.get_dodge_chance():
		dodged.emit(source)
		_show_text("DODGE!", DODGE_COLOR)
		return false

	var amount := stats.calc_incoming_damage(raw)
	stats.set_hp(stats.current_hp - amount)
	damaged.emit(amount, source)
	_show_text("-%d" % int(round(amount)), Color(1.0, 0.45, 0.4, 1.0))

	if knockback_dir.length_squared() > 0.0 and knockback_distance > 0.0:
		if player != null and player.has_method(&"apply_knockback"):
			var multiplier := 1.0
			if "knockback_multiplier" in player:
				multiplier = float(player.knockback_multiplier)
			var duration := combat_config.knockback_duration if combat_config != null else 0.2
			player.apply_knockback(knockback_dir, knockback_distance * multiplier, duration)
	return true


func _bind() -> void:
	if player == null:
		player = get_parent()
	if stats == null and player != null:
		stats = player.get_node_or_null("StatsComponent") as StatsComponent
	if combat_config == null:
		combat_config = DEFAULT_CONFIG
	if run_config == null:
		run_config = DEFAULT_RUN_CONFIG
	if _visual == null and player != null:
		_visual = player.get_node_or_null("Visual") as CanvasItem
	if player != null:
		var combat := player.get_node_or_null("CombatComponent")
		if combat != null and combat.has_signal(&"hit_dealt") and not combat.hit_dealt.is_connected(_on_attack_dealt):
			combat.hit_dealt.connect(_on_attack_dealt)


# --- Protection (Mission 9) -------------------------------------------------

func is_protected() -> bool:
	return _protection_remaining > 0.0


func get_protection_remaining() -> float:
	return _protection_remaining


## Mulai/perpanjang perlindungan. `seconds` < 0 = pakai RunConfig.
func start_protection(seconds: float = -1.0) -> void:
	var duration := seconds
	if duration < 0.0:
		duration = run_config.respawn_protection_seconds if run_config != null else 5.0
	if duration <= 0.0:
		return
	_protection_remaining = duration
	_blink_time = 0.0
	protection_started.emit(duration)


func stop_protection() -> void:
	if _protection_remaining <= 0.0:
		return
	_protection_remaining = 0.0
	_restore_alpha()
	protection_ended.emit()


## Waktu nyata (tidak dikali time scale game).
func tick(delta: float) -> void:
	if _protection_remaining <= 0.0 or delta <= 0.0:
		return
	_protection_remaining = maxf(_protection_remaining - delta, 0.0)
	_blink_time += delta
	_blink()
	if _protection_remaining <= 0.0:
		_restore_alpha()
		protection_ended.emit()


func _blink() -> void:
	if _visual == null and player != null:
		_visual = player.get_node_or_null("Visual") as CanvasItem
	if _visual == null:
		return
	var hz := run_config.protection_blink_hz if run_config != null else 6.0
	var on := fmod(maxf(_blink_time * maxf(hz, 0.01), 0.0), 1.0) < 0.5
	var tint := _visual.modulate
	tint.a = 1.0 if on else PROTECTED_ALPHA
	_visual.modulate = tint


func _restore_alpha() -> void:
	if _visual == null:
		return
	var tint := _visual.modulate
	tint.a = 1.0
	_visual.modulate = tint


func _on_attack_dealt(_target: Node, _amount: float) -> void:
	if run_config != null and run_config.protection_ends_on_attack and is_protected():
		stop_protection()


func _show_text(message: String, tint: Color) -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	if _floating_scene == null:
		_floating_scene = load(FLOATING_TEXT_SCENE_PATH) as PackedScene
	var anchor := Vector2.ZERO
	if player is Node2D:
		anchor = (player as Node2D).global_position + Vector2(0.0, -18.0)
	FloatingText.spawn(tree.current_scene, anchor, message, tint)

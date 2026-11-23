class_name HealthRegenComponent
extends Node

## Mission 9: regen HP pasif. Anak dari Player di island.tscn.
##
## Aturan:
## - tidak ada regen saat HP penuh;
## - menunggu `out_of_combat_delay` detik game sejak damage terakhir;
## - multiplier = min(kurva Hunger, kurva Thirst) dari HealthRegenConfig;
## - tidak ada regen saat Hunger atau Thirst di tier ZERO (damage kelaparan menang).
##
## `tick(delta)` memakai waktu game (delta x clock.get_time_scale()), jadi Jaga
## Malam (x2) dan final dawn (0) ikut terasa tanpa penanganan khusus.

const DEFAULT_CONFIG: HealthRegenConfig = preload("res://src/data/configs/health_regen_config.tres")

@export var config: HealthRegenConfig = DEFAULT_CONFIG
@export var stats: StatsComponent
@export var needs: NeedsComponent
@export var clock: Node

var _since_damage: float = 0.0
var _ready_bound: bool = false
var _last_hp: float = -1.0


func _ready() -> void:
	_bind()


func _process(delta: float) -> void:
	tick(delta)


## Satu tick game. Dipanggil `_process` dan tes.
func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	_bind()
	if config == null or stats == null:
		return
	var game_delta := delta * _time_scale()
	if game_delta <= 0.0:
		return

	_since_damage += game_delta
	if _since_damage < config.out_of_combat_delay:
		return
	if stats.current_hp >= stats.get_max_hp():
		return
	var multiplier := get_multiplier()
	if multiplier <= 0.0:
		return
	var amount := config.base_regen_per_second * multiplier * game_delta
	stats.set_hp(minf(stats.current_hp + amount, stats.get_max_hp()))


# --- Read API ---------------------------------------------------------------

func get_multiplier() -> float:
	if config == null or needs == null:
		return 1.0
	# Tier ZERO mematikan regen sepenuhnya, walau desainer mengubah kurvanya.
	if needs.is_zero_tier(NeedsComponent.Need.HUNGER) or needs.is_zero_tier(NeedsComponent.Need.THIRST):
		return 0.0
	return config.get_multiplier(needs.get_hunger_value(), needs.get_thirst_value())


func get_since_damage() -> float:
	return _since_damage


## Untuk tes/save: paksa waktu sejak damage terakhir.
func set_since_damage(value: float) -> void:
	_since_damage = maxf(value, 0.0)


# --- Internal ---------------------------------------------------------------

func _bind() -> void:
	if _ready_bound:
		return
	if stats == null:
		stats = get_parent().get_node_or_null("StatsComponent") as StatsComponent
	if needs == null:
		needs = get_parent().get_node_or_null("NeedsComponent") as NeedsComponent
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	if config == null:
		config = DEFAULT_CONFIG
	if stats == null:
		return
	if not stats.hp_changed.is_connected(_on_hp_changed):
		stats.hp_changed.connect(_on_hp_changed)
	_ready_bound = true


## StatsComponent tidak punya sinyal `damaged`; HP yang turun dianggap damage
## (termasuk kerusakan kelaparan, yang memang mematikan regen).
func _on_hp_changed(current: float, _max_value: float) -> void:
	if _last_hp >= 0.0 and current < _last_hp - 0.0001:
		_since_damage = 0.0
	_last_hp = current


func _time_scale() -> float:
	if clock != null and clock.has_method(&"get_time_scale"):
		return maxf(float(clock.get_time_scale()), 0.0)
	return 1.0

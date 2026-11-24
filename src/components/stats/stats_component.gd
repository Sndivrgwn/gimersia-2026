class_name StatsComponent
extends Node

## Komponen stat pemain. Player hanya merangkai komponen ini.
##
## Angka dasar dibaca dari PlayerBaseStats. Semua nilai akhir dihitung ulang
## setiap level/modifier berubah, lalu hasilnya di-cache. Nilai turunan selalu
## dihitung lewat rumus di bawah, tidak ada angka stat yang ditulis di sini.

signal hp_changed(current: float, max_value: float)
signal stats_changed()

const MIN_PROFICIENCY_LEVEL := 1
const MAX_PROFICIENCY_LEVEL := 10

## Koefisien rumus proficiency (Bagian 5.B spesifikasi).
const HP_PER_STRENGTH := 5.0
const MOVE_SPEED_PER_SPEED_LEVEL := 0.04
const ATTACK_DAMAGE_PER_STRENGTH := 0.10
const ATTACK_SPEED_PER_AGILITY := 0.05
const CRAFT_TIME_PER_MASTERY := 0.06
const GATHER_TIME_PER_MASTERY := 0.06
const SPRINT_FATIGUE_PER_SPEED_LEVEL := 0.03
const DODGE_PER_AGILITY := 0.02
const LIGHT_FOOTED_SPEED_LEVEL := 3
const LIGHT_FOOTED_SPRINT_BONUS := 0.10

const SUPPORTED_STATS: Array[StringName] = [
	&"max_hp",
	&"damage_reduction",
	&"move_speed",
	&"sprint_speed",
	&"attack_damage",
	&"attack_speed",
	&"dodge",
	&"craft_time",
	&"gather_time",
	&"sprint_fatigue_drain",
]

## Nilai dasar. Jika null, dipakai PlayerBaseStats.new() (nilai default script).
@export var base_stats: PlayerBaseStats:
	get:
		return _base_stats
	set(value):
		if _base_stats == value:
			return
		_base_stats = value
		_cache_valid = false
		if is_inside_tree():
			_refresh()

# --- Level proficiency (1..10) ---------------------------------------------

var strength_level: int:
	get:
		return _strength_level
	set(value):
		_strength_level = clampi(value, MIN_PROFICIENCY_LEVEL, MAX_PROFICIENCY_LEVEL)
		_refresh()

var speed_level: int:
	get:
		return _speed_level
	set(value):
		_speed_level = clampi(value, MIN_PROFICIENCY_LEVEL, MAX_PROFICIENCY_LEVEL)
		_refresh()

var mastery_level: int:
	get:
		return _mastery_level
	set(value):
		_mastery_level = clampi(value, MIN_PROFICIENCY_LEVEL, MAX_PROFICIENCY_LEVEL)
		_refresh()

var agility_level: int:
	get:
		return _agility_level
	set(value):
		_agility_level = clampi(value, MIN_PROFICIENCY_LEVEL, MAX_PROFICIENCY_LEVEL)
		_refresh()

# --- HP --------------------------------------------------------------------

## Ubah lewat set_hp() atau heal() agar hp_changed tetap terpancar.
var current_hp: float = 0.0

var _base_stats: PlayerBaseStats
var _strength_level: int = 1
var _speed_level: int = 1
var _mastery_level: int = 1
var _agility_level: int = 1

var _modifiers: Array[StatModifier] = []
var _fallback_base: PlayerBaseStats
var _cache_valid: bool = false
var _hp_initialized: bool = false

var _max_hp: float = 0.0
var _move_speed: float = 0.0
var _sprint_speed: float = 0.0
var _attack_damage: float = 0.0
var _attack_speed: float = 0.0
var _dodge_chance: float = 0.0
var _damage_reduction: float = 0.0
var _craft_time_factor: float = 1.0
var _gather_time_factor: float = 1.0
var _sprint_fatigue_drain_factor: float = 1.0


func _ready() -> void:
	_refresh()


# --- API modifier ----------------------------------------------------------

## Tambah satu modifier. Satu source_id boleh punya beberapa modifier.
func add_modifier(source_id: StringName, stat: StringName, kind: int, value: float) -> void:
	if not SUPPORTED_STATS.has(stat):
		push_warning("StatsComponent: stat '%s' tidak dikenal; modifier diabaikan." % stat)
		return
	if kind != StatModifier.Kind.FLAT and kind != StatModifier.Kind.PERCENT:
		push_warning("StatsComponent: kind modifier %d tidak dikenal; modifier diabaikan." % kind)
		return

	_modifiers.append(StatModifier.new(source_id, stat, kind, value))
	_refresh()


## Hapus semua modifier milik source_id.
func remove_modifier(source_id: StringName) -> void:
	var removed := false
	for index in range(_modifiers.size() - 1, -1, -1):
		if _modifiers[index].source_id == source_id:
			_modifiers.remove_at(index)
			removed = true

	if removed:
		_refresh()


# --- Getter publik ---------------------------------------------------------

func get_max_hp() -> float:
	_ensure_cache()
	return _max_hp


func get_move_speed() -> float:
	_ensure_cache()
	return _move_speed


func get_sprint_speed() -> float:
	_ensure_cache()
	return _sprint_speed


## weapon_base < 0 berarti memakai base_attack_damage. Nilai senjata lain
## memakai bonus persentase yang sama dengan serangan dasar.
func get_attack_damage(weapon_base: float = -1.0) -> float:
	_ensure_cache()
	if weapon_base < 0.0:
		return _attack_damage
	return weapon_base * _attack_damage_factor()


func get_attack_speed() -> float:
	_ensure_cache()
	return _attack_speed


func get_attack_cooldown() -> float:
	var speed := get_attack_speed()
	if speed <= 0.0:
		return 0.0
	return 1.0 / speed


func get_dodge_chance() -> float:
	_ensure_cache()
	return _dodge_chance


func get_damage_reduction() -> float:
	_ensure_cache()
	return _damage_reduction


## Faktor pengali waktu craft (bukan durasi absolut).
func get_craft_time_factor() -> float:
	_ensure_cache()
	return _craft_time_factor


## Faktor pengali waktu gather (bukan durasi absolut).
func get_gather_time_factor() -> float:
	_ensure_cache()
	return _gather_time_factor


## Faktor pengali pengurasan Fatigue saat sprint.
func get_sprint_fatigue_drain_factor() -> float:
	_ensure_cache()
	return _sprint_fatigue_drain_factor


func calc_incoming_damage(raw: float) -> float:
	return raw * (1.0 - get_damage_reduction())


# --- HP --------------------------------------------------------------------

func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	_ensure_cache()
	set_hp(current_hp + amount)


func set_hp(value: float) -> void:
	var maximum := get_max_hp()
	var clamped := clampf(value, 0.0, maximum)
	if _hp_initialized and is_equal_approx(clamped, current_hp):
		return

	_hp_initialized = true
	current_hp = clamped
	hp_changed.emit(current_hp, maximum)


# --- Kalkulasi -------------------------------------------------------------

func _ensure_cache() -> void:
	if _cache_valid:
		return

	_compute_values()
	_cache_valid = true
	if not _hp_initialized:
		current_hp = _max_hp
		_hp_initialized = true


## Hitung ulang semua nilai lalu sinkronkan HP dan signal.
func _refresh() -> void:
	var previous_max := _max_hp
	var previous_hp := current_hp
	var was_initialized := _hp_initialized

	_compute_values()
	_cache_valid = true

	if not _hp_initialized:
		current_hp = _max_hp
		_hp_initialized = true
	else:
		current_hp = clampf(current_hp, 0.0, _max_hp)

	var should_emit_hp := not was_initialized
	should_emit_hp = should_emit_hp or not is_equal_approx(previous_max, _max_hp)
	should_emit_hp = should_emit_hp or not is_equal_approx(previous_hp, current_hp)
	if should_emit_hp:
		hp_changed.emit(current_hp, _max_hp)

	stats_changed.emit()


func _compute_values() -> void:
	var base := _resolve_base()

	# max_hp = base + bonus Strength + FLAT(max_hp).
	_max_hp = base.base_max_hp + HP_PER_STRENGTH * float(strength_level - 1) + _sum_flat(&"max_hp")

	# Ketiga stat ini memakai faktor yang sama: 1 + bonus level + semua PERCENT.
	_move_speed = base.base_move_speed * maxf(
		base.percent_modifier_floor,
		1.0 + MOVE_SPEED_PER_SPEED_LEVEL * float(speed_level - 1) + _sum_percent(&"move_speed")
	)

	_attack_damage = base.base_attack_damage * _attack_damage_factor()

	_attack_speed = base.base_attack_speed * maxf(
		base.percent_modifier_floor,
		1.0 + ATTACK_SPEED_PER_AGILITY * float(agility_level - 1) + _sum_percent(&"attack_speed")
	)

	# Light Footed (passive, Speed >= 3): +0.10 ditambahkan ke pengali sprint,
	# bukan ke move speed. Jadi sprint = move_speed * (sprint_multiplier + 0.10).
	var sprint_multiplier := base.sprint_multiplier
	if speed_level >= LIGHT_FOOTED_SPEED_LEVEL:
		sprint_multiplier += LIGHT_FOOTED_SPRINT_BONUS
	_sprint_speed = _move_speed * sprint_multiplier + _sum_flat(&"sprint_speed")

	_craft_time_factor = maxf(
		base.percent_modifier_floor,
		1.0 - CRAFT_TIME_PER_MASTERY * float(mastery_level - 1) + _sum_percent(&"craft_time")
	)
	_gather_time_factor = maxf(
		base.percent_modifier_floor,
		1.0 - GATHER_TIME_PER_MASTERY * float(mastery_level - 1) + _sum_percent(&"gather_time")
	)
	_sprint_fatigue_drain_factor = maxf(
		base.percent_modifier_floor,
		1.0 - SPRINT_FATIGUE_PER_SPEED_LEVEL * float(speed_level - 1) + _sum_percent(&"sprint_fatigue_drain")
	)

	# Dodge additive murni (tanpa floor 0.25), tetap dibatasi dodge_hard_cap.
	_dodge_chance = clampf(
		DODGE_PER_AGILITY * float(agility_level - 1) + base.base_dodge_chance + _sum_percent(&"dodge"),
		0.0,
		base.dodge_hard_cap
	)

	_damage_reduction = clampf(
		base.base_damage_reduction + _sum_percent(&"damage_reduction"),
		0.0,
		base.max_damage_reduction
	)


func _attack_damage_factor() -> float:
	var base := _resolve_base()
	var level_bonus := ATTACK_DAMAGE_PER_STRENGTH * float(strength_level - 1)
	return maxf(base.percent_modifier_floor, 1.0 + level_bonus + _sum_percent(&"attack_damage"))


## Nilai dasar yang benar-benar dipakai (termasuk fallback default).
## Dipakai modul lain yang membaca setting "satu run", mis. jumlah token respawn.
func get_base_stats() -> PlayerBaseStats:
	return _resolve_base()


func _resolve_base() -> PlayerBaseStats:
	if _base_stats != null:
		return _base_stats
	if _fallback_base == null:
		_fallback_base = PlayerBaseStats.new()
	return _fallback_base


func _sum_flat(stat: StringName) -> float:
	var total := 0.0
	for modifier in _modifiers:
		if modifier.stat == stat and modifier.kind == StatModifier.Kind.FLAT:
			total += modifier.value
	return total


func _sum_percent(stat: StringName) -> float:
	var total := 0.0
	for modifier in _modifiers:
		if modifier.stat == stat and modifier.kind == StatModifier.Kind.PERCENT:
			total += modifier.value
	return total

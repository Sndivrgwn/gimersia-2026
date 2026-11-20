class_name HealthComponent
extends Node

## HP untuk fauna (dan entity lain yang bukan Player). Pemilik tunggal HP.
##
## Bleed memakai delta yang diberikan pemanggil (FaunaBase meneruskannya), jadi
## tes bisa menggerakkannya deterministik.

signal hp_changed(current: float, max_value: float)
signal damaged(amount: float, source: Node)
signal died(source: Node)

const GROUP := &"damageable"

@export var max_hp: float = 1.0

var current_hp: float = 1.0

var _bleed_dps: float = 0.0
var _bleed_remaining: float = 0.0
var _bleed_source: Node
var _dead: bool = false


func _ready() -> void:
	_enter_group()
	if is_equal_approx(current_hp, 0.0):
		current_hp = max_hp


func setup(value: float) -> void:
	max_hp = maxf(value, 1.0)
	current_hp = max_hp
	_dead = false
	_enter_group()
	hp_changed.emit(current_hp, max_hp)


func get_max_hp() -> float:
	return max_hp


func get_current_hp() -> float:
	return current_hp


func get_ratio() -> float:
	if max_hp <= 0.0:
		return 0.0
	return clampf(current_hp / max_hp, 0.0, 1.0)


func is_dead() -> bool:
	return _dead or current_hp <= 0.0


## Mengembalikan jumlah HP yang benar-benar hilang.
func take_damage(amount: float, source: Node) -> float:
	if amount <= 0.0 or is_dead():
		return 0.0
	var before := current_hp
	current_hp = maxf(current_hp - amount, 0.0)
	var applied := before - current_hp
	hp_changed.emit(current_hp, max_hp)
	damaged.emit(applied, source)
	if current_hp <= 0.0 and not _dead:
		_dead = true
		died.emit(source)
	return applied


func heal(amount: float) -> float:
	if amount <= 0.0 or is_dead():
		return 0.0
	var before := current_hp
	current_hp = minf(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)
	return current_hp - before


## Simpan rasio HP saat scaling malam berubah.
func set_max_hp_keeping_ratio(value: float) -> void:
	var ratio := get_ratio()
	max_hp = maxf(value, 1.0)
	current_hp = clampf(max_hp * ratio, 1.0, max_hp)
	hp_changed.emit(current_hp, max_hp)


func apply_bleed(dps: float, duration: float, source: Node) -> void:
	if dps <= 0.0 or duration <= 0.0 or is_dead():
		return
	_bleed_dps = dps
	_bleed_remaining = duration
	_bleed_source = source


func is_bleeding() -> bool:
	return _bleed_remaining > 0.0


func tick(delta: float) -> void:
	if delta <= 0.0 or _bleed_remaining <= 0.0 or is_dead():
		return
	var step := minf(delta, _bleed_remaining)
	_bleed_remaining -= step
	take_damage(_bleed_dps * step, _bleed_source)
	if _bleed_remaining <= 0.001:
		_bleed_remaining = 0.0


func _enter_group() -> void:
	var owner_node := get_parent()
	if owner_node != null:
		owner_node.add_to_group(GROUP)

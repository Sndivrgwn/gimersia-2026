class_name StatusEffectsComponent
extends Node

## Efek status berdurasi (Mission 8): saat ini hanya regen HP dari item.
##
## Sumber angka: `ItemEffect.regen_hp_per_second` dan `regen_duration` pada item
## yang dipakai. Durasi memakai waktu game (delta x clock.get_time_scale()),
## jadi berhenti saat time scale 0 (night watch skip dsb.).
##
## Memakai ulang item yang sama MENYEGARKAN durasi (tidak menumpuk). Efek
## berhenti saat durasi habis atau saat pemain mati.

signal effect_started(effect_id: StringName, display_name: String, duration: float)
signal effect_ended(effect_id: StringName)

const INVENTORY_NAME := "InventoryComponent"
const PLAYER_GROUP := &"player"

## Opsional; bila kosong dicari di parent.
@export var stats: StatsComponent
@export var inventory: InventoryComponent
## Opsional; default autoload DayNightManager.
@export var clock: Node
## Opsional; default DeathController di parent pemain.
@export var death_controller: Node

var _effects: Dictionary = {}
var _death_connected: bool = false


func _ready() -> void:
	_bind()


func _process(delta: float) -> void:
	tick(delta)


## Satu tick game; `delta` adalah waktu nyata, diskalakan oleh time scale clock.
func tick(delta: float) -> void:
	if delta <= 0.0 or _effects.is_empty():
		return
	var scale := _time_scale()
	if scale <= 0.0:
		return
	var game_delta := delta * scale
	var finished: Array[StringName] = []
	for id in _effects.keys():
		var effect: Dictionary = _effects[id]
		var rate: float = effect["rate"]
		if rate > 0.0 and _stats() != null:
			_stats().heal(rate * game_delta)
		effect["remaining"] = float(effect["remaining"]) - game_delta
		if float(effect["remaining"]) <= 0.0:
			finished.append(id)
	for id in finished:
		_end(id)


## Mulai/segarkan efek. Id = id item supaya pemakaian ulang tidak menumpuk.
func apply(effect_id: StringName, display_name: String, rate: float, duration: float) -> void:
	if duration <= 0.0:
		return
	var refreshed := _effects.has(effect_id)
	_effects[effect_id] = {
		"rate": rate,
		"remaining": duration,
		"duration": duration,
		"name": display_name,
	}
	if not refreshed:
		effect_started.emit(effect_id, display_name, duration)


func is_active(effect_id: StringName) -> bool:
	return _effects.has(effect_id)


func get_active_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id in _effects.keys():
		result.append(id)
	return result


func get_remaining(effect_id: StringName) -> float:
	if not _effects.has(effect_id):
		return 0.0
	return float(_effects[effect_id]["remaining"])


## Daftar untuk HUD: [{id, name, rate, remaining}].
func get_effects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in _effects.keys():
		var effect: Dictionary = _effects[id]
		result.append({
			"id": id,
			"name": String(effect["name"]),
			"rate": float(effect["rate"]),
			"remaining": float(effect["remaining"]),
		})
	return result


## Hentikan semua efek (mis. kematian).
func clear_all() -> void:
	for id in _effects.keys():
		_end(id)


## Teks satu baris untuk HUD: "Kaldu +1 HP/s 12s".
func format_effect(effect: Dictionary) -> String:
	return "%s +%.0f HP/s %ds" % [
		String(effect["name"]),
		float(effect["rate"]),
		int(ceilf(float(effect["remaining"]))),
	]


# --- Internal ---------------------------------------------------------------

func _bind() -> void:
	if stats == null and get_parent() != null:
		stats = get_parent().get_node_or_null("StatsComponent") as StatsComponent
	if inventory == null and get_parent() != null:
		inventory = get_parent().get_node_or_null(INVENTORY_NAME) as InventoryComponent
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	if inventory != null and not inventory.item_used.is_connected(_on_item_used):
		inventory.item_used.connect(_on_item_used)
	if not _death_connected:
		var death := death_controller
		if death == null and get_parent() != null and get_parent().get_parent() != null:
			death = get_parent().get_parent().get_node_or_null("DeathController")
		if death != null and death.has_signal(&"died"):
			death.died.connect(_on_died)
			_death_connected = true


func _stats() -> StatsComponent:
	if stats == null:
		_bind()
	return stats


func _time_scale() -> float:
	if clock == null:
		_bind()
	if clock == null or not clock.has_method(&"get_time_scale"):
		return 1.0
	return float(clock.call(&"get_time_scale"))


func _on_item_used(item: ItemDefinition, _slot_index: int) -> void:
	if item == null or item.consume_effect == null:
		return
	var effect := item.consume_effect
	if effect.regen_hp_per_second <= 0.0 or effect.regen_duration <= 0.0:
		return
	apply(item.id, item.display_name, effect.regen_hp_per_second, effect.regen_duration)


func _on_died(_respawns_remaining: int) -> void:
	clear_all()


func _end(effect_id: StringName) -> void:
	if not _effects.has(effect_id):
		return
	_effects.erase(effect_id)
	effect_ended.emit(effect_id)

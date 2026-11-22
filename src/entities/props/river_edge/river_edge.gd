class_name RiverEdge
extends Interactable

## Tepi sungai: minum dengan hold-E. +25 Thirst, -8 Hunger, lalu cooldown
## 15 detik nyata per pemain (bukan waktu gameplay: cooldown memakai delta
## proses biasa, jadi tidak terpengaruh time scale DayNightManager).

const HOLD_TIME := 1.5
const THIRST_GAIN := 25.0
const HUNGER_COST := 8.0
const COOLDOWN_SECONDS := 15.0
const PROMPT := "Tahan E: Minum Air Sungai"
const COOLDOWN_FORMAT := "Tunggu %d dtk"

## instance_id interactor -> sisa cooldown (detik).
var _cooldowns: Dictionary = {}


func _ready() -> void:
	VisualSlot.attach(self, &"river_edge", [get_node_or_null("Visual")])


func _process(delta: float) -> void:
	advance_cooldowns(delta)


func get_prompt(_interactor: Node) -> String:
	return PROMPT


func get_hold_time(_interactor: Node) -> float:
	return HOLD_TIME


func can_interact(interactor: Node) -> bool:
	return get_cooldown_remaining(interactor) <= 0.0


func get_block_reason(interactor: Node) -> String:
	var remaining := get_cooldown_remaining(interactor)
	if remaining <= 0.0:
		return ""
	return COOLDOWN_FORMAT % int(ceil(remaining))


func interact(interactor: Node) -> void:
	if interactor == null:
		return
	if get_cooldown_remaining(interactor) > 0.0:
		return
	var needs := _needs_of(interactor)
	if needs == null:
		return

	needs.add(NeedsComponent.Need.THIRST, THIRST_GAIN)
	needs.add(NeedsComponent.Need.HUNGER, -HUNGER_COST)
	_cooldowns[interactor.get_instance_id()] = COOLDOWN_SECONDS


func get_cooldown_remaining(interactor: Node) -> float:
	if interactor == null:
		return 0.0
	return float(_cooldowns.get(interactor.get_instance_id(), 0.0))


## Dipanggil `_process`; publik supaya tes bisa memajukan cooldown.
func advance_cooldowns(delta: float) -> void:
	if _cooldowns.is_empty() or delta <= 0.0:
		return
	for key in _cooldowns.keys():
		var remaining: float = float(_cooldowns[key]) - delta
		if remaining <= 0.0:
			_cooldowns.erase(key)
		else:
			_cooldowns[key] = remaining


func _needs_of(interactor: Node) -> NeedsComponent:
	if interactor == null or not interactor.has_method(&"get_needs"):
		return null
	return interactor.get_needs() as NeedsComponent

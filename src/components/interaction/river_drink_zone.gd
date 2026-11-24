class_name RiverDrinkZone
extends Interactable

## Minum di mana saja di area sungai (bukan hanya di node RiverEdge).
##
## Node ini anak Player dan hanya ikut grup `interactable` selama pemain berada
## di zona RIVER atau masih di tepinya, jadi tidak mengganggu interaksi lain di
## darat. Efek dan cooldown memakai angka yang sama dengan RiverEdge.

const EDGE_MARGIN := 32.0
const PROMPT := "Tahan E: Minum Air Sungai"
const COOLDOWN_FORMAT := "Tunggu %d dtk"

@export var margin: float = EDGE_MARGIN

var _cooldown: float = 0.0
var _active: bool = false


func _ready() -> void:
	# Interactable menambahkan grup saat _enter_tree; seleksi ulang per frame.
	remove_from_group(Interactable.GROUP)
	set_process(true)
	_update_active()


func _process(delta: float) -> void:
	advance_cooldown(delta)
	_update_active()


## Titik dianggap air sungai bila masuk zona RIVER atau masih di tepinya.
static func is_river_water(point: Vector2, edge_margin: float = EDGE_MARGIN) -> bool:
	if IslandZones.zone_at(point) == IslandZones.Zone.RIVER:
		return true
	if absf(point.y) > IslandZones.BEACH_EDGE:
		return false
	return point.x >= IslandZones.RIVER_MIN_X - edge_margin \
		and point.x <= IslandZones.RIVER_MAX_X + edge_margin


func get_prompt(interactor: Node) -> String:
	if RiverEdge.has_empty_waterskin(interactor):
		return RiverEdge.REFILL_PROMPT
	return PROMPT


func get_hold_time(_interactor: Node) -> float:
	return RiverEdge.HOLD_TIME


func can_interact(interactor: Node) -> bool:
	if RiverEdge.has_empty_waterskin(interactor):
		return true
	return _cooldown <= 0.0


func get_block_reason(interactor: Node) -> String:
	if RiverEdge.has_empty_waterskin(interactor):
		return ""
	if _cooldown <= 0.0:
		return ""
	return COOLDOWN_FORMAT % int(ceil(_cooldown))


func interact(interactor: Node) -> void:
	if RiverEdge.refill_waterskin(interactor):
		return
	if _cooldown > 0.0:
		return
	if RiverEdge.apply_drink(interactor):
		_cooldown = RiverEdge.COOLDOWN_SECONDS


## Dipakai tes dan _process.
func advance_cooldown(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(_cooldown - delta, 0.0)


func get_cooldown_remaining() -> float:
	return _cooldown


func is_active() -> bool:
	return _active


func _update_active() -> void:
	var active := is_river_water(global_position, margin)
	if active == _active:
		return
	_active = active
	if active:
		add_to_group(Interactable.GROUP)
	else:
		remove_from_group(Interactable.GROUP)

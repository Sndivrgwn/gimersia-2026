class_name SignalBeacon
extends Interactable

## Signal Beacon di (0, 2100): hold E 1.5 s sambil membawa Suar Darurat pada
## fase rescue (fajar Hari 7) -> Victory (spec §7.8).
##
## Suar DIKONSUMSI saat victory (keputusan owner Mission 7).

signal victory_triggered

const HOLD_TIME := 1.5
const PROMPT := "Tahan E: Nyalakan Suar Darurat"
const BLOCK_NO_RESCUE := "Belum waktunya"
const BLOCK_NO_FLARE := "Butuh Suar Darurat"
const FLARE_ID := &"signal_flare"
const PLAYER_GROUP := &"player"

@export var inventory: InventoryComponent
@export var clock: Node

var _victory_done: bool = false


func _enter_tree() -> void:
	super._enter_tree()
	add_to_group(&"signal_beacon")


func _ready() -> void:
	_bind()


# --- Interactable -----------------------------------------------------------

func get_prompt(_interactor: Node) -> String:
	return PROMPT if is_rescue_active() else ""


func get_hold_time(_interactor: Node) -> float:
	return HOLD_TIME


func can_interact(_interactor: Node) -> bool:
	return is_rescue_active() and has_flare()


func get_block_reason(_interactor: Node) -> String:
	if not is_rescue_active():
		return BLOCK_NO_RESCUE
	if not has_flare():
		return BLOCK_NO_FLARE
	return ""


func interact(interactor: Node) -> void:
	if _victory_done or not can_interact(interactor):
		return
	var bag := inventory
	if bag == null and interactor != null and interactor.has_method(&"get_inventory"):
		bag = interactor.get_inventory() as InventoryComponent
	if bag == null or not bag.remove_item(FLARE_ID, 1):
		return
	_victory_done = true
	victory_triggered.emit()


# --- Read API ---------------------------------------------------------------

func is_rescue_active() -> bool:
	_bind()
	if clock == null:
		return false
	return bool(clock.get("rescue_triggered")) if "rescue_triggered" in clock else false


func has_flare() -> bool:
	_bind()
	return inventory != null and inventory.has_item(FLARE_ID, 1)


# --- Internal ---------------------------------------------------------------

func _bind() -> void:
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	if inventory == null:
		var tree := get_tree()
		if tree != null:
			var player := tree.get_first_node_in_group(PLAYER_GROUP)
			if player != null:
				inventory = player.get_node_or_null("InventoryComponent") as InventoryComponent

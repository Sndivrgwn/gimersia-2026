class_name CampfireRefuel
extends Interactable

## Interactable anak Campfire: hold-E untuk mengisi bahan bakar (2 kayu, +180 s).
##
## Dipisah dari Campfire karena Campfire turunan CampStructure (Node2D, bukan
## Interactable). Prompt dan alasan blokir diteruskan dari Campfire.

const PROMPT := "Tahan E: Isi Ulang Api Unggun (2 Kayu)"
const PROMPT_FUEL := "Tahan E: Isi Bahan Bakar"
const PROMPT_IGNITE := "Tahan E: Gesek Batu"

## Opsional; default = parent Campfire.
@export var campfire: Campfire


func _ready() -> void:
	if campfire == null:
		campfire = get_parent() as Campfire


func get_prompt(_interactor: Node) -> String:
	if campfire == null:
		return PROMPT
	if campfire.needs_ignition():
		return PROMPT_IGNITE
	if campfire.is_cold():
		return PROMPT_FUEL
	return PROMPT


func get_hold_time(_interactor: Node) -> float:
	if campfire == null:
		return 0.5
	return campfire.get_refuel_hold_time()


func can_interact(interactor: Node) -> bool:
	if campfire == null:
		return false
	if campfire.needs_ignition():
		return campfire.get_ignite_block_reason(interactor).is_empty()
	return campfire.can_refuel(interactor)


func get_block_reason(interactor: Node) -> String:
	if campfire == null:
		return ""
	if campfire.needs_ignition():
		return campfire.get_ignite_block_reason(interactor)
	return campfire.get_refuel_block_reason(interactor)


func interact(interactor: Node) -> void:
	if campfire == null:
		return
	if campfire.needs_ignition():
		campfire.request_ignition(interactor)
		return
	campfire.refuel(interactor)

class_name CampfireRefuel
extends Interactable

## Interactable anak Campfire: hold-E untuk mengisi bahan bakar (2 kayu, +180 s).
##
## Dipisah dari Campfire karena Campfire turunan CampStructure (Node2D, bukan
## Interactable). Prompt dan alasan blokir diteruskan dari Campfire.

const PROMPT := "Tahan E: Isi Ulang Api Unggun (2 Kayu)"

## Opsional; default = parent Campfire.
@export var campfire: Campfire


func _ready() -> void:
	if campfire == null:
		campfire = get_parent() as Campfire


func get_prompt(_interactor: Node) -> String:
	return PROMPT


func get_hold_time(_interactor: Node) -> float:
	if campfire == null:
		return 0.5
	return campfire.get_refuel_hold_time()


func can_interact(interactor: Node) -> bool:
	return campfire != null and campfire.can_refuel(interactor)


func get_block_reason(interactor: Node) -> String:
	if campfire == null:
		return ""
	return campfire.get_refuel_block_reason(interactor)


func interact(interactor: Node) -> void:
	if campfire != null:
		campfire.refuel(interactor)

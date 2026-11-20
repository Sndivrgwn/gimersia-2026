class_name ChestInteract
extends Interactable

## Interactable anak Peti: menampilkan prompt "Peti (24 slot)".
## Panel penyimpanan belum ada; interact() hanya meneruskan ke Chest.

@export var chest: Chest


func _ready() -> void:
	if chest == null:
		chest = get_parent() as Chest


func get_prompt(interactor: Node) -> String:
	if chest == null:
		return ""
	return chest.get_prompt(interactor)


func get_hold_time(_interactor: Node) -> float:
	return 0.0


func can_interact(_interactor: Node) -> bool:
	return chest != null


func get_block_reason(_interactor: Node) -> String:
	return "" if chest != null else "Peti rusak"


func interact(interactor: Node) -> void:
	if chest != null:
		chest.on_interacted(interactor)

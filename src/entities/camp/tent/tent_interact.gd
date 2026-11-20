class_name TentInteract
extends Interactable

## Interactable anak Tenda: tidur (siang) atau Jaga Malam (malam).
## Semua keputusan ada di Tent; node ini hanya meneruskan.

@export var tent: Tent


func _ready() -> void:
	if tent == null:
		tent = get_parent() as Tent


func get_prompt(interactor: Node) -> String:
	return "" if tent == null else tent.get_prompt(interactor)


func get_hold_time(interactor: Node) -> float:
	return 0.0 if tent == null else tent.get_hold_time(interactor)


func can_interact(interactor: Node) -> bool:
	return tent != null and tent.get_block_reason(interactor).is_empty()


func get_block_reason(interactor: Node) -> String:
	return "" if tent == null else tent.get_block_reason(interactor)


func interact(interactor: Node) -> void:
	if tent != null:
		tent.perform_action(interactor)

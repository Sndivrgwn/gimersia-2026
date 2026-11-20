class_name Chest
extends CampStructure

## Peti camp: 24 slot penyimpanan.
##
## Phase ini hanya menampilkan prompt "Peti (24 slot)"; panel UI-nya tugas
## stretch. Saat peti hancur, seluruh isinya dijatuhkan sebagai ItemPickup di
## posisinya.

signal interaction_requested(interactor: Node)

const CHEST_PROMPT := "Peti (24 slot)"
const COMPONENT_NAME := "ChestComponent"
const PICKUP_SCENE: PackedScene = preload("res://src/entities/props/item_pickup.tscn")


func _ready() -> void:
	super()
	destroyed.connect(_drop_contents)


func get_component() -> ChestComponent:
	return get_node_or_null(COMPONENT_NAME) as ChestComponent


func get_prompt(_interactor: Node) -> String:
	return CHEST_PROMPT


## Dipanggil Interactable anak. Panel peti menyusul (stretch).
func on_interacted(interactor: Node) -> void:
	interaction_requested.emit(interactor)


func _drop_contents() -> void:
	var component := get_component()
	if component == null:
		return
	var parent := get_parent()
	if parent == null:
		push_warning("Chest: tidak ada parent untuk menjatuhkan isi peti.")
		return

	for stack in component.get_slots():
		if stack == null or stack.is_empty():
			continue
		var pickup := PICKUP_SCENE.instantiate()
		pickup.item = stack.item
		pickup.count = stack.count
		parent.add_child(pickup)
		if pickup is Node2D:
			(pickup as Node2D).global_position = global_position
	component.clear()

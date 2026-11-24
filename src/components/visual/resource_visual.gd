class_name ResourceVisual
extends VisualDriver

## Driver animasi node resource: full / depleted.


func step(_delta: float) -> void:
	if owner_node == null or not owner_node.has_method(&"is_depleted"):
		return
	push(VisualStateMap.resource_state(bool(owner_node.call(&"is_depleted"))))

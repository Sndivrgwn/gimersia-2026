class_name CampfireVisual
extends VisualDriver

## Driver animasi api unggun: lit / ember / cold.


func step(_delta: float) -> void:
	if owner_node == null:
		return
	var lit := bool(owner_node.call(&"is_lit")) if owner_node.has_method(&"is_lit") else false
	var cold := bool(owner_node.call(&"is_cold")) if owner_node.has_method(&"is_cold") else false
	push(VisualStateMap.campfire_state(lit, cold))

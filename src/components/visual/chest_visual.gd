class_name ChestVisual
extends VisualDriver

## Driver animasi peti: open selama panel peti untuk peti ini terbuka.


func step(_delta: float) -> void:
	push(VisualStateMap.chest_state(_is_panel_open_for_owner()))


func _is_panel_open_for_owner() -> bool:
	var tree := get_tree()
	if tree == null or owner_node == null:
		return false
	var panel := tree.root.find_child("ChestPanel", true, false)
	if panel == null:
		return false
	if panel.has_method(&"is_open") and not bool(panel.call(&"is_open")):
		return false
	if not ("chest" in panel):
		return false
	var chest := panel.get("chest") as Node
	return chest == owner_node

class_name FaunaVisual
extends VisualDriver

## Driver animasi fauna: memetakan enum state ke nama animasi.
## Temperament hanya dipakai debug (label), tidak mengubah animasi.


func step(_delta: float) -> void:
	if owner_node == null:
		return
	var value := 0
	if owner_node.has_method(&"get_state"):
		value = int(owner_node.call(&"get_state"))
	var moving := owner_velocity().length_squared() > 1.0
	var state := VisualStateMap.fauna_state(String(slot.key), value, moving)
	push(state, owner_facing(_last_dir))

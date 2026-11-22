class_name BeaconVisual
extends VisualDriver

## Driver animasi beacon: active setelah fase rescue aktif.


func step(_delta: float) -> void:
	if owner_node == null or not owner_node.has_method(&"is_rescue_active"):
		return
	push(VisualStateMap.beacon_state(bool(owner_node.call(&"is_rescue_active"))))

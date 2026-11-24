class_name StationInteractable
extends Interactable

## Mission 10 Phase 2: jembatan E -> panel stasiun tanpa mengubah CampStructure.
## StationInteractable adalah Interactable biasa (grup & kontrak hold-E), jadi
## InteractorComponent tidak perlu tahu apa-apa soal stasiun.

@export var station: Node


func get_prompt(_interactor: Node) -> String:
	if station == null or not is_instance_valid(station):
		return ""
	if station.has_method(&"get_interaction_prompt"):
		return String(station.call(&"get_interaction_prompt"))
	return ""


## 0 = sekali tekan E, panel langsung terbuka.
func get_hold_time(_interactor: Node) -> float:
	return 0.0


func can_interact(_interactor: Node) -> bool:
	return not get_prompt(null).is_empty()


func interact(interactor: Node) -> void:
	if station != null and is_instance_valid(station) and station.has_method(&"request_station_panel"):
		station.call(&"request_station_panel", interactor)

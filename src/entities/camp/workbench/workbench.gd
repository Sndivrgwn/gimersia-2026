class_name Workbench
extends CampStructure

## Workbench: stasiun crafting WORKBENCH yang selalu aktif selama berdiri.

const STATION_GROUP := &"crafting_station"
const STATION_TYPE := RecipeDefinition.Station.WORKBENCH


func _enter_tree() -> void:
	super()
	add_to_group(STATION_GROUP)


## `station_type` dibaca CraftingComponent lewat properti dinamis.
var station_type: int = STATION_TYPE


func is_station_active() -> bool:
	return true

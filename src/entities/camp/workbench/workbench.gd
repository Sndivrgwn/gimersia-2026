class_name Workbench
extends CampStructure

## Workbench: stasiun crafting WORKBENCH yang selalu aktif selama berdiri.

signal interaction_requested(station: Node, interactor: Node)

const STATION_GROUP := &"crafting_station"
const STATION_TYPE := RecipeDefinition.Station.WORKBENCH
const PROMPT := "E: Meja Kerja"


func _enter_tree() -> void:
	super()
	add_to_group(STATION_GROUP)


## `station_type` dibaca CraftingComponent lewat properti dinamis.
var station_type: int = STATION_TYPE


func is_station_active() -> bool:
	return true


func get_interaction_prompt() -> String:
	return PROMPT


func request_station_panel(interactor: Node) -> void:
	interaction_requested.emit(self, interactor)


func _ready() -> void:
	super()
	var link := StationInteractable.new()
	link.name = "StationInteractable"
	link.station = self
	add_child(link)
	VisualSlot.attach(
		self,
		&"workbench",
		[get_node_or_null("Top"), get_node_or_null("LegLeft"), get_node_or_null("LegRight")]
	)

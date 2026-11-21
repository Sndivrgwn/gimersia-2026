class_name BaseHUD
extends CanvasLayer

## Hint lokasi base (read-only). Tersembunyi setelah base ditentukan.

const HINT := "Tekan B untuk menentukan lokasi base"
const PREVIEW_OFFER := "B: pasang - Esc: batal"

@export var anchor: CampAnchor
@export var placement: BasePlacementController

var _label: Label
var _text: String = ""


func _ready() -> void:
	layer = 22
	_build()
	refresh()


func _process(_delta: float) -> void:
	refresh()


func get_text() -> String:
	return _text


func is_showing() -> bool:
	return _label != null and _label.visible


func refresh() -> void:
	if anchor == null:
		anchor = CampAnchor.find_anchor(self)
	if placement == null:
		placement = _find_placement()
	var founded := anchor != null and anchor.is_founded()
	var preview := placement != null and placement.is_preview_active()
	if founded and not preview:
		_set_text("")
		return
	if preview:
		var reason := String(placement.get_result().get("reason", ""))
		_set_text("%s\n%s" % [reason, PREVIEW_OFFER] if not reason.is_empty() else PREVIEW_OFFER)
		return
	_set_text(HINT)


func _find_placement() -> BasePlacementController:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(BasePlacementController.GROUP) as BasePlacementController


func _build() -> void:
	_label = Label.new()
	_label.name = "Hint"
	_label.add_theme_font_size_override("font_size", 13)
	_label.position = Vector2(12.0, 8.0)
	add_child(_label)


func _set_text(value: String) -> void:
	_text = value
	if _label == null:
		return
	_label.text = value
	_label.visible = not value.is_empty()

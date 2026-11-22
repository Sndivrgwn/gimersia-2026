class_name AssetDebug
extends Node

## Node debug aset (hanya island.tscn, nonaktif secara default).
##
## Tombol: F1 = muat ulang semua art tanpa restart, Home = tampilkan kotak slot
## + pivot + toast cakupan. Keduanya didaftarkan lewat InputSetup.

const SLOT_GROUP := &"visual_slot"
const TOAST_TIME := 3.0

var _boxes_visible: bool = false
var _overlay: Node2D
var _toast: Label
var _toast_time: float = 0.0


func _ready() -> void:
	InputSetup.ensure_actions()
	var layer := CanvasLayer.new()
	layer.name = "AssetDebugLayer"
	layer.layer = 40
	add_child(layer)
	_toast = Label.new()
	_toast.name = "Toast"
	_toast.position = Vector2(12.0, 12.0)
	_toast.visible = false
	layer.add_child(_toast)

	_overlay = Node2D.new()
	_overlay.name = "SlotBoxes"
	_overlay.z_index = 50
	_overlay.visible = false
	_overlay.draw.connect(_draw_boxes)
	add_child(_overlay)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(InputSetup.DEBUG_RELOAD_ASSETS):
		reload_assets()
	if Input.is_action_just_pressed(InputSetup.DEBUG_ASSET_BOXES):
		toggle_boxes()
	if _toast_time > 0.0:
		_toast_time = maxf(_toast_time - delta, 0.0)
		if _toast_time <= 0.0:
			_toast.visible = false


func reload_assets() -> void:
	Assets.reload_assets()
	UiSkin.reset()
	for node in get_tree().get_nodes_in_group(SLOT_GROUP):
		if node is VisualSlot:
			(node as VisualSlot).refresh()
	show_toast()


func toggle_boxes() -> void:
	_boxes_visible = not _boxes_visible
	_overlay.visible = _boxes_visible
	if _boxes_visible:
		show_toast()


func is_boxes_visible() -> bool:
	return _boxes_visible


func show_toast() -> void:
	var coverage := Assets.coverage()
	_toast.text = "Aset: %d/%d terisi" % [coverage["filled"], coverage["total"]]
	_toast.visible = true
	_toast_time = TOAST_TIME


func get_toast_text() -> String:
	return _toast.text if _toast != null else ""


func _draw_boxes() -> void:
	_overlay.queue_redraw()
	var registry := Assets.registry()
	for node in get_tree().get_nodes_in_group(SLOT_GROUP):
		var slot := node as VisualSlot
		if slot == null:
			continue
		var definition := registry.get_slot(slot.key)
		if definition == null:
			continue
		var size := definition.display_size
		var origin := slot.global_position
		var rect := Rect2(origin - size * 0.5, size)
		if definition.pivot == AssetSlotDefinition.Pivot.BOTTOM_CENTER:
			rect = Rect2(origin - Vector2(size.x * 0.5, size.y), size)
		_overlay.draw_rect(rect, Color(0.2, 0.9, 1.0, 0.6), false, 1.0)
		_overlay.draw_circle(origin, 2.0, Color(1.0, 0.4, 0.3, 0.9))

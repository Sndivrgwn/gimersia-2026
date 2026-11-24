class_name PlaceholderLabels
extends Control

## Mission 9: selama art masih kosong, pemain perlu tahu bentuk polos itu apa.
## Satu overlay HUD dengan kolam label kecil menampilkan nama slot di dekat
## pemain (maksimal `MAX_LABELS`, hanya untuk slot yang belum punya art).
##
## Sengaja TIDAK satu Label per VisualSlot: 150+ Control per frame membuat soak
## 7 hari jauh lebih lambat. Pemindaian dilakukan tiap `SCAN_INTERVAL` saja dan
## memakai ulang label yang sama.

const SCAN_INTERVAL := 0.25
const RANGE := 240.0
const MAX_LABELS := 12
const SLOT_GROUP := &"visual_slot"
const PLAYER_GROUP := &"player"
const SKIP_PREFIX := "ground_"
const LABEL_COLOR := Color(0.92, 0.95, 0.92, 0.8)
const FONT_SIZE := 9

@export var player: Node2D
## Bisa dimatikan (mis. di build final) tanpa mengubah visual apa pun.
@export var enabled: bool = true

var _labels: Array[Label] = []
var _timer: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for index in MAX_LABELS:
		var label := Label.new()
		label.name = "SlotLabel%d" % index
		label.add_theme_font_size_override("font_size", FONT_SIZE)
		label.add_theme_color_override("font_color", LABEL_COLOR)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.visible = false
		add_child(label)
		_labels.append(label)


func _process(delta: float) -> void:
	if not enabled:
		return
	_timer += delta
	if _timer < SCAN_INTERVAL:
		return
	_timer = 0.0
	refresh()


## Perbarui label dari posisi pemain saat ini. Dipanggil `_process` dan tes.
func refresh() -> void:
	var origin = _player_position()
	var shown := 0
	if enabled and origin != null:
		var slots := _nearby_slots(origin)
		slots.sort_custom(func(a: Node2D, b: Node2D) -> bool:
			return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin)
		)
		var transform: Transform2D = Transform2D.IDENTITY
		var viewport := get_viewport() if is_inside_tree() else null
		if viewport != null:
			transform = viewport.get_canvas_transform()
		for node in slots:
			if shown >= _labels.size():
				break
			var slot := node as VisualSlot
			var label := _labels[shown]
			label.text = String(slot.key)
			label.position = transform * slot.global_position + Vector2(-24.0, 10.0)
			label.size = Vector2(64.0, 12.0)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.visible = true
			shown += 1
	for index in range(shown, _labels.size()):
		_labels[index].visible = false


func get_visible_texts() -> PackedStringArray:
	var texts := PackedStringArray()
	for label in _labels:
		if label.visible:
			texts.append(label.text)
	return texts


func get_visible_count() -> int:
	var count := 0
	for label in _labels:
		if label.visible:
			count += 1
	return count


func _nearby_slots(origin: Vector2) -> Array[Node2D]:
	var result: Array[Node2D] = []
	var tree := get_tree()
	if tree == null:
		return result
	for node in tree.get_nodes_in_group(SLOT_GROUP):
		var slot := node as VisualSlot
		if slot == null or not is_instance_valid(slot) or not slot.is_inside_tree():
			continue
		if slot.is_showing_art():
			continue
		if String(slot.key).is_empty() or String(slot.key).begins_with(SKIP_PREFIX):
			continue
		if not slot.is_visible_in_tree():
			continue
		if slot.global_position.distance_to(origin) > RANGE:
			continue
		result.append(slot)
	return result


func _player_position() -> Variant:
	if player == null or not is_instance_valid(player):
		var tree := get_tree()
		if tree == null:
			return null
		player = tree.get_first_node_in_group(PLAYER_GROUP) as Node2D
	if player == null or not is_instance_valid(player):
		return null
	return player.global_position

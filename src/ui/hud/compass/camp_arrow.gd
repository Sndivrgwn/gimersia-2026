extends CanvasLayer

## Mission 9 polish / Fase 2A: penunjuk arah base saat pemain jauh dari camp.
## Hanya membaca posisi; tidak mengubah state gameplay.
## Label di-anchor ke pojok kanan-atas viewport, bukan piksel tetap.
##
## Fase 2A: pusat base dibaca dari `CampAnchor.get_center()`. Sebelumnya node
## `CampAnchor` di-cast ke `Node2D` (padahal ia `Node` bertipe `class_name`
## CampAnchor), jadi panah tidak pernah muncul. Jarak tampil kini dari
## `compass_config.tres`.

const PLAYER_GROUP := &"player"
const CONFIG_PATH := "res://src/data/configs/compass_config.tres"
const FORMAT := "%s Base %d px"
const MARGIN := 16

@export var config: CompassConfig

var _label: Label
var _player: Node2D
var _anchor: Node


func _ready() -> void:
	layer = 13
	process_mode = Node.PROCESS_MODE_ALWAYS
	if config == null:
		config = load(CONFIG_PATH) as CompassConfig
	_build()
	refresh()


func _process(_delta: float) -> void:
	refresh()


## Dipakai tes dan _process: hitung ulang teks/visibilitas.
func refresh() -> void:
	if _label == null:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(PLAYER_GROUP) as Node2D
	if _anchor == null or not is_instance_valid(_anchor):
		_anchor = find_anchor()
	var center := get_anchor_center()
	if _player == null or _anchor == null or not _is_anchor_ready():
		_label.visible = false
		return
	var to_anchor := center - _player.global_position
	var distance := to_anchor.length()
	_label.visible = distance > get_show_distance()
	if not _label.visible:
		return
	_label.text = FORMAT % [Dir4.glyph(to_anchor), int(round(distance))]


## Dipakai tes: teks penunjuk saat ini (kosong bila disembunyikan).
func get_text() -> String:
	if _label == null or not _label.visible:
		return ""
	return _label.text


func get_label() -> Label:
	return _label


func is_showing() -> bool:
	return _label != null and _label.visible


func get_show_distance() -> float:
	return 340.0 if config == null else config.camp_arrow_distance


## Panah hanya berguna setelah base ditentukan (sebelum itu BaseHUD yang
## memandu menekan B).
func _is_anchor_ready() -> bool:
	if _anchor == null:
		return false
	if _anchor.has_method(&"is_founded"):
		return bool(_anchor.call(&"is_founded"))
	return true


func get_anchor_center() -> Vector2:
	if _anchor == null:
		return Vector2.ZERO
	if _anchor.has_method(&"get_center"):
		var center: Vector2 = _anchor.call(&"get_center")
		return center
	var node2d := _anchor as Node2D
	return node2d.global_position if node2d != null else Vector2.ZERO


func find_anchor() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var found := tree.get_first_node_in_group(CampAnchor.GROUP)
	if found != null:
		return found
	var scene := tree.current_scene
	if scene == null:
		return null
	return scene.find_child("CampAnchor", true, false)


func _build() -> void:
	_label = Label.new()
	_label.name = "CampArrow"
	_label.visible = false
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0, 0.9))
	_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, MARGIN)
	_label.offset_top = 88.0
	_label.offset_left = -216.0
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(_label)


func _glyph(direction: Vector2) -> String:
	return Dir4.glyph(direction)

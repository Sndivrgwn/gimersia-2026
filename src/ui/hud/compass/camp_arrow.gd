extends CanvasLayer

## Mission 9 polish: penunjuk arah base/camp saat pemain jauh dari camp.
## Hanya membaca posisi; tidak mengubah state gameplay.
## Label di-anchor ke pojok kanan-atas viewport, bukan piksel tetap.

const PLAYER_GROUP := &"player"
const SHOW_DISTANCE := 340.0
const FORMAT := "%s Base %d px"
const MARGIN := 16

var _label: Label
var _player: Node2D
var _anchor: Node2D


func _ready() -> void:
	layer = 13
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group(PLAYER_GROUP) as Node2D
	if _anchor == null:
		_anchor = find_anchor()
	if _player == null or _anchor == null:
		_label.visible = false
		return
	var offset := _anchor.global_position - _player.global_position
	var distance := offset.length()
	_label.visible = distance > SHOW_DISTANCE
	if not _label.visible:
		return
	_label.text = FORMAT % [_glyph(offset), int(round(distance))]


## Dipakai tes: teks penunjuk saat ini (kosong bila disembunyikan).
func get_text() -> String:
	if _label == null or not _label.visible:
		return ""
	return _label.text


func get_label() -> Label:
	return _label


func find_anchor() -> Node2D:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.find_child("CampAnchor", true, false) as Node2D


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
	if direction == Vector2.ZERO:
		return "↑"
	var angle := direction.angle()
	if angle >= -PI / 4.0 and angle < PI / 4.0:
		return "→"
	if angle >= PI / 4.0 and angle < 3.0 * PI / 4.0:
		return "↓"
	if angle >= -3.0 * PI / 4.0 and angle < -PI / 4.0:
		return "↑"
	return "←"

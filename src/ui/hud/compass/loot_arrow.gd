extends CanvasLayer

## Fase 2B: penanda arah ke tas jatuh (LootBag) setelah pemain mati.
##
## Read-only. Tas dibaca dari grup `loot_bag` (LootBag mendaftar sendiri dan
## bebas saat kosong), jadi penanda hilang otomatis begitu tas diambil. Pola
## sama dengan panah base: glyph arah + jarak, di pojok kanan-atas di bawah
## panah base.

const PLAYER_GROUP := &"player"
const LOOT_GROUP := &"loot_bag"
const CONFIG_PATH := "res://src/data/configs/compass_config.tres"
const FORMAT := "%s Tas %d px"
const MARGIN := 16

@export var config: CompassConfig

var _label: Label
var _player: Node2D


func _ready() -> void:
	layer = 13
	process_mode = Node.PROCESS_MODE_ALWAYS
	if config == null:
		config = load(CONFIG_PATH) as CompassConfig
	_build()
	refresh()


func _process(_delta: float) -> void:
	refresh()


## Dipakai tes dan _process: cari tas terdekat, perbarui teks/visibilitas.
func refresh() -> void:
	if _label == null:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(PLAYER_GROUP) as Node2D
	var bag := find_nearest_bag()
	if _player == null or bag == null:
		_label.visible = false
		return
	var to_bag := bag.global_position - _player.global_position
	var distance := to_bag.length()
	_label.visible = distance > get_hide_distance()
	if not _label.visible:
		return
	_label.text = FORMAT % [_glyph(to_bag), int(round(distance))]


func get_text() -> String:
	if _label == null or not _label.visible:
		return ""
	return _label.text


func get_label() -> Label:
	return _label


func is_showing() -> bool:
	return _label != null and _label.visible


func get_hide_distance() -> float:
	return 40.0 if config == null else config.loot_arrow_distance


## Tas terdekat yang masih ada; null bila tidak ada tas di dunia.
func find_nearest_bag() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var best: Node2D = null
	var best_distance := INF
	for node in tree.get_nodes_in_group(LOOT_GROUP):
		var bag := node as Node2D
		if bag == null or not is_instance_valid(bag) or bag.is_queued_for_deletion():
			continue
		var distance := 0.0
		if _player != null and is_instance_valid(_player):
			distance = _player.global_position.distance_to(bag.global_position)
		if distance < best_distance:
			best = bag
			best_distance = distance
	return best


func _build() -> void:
	_label = Label.new()
	_label.name = "LootArrow"
	_label.visible = false
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55, 0.95))
	_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, MARGIN)
	_label.offset_top = 112.0
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

class_name StatusEffectHUD
extends CanvasLayer

## Daftar efek status aktif (read-only) di kiri bawah layar.
## Tanpa efek, HUD tidak menampilkan apa pun.

const PLAYER_GROUP := &"player"
const COMPONENT_NAME := "StatusEffectsComponent"
const REFRESH_INTERVAL := 0.25

var _component: StatusEffectsComponent
var _label: Label
var _timer: float = 0.0


func _ready() -> void:
	layer = 15
	_build()
	_bind()


func _process(delta: float) -> void:
	_timer += delta
	if _timer < REFRESH_INTERVAL:
		return
	_timer = 0.0
	refresh()


func refresh() -> void:
	if _label == null:
		return
	if _component == null:
		_bind()
	if _component == null:
		_label.text = ""
		return
	var lines := PackedStringArray()
	for effect in _component.get_effects():
		lines.append(_component.format_effect(effect))
	_label.text = "\n".join(lines)


func get_text() -> String:
	return _label.text if _label != null else ""


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_label = Label.new()
	_label.name = "Effects"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.14, 0.09, 0.05, 0.95))
	_label.add_theme_constant_override("outline_size", 3)
	root.add_child(_label)
	_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_label.position = Vector2(20.0, -84.0)


func _bind() -> void:
	if _component != null:
		return
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group(PLAYER_GROUP)
	if player == null:
		return
	_component = player.get_node_or_null(COMPONENT_NAME) as StatusEffectsComponent

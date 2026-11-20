class_name FloatingText
extends Node2D

## Teks melayang singkat (damage, "DODGE!"). Label dibuat di kode.

const SCENE: PackedScene = preload("res://src/ui/feedback/floating_text.tscn")
const RISE_SPEED := 34.0

@export var lifetime: float = 0.8
@export var rise_speed: float = RISE_SPEED

var text: String = ""
var color: Color = Color(1.0, 1.0, 1.0, 1.0)

var _elapsed: float = 0.0
var _label: Label


## Spawn sekali pakai di parent (biasanya current_scene).
static func spawn(parent: Node, world_position: Vector2, message: String, tint: Color, life: float = 0.8) -> FloatingText:
	if parent == null:
		return null
	var node := SCENE.instantiate() as FloatingText
	if node == null:
		return null
	node.text = message
	node.color = tint
	node.lifetime = maxf(life, 0.05)
	parent.add_child(node)
	node.global_position = world_position
	return node


func _ready() -> void:
	_label = Label.new()
	_label.text = text
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", color)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(80.0, 16.0)
	_label.position = Vector2(-40.0, -8.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _process(delta: float) -> void:
	_elapsed += delta
	position.y -= rise_speed * delta
	if _label != null:
		_label.modulate.a = clampf(1.0 - _elapsed / maxf(lifetime, 0.05), 0.0, 1.0)
	if _elapsed >= lifetime:
		queue_free()


func get_label() -> Label:
	return _label

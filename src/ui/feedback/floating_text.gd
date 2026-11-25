class_name FloatingText
extends Node2D

## Teks melayang dengan latar panel NinePatchRect dan ikon status dari UI kit.

enum FeedbackType {
	AUTO,
	NEUTRAL,
	HEALTH,
	HUNGER,
	HYDRATION,
	STAMINA,
	DANGER,
}

const SCENE: PackedScene = preload("res://src/ui/feedback/floating_text.tscn")
const RISE_SPEED := 34.0

const PANEL_CREAM: Texture2D = preload("res://assets/textures/ui/02_panel/panel_cream_plain.png")
const PANEL_WALNUT: Texture2D = preload("res://assets/textures/ui/02_panel/panel_walnut_stitched.png")

const ICONS := {
	FeedbackType.HEALTH: preload("res://assets/textures/ui/07_icon/icon_health.png"),
	FeedbackType.HUNGER: preload("res://assets/textures/ui/07_icon/icon_hunger.png"),
	FeedbackType.HYDRATION: preload("res://assets/textures/ui/07_icon/icon_hydration.png"),
	FeedbackType.STAMINA: preload("res://assets/textures/ui/07_icon/icon_stamina.png"),
}

# Warna standar berdasarkan palet res://assets/textures/ui/01_palette/
const COLOR_INK_STROKE := Color("#3E271A")
const COLOR_IVORY_HIGHLIGHT := Color("#FFFDF9")
const COLOR_SAGE_SUCCESS := Color("#A3C985")
const COLOR_HONEY_WARNING := Color("#EBC273")
const COLOR_CORAL_DANGER := Color("#E58A73")
const COLOR_SKY_INFO := Color("#96C2D4")

@export var lifetime: float = 0.8
@export var rise_speed: float = RISE_SPEED

var text: String = ""
var color: Color = COLOR_INK_STROKE
var feedback_type: FeedbackType = FeedbackType.AUTO

var _elapsed: float = 0.0

@onready var _panel: NinePatchRect = $PanelPatch
@onready var _margin: MarginContainer = $PanelPatch/ContentMargin
@onready var _icon: TextureRect = $PanelPatch/ContentMargin/HBox/Icon
@onready var _label: Label = $PanelPatch/ContentMargin/HBox/Label


## Spawn sekali pakai di parent (biasanya current_scene).
## Kompatibel penuh dengan pemanggilan lama sekaligus mendukung FeedbackType & ikon.
static func spawn(
	parent: Node,
	world_position: Vector2,
	message: String,
	tint: Color = COLOR_INK_STROKE,
	life: float = 0.8,
	type: FeedbackType = FeedbackType.AUTO
) -> FloatingText:
	if parent == null:
		return null
	var node := SCENE.instantiate() as FloatingText
	if node == null:
		return null
	node.text = message
	node.color = tint
	node.lifetime = maxf(life, 0.05)
	node.feedback_type = type
	parent.add_child(node)
	node.global_position = world_position
	return node


func _ready() -> void:
	_apply_visual_style()
	_update_panel_layout()


func _apply_visual_style() -> void:
	_label.text = text
	_label.add_theme_font_size_override("font_size", 12)

	var resolved_type := _resolve_feedback_type()
	var use_dark_panel := (resolved_type == FeedbackType.DANGER)

	_panel.texture = PANEL_WALNUT if use_dark_panel else PANEL_CREAM

	if ICONS.has(resolved_type):
		_icon.texture = ICONS[resolved_type]
		_icon.visible = true
	else:
		_icon.texture = null
		_icon.visible = false

	var final_text_color := _resolve_text_color(resolved_type, use_dark_panel)
	_label.add_theme_color_override("font_color", final_text_color)


func _resolve_feedback_type() -> FeedbackType:
	if feedback_type != FeedbackType.AUTO:
		return feedback_type
	# Deteksi otomatis jika pemanggil lama hanya mengirim tint merah/coral untuk damage
	if color.r > 0.75 and color.g < 0.55 and color.b < 0.55:
		return FeedbackType.DANGER
	return FeedbackType.NEUTRAL


func _resolve_text_color(resolved_type: FeedbackType, use_dark_panel: bool) -> Color:
	match resolved_type:
		FeedbackType.DANGER:
			return COLOR_CORAL_DANGER if color == Color.WHITE else COLOR_IVORY_HIGHLIGHT
		FeedbackType.HEALTH:
			return Color("#3F6B2C")
		FeedbackType.HUNGER:
			return Color("#8C5A14")
		FeedbackType.HYDRATION:
			return Color("#2A647D")
		FeedbackType.STAMINA:
			return Color("#476930")
		_:
			# Jika pemanggil memakai warna default putih, ganti ke ink_stroke agar terbaca di panel krem
			if color == Color.WHITE and not use_dark_panel:
				return COLOR_INK_STROKE
			return color


func _update_panel_layout() -> void:
	# Hitung ukuran minimum container agar NinePatchRect membungkus teks & ikon secara pas
	var min_size := _margin.get_combined_minimum_size()
	_panel.size = min_size
	_panel.position = Vector2(-min_size.x * 0.5, -min_size.y * 0.5)


func _process(delta: float) -> void:
	_elapsed += delta
	position.y -= rise_speed * delta
	modulate.a = clampf(1.0 - _elapsed / maxf(lifetime, 0.05), 0.0, 1.0)
	if _elapsed >= lifetime:
		queue_free()


func get_label() -> Label:
	return _label

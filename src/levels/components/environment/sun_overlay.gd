class_name SunOverlay
extends CanvasLayer

## Arah matahari sebagai gradien hangat aditif di layar.
##
## Layer 1 (di atas dunia, di bawah HUD). Intensitas mengikuti kegelapan dari
## DayNightVisual: nol saat malam penuh, paling hangat saat matahari rendah
## (fajar/senja), lebih netral saat matahari tinggi. Tekstur gradien dibuat
## saat runtime (tidak ada biner di repo).

const LAYER := 1
const TEXTURE_SIZE := 128
const MAX_ALPHA := 0.16
const MIN_ALPHA := 0.05
const LOW_SUN_COLOR := Color(1.0, 0.78, 0.55, 1.0)
const HIGH_SUN_COLOR := Color(1.0, 0.95, 0.85, 1.0)

var _rect: TextureRect
var _texture: GradientTexture2D


func _ready() -> void:
	layer = LAYER
	_build()
	hide_sun()


func apply(day_progress: float, darkness: float) -> void:
	if _rect == null or _texture == null:
		return
	var daylight := clampf(1.0 - darkness, 0.0, 1.0)
	if daylight <= 0.001:
		hide_sun()
		return

	var direction := DayLightCurve.sun_direction(day_progress)
	var elevation := sin(PI * clampf(day_progress, 0.0, 1.0))
	var center := Vector2(0.5, 0.5)
	_texture.fill_from = center - direction * 0.5
	_texture.fill_to = center + direction * 0.5

	var color := LOW_SUN_COLOR.lerp(HIGH_SUN_COLOR, elevation)
	var alpha := daylight * lerpf(MAX_ALPHA, MIN_ALPHA, elevation)
	_rect.modulate = Color(color.r, color.g, color.b, alpha)
	visible = true


func hide_sun() -> void:
	visible = false


## Dipakai tes: alpha gradien saat ini.
func get_alpha() -> float:
	if _rect == null or not visible:
		return 0.0
	return _rect.modulate.a


func _build() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.85),
		Color(1.0, 1.0, 1.0, 0.25),
		Color(1.0, 1.0, 1.0, 0.0),
	])

	_texture = GradientTexture2D.new()
	_texture.gradient = gradient
	_texture.fill = GradientTexture2D.FILL_LINEAR
	_texture.width = TEXTURE_SIZE
	_texture.height = TEXTURE_SIZE
	_texture.fill_from = Vector2(0.0, 0.5)
	_texture.fill_to = Vector2(1.0, 0.5)

	_rect = TextureRect.new()
	_rect.name = "Gradient"
	_rect.texture = _texture
	_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_rect.material = material
	add_child(_rect)

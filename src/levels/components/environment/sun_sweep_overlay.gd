class_name SunSweepOverlay
extends CanvasLayer

## Mission 13: overlay multiply layar penuh untuk sapuan fajar/senja.
##
## Layer 2: di atas dunia dan gradien matahari (SunOverlay layer 1), di bawah
## semua HUD (layer 10+). Overlay ini TIDAK menambah CanvasModulate kedua —
## DayNightVisual tetap satu-satunya pemilik CanvasModulate.
##
## Mask 128x1 dibangun ulang tiap frame dari SunSweep.mask (kanal R) dan
## SunSweep.rim (kanal G), lalu shader `blend_mul` mengalikan layar dengan
## mix(ratio, putih, mask). Pita hangat hanya menurunkan kanal merah paling
## sedikit, jadi tetap aman untuk blend_mul (tidak pernah mencerahkan).

const LAYER := 2
const MASK_WIDTH := 128
const RIM_TINT := Color(1.0, 0.9, 0.78, 1.0)

var _rect: ColorRect
var _material: ShaderMaterial
var _image: Image
var _texture: ImageTexture


func _ready() -> void:
	layer = LAYER
	_build()
	clear()


## Tampilkan sapuan: `darken_swept = false` (fajar) membuat bagian yang dilewati
## front menjadi terang; `darken_swept = true` (senja) membuat bagian yang
## dilewati front menjadi gelap menuju warna malam.
func apply(progress: float, side: int, softness: float, warm_strength: float, ratio_color: Color, darken_swept: bool = false) -> void:
	if _rect == null or _image == null:
		return
	var clamped := clampf(progress, 0.0, 1.0)
	for index in MASK_WIDTH:
		var x := float(index) / float(MASK_WIDTH - 1)
		_image.set_pixel(index, 0, Color(
			SunSweep.mask(clamped, side, softness, x),
			SunSweep.rim(clamped, side, softness, x),
			0.0,
			1.0
		))
	_texture.update(_image)
	_material.set_shader_parameter("ratio", ratio_color)
	_material.set_shader_parameter("rim_strength", clampf(warm_strength, 0.0, 1.0))
	_material.set_shader_parameter("darken_swept", 1.0 if darken_swept else 0.0)
	visible = true


## Kembali ke transisi seragam (atau steady): overlay tidak menyentuh layar.
func clear() -> void:
	visible = false


func is_sweeping() -> bool:
	return visible


## Dipakai tes: nilai mask yang sedang dipakai di posisi layar `x_norm`.
func get_mask_value(x_norm: float) -> float:
	if _image == null:
		return 0.0
	var index := clampi(int(round(x_norm * float(MASK_WIDTH - 1))), 0, MASK_WIDTH - 1)
	return _image.get_pixel(index, 0).r


func _build() -> void:
	_image = Image.create(MASK_WIDTH, 1, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_mul;

uniform sampler2D sweep_mask : filter_linear, repeat_disable;
uniform vec4 ratio : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 rim_tint : source_color = vec4(1.0, 0.9, 0.78, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.0;
uniform float darken_swept : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 sample_mask = texture(sweep_mask, vec2(UV.x, 0.5)).rg;
	float swept = sample_mask.r;
	float lit = mix(swept, 1.0 - swept, darken_swept);
	float rim = sample_mask.g * rim_strength;
	// blend_mul hanya menggelapkan: pita hangat = tint hangat (kanal <= 1).
	vec3 tint = mix(rim_tint.rgb, vec3(1.0), 1.0 - rim);
	vec3 darkened = ratio.rgb * tint;
	COLOR = vec4(mix(darkened, vec3(1.0), lit), 1.0);
}
"""

	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("sweep_mask", _texture)
	_material.set_shader_parameter("rim_tint", RIM_TINT)

	_rect = ColorRect.new()
	_rect.name = "Mask"
	_rect.color = Color.WHITE
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _material
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)

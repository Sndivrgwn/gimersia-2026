extends CanvasLayer

## Mission 9 polish: vignette merah berdenyut saat HP rendah.
## Read-only: hanya membaca StatsComponent, tidak menulis state gameplay.
## Memakai art slot `ui_vignette_low_hp` bila ada, kalau tidak shader bawaan.

const PLAYER_GROUP := &"player"
const STATS_NAME := "StatsComponent"
const SHADER_CODE := """
shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.55, 0.03, 0.04, 1.0);

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv * vec2(1.0, 1.15)) * 1.72;
	float edge = smoothstep(0.32, 0.95, d);
	COLOR = vec4(tint.rgb, tint.a * edge * strength);
}
"""

## Ambang HP dalam persen (default sama dengan JuiceConfig).
@export var threshold_percent: float = 25.0
@export var pulse_speed: float = 1.4
@export var max_strength: float = 0.85

var _overlay: ColorRect
var _material: ShaderMaterial
var _stats: StatsComponent
var _time: float = 0.0
var _strength: float = 0.0


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_bind()


func _process(delta: float) -> void:
	_time += delta
	if _stats == null:
		_bind()
		if _stats == null:
			return
	var ratio := _ratio()
	var threshold := clampf(threshold_percent / 100.0, 0.01, 1.0)
	if ratio >= threshold:
		_set_strength(0.0)
		return
	var t := clampf(1.0 - ratio / threshold, 0.0, 1.0)
	var pulse := 0.72 + 0.28 * sin(_time * TAU * pulse_speed * 0.5)
	_set_strength(t * pulse)


## Dipakai tes: kekuatan vignette saat ini (0..1).
func get_strength() -> float:
	return _strength


func get_overlay() -> ColorRect:
	return _overlay


func _build() -> void:
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter(&"strength", 0.0)

	_overlay = ColorRect.new()
	_overlay.name = "Overlay"
	_overlay.color = Color.WHITE
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.material = _material
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)


func _bind() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group(PLAYER_GROUP)
	if player == null:
		return
	_stats = player.get_node_or_null(STATS_NAME) as StatsComponent


func _ratio() -> float:
	if _stats == null:
		return 1.0
	var max_hp := maxf(_stats.get_max_hp(), 0.001)
	return clampf(_stats.current_hp / max_hp, 0.0, 1.0)


func _set_strength(value: float) -> void:
	var next := clampf(value, 0.0, 1.0) * max_strength
	if is_equal_approx(next, _strength):
		return
	_strength = next
	if _material != null:
		_material.set_shader_parameter(&"strength", _strength)

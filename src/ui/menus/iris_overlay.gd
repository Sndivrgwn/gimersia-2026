class_name IrisOverlay
extends CanvasLayer

## Overlay transisi lingkaran (iris wipe) di get_tree().root yang bertahan
## melewati pergantian scene lalu menghapus dirinya sendiri saat selesai.

signal finished

## Lebih tinggi dari semua CanvasLayer UI/FX proyek (ScreenFade = 90, PauseMenu = 40).
const OVERLAY_LAYER := 100
const SHADER_PATH := "res://src/ui/menus/iris_transition.gdshader"

var _config: SplashConfig
var _transition: IrisTransition
var _rect: ColorRect
var _material: ShaderMaterial
var _started: bool = false
var _valid: bool = false


func setup(cfg: SplashConfig, shader_override: Shader = null) -> bool:
	_config = cfg if cfg != null else SplashConfig.new()
	name = "IrisOverlay"
	layer = OVERLAY_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS

	var shader := shader_override
	if shader == null and ResourceLoader.exists(SHADER_PATH):
		shader = ResourceLoader.load(SHADER_PATH) as Shader
	if shader == null:
		push_warning("IrisOverlay: gagal memuat shader %s, transisi dilewati." % SHADER_PATH)
		_valid = false
		return false

	_material = ShaderMaterial.new()
	_material.shader = shader

	_rect = ColorRect.new()
	_rect.name = "Mask"
	_rect.color = _config.background_color
	_rect.material = _material
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP if _config.transition_block_input else Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)

	_transition = IrisTransition.new()
	_transition.setup(_config)
	_transition.finished.connect(_on_transition_finished)

	_valid = true
	_update_uniforms()
	return true


func is_valid() -> bool:
	return _valid


func is_started() -> bool:
	return _started


func get_transition() -> IrisTransition:
	return _transition


func get_mask_rect() -> ColorRect:
	return _rect


func start() -> void:
	if not _valid or _started:
		return
	_started = true
	_update_uniforms()


## Tunggu 1 frame setelah scene baru masuk supaya _ready menu selesai, lalu mulai membesar.
func start_after_next_frame() -> void:
	if not _valid or _started:
		return
	var tree := get_tree()
	if tree == null:
		start()
		return
	await tree.process_frame
	if is_instance_valid(self) and is_inside_tree():
		start()


func _ready() -> void:
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_update_uniforms):
		viewport.size_changed.connect(_update_uniforms)
	_update_uniforms()


func _process(delta: float) -> void:
	if not _valid or not _started or _transition == null or _transition.is_finished():
		return
	_transition.tick(delta)
	_update_uniforms()


func _update_uniforms() -> void:
	if _material == null or _config == null:
		return
	var viewport_size := _viewport_size()
	var max_radius := IrisTransition.max_radius_px(viewport_size)
	var min_dim := minf(viewport_size.x, viewport_size.y)
	var softness_px := maxf(_config.transition_softness, 0.0) * min_dim
	var radius_ratio := _transition.radius() if _transition != null else 0.0
	_material.set_shader_parameter(&"radius_px", max_radius * radius_ratio)
	_material.set_shader_parameter(&"softness_px", softness_px)
	_material.set_shader_parameter(&"center", viewport_size * 0.5)
	_material.set_shader_parameter(&"color", _config.background_color)


func _viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport != null:
		var size := viewport.get_visible_rect().size
		if size.x > 0.0 and size.y > 0.0:
			return size
	return Vector2(1280.0, 720.0)


func _on_transition_finished() -> void:
	if _rect != null and is_instance_valid(_rect):
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	finished.emit()
	queue_free()

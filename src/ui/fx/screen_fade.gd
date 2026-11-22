extends RefCounted

## Transisi layar (Mission 9 polish): fade keluar/masuk dan flash.
## Fade keluar memakai callback satu kali (bukan await) supaya
## `RunController._change_scene()` tetap sinkron dan bisa ditimpa tes.
## Di headless (tes GUT) semua efek langsung no-op.

const LAYER := 90
const FADE_TIME := 0.22


static func is_visual_disabled() -> bool:
	return DisplayServer.get_name() == "headless"


## Fade ke warna lalu panggil `on_done` tepat setelah tween selesai.
static func fade_out_then(tree: SceneTree, on_done: Callable, color: Color = Color.BLACK) -> void:
	if tree == null or is_visual_disabled() or tree.current_scene == null:
		on_done.call()
		return
	var rect := _spawn(tree.current_scene, Color(color.r, color.g, color.b, 0.0), LAYER)
	var tween := tree.create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(rect, "color:a", 1.0, FADE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(on_done, CONNECT_ONE_SHOT)


## Fade masuk saat scene baru siap (dipanggil dari `_ready` root scene).
static func fade_in(root: Node, color: Color = Color.BLACK, duration: float = FADE_TIME) -> void:
	if root == null or is_visual_disabled() or root.get_tree() == null:
		return
	var rect := _spawn(root, color, LAYER)
	var tween := root.create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(rect, "color:a", 0.0, duration).set_delay(0.05)
	tween.finished.connect(rect.get_parent().queue_free, CONNECT_ONE_SHOT)


## Kilat satu warna (victory). `color.a` adalah puncak opacity.
static func flash(root: Node, color: Color, hold: float = 0.35) -> void:
	if root == null or is_visual_disabled() or root.get_tree() == null:
		return
	var rect := _spawn(root, Color(color.r, color.g, color.b, 0.0), 80)
	var tween := root.create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(rect, "color:a", color.a, 0.18)
	tween.tween_interval(hold)
	tween.tween_property(rect, "color:a", 0.0, 0.55)
	tween.finished.connect(rect.get_parent().queue_free, CONNECT_ONE_SHOT)


## Satu tempat pembuatan overlay, agar tiga efek di atas tidak duplikat.
static func _spawn(root: Node, color: Color, layer_index: int) -> ColorRect:
	var layer := CanvasLayer.new()
	layer.name = "ScreenFade"
	layer.layer = layer_index
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var rect := ColorRect.new()
	rect.name = "Rect"
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	root.add_child(layer)
	return rect

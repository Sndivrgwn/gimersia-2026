extends CanvasLayer

## Mission 10 feedback: busur merah di tepi layar yang menunjukkan arah
## datangnya serangan. Hanya membaca `PlayerDamageReceiver.damaged`.

const SHOW_TIME := 0.65
const SPAN := 0.5
const RADIUS_RATIO := 0.42
const THICKNESS := 10.0
const COLOR := Color(0.95, 0.15, 0.12, 1.0)

var _canvas: Control
var _timer: float = 0.0
var _angle: float = 0.0


func _ready() -> void:
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.name = "Arc"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)


func bind_player(player: Node) -> void:
	if player == null:
		return
	var receiver := player.get_node_or_null("PlayerDamageReceiver") as PlayerDamageReceiver
	if receiver != null and not receiver.damaged.is_connected(_on_damaged):
		receiver.damaged.connect(_on_damaged)


func show_direction(angle: float) -> void:
	_angle = angle
	_timer = SHOW_TIME
	_redraw()


func show_from(player_position: Vector2, source_position: Vector2) -> void:
	show_direction((source_position - player_position).angle())


func is_active() -> bool:
	return _timer > 0.0


func get_angle() -> float:
	return _angle


func tick(delta: float) -> void:
	if _timer <= 0.0:
		return
	_timer = maxf(_timer - delta, 0.0)
	_redraw()


func _process(delta: float) -> void:
	tick(delta)


func _on_damaged(_amount: float, source: Node) -> void:
	if not (source is Node2D):
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player == null:
		return
	show_from(player.global_position, (source as Node2D).global_position)


func _redraw() -> void:
	if _canvas != null:
		_canvas.queue_redraw()


func _on_draw() -> void:
	if _timer <= 0.0 or _canvas == null:
		return
	var size := _canvas.size
	var center := size * 0.5
	var radius := minf(size.x, size.y) * RADIUS_RATIO
	if radius <= 1.0:
		return
	var alpha := clampf(_timer / SHOW_TIME, 0.0, 1.0)
	var color := Color(COLOR.r, COLOR.g, COLOR.b, 0.75 * alpha)
	_canvas.draw_arc(center, radius, _angle - SPAN, _angle + SPAN, 32, color, THICKNESS, true)
	_canvas.draw_arc(center, radius + 8.0, _angle - SPAN * 0.7, _angle + SPAN * 0.7, 24, Color(COLOR.r, COLOR.g, COLOR.b, 0.35 * alpha), THICKNESS * 0.5, true)

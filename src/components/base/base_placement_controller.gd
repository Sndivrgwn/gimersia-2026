class_name BasePlacementController
extends Node

## D1: B membuka preview ring yang mengikuti pemain; B lagi memasang base.
## Input dibaca dengan polling action (aturan INPUT RULE).

signal preview_changed(valid: bool, reason: String)
signal base_placed(center: Vector2)
signal placement_cancelled

const GROUP := &"base_placement"
const SNAP := 16.0
const RING_SEGMENTS := 48

@export var player: Node2D
@export var anchor: CampAnchor
## Mission 10: geometri pagar untuk preview (sama dengan FenceRing.layout).
@export var fence_config: FenceConfig = preload("res://src/data/configs/fence_config.tres")
@export var site_config: BaseSiteConfig
## Untuk tes: Callable(Vector2) -> Dictionary {valid, reason}.
var rules_override: Callable = Callable()

var _preview_active: bool = false
var _preview_position: Vector2 = Vector2.ZERO
var _result: Dictionary = {"valid": false, "reason": ""}
var _ring: Line2D
var _drawer: PreviewDraw


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	InputSetup.ensure_actions()
	if player == null:
		player = get_parent() as Node2D
	if anchor == null:
		anchor = CampAnchor.find_anchor(self)
	_ensure_ring()
	_ensure_drawer()
	refresh_ring()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(InputSetup.BASE_PLACE):
		if _preview_active:
			confirm()
		else:
			start_preview()
		return
	if not _preview_active:
		return
	if Input.is_action_just_pressed(&"ui_cancel"):
		cancel()
		return
	_update_preview()


func start_preview() -> void:
	if anchor == null:
		return
	# Mission 10: panel stasiun/tas yang terbuka menahan preview base.
	if UiBackStack.has_open(self):
		return
	_preview_active = true
	UiBackStack.register(self)
	_update_preview()


func cancel() -> void:
	if not _preview_active:
		return
	_preview_active = false
	UiBackStack.unregister(self)
	refresh_ring()
	placement_cancelled.emit()


func confirm() -> bool:
	if not _preview_active or anchor == null:
		return false
	_update_preview()
	if not bool(_result.get("valid", false)):
		return false
	_preview_active = false
	var placed := anchor.found(_preview_position)
	refresh_ring()
	if placed:
		base_placed.emit(_preview_position)
	return placed


func is_preview_active() -> bool:
	return _preview_active


## Nama seragam untuk UiBackStack (Esc menutup preview dulu).
func is_open() -> bool:
	return _preview_active


func close() -> void:
	cancel()


func get_preview_position() -> Vector2:
	return _preview_position


func get_result() -> Dictionary:
	return _result


func set_preview_position(position: Vector2) -> void:
	_preview_position = position.snapped(Vector2(SNAP, SNAP))
	_result = evaluate_at(_preview_position)
	refresh_ring()
	preview_changed.emit(bool(_result.get("valid", false)), String(_result.get("reason", "")))


## Mission 10: preview = aturan site + seluruh segmen pagar + 4 slot inti.
func evaluate_at(position: Vector2) -> Dictionary:
	if rules_override.is_valid():
		return rules_override.call(position) as Dictionary
	if anchor != null and anchor.is_founded():
		return BaseSiteRules.evaluate(position, _site_config(), true)
	var site := _site_config()
	return BasePlacementPreview.compute(position, site, _fence_config(), false)


func _site_config() -> BaseSiteConfig:
	if site_config != null:
		return site_config
	if anchor != null:
		site_config = anchor.get_rules_config()
	return site_config if site_config != null else BaseSiteConfig.new()


func _fence_config() -> FenceConfig:
	var site := _site_config()
	if site != null and site.fence_config != null:
		return site.fence_config
	return fence_config


func refresh_ring() -> void:
	if _drawer != null:
		_drawer.visible = _preview_active
		_drawer.segments = _result.get("fence_segments", [])
		_drawer.slots = _result.get("core_slots", [])
		_drawer.queue_redraw()
	if _ring == null:
		return
	var radius := BasePlacementPreview.fence_radius(_fence_config())
	var points := PackedVector2Array()
	for index in RING_SEGMENTS:
		var angle := TAU * float(index) / float(RING_SEGMENTS)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	_ring.points = points
	_ring.visible = _preview_active
	_ring.position = _preview_position - player.global_position if player != null else Vector2.ZERO
	var valid := bool(_result.get("valid", false))
	_ring.default_color = Color(0.3, 1.0, 0.4, 0.8) if valid else Color(1.0, 0.3, 0.3, 0.8)


func _update_preview() -> void:
	if player == null:
		return
	set_preview_position(player.global_position)


func _ensure_drawer() -> void:
	if _drawer != null and is_instance_valid(_drawer):
		return
	_drawer = PreviewDraw.new()
	_drawer.name = "BasePreviewDraw"
	_drawer.z_index = 4
	_drawer.visible = false
	add_child(_drawer)


## Gambar segmen pagar + marker slot inti dalam koordinat dunia.
class PreviewDraw extends Node2D:
	const SEGMENT_SIZE := Vector2(48.0, 8.0)
	const VALID_COLOR := Color(0.3, 1.0, 0.4, 0.35)
	const INVALID_COLOR := Color(1.0, 0.3, 0.3, 0.45)
	const SLOT_COLOR := Color(0.95, 0.88, 0.45, 0.55)

	var segments: Array = []
	var slots: Array = []

	func _draw() -> void:
		for entry in segments:
			draw_set_transform(entry["position"], float(entry["rotation"]), Vector2.ONE)
			var color := VALID_COLOR if bool(entry.get("valid", true)) else INVALID_COLOR
			draw_rect(Rect2(-SEGMENT_SIZE * 0.5, SEGMENT_SIZE), color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var font := ThemeDB.fallback_font
		for slot in slots:
			var point: Vector2 = slot["position"]
			draw_circle(point, 5.0, SLOT_COLOR)
			draw_string(font, point + Vector2(6.0, 3.0), String(slot["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, SLOT_COLOR)


func _ensure_ring() -> void:
	if _ring != null and is_instance_valid(_ring):
		return
	_ring = Line2D.new()
	_ring.name = "BasePreviewRing"
	_ring.width = 2.0
	_ring.z_index = 5
	add_child(_ring)

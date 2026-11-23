class_name ChopFeedback
extends Node2D

## Mission 7: umpan balik menebang pohon (tanpa audio).
## Menempel sebagai child ResourceNode hanya untuk definisi chop_feedback_enabled.
##
## Mission 9 (fix): getaran HANYA saat progres menebang benar-benar berjalan
## (tombol tahan ditekan), bukan saat pemain sekadar berdiri dekat pohon.
## Getaran juga berirama: satu getaran pendek setiap `CHOP_INTERVAL`, bukan
## berkelanjutan, supaya terasa seperti ayunan kapak.

signal feedback_event(kind: StringName, position: Vector2)

const SHAKE_PX := 2.0
const SHAKE_HZ := 18.0
## Jeda antar ayunan: serpihan + getaran pendek.
const CHOP_INTERVAL := 0.22
## Lama satu getaran; sisanya diam menunggu ayunan berikutnya.
const SHAKE_BURST := 0.12
const FALL_TIME := 0.6
const FALL_DEGREES := 85.0
const REGROW_TIME := 0.5
const REGROW_SCALE := 0.3
const STUMP_SIZE := Vector2(16.0, 6.0)

var _target: Node
var _interactor: InteractorComponent
var _visual: Node2D
## Pemain sedang menargetkan pohon ini (hanya dekat, belum tentu menebang).
var _targeted: bool = false
## Progres menebang sedang berjalan untuk pohon ini.
var _active: bool = false
var _shake_phase: float = 0.0
var _interval_timer: float = 0.0
var _burst_remaining: float = 0.0
## Rasio hold terakhir dari InteractorComponent (0 = tidak menebang).
var _ratio: float = 0.0
var _fallen: bool = false
var _stump: Polygon2D


func _ready() -> void:
	_target = get_parent()
	_visual = _target.get_node_or_null("Visual") as Node2D
	_bind_interactor()


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	_poll_depleted()
	if _interactor == null:
		_bind_interactor()
	# Dicek tiap frame: getaran berhenti seketika progres menebang berakhir,
	# walau sinyal progres tidak sempat terkirim.
	_refresh_active()
	if _fallen or not _active:
		return

	_interval_timer += delta
	if _interval_timer >= CHOP_INTERVAL:
		_interval_timer = 0.0
		_burst_remaining = SHAKE_BURST
		_spawn_chips()
		feedback_event.emit(&"chop_hit", global_position)

	if _burst_remaining <= 0.0:
		return
	_burst_remaining = maxf(_burst_remaining - delta, 0.0)
	_shake_phase += delta
	if _visual != null:
		var offset := sin(_shake_phase * TAU * SHAKE_HZ) * SHAKE_PX
		_visual.position = Vector2(offset, 0.0) if _burst_remaining > 0.0 else Vector2.ZERO


func is_chopping() -> bool:
	return _active and not _fallen


func is_targeted() -> bool:
	return _targeted


func is_fallen() -> bool:
	return _fallen


func get_stump() -> Polygon2D:
	return _stump


# --- Internal ---------------------------------------------------------------

func _bind_interactor() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group(&"player")
	if player == null:
		return
	_interactor = player.get_node_or_null("InteractorComponent") as InteractorComponent
	if _interactor == null:
		return
	if not _interactor.target_changed.is_connected(_on_target_changed):
		_interactor.target_changed.connect(_on_target_changed)
	if not _interactor.progress_changed.is_connected(_on_progress_changed):
		_interactor.progress_changed.connect(_on_progress_changed)


func _on_target_changed(target: Interactable) -> void:
	_targeted = target == _target
	if not _targeted:
		_deactivate()


## Progres 0 berarti tombol dilepas/batal: getaran berhenti walau masih dekat.
func _on_progress_changed(ratio: float) -> void:
	_ratio = clampf(ratio, 0.0, 1.0)
	_refresh_active()


func _refresh_active() -> void:
	var active := _is_chopping_now()
	if active == _active:
		return
	if active:
		_activate()
	else:
		_deactivate()


## Pohon hanya bergetar bila progres menebang MILIK pohon ini sedang berjalan:
## ditargetkan, progres > 0, tombol belum dilepas, dan target aktif bukan pohon lain.
func _is_chopping_now() -> bool:
	if _fallen or not _targeted or _ratio <= 0.0:
		return false
	if _interactor == null or not is_instance_valid(_interactor):
		return false
	if _interactor.is_waiting_for_release():
		return false
	# Mission 10 (fix): target aktif HARUS pohon ini. Dulu `null` dianggap
	# "milik pohon ini", sehingga getaran tetap jalan saat target sudah lepas
	# (lubang yang hanya tertutup di tes karena tes tidak pernah set target).
	return _interactor.get_target() == _target


func _activate() -> void:
	_active = true
	_interval_timer = CHOP_INTERVAL
	_burst_remaining = SHAKE_BURST
	_shake_phase = 0.0


func _deactivate() -> void:
	_active = false
	_interval_timer = 0.0
	_burst_remaining = 0.0
	_shake_phase = 0.0
	if _visual != null:
		_visual.position = Vector2.ZERO


func _poll_depleted() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	if not _target.has_method(&"is_depleted"):
		return
	var depleted: bool = _target.is_depleted()
	if depleted and not _fallen:
		_start_fall()
	elif not depleted and _fallen:
		_regrow()


func _start_fall() -> void:
	_fallen = true
	_deactivate()
	var parent := _target.get_parent()
	if parent != null:
		var body := Node2D.new()
		body.name = "TreeFall"
		if _visual != null:
			var copy := _duplicate_visual()
			if copy is Node2D:
				body.add_child(copy)
		body.global_position = _target.global_position
		parent.add_child(body)
		var tween := body.create_tween()
		tween.set_parallel(true)
		tween.tween_property(body, "rotation", deg_to_rad(FALL_DEGREES), FALL_TIME)
		tween.tween_property(body, "modulate:a", 0.0, FALL_TIME)
		tween.chain().tween_callback(body.queue_free)
		_spawn_stump(parent)
	feedback_event.emit(&"tree_fall", _target.global_position)


func _spawn_stump(parent: Node) -> void:
	if _stump != null and is_instance_valid(_stump):
		return
	_stump = Polygon2D.new()
	_stump.name = "TreeStump"
	var half := STUMP_SIZE * 0.5
	_stump.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
	_stump.color = Color(0.35, 0.22, 0.12, 1.0)
	_stump.global_position = _target.global_position
	_stump.z_index = -1
	parent.add_child(_stump)


## Salinan art bila slot punya art; kalau tidak, polygon placeholder lama.
func _duplicate_visual() -> Node:
	if _target != null and is_instance_valid(_target):
		var slot := _target.get_node_or_null("VisualSlot") as VisualSlot
		if slot != null and slot.is_showing_art():
			var art := slot.duplicate_art()
			if art != null:
				return art
	return _visual.duplicate() if _visual != null else null


func _regrow() -> void:
	_fallen = false
	if _stump != null and is_instance_valid(_stump):
		_stump.queue_free()
	_stump = null
	if _target == null or not is_instance_valid(_target):
		return
	(_target as Node2D).scale = Vector2(REGROW_SCALE, REGROW_SCALE)
	var tween := create_tween()
	tween.tween_property(_target, "scale", Vector2.ONE, REGROW_TIME)


func _spawn_chips() -> void:
	var parent := _target.get_parent() if _target != null else null
	if parent == null or not is_inside_tree():
		return
	var chips := CPUParticles2D.new()
	chips.name = "ChopChips"
	chips.one_shot = true
	chips.emitting = true
	chips.amount = 6
	chips.lifetime = 0.3
	chips.explosiveness = 1.0
	chips.spread = 180.0
	chips.initial_velocity_min = 30.0
	chips.initial_velocity_max = 70.0
	chips.gravity = Vector2(0.0, 160.0)
	chips.color = Color(0.6, 0.4, 0.2, 1.0)
	var chip_texture := Assets.ui_texture(&"fx_chip")
	if chip_texture != null:
		chips.texture = chip_texture
	chips.global_position = _target.global_position
	parent.add_child(chips)
	chips.finished.connect(chips.queue_free)

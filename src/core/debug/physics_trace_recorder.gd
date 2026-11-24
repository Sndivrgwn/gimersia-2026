class_name PhysicsTraceRecorder
extends Node

## Mission 11 (Block A): perekam jejak fisika khusus island, DEFAULT OFF.
## Tekan K selama 6 detik: setiap frame fisika mencatat pemain + 2 fauna
## terdekat (posisi, kecepatan, state, kecepatan AI, kedalaman tumpuk, dan
## pemisahan badan yang diterapkan), lalu menulis CSV ke user:// supaya laporan
## "fauna masih terseret" bisa dianalisis tanpa menebak.
##
## Tidak mengubah state gameplay: hanya membaca node dan menulis satu file.

const ACTION := &"debug_drag_trace"
const PLAYER_GROUP := &"player"
const FAUNA_GROUP := &"fauna"
const NEAREST_FAUNA := 2
const DEFAULT_SECONDS := 6.0
const TOAST_SAVED := "Jejak disimpan: %s"
const TOAST_FAILED := "Gagal menyimpan jejak: %s"
const CSV_HEADER := "frame,slot,kind,state,x,y,vx,vy,ai_vx,ai_vy,overlap,sep_x,sep_y,player_gap"

@export var record_seconds: float = DEFAULT_SECONDS
@export var path_prefix: String = "user://drag_trace_"

var _recording: bool = false
var _elapsed: float = 0.0
var _frame: int = 0
var _rows: Array[Dictionary] = []
var _was_pressed: bool = false


func _physics_process(delta: float) -> void:
	var pressed := Input.is_action_pressed(ACTION)
	if pressed and not _was_pressed:
		start_recording()
	_was_pressed = pressed
	if not _recording:
		return
	_sample()
	_elapsed += delta
	if _elapsed >= record_seconds:
		stop_recording()


func is_recording() -> bool:
	return _recording


func get_rows() -> Array[Dictionary]:
	return _rows.duplicate()


func start_recording() -> void:
	_rows.clear()
	_frame = 0
	_elapsed = 0.0
	_recording = true


## Selesai merekam: tulis CSV dan tampilkan toast. Mengembalikan path ("" gagal).
func stop_recording() -> String:
	if not _recording:
		return ""
	_recording = false
	var path := path_prefix + _timestamp() + ".csv"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_show_toast(TOAST_FAILED % path)
		return ""
	file.store_string(build_csv(_rows))
	file.close()
	_show_toast(TOAST_SAVED % path)
	return path


## Format CSV murni (tanpa akses file) supaya bisa dites unit.
static func build_csv(rows: Array[Dictionary]) -> String:
	var lines := PackedStringArray([CSV_HEADER])
	for row in rows:
		lines.append("%d,%d,%s,%d,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f" % [
			int(row.get("frame", 0)),
			int(row.get("slot", 0)),
			String(row.get("kind", "")),
			int(row.get("state", -1)),
			float(row.get("x", 0.0)),
			float(row.get("y", 0.0)),
			float(row.get("vx", 0.0)),
			float(row.get("vy", 0.0)),
			float(row.get("ai_vx", 0.0)),
			float(row.get("ai_vy", 0.0)),
			float(row.get("overlap", 0.0)),
			float(row.get("sep_x", 0.0)),
			float(row.get("sep_y", 0.0)),
			float(row.get("player_gap", 0.0)),
		])
	return "\n".join(lines) + "\n"


func _sample() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group(PLAYER_GROUP) as Node2D
	var targets := _nearest_fauna(tree, player)
	_rows.append(_row(_frame, 0, player, player, Vector2.ZERO))
	for index in targets.size():
		var animal := targets[index]
		_rows.append(_row(_frame, index + 1, player, animal, animal.last_separation))
	_frame += 1


func _nearest_fauna(tree: SceneTree, player: Node2D) -> Array[FaunaBase]:
	var result: Array[FaunaBase] = []
	var origin := player.global_position if player != null else Vector2.ZERO
	var candidates: Array[FaunaBase] = []
	for node in tree.get_nodes_in_group(FAUNA_GROUP):
		if node is FaunaBase and is_instance_valid(node):
			candidates.append(node)
	candidates.sort_custom(func(a: FaunaBase, b: FaunaBase) -> bool:
		return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin))
	for index in mini(NEAREST_FAUNA, candidates.size()):
		result.append(candidates[index])
	return result


func _row(frame: int, slot: int, player: Node2D, body: Node2D, separation: Vector2) -> Dictionary:
	var kind := "player"
	var state := -1
	var velocity := Vector2.ZERO
	var ai_velocity := Vector2.ZERO
	if body is FaunaBase:
		var animal := body as FaunaBase
		kind = String(animal.visual_key())
		state = animal.get_state() if animal.has_method(&"get_state") else -1
		velocity = animal.velocity
		ai_velocity = animal.velocity
	elif body is CharacterBody2D:
		velocity = (body as CharacterBody2D).velocity
	var position := body.global_position if body != null else Vector2.ZERO
	var gap := 0.0
	var overlap := 0.0
	if player != null and body != null:
		gap = player.global_position.distance_to(body.global_position)
		var radius := BodySeparation.radius_of(player) + BodySeparation.radius_of(body)
		overlap = maxf(radius - gap, 0.0)
	return {
		"frame": frame,
		"slot": slot,
		"kind": kind,
		"state": state,
		"x": position.x,
		"y": position.y,
		"vx": velocity.x,
		"vy": velocity.y,
		"ai_vx": ai_velocity.x,
		"ai_vy": ai_velocity.y,
		"overlap": overlap,
		"sep_x": separation.x,
		"sep_y": separation.y,
		"player_gap": gap,
	}


func _timestamp() -> String:
	return Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")


func _show_toast(text: String) -> void:
	var tree := get_tree()
	if tree == null:
		return
	var toast := tree.get_root().find_child("ToastHUD", true, false)
	if toast != null and toast.has_method(&"show_toast"):
		toast.call(&"show_toast", text)

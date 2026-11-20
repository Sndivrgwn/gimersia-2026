class_name EndgameController
extends Node

## Endgame Hari 7 (spesifikasi V8 §7.8): banner pagi Hari 7, status rescue,
## arah/​jarak ke Beacon, dan Victory dari SignalBeacon.
##
## Anti-softlock boar sudah ditangani `FaunaQuota` pada `rescue_started`; modul
## ini tidak menspawn apa pun.

signal banner_shown(text: String)
signal rescue_ready
signal victory

const BANNER_TEXT := (
	"Kapal penyelamat terlihat di cakrawala! Siapkan Suar Darurat dan "
	+ "bertahanlah melewati malam terakhir..."
)
const RESCUE_TEXT := "Fajar! Beacon aktif - nyalakan Suar Darurat di Signal Beacon."
const PLAYER_GROUP := &"player"

@export var clock: Node
@export var player: Node
@export var beacon: SignalBeacon

var _bound: bool = false


func _ready() -> void:
	add_to_group(&"endgame_controller")
	_bind()


func setup(p_clock: Node, p_player: Node, p_beacon: SignalBeacon) -> void:
	clock = p_clock
	player = p_player
	beacon = p_beacon
	_bound = false
	_bind()


# --- Read API ---------------------------------------------------------------

func is_rescue_active() -> bool:
	if clock == null:
		return false
	if "rescue_triggered" in clock:
		return bool(clock.rescue_triggered)
	return false


func get_beacon() -> SignalBeacon:
	_bind()
	return beacon


func get_beacon_position() -> Vector2:
	var target := get_beacon()
	if target == null:
		return Vector2.ZERO
	return target.global_position


func get_beacon_direction() -> Vector2:
	var target := get_beacon()
	if target == null or player == null or not (player is Node2D):
		return Vector2.ZERO
	var offset := target.global_position - (player as Node2D).global_position
	if offset.length_squared() <= 0.0001:
		return Vector2.ZERO
	return offset.normalized()


func get_beacon_distance() -> float:
	var target := get_beacon()
	if target == null or player == null or not (player is Node2D):
		return 0.0
	return (player as Node2D).global_position.distance_to(target.global_position)


func can_use_beacon() -> bool:
	var target := get_beacon()
	return target != null and target.can_interact(null)


# --- Internal ---------------------------------------------------------------

func _bind() -> void:
	if _bound:
		return
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	if player == null:
		var tree := get_tree()
		if tree != null:
			player = tree.get_first_node_in_group(PLAYER_GROUP)
	if beacon == null:
		var tree := get_tree()
		if tree != null:
			beacon = tree.get_first_node_in_group(&"signal_beacon") as SignalBeacon

	if clock != null:
		if clock.has_signal(&"day_started") and not clock.day_started.is_connected(_on_day_started):
			clock.day_started.connect(_on_day_started)
		if clock.has_signal(&"rescue_started") and not clock.rescue_started.is_connected(_on_rescue_started):
			clock.rescue_started.connect(_on_rescue_started)
	if beacon != null and not beacon.victory_triggered.is_connected(_on_beacon_victory):
		beacon.victory_triggered.connect(_on_beacon_victory)

	_bound = true


func _on_day_started(day: int) -> void:
	if clock == null:
		return
	var max_days := 1
	if clock.has_method(&"get_max_days"):
		max_days = int(clock.get_max_days())
	if day == max_days:
		banner_shown.emit(BANNER_TEXT)


func _on_rescue_started() -> void:
	rescue_ready.emit()
	banner_shown.emit(RESCUE_TEXT)


func _on_beacon_victory() -> void:
	victory.emit()

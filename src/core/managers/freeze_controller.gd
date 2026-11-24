class_name FreezeController
extends Node

## Mission 9: pembekuan game berbasis ALASAN (reason set). Selama set tidak
## kosong: `get_tree().paused = true` dan jam game di-skala 0 dengan cara yang
## sama seperti PauseMenu. Saat set kembali kosong, skala waktu dipulihkan
## PERSIS seperti sebelumnya (Jaga Malam x2 dan final dawn 0 tetap hidup).
##
## Bukan autoload: dipasang di island.tscn dan ditemukan lewat grup
## `&"game_freeze"`. PauseMenu meminta alasan `&"pause"`, DeathController
## meminta `&"death"`.

const GROUP := &"game_freeze"
const REASON_PAUSE := &"pause"
const REASON_DEATH := &"death"

@export var clock: Node

var _reasons: Dictionary = {}
var _frozen: bool = false
var _previous_scale: float = 1.0


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")


# --- API --------------------------------------------------------------------

## Minta beku. True bila alasan ini baru ditambahkan.
func request(reason: StringName) -> bool:
	if _reasons.has(reason):
		return false
	_reasons[reason] = true
	if not _frozen:
		_freeze()
	return true


## Lepas satu alasan. Beku hanya berakhir saat semua alasan sudah dilepas.
func release(reason: StringName) -> void:
	if not _reasons.has(reason):
		return
	_reasons.erase(reason)
	if _reasons.is_empty():
		_unfreeze()


func is_frozen() -> bool:
	return _frozen


func has_reason(reason: StringName) -> bool:
	return _reasons.has(reason)


func get_reasons() -> Array[StringName]:
	var result: Array[StringName] = []
	for key in _reasons:
		result.append(key)
	return result


func get_reason_count() -> int:
	return _reasons.size()


## Skala waktu yang dipulihkan saat beku berakhir.
func get_previous_time_scale() -> float:
	return _previous_scale


## Cari controller di tree (null bila scene tidak memasangnya).
static func find_controller(node: Node) -> FreezeController:
	if node == null:
		return null
	var tree := node.get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(GROUP) as FreezeController


# --- Internal ---------------------------------------------------------------

func _freeze() -> void:
	_previous_scale = _read_time_scale()
	var tree := get_tree()
	if tree != null:
		tree.paused = true
	_write_time_scale(0.0)
	_frozen = true


func _unfreeze() -> void:
	var tree := get_tree()
	if tree != null:
		tree.paused = false
	_write_time_scale(_previous_scale)
	_frozen = false


func _read_time_scale() -> float:
	if clock != null and clock.has_method(&"get_time_scale"):
		return float(clock.get_time_scale())
	return 1.0


func _write_time_scale(value: float) -> void:
	if clock != null and clock.has_method(&"set_time_scale"):
		clock.set_time_scale(value)

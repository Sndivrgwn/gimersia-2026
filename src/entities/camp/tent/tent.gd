class_name Tent
extends CampStructure

## Tenda Daun: tidur di siang hari dan pintu masuk Jaga Malam di malam hari.
##
## Tidur hanya memanggil `clock.skip_time(config.skip_seconds)` SEKALI; efek
## hunger/thirst/plafon Fatigue ditangani NeedsComponent lewat `time_skipped`
## (tidak diduplikasi di sini).
##
## Syarat tidur: siang, sisa siang > 60 detik game, dan >= 60 detik game sejak
## tidur terakhir (`get_total_elapsed_seconds()`).
##
## Malam: aksi diteruskan ke NightWatchController lewat `night_watch` (untyped
## untuk menghindari referensi kelas melingkar).

signal sleep_completed
signal night_watch_requested(interactor: Node)

const REASON_DAY_ONLY := "Hanya bisa tidur di siang hari"
const REASON_DAY_TOO_SHORT := "Waktu siang kurang dari 60 detik"
const REASON_COOLDOWN := "Tenda masih perlu istirahat"
const PROMPT_SLEEP := "Tahan E: Tidur"
const PROMPT_WATCH := "Tahan E: Jaga Malam"
const PROMPT_WATCH_STOP := "Tahan E: Berhenti Jaga Malam"

## Tuning. Null berarti memakai TentConfig() bawaan.
@export var config: TentConfig
## Opsional; default autoload DayNightManager.
@export var clock: Node
## Diisi NightWatchController saat Tenda dibangun (malam = Jaga Malam).
@export var night_watch: Node

var _last_sleep_time: float = 0.0
var _has_slept: bool = false


func _ready() -> void:
	super()
	if config == null:
		config = TentConfig.new()
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	VisualSlot.attach(self, &"tent", [get_node_or_null("Body"), get_node_or_null("Door")], null, TentVisual.new())


# --- Interactable API (dipakai TentInteract) --------------------------------

func get_prompt(_interactor: Node) -> String:
	if _is_night():
		if night_watch != null and night_watch.has_method("is_active") and night_watch.is_active():
			return PROMPT_WATCH_STOP
		return PROMPT_WATCH
	return PROMPT_SLEEP


func get_hold_time(_interactor: Node) -> float:
	if _is_night():
		return config.night_watch_hold_time
	return maxf(config.hold_time, 0.0)


func get_block_reason(_interactor: Node) -> String:
	if _is_night():
		if night_watch == null:
			return REASON_DAY_ONLY
		if night_watch.has_method("is_active") and night_watch.is_active():
			return ""
		return night_watch.get_start_block_reason()
	return get_sleep_block_reason()


func perform_action(interactor: Node) -> void:
	if _is_night():
		night_watch_requested.emit(interactor)
		if night_watch != null and night_watch.has_method("toggle"):
			night_watch.toggle()
		return
	sleep(interactor)


# --- Tidur ------------------------------------------------------------------

## Alasan tidak bisa tidur sekarang; "" bila boleh.
func get_sleep_block_reason() -> String:
	if clock == null:
		return REASON_DAY_ONLY
	if not clock.is_day():
		return REASON_DAY_ONLY
	if clock.get_remaining_seconds() <= config.min_day_remaining:
		return REASON_DAY_TOO_SHORT
	if _has_slept and clock.get_total_elapsed_seconds() - _last_sleep_time < config.cooldown_seconds:
		return REASON_COOLDOWN
	return ""


func can_sleep() -> bool:
	return get_sleep_block_reason().is_empty()


## Tidur: catat waktu, lalu panggil `skip_time` tepat sekali.
func sleep(_interactor: Node = null) -> bool:
	if not can_sleep():
		return false
	_last_sleep_time = clock.get_total_elapsed_seconds()
	_has_slept = true
	# Mission 12: toast "Tidur: 22:10 -> 05:20" dari jam sebelum/sesudah lompatan.
	var before_hour := -1.0
	if clock.has_method(&"get_clock_hour"):
		before_hour = clock.get_clock_hour()
	clock.skip_time(config.skip_seconds)
	if before_hour >= 0.0:
		_show_sleep_toast(before_hour)
	sleep_completed.emit()
	return true


func _show_sleep_toast(before_hour: float) -> void:
	if not clock.has_method(&"get_clock_format") or not clock.has_method(&"get_clock_text"):
		return
	var format: ClockFormatConfig = clock.get_clock_format()
	if format == null or not format.sleep_toast:
		return
	var tree := get_tree()
	if tree == null:
		return
	var toast := tree.get_root().find_child("ToastHUD", true, false)
	if toast == null or not toast.has_method(&"show_toast"):
		return
	toast.call(&"show_toast", GameClockFormat.sleep_toast_text(before_hour, clock.get_clock_hour(), format))


func has_slept() -> bool:
	return _has_slept


func get_last_sleep_time() -> float:
	return _last_sleep_time


func _is_night() -> bool:
	return clock != null and clock.has_method("is_night") and clock.is_night()

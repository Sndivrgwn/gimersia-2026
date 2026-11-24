extends CanvasLayer

## Read-only HUD for the day/night cycle.
##
## Waits for DayNightManager's time_updated signal for text, and reads
## get_phase_progress() for the progress bar. It never counts time itself.
## The CanvasLayer keeps these controls out of the world canvas, so the
## DayNightVisual CanvasModulate tint cannot darken them.

const MANAGER_PATH := "/root/DayNightManager"
const DEFAULT_SUN_CONFIG := preload("res://src/data/configs/environment/sun_config.tres")
const DAY_PHASE_COLOR := Color(1.0, 0.86, 0.5, 1.0)
const NIGHT_PHASE_COLOR := Color(0.62, 0.76, 1.0, 1.0)

@onready var _clock_label: Label = $Root/Panel/Margin/VBox/ClockLabel
@onready var _day_label: Label = $Root/Panel/Margin/VBox/DayLabel
@onready var _phase_label: Label = $Root/Panel/Margin/VBox/PhaseLabel
@onready var _remaining_label: Label = $Root/Panel/Margin/VBox/RemainingLabel
@onready var _survival_label: Label = $Root/Panel/Margin/VBox/SurvivalLabel
## Mission 7: dimatikan di island karena NightSurvivalHUD menggantikannya.
@export var show_survival_label: bool = true
## Mission 13: sumber `sun_arc_enabled` dan sisi terbit arc matahari.
@export var sun_config: SunConfig = DEFAULT_SUN_CONFIG
@onready var _sun_arc: SunArc = get_node_or_null("Root/SunArc") as SunArc
@onready var _phase_progress: ProgressBar = $Root/Panel/Margin/VBox/PhaseProgress

# Untyped: see the note in day_night_visual.gd.
var _manager
var _phase_tween: Tween
var _day_tween: Tween
var _last_day: int = -1
var _last_is_night: bool = false
var _has_state: bool = false


func _ready() -> void:
	_manager = get_node_or_null(MANAGER_PATH)
	_configure_sun_arc()
	if _manager == null:
		push_warning("TimeHUD: DayNightManager autoload not found.")
		_clock_label.text = "--:--"
		_day_label.text = "Hari -- / --"
		_phase_label.text = "--"
		_remaining_label.text = "--:--"
		_remaining_label.visible = false
		_survival_label.visible = false
		_phase_progress.value = 0.0
		return

	_manager.connect("time_updated", _on_time_updated)
	_manager.connect("rescue_started", _on_rescue_started)
	_refresh(_manager.current_day, _manager.get_remaining_seconds())
	_update_progress()


func _process(_delta: float) -> void:
	if not show_survival_label:
		_survival_label.visible = false
	_update_progress()
	_update_sun_arc()


## Mission 13: arc hanya membaca fase; tidak pernah menghitung waktu sendiri.
func _clock_format() -> ClockFormatConfig:
	if _manager == null:
		return null
	if _manager.has_method(&"get_clock_format"):
		return _manager.get_clock_format() as ClockFormatConfig
	return null


func _update_sun_arc() -> void:
	if _sun_arc == null or not _sun_arc.visible or _manager == null:
		return
	# Mission 12: posisi glyph mengikuti jam dinding (terbit/terbenam di batas fase).
	if _manager.has_method(&"get_clock_hour"):
		_sun_arc.set_clock_hour(
			float(_manager.get_clock_hour()),
			bool(_manager.is_day()),
			_clock_format(),
			float(_manager.get_phase_progress())
		)
		return
	_sun_arc.set_phase(float(_manager.get_phase_progress()), bool(_manager.is_night()))


func _configure_sun_arc() -> void:
	if _sun_arc == null:
		return
	if sun_config != null:
		_sun_arc.visible = sun_config.sun_arc_enabled
		_sun_arc.set_dawn_side(sun_config.dawn_side)
	else:
		_sun_arc.visible = true
	_sun_arc.set_phase(0.0, false)


func _on_time_updated(day: int, _phase: int, remaining_seconds: float) -> void:
	_refresh(day, remaining_seconds)


func _on_rescue_started() -> void:
	_phase_label.text = "RESCUE"
	_phase_label.add_theme_color_override("font_color", DAY_PHASE_COLOR)
	_remaining_label.text = "00:00"
	_survival_label.visible = false
	_phase_progress.value = 1.0


func _refresh(day: int, remaining_seconds: float) -> void:
	var is_night: bool = _manager.is_night()

	if _has_state:
		if day != _last_day:
			_animate_day_label()
		if is_night != _last_is_night:
			_animate_phase_label(is_night)

	_last_day = day
	_last_is_night = is_night
	_has_state = true

	# Mission 12: jam dunia nyata sebagai teks utama; periode + hari di sebelahnya.
	var format: ClockFormatConfig = _clock_format()
	if _clock_label != null:
		_clock_label.text = _manager.get_clock_text() if _manager.has_method(&"get_clock_text") else _format_seconds(remaining_seconds)
	_day_label.text = "Hari %d / %d" % [day, _manager.get_max_days()]
	var period := ""
	if _manager.has_method(&"get_clock_period"):
		period = _manager.get_clock_period()
	if period.is_empty():
		period = "NIGHT" if is_night else "DAY"
	_phase_label.text = period if format == null or format.show_period_label else ""
	_phase_label.add_theme_color_override("font_color", NIGHT_PHASE_COLOR if is_night else DAY_PHASE_COLOR)
	_remaining_label.text = _format_seconds(remaining_seconds)
	var show_remaining := true
	if format != null:
		show_remaining = format.show_remaining_at_night if is_night else format.show_remaining_by_day
	_remaining_label.visible = show_remaining

	# The survival timer is not a separate clock; it mirrors the remaining
	# night time already tracked by the manager. Island mematikannya karena
	# NightSurvivalHUD sudah menampilkan hal yang sama.
	_survival_label.visible = is_night and show_survival_label
	if show_survival_label:
		_survival_label.text = "Survival: %s" % _format_seconds(remaining_seconds)


func _update_progress() -> void:
	if _manager == null:
		return
	_phase_progress.value = _manager.get_phase_progress()


func _animate_phase_label(is_night: bool) -> void:
	if _phase_tween != null and _phase_tween.is_valid():
		_phase_tween.kill()

	_phase_label.pivot_offset = _phase_label.size * 0.5
	_phase_label.scale = Vector2(1.18, 1.18)
	_phase_label.modulate = Color(0.8, 0.9, 1.0, 1.0) if is_night else Color(1.0, 0.95, 0.8, 1.0)

	_phase_tween = create_tween()
	_phase_tween.set_parallel(true)
	_phase_tween.tween_property(_phase_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_phase_tween.tween_property(_phase_label, "modulate", Color.WHITE, 0.35)


func _animate_day_label() -> void:
	if _day_tween != null and _day_tween.is_valid():
		_day_tween.kill()

	_day_label.pivot_offset = _day_label.size * 0.5
	_day_label.scale = Vector2(1.12, 1.12)
	_day_label.modulate = Color(1.0, 1.0, 1.0, 0.35)

	_day_tween = create_tween()
	_day_tween.set_parallel(true)
	_day_tween.tween_property(_day_label, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_day_tween.tween_property(_day_label, "modulate", Color.WHITE, 0.45)


func _format_seconds(seconds: float) -> String:
	var total := int(ceilf(maxf(seconds, 0.0)))
	return "%02d:%02d" % [int(total / 60.0), total % 60]

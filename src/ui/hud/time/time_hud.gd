extends CanvasLayer

## Read-only HUD for the day/night cycle.
##
## Waits for DayNightManager's time_updated signal for text, and reads
## get_phase_progress() for the progress bar. It never counts time itself.
## The CanvasLayer keeps these controls out of the world canvas, so the
## DayNightVisual CanvasModulate tint cannot darken them.

const MANAGER_PATH := "/root/DayNightManager"
const DAY_PHASE_COLOR := Color(1.0, 0.86, 0.5, 1.0)
const NIGHT_PHASE_COLOR := Color(0.62, 0.76, 1.0, 1.0)

@onready var _day_label: Label = $Root/Panel/Margin/VBox/DayLabel
@onready var _phase_label: Label = $Root/Panel/Margin/VBox/PhaseLabel
@onready var _remaining_label: Label = $Root/Panel/Margin/VBox/RemainingLabel
@onready var _survival_label: Label = $Root/Panel/Margin/VBox/SurvivalLabel
## Mission 7: dimatikan di island karena NightSurvivalHUD menggantikannya.
@export var show_survival_label: bool = true
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
	if _manager == null:
		push_warning("TimeHUD: DayNightManager autoload not found.")
		_day_label.text = "Day -- / --"
		_phase_label.text = "--"
		_remaining_label.text = "--:--"
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

	_day_label.text = "Day %d / %d" % [day, _manager.get_max_days()]
	_phase_label.text = "NIGHT" if is_night else "DAY"
	_phase_label.add_theme_color_override("font_color", NIGHT_PHASE_COLOR if is_night else DAY_PHASE_COLOR)
	_remaining_label.text = _format_seconds(remaining_seconds)

	# The survival timer is not a separate clock; it mirrors the remaining
	# night time already tracked by the manager.
	_survival_label.visible = is_night
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

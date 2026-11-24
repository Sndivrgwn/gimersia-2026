class_name NightSurvivalHUD
extends Control

## Mission 7 + 12: hanya saat malam.
## Dengan jam dunia nyata: "Malam N | HH:MM | Fajar dalam mm:ss | Musuh X/Y".
## Stub/manager lama tanpa `get_clock_text()` tetap memakai "Bertahan mm:ss".

@export var clock: Node
@export var spawner: Node
@export var quota: Node
@export var scaling: NightScalingConfig

var _remaining: float = 0.0
var _day: int = 1
var _label: Label
var _bar: ProgressBar


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_label = Label.new()
	_label.name = "SurvivalLabel"
	add_child(_label)
	_bar = ProgressBar.new()
	_bar.name = "SurvivalBar"
	_bar.max_value = 1.0
	_bar.step = 0.001
	add_child(_bar)
	_bind()


func _process(delta: float) -> void:
	tick(delta)


func tick(_delta: float = 0.0) -> void:
	_bind()
	if not is_night():
		visible = false
		return
	visible = true
	if _label != null:
		_label.text = get_text()
	if _bar != null:
		_bar.value = get_progress_ratio()


func is_night() -> bool:
	return clock != null and clock.has_method(&"is_night") and clock.is_night()


func get_text() -> String:
	if not is_night():
		return ""
	# Mission 12: kalau jam dunia nyata tersedia, tampilkan jam + hitung mundur
	# fajar. Stub/tes lama tanpa get_clock_text tetap memakai teks lama.
	if clock != null and clock.has_method(&"get_clock_text"):
		return "Malam %d | %s | Fajar dalam %s | Musuh %d/%d" % [
			_day, clock.get_clock_text(), format_seconds(_remaining), get_hostile_count(), get_max_enemies()
		]
	return "Malam %d | Bertahan %s | Musuh %d/%d" % [
		_day, format_seconds(_remaining), get_hostile_count(), get_max_enemies()
	]


func get_hostile_count() -> int:
	if spawner != null and spawner.has_method(&"get_hostile_count"):
		return spawner.get_hostile_count()
	if quota != null and quota.has_method(&"get_hostile_count"):
		return quota.get_hostile_count()
	return 0


func get_max_enemies() -> int:
	if scaling != null:
		return scaling.get_max_enemies(_day)
	return 0


func get_progress_ratio() -> float:
	var total := 0.0
	if clock != null and clock.has_method(&"get_phase_duration"):
		total = clock.get_phase_duration()
	if total <= 0.0:
		return 0.0
	return clampf(_remaining / total, 0.0, 1.0)


func set_remaining(seconds: float) -> void:
	_remaining = maxf(seconds, 0.0)


func set_day(day: int) -> void:
	_day = day


func format_seconds(seconds: float) -> String:
	var total := int(maxf(seconds, 0.0))
	return "%02d:%02d" % [total / 60, total % 60]


func _bind() -> void:
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	if clock == null:
		return
	if clock.has_method(&"get_current_day"):
		_day = clock.get_current_day()
	if clock.has_signal(&"time_updated") and not clock.time_updated.is_connected(_on_time_updated):
		clock.time_updated.connect(_on_time_updated)


func _on_time_updated(day: int, _phase: int, remaining_seconds: float) -> void:
	_day = day
	_remaining = maxf(remaining_seconds, 0.0)

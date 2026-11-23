class_name RaidWarningHUD
extends Control

## Mission 9: banner baca-saja saat raid mendekat. Gaya sama dengan NightBanner
## (label di tengah atas, hilang sendiri). Tidak menulis state gameplay apa pun.

const WARNING_TEXT := "Babi hutan mendekati base!"
const FEEDBACK_KIND := &"raid_warning"

@export var director: Node

var _timer: float = 0.0
var _text: String = ""
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_label = Label.new()
	_label.name = "RaidWarningLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.45, 1.0))
	add_child(_label)
	_connect_director()


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if _timer <= 0.0:
		return
	_timer = maxf(_timer - delta, 0.0)
	if _timer <= 0.0:
		visible = false


# --- Read API ---------------------------------------------------------------

func get_text() -> String:
	return _text


func is_showing() -> bool:
	return visible and _timer > 0.0


func get_remaining() -> float:
	return _timer


# --- Hook -------------------------------------------------------------------

func show_warning(seconds: float) -> void:
	_text = WARNING_TEXT
	_timer = maxf(seconds, 0.1)
	if _label != null:
		_label.text = _text
	visible = true
	_emit_feedback()


func _connect_director() -> void:
	if director == null:
		var tree := get_tree()
		if tree != null:
			director = tree.get_first_node_in_group(RaidDirector.GROUP)
	if director == null:
		return
	if director.has_signal(&"raid_warning") and not director.raid_warning.is_connected(_on_raid_warning):
		director.raid_warning.connect(_on_raid_warning)


func _on_raid_warning(_day: int, _count: int, seconds: float) -> void:
	show_warning(seconds)


## Hook event feedback opsional (CombatFeedback.feedback_event bila ada).
func _emit_feedback() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var feedback := tree.get_first_node_in_group(&"combat_feedback")
	if feedback == null or not feedback.has_signal(&"feedback_event"):
		return
	feedback.feedback_event.emit(FEEDBACK_KIND, CampAnchor.center_of(self))

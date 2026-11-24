extends CanvasLayer

## Fase 1A: satu baris tujuan harian di HUD (kiri bawah).
##
## Read-only. Tujuan dibaca dari `daily_goals.tres` dan dievaluasi dari state
## hidup (tas pemain, struktur camp, base), jadi tidak ada progres yang perlu
## disimpan. Tujuan yang sudah selesai diganti tujuan berikutnya; saat semua
## selesai, baris menampilkan "semua tujuan selesai (3/3)".

const CONFIG_PATH := "res://src/data/configs/daily_goals.tres"
const PLAYER_GROUP := &"player"
const REFRESH_INTERVAL := 0.4
const FALLBACK_TEXT := "jelajahi pulau dan siapkan bertahan malam"

@export var config: DailyGoalConfig
@export var clock: Node

var _panel: PanelContainer
var _label: Label
var _player: Node
var _camp: Node
var _anchor: Node
var _timer: float = 0.0
var _last_text: String = ""


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	if config == null:
		config = load(CONFIG_PATH) as DailyGoalConfig
	_build()
	refresh()


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = REFRESH_INTERVAL
	refresh()


# --- API --------------------------------------------------------------------

## Teks baris tujuan saat ini (dipakai tes dan debug).
func get_text() -> String:
	return _last_text


func refresh() -> void:
	if _label == null:
		return
	var day := _current_day()
	var goals: Array[DailyGoal] = []
	if config != null:
		goals = config.get_goals_for_day(day)
	var text := ""
	if goals.is_empty():
		text = "Hari %d: %s" % [day, FALLBACK_TEXT]
	else:
		_bind()
		var met := 0
		var next_goal: DailyGoal = null
		for goal in goals:
			if goal.is_met(_inventory(), _camp, _anchor):
				met += 1
			elif next_goal == null:
				next_goal = goal
		if next_goal == null:
			text = "Hari %d: semua tujuan selesai" % day
		else:
			text = "Hari %d: %s" % [day, next_goal.describe()]
		text += "  (%d/%d)" % [met, goals.size()]
	if text == _last_text:
		return
	_last_text = text
	_label.text = text


# --- Internal ---------------------------------------------------------------

func _current_day() -> int:
	if clock == null:
		clock = get_node_or_null("/root/DayNightManager")
	if clock != null and clock.has_method(&"get_current_day"):
		return int(clock.get_current_day())
	return 1


func _bind() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if _player == null or not is_instance_valid(_player):
		_player = tree.get_first_node_in_group(PLAYER_GROUP)
	if _camp == null or not is_instance_valid(_camp):
		_camp = _find_node_of_type(tree.current_scene, "CampController")
	if _anchor == null or not is_instance_valid(_anchor):
		_anchor = _find_node_of_type(tree.current_scene, "CampAnchor")


func _inventory() -> Node:
	if _player == null or not is_instance_valid(_player):
		return null
	return _player.get_node_or_null("InventoryComponent")


func _find_node_of_type(root: Node, type_name: String) -> Node:
	if root == null:
		return null
	if root.is_class(type_name):
		return root
	var matches := root.find_children("", type_name, true, false)
	return matches[0] if not matches.is_empty() else null


func _build() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_panel = PanelContainer.new()
	_panel.name = "GoalPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 16.0
	_panel.offset_right = 620.0
	_panel.offset_top = -46.0
	_panel.offset_bottom = -16.0
	_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	_label = Label.new()
	_label.name = "GoalLabel"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color(0.94, 0.89, 0.72, 1.0))
	_label.clip_text = true
	margin.add_child(_label)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.1, 0.78)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.78, 0.55, 0.4)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style

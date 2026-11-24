extends CanvasLayer

## Fase 1A: satu baris tujuan harian di HUD (bawah tengah, di atas hotbar).
##
## Read-only. Tujuan dibaca dari `daily_goals.tres` dan dievaluasi dari state
## hidup (tas pemain, struktur camp, base), jadi tidak ada progres yang perlu
## disimpan. Semua tujuan hari itu tampil dalam satu baris; tujuan yang sudah
## selesai dicoret dan ikut dihitung pada `(n/m)`.

const CONFIG_PATH := "res://src/data/configs/daily_goals.tres"
const PLAYER_GROUP := &"player"
const REFRESH_INTERVAL := 0.4
const FALLBACK_TEXT := "jelajahi pulau dan siapkan bertahan malam"
## Warna tujuan yang sudah selesai (dicoret) dan penghitung (n/m).
const DONE_HEX := "8f9499"
const COUNT_HEX := "b8b094"
const GOAL_SEPARATOR := ", "

@export var config: DailyGoalConfig
@export var clock: Node

var _panel: PanelContainer
var _label: RichTextLabel
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

## Teks baris tujuan saat ini tanpa markup (dipakai tes dan debug).
func get_text() -> String:
	return _last_text


func refresh() -> void:
	if _label == null:
		return
	var day := _current_day()
	var goals: Array[DailyGoal] = []
	if config != null:
		goals = config.get_goals_for_day(day)
	var plain := ""
	var rich := ""
	if goals.is_empty():
		plain = "Hari %d: %s" % [day, FALLBACK_TEXT]
		rich = plain
	else:
		_bind()
		var inventory := _inventory()
		var met := 0
		var plain_parts: Array[String] = []
		var rich_parts: Array[String] = []
		for goal in goals:
			var done := goal.is_met(inventory, _camp, _anchor)
			if done:
				met += 1
			plain_parts.append(goal.describe())
			if done:
				rich_parts.append("[s][color=#%s]%s[/color][/s]" % [DONE_HEX, goal.describe()])
			else:
				rich_parts.append(goal.describe())
		plain = "Hari %d: %s  (%d/%d)" % [day, GOAL_SEPARATOR.join(plain_parts), met, goals.size()]
		rich = "Hari %d: %s  [color=#%s](%d/%d)[/color]" % [
			day, GOAL_SEPARATOR.join(rich_parts), COUNT_HEX, met, goals.size()
		]
	if plain == _last_text:
		return
	_last_text = plain
	_label.text = rich


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

	# Bawah tengah, persis di atas hotbar dan prompt interaksi (tidak menimpa
	# StatsHUD di kiri bawah).
	_panel = PanelContainer.new()
	_panel.name = "GoalPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -310.0
	_panel.offset_right = 310.0
	_panel.offset_top = -226.0
	_panel.offset_bottom = -198.0
	_panel.clip_contents = true
	_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	_label = RichTextLabel.new()
	_label.name = "GoalLabel"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.bbcode_enabled = true
	_label.scroll_active = false
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.custom_minimum_size = Vector2(0.0, 20.0)
	_label.add_theme_font_size_override("normal_font_size", 15)
	_label.add_theme_color_override("default_color", Color(0.94, 0.89, 0.72, 1.0))
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

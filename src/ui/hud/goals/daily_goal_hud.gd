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

	# Kanan atas: panel quest harian dengan tekstur walnut.
	_panel = PanelContainer.new()
	_panel.name = "GoalPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_panel.offset_left = -372.0
	_panel.offset_right = -20.0
	_panel.offset_top = 20.0
	_panel.offset_bottom = 122.0
	_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var header := Label.new()
	header.text = "QUEST HARIAN"
	header.add_theme_font_size_override("font_size", 13)
	header.add_theme_color_override("font_color", Color(0.922, 0.761, 0.451, 1.0))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header)

	_label = RichTextLabel.new()
	_label.name = "GoalLabel"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.bbcode_enabled = true
	_label.scroll_active = false
	_label.fit_content = true
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(300.0, 24.0)
	_label.add_theme_font_size_override("normal_font_size", 15)
	_label.add_theme_color_override("default_color", Color(0.968627, 0.945098, 0.898039, 1.0))
	vbox.add_child(_label)


func _panel_style() -> StyleBox:
	var tex_path := "res://assets/textures/ui/02_panel/panel_walnut_stitched.png"
	if ResourceLoader.exists(tex_path):
		var tex := load(tex_path) as Texture2D
		if tex != null:
			var box := StyleBoxTexture.new()
			box.texture = tex
			box.texture_margin_left = 24.0
			box.texture_margin_top = 24.0
			box.texture_margin_right = 24.0
			box.texture_margin_bottom = 24.0
			box.content_margin_left = 24.0
			box.content_margin_top = 20.0
			box.content_margin_right = 24.0
			box.content_margin_bottom = 20.0
			return box
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.11, 0.08, 0.88)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.85, 0.78, 0.55, 0.5)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

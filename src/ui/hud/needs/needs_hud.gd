extends CanvasLayer

const UiMotion := preload("res://src/ui/fx/ui_motion.gd")

## Read-only HUD untuk Hunger/Thirst/Fatigue.
##
## Hanya membaca NeedsComponent (lewat sinyal dan getter) dan tidak menyimpan
## atau menulis state gameplay. CanvasLayer menjaga bar tetap di luar canvas
## dunia, sehingga tint CanvasModulate DayNightVisual tidak menggelapkan HUD.

const PLAYER_GROUP := &"player"
const COMPONENT_NAME := "NeedsComponent"
const NORMAL_COLOR := Color(0.45, 0.82, 0.55, 0.9)
const WARNING_COLOR := Color(0.92, 0.45, 0.35, 0.95)
const NORMAL_TEXT := Color(0.92, 0.96, 0.9, 1.0)
const WARNING_TEXT := Color(1.0, 0.66, 0.52, 1.0)
const ROW_PATHS: Array[String] = [
	"Root/Panel/Margin/VBox/Hunger",
	"Root/Panel/Margin/VBox/Thirst",
	"Root/Panel/Margin/VBox/Fatigue",
]
const NEED_SLUGS: Array[String] = ["hunger", "thirst", "fatigue"]
const ICON_SIZE := Vector2(16.0, 16.0)

## Opsional; bila kosong dicari lewat grup "player" -> NeedsComponent.
@export var needs_component: NeedsComponent

var _name_labels: Array[Label] = []
var _value_labels: Array[Label] = []
var _bars: Array[ProgressBar] = []
var _fills: Array[StyleBoxFlat] = []
var _hp_bar: ProgressBar
var _hp_value: Label
var _stats_component: StatsComponent


func _ready() -> void:
	_collect_rows()
	_hp_bar = get_node_or_null("Root/Panel/Margin/VBox/HP/Bar") as ProgressBar
	_hp_value = get_node_or_null("Root/Panel/Margin/VBox/HP/Value") as Label
	_bind_hp()

	if needs_component == null:
		needs_component = _find_component()
	if needs_component == null:
		push_warning("NeedsHUD: NeedsComponent tidak ditemukan.")
		return

	for bar in _bars:
		bar.max_value = needs_component.get_config().max_value

	needs_component.value_changed.connect(_on_value_changed)
	needs_component.tier_changed.connect(_on_tier_changed)

	for need in _bars.size():
		_refresh(need, needs_component.get_value(need), needs_component.get_tier(need))


func _collect_rows() -> void:
	for path in ROW_PATHS:
		var row := get_node_or_null(path)
		if row == null:
			push_warning("NeedsHUD: baris '%s' tidak ditemukan." % path)
			continue
		_name_labels.append(row.get_node_or_null("Name") as Label)
		_bars.append(row.get_node_or_null("Bar") as ProgressBar)
		_value_labels.append(row.get_node_or_null("Value") as Label)

		var fill := _bars[-1].get_theme_stylebox("fill")
		_fills.append(fill.duplicate() as StyleBoxFlat if fill is StyleBoxFlat else null)
		_add_icon(row, _bars.size() - 1)


## Ikon di kiri baris hanya dibuat bila art-nya ada (tanpa art: tidak ada node).
func _add_icon(row: Control, index: int) -> void:
	if row.has_node("Icon"):
		return
	var texture := Assets.ui_texture(StringName("ui_icon_%s" % NEED_SLUGS[index]))
	if texture == null:
		return
	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = texture
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	row.move_child(icon, 0)


func _bind_hp() -> void:
	if _hp_bar == null:
		return
	var tree := get_tree()
	if tree == null:
		return
	var player := tree.get_first_node_in_group(PLAYER_GROUP)
	if player == null:
		return
	_stats_component = player.get("stats") as StatsComponent
	if _stats_component == null:
		return
	if not _stats_component.hp_changed.is_connected(_on_hp_changed):
		_stats_component.hp_changed.connect(_on_hp_changed)
	if not _stats_component.stats_changed.is_connected(_on_stats_changed):
		_stats_component.stats_changed.connect(_on_stats_changed)
	_on_hp_changed(_stats_component.current_hp, _stats_component.get_max_hp())


func _on_stats_changed() -> void:
	if _stats_component != null:
		_on_hp_changed(_stats_component.current_hp, _stats_component.get_max_hp())


func _on_hp_changed(current: float, max_hp: float) -> void:
	if _hp_bar == null:
		return
	_hp_bar.max_value = maxf(max_hp, 1.0)
	UiMotion.tween_bar(_hp_bar, current)
	if _hp_value != null:
		_hp_value.text = "%d" % int(roundf(current))
		var low := max_hp > 0.0 and (current / max_hp) <= 0.3
		_hp_value.add_theme_color_override("font_color", WARNING_TEXT if low else NORMAL_TEXT)


func _find_component() -> NeedsComponent:
	var tree := get_tree()
	if tree == null:
		return null
	var candidate := tree.get_first_node_in_group(PLAYER_GROUP)
	if candidate == null:
		return null
	return candidate.get_node_or_null(COMPONENT_NAME) as NeedsComponent


func _on_value_changed(need: int, value: float) -> void:
	_refresh(need, value, needs_component.get_tier(need))


func _on_tier_changed(need: int, _tier: int) -> void:
	_refresh(need, needs_component.get_value(need), needs_component.get_tier(need))


func _refresh(need: int, value: float, tier: int) -> void:
	if need < 0 or need >= _bars.size():
		return

	var is_warning := tier != NeedsComponent.Tier.NORMAL
	var text_color := WARNING_TEXT if is_warning else NORMAL_TEXT

	UiMotion.tween_bar(_bars[need], value)
	var fill_key := StringName("fill_%s" % NEED_SLUGS[need])
	if _bars[need].has_theme_stylebox(fill_key):
		_bars[need].add_theme_stylebox_override("fill", _bars[need].get_theme_stylebox(fill_key))
	elif _fills[need] != null:
		_fills[need].bg_color = WARNING_COLOR if is_warning else NORMAL_COLOR
		_bars[need].add_theme_stylebox_override("fill", _fills[need])

	_value_labels[need].text = "%d" % int(roundf(value))
	_value_labels[need].add_theme_color_override("font_color", text_color)
	_name_labels[need].add_theme_color_override("font_color", text_color)

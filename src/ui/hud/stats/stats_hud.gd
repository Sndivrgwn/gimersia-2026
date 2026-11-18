extends CanvasLayer

## Read-only HUD angka stat Player (StatsComponent) + tier needs.
##
## Untuk melihat efek Hunger/Thirst/Fatigue LOW/ZERO secara langsung: move speed,
## attack, gather time, dan sprint drain berubah di panel ini. HUD tidak
## menyimpan state gameplay dan tidak menulis apa pun.

const PLAYER_GROUP := &"player"
const NEEDS_NAME := "NeedsComponent"
## Urutan sama dengan enum NeedsComponent.Need.
const NEED_NAMES: Array[String] = ["HUNGER", "THIRST", "FATIGUE"]
const NORMAL_COLOR := Color(0.88, 0.93, 0.88, 1.0)
const WARNING_COLOR := Color(1.0, 0.66, 0.52, 1.0)

## Opsional; bila kosong dicari lewat grup "player".
@export var player: Player

@onready var _stats_label: Label = $Root/Panel/Margin/VBox/StatsLabel
@onready var _tier_label: Label = $Root/Panel/Margin/VBox/TierLabel

var _stats: StatsComponent
var _needs: NeedsComponent


func _ready() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group(PLAYER_GROUP) as Player
	if player == null or player.stats == null:
		push_warning("StatsHUD: Player atau StatsComponent tidak ditemukan.")
		return

	_stats = player.stats
	_needs = player.get_node_or_null(NEEDS_NAME) as NeedsComponent

	_stats.stats_changed.connect(_refresh)
	_stats.hp_changed.connect(_refresh.unbind(2))
	if _needs != null:
		_needs.tier_changed.connect(_refresh.unbind(2))
	_refresh()


func _refresh() -> void:
	_stats_label.text = "\n".join(PackedStringArray([
		"HP           %.0f / %.0f" % [_stats.current_hp, _stats.get_max_hp()],
		"Move speed   %.0f" % _stats.get_move_speed(),
		"Sprint speed %.0f" % _stats.get_sprint_speed(),
		"Attack dmg   %.1f" % _stats.get_attack_damage(),
		"Attack speed %.2f/s" % _stats.get_attack_speed(),
		"Gather time  x%.2f" % _stats.get_gather_time_factor(),
		"Sprint drain x%.2f" % _stats.get_sprint_fatigue_drain_factor(),
	]))

	var parts := PackedStringArray()
	var warned := false
	for index in NEED_NAMES.size():
		var tier := _needs.get_tier(index) if _needs != null else NeedsComponent.Tier.NORMAL
		parts.append("%s %s" % [NEED_NAMES[index], _tier_name(tier)])
		warned = warned or tier != NeedsComponent.Tier.NORMAL

	_tier_label.text = "   ".join(parts)
	_tier_label.add_theme_color_override("font_color", WARNING_COLOR if warned else NORMAL_COLOR)


func _tier_name(tier: int) -> String:
	match tier:
		NeedsComponent.Tier.LOW:
			return "LOW"
		NeedsComponent.Tier.ZERO:
			return "ZERO"
		_:
			return "NORMAL"

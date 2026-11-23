extends GutTest

## Mission 9: daftar profisiensi ada di panel tas (Tab/I), tab ketiga.

const BAG_SCENE: PackedScene = preload("res://src/ui/panels/inventory/bag_panel.tscn")
const PROF_CONFIG: ProficiencyConfig = preload("res://src/data/configs/proficiency_config.tres")

var player: Node2D
var proficiency: ProficiencyComponent
var bag: CanvasLayer


func before_each() -> void:
	player = Node2D.new()
	player.name = "Player"
	player.add_to_group(&"player")
	add_child_autofree(player)
	var stats := StatsComponent.new()
	stats.name = "StatsComponent"
	player.add_child(stats)
	proficiency = ProficiencyComponent.new()
	proficiency.name = "ProficiencyComponent"
	proficiency.config = PROF_CONFIG
	player.add_child(proficiency)
	proficiency.setup(player)

	bag = BAG_SCENE.instantiate() as CanvasLayer
	add_child_autofree(bag)


func test_proficiency_tab_exists_next_to_bag_and_crafting() -> void:
	var tabs := bag.get_node("Root/Frame/Margin/VBox/Tabs") as TabContainer
	assert_eq(tabs.get_tab_count(), 3, "Tas + Crafting + Profisiensi")
	assert_not_null(bag.get_proficiency_tab(), "tab profisiensi ada")
	assert_eq(bag.get_proficiency_tab().name, "Profisiensi")


func test_rows_show_level_xp_and_passive() -> void:
	var row: Node = bag.get_proficiency_tab().get_node("Rows/Prof0")
	var title := row.get_child(0) as Label
	assert_string_contains(title.text, "Kekuatan")
	assert_string_contains(title.text, "Lv 1")
	assert_string_contains(title.text, "XP")
	var passive := row.get_child(2) as Label
	assert_string_contains(passive.text, "Heavy Strike")
	assert_string_contains(passive.text, "Lv 3", "passive belum terbuka di level 1")


func test_refresh_follows_proficiency_xp() -> void:
	var stats := player.get_node("StatsComponent") as StatsComponent
	stats.strength_level = 3
	bag.refresh_proficiency()
	var title: Label = bag.get_proficiency_tab().get_node("Rows/Prof0").get_child(0)
	assert_string_contains(title.text, "Lv 3")
	var passive: Label = bag.get_proficiency_tab().get_node("Rows/Prof0").get_child(2)
	assert_string_contains(passive.text, "terbuka", "Heavy Strike terbuka di Lv 3")

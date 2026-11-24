extends GutTest

## Panel tas hanya punya tab Tas + Crafting; tab Profisiensi sudah dihapus.

const BAG_SCENE: PackedScene = preload("res://src/ui/panels/inventory/bag_panel.tscn")

var bag: CanvasLayer


func before_each() -> void:
	bag = BAG_SCENE.instantiate() as CanvasLayer
	add_child_autofree(bag)


func test_bag_has_only_tas_and_crafting_tabs() -> void:
	var tabs := bag.get_node("Root/Frame/Margin/VBox/Tabs") as TabContainer
	assert_eq(tabs.get_tab_count(), 2, "Tas + Crafting")
	assert_eq(tabs.get_tab_title(0), "Tas")
	assert_eq(tabs.get_tab_title(1), "Crafting")
	assert_null(tabs.get_node_or_null("Profisiensi"), "tab Profisiensi sudah dihapus")

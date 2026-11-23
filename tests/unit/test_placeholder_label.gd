extends GutTest

## Mission 9: selama art masih kosong, nama slot muncul di dekat pemain supaya
## bentuk polos tidak membingungkan. Satu overlay HUD, kolam label terbatas.

var hud: PlaceholderLabels
var player: Node2D


func before_each() -> void:
	player = Node2D.new()
	player.name = "Player"
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2.ZERO

	hud = PlaceholderLabels.new()
	add_child_autofree(hud)
	hud.player = player


func _slot(key: StringName, at: Vector2 = Vector2(40.0, 0.0)) -> VisualSlot:
	var node := Node2D.new()
	add_child_autofree(node)
	node.global_position = at
	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8),
	])
	node.add_child(polygon)
	return VisualSlot.attach(node, key, [polygon])


func test_nearby_placeholder_shows_its_key() -> void:
	_slot(&"tree")
	hud.refresh()
	assert_has(hud.get_visible_texts(), "tree")
	assert_eq(hud.get_visible_count(), 1)


func test_ground_slots_are_skipped() -> void:
	_slot(&"ground_forest")
	hud.refresh()
	assert_eq(hud.get_visible_count(), 0, "tanah tidak diberi label")


func test_far_slots_are_hidden() -> void:
	var slot := _slot(&"tree")
	(slot.get_parent() as Node2D).global_position = Vector2(PlaceholderLabels.RANGE + 100.0, 0.0)
	hud.refresh()
	assert_eq(hud.get_visible_count(), 0)


func test_label_pool_is_capped() -> void:
	for index in PlaceholderLabels.MAX_LABELS + 4:
		_slot(&"rock", Vector2(20.0 + index, 0.0))
	hud.refresh()
	assert_eq(hud.get_visible_count(), PlaceholderLabels.MAX_LABELS, "kolam label dibatasi")


func test_disabled_hides_everything() -> void:
	_slot(&"tree")
	hud.enabled = false
	hud.refresh()
	assert_eq(hud.get_visible_count(), 0)

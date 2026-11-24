extends GutTest

## Fase 4C: membangun base — pusat di-snap 16 px (sudah ada) dan ring pagar
## bisa diputar 15° sebelum base ditentukan supaya tidak menabrak sungai/tepi.

const FENCE: FenceConfig = preload("res://src/data/configs/fence_config.tres")
const IslandHarness = preload("res://tests/integration/island_harness.gd")

var SITE: BaseSiteConfig = BaseSiteConfig.new()


func test_rotation_action_is_q_and_documented() -> void:
	InputSetup.ensure_actions()
	assert_true(InputMap.has_action(InputSetup.BASE_ROTATE), "base_rotate terdaftar")
	var has_q := false
	for event in InputMap.action_get_events(InputSetup.BASE_ROTATE):
		var key := event as InputEventKey
		if key != null and key.physical_keycode == KEY_Q:
			has_q = true
	assert_true(has_q, "Q memutar ring")

	var generator := InputGuideGenerator.new()
	assert_false(
		generator.missing_purposes().has("base_rotate"),
		"base_rotate harus punya tujuan di PURPOSES"
	)


func test_layout_rotation_keeps_radius_and_moves_segments() -> void:
	var center := Vector2(700.0, 300.0)
	var base := FenceRing.layout(center, FENCE)
	var turned := FenceRing.layout(center, FENCE, PI / 12.0)
	assert_eq(turned.size(), base.size())

	for index in base.size():
		var a: Vector2 = base[index]["position"]
		var b: Vector2 = turned[index]["position"]
		assert_almost_eq(a.distance_to(center), b.distance_to(center), 0.01, "radius tetap")
		assert_gt(a.distance_to(b), 1.0, "segmen benar-benar berputar")


func test_preview_uses_rotation_and_stays_valid() -> void:
	var result := BasePlacementPreview.compute(Vector2(700.0, 300.0), SITE, FENCE, false, PI / 12.0)
	assert_true(bool(result["valid"]), "rotasi 15° tetap valid di darat")
	assert_eq((result["fence_segments"] as Array).size(), FENCE.segment_count)

	var straight := BasePlacementPreview.compute(Vector2(700.0, 300.0), SITE, FENCE)
	var first: Vector2 = result["fence_segments"][0]["position"]
	var first_straight: Vector2 = straight["fence_segments"][0]["position"]
	assert_gt(first.distance_to(first_straight), 1.0)


func test_controller_rotates_preview_and_confirm_stores_rotation() -> void:
	var player := Node2D.new()
	add_child_autofree(player)
	player.global_position = Vector2(1000.0, 500.0)

	var anchor := CampAnchor.new()
	add_child_autofree(anchor)
	var controller := BasePlacementController.new()
	controller.player = player
	controller.anchor = anchor
	player.add_child(controller)
	await get_tree().process_frame

	controller.start_preview()
	controller.set_preview_position(Vector2(1000.0, 500.0))
	assert_almost_eq(controller.get_rotation(), 0.0, 0.001)

	controller.rotate_ring()
	assert_almost_eq(controller.get_rotation(), BasePlacementController.ROTATE_STEP, 0.001)
	assert_eq(anchor.get_center(), Vector2.ZERO, "belum terpasang")

	assert_true(controller.confirm())
	assert_almost_eq(
		anchor.get_fence_rotation(),
		BasePlacementController.ROTATE_STEP,
		0.001,
		"rotasi tersimpan di anchor"
	)


func test_fence_ring_follows_anchor_rotation() -> void:
	var harness := IslandHarness.new()
	harness.setup(self)
	var center := Vector2(700.0, 300.0)
	var angle := PI / 12.0
	harness.anchor.found(center, angle)

	var ring := harness.island.get_node("CampController/FenceRing") as FenceRing
	assert_almost_eq(ring.get_ring_rotation(), angle, 0.001)

	var slots := ring.get_slots()
	var expected := BasePlacementPreview.compute(center, SITE, FENCE, false, angle)
	var segments: Array = expected["fence_segments"]
	assert_eq(slots.size(), segments.size())
	for index in slots.size():
		var point: Vector2 = segments[index]["position"]
		assert_almost_eq(slots[index].global_position.x, point.x, 0.5)
		assert_almost_eq(slots[index].global_position.y, point.y, 0.5)
	harness.teardown()

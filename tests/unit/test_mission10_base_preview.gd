extends GutTest

## Mission 10 Phase 1: satu alur penempatan camp + pagar dengan preview.

const FENCE: FenceConfig = preload("res://src/data/configs/fence_config.tres")
const IslandHarness = preload("res://tests/integration/island_harness.gd")

var SITE: BaseSiteConfig = BaseSiteConfig.new()


func test_valid_center_has_ring_segments_and_core_slots() -> void:
	var result := BasePlacementPreview.compute(Vector2(700.0, 300.0), SITE, FENCE)
	assert_true(bool(result["valid"]), "titik di darat valid")
	assert_eq(String(result["reason"]), "")
	assert_eq((result["fence_segments"] as Array).size(), FENCE.segment_count)
	assert_eq((result["core_slots"] as Array).size(), 4)
	var labels := PackedStringArray()
	for slot in result["core_slots"]:
		labels.append(String(slot["label"]))
	assert_has(labels, "Meja Kerja")
	assert_has(labels, "Api Unggun")


func test_ring_radius_single_source_is_fence_config() -> void:
	assert_almost_eq(BaseSiteRules.ring_radius(SITE), FENCE.ring_radius, 0.01)
	assert_almost_eq(BasePlacementPreview.fence_radius(FENCE), FENCE.ring_radius, 0.01)


func test_fence_outside_island_invalidates_preview() -> void:
	var result := BasePlacementPreview.compute(Vector2(2050.0, 0.0), SITE, FENCE)
	assert_false(bool(result["valid"]))
	assert_eq(String(result["reason"]), BasePlacementPreview.REASON_FENCE_OUTSIDE)
	var invalid := 0
	for entry in result["fence_segments"]:
		if not bool(entry["valid"]):
			invalid += 1
	assert_gt(invalid, 0, "ada segmen merah")


func test_fence_hitting_river_invalidates_preview() -> void:
	var site := BaseSiteConfig.new()
	site.river_clearance = 0.0
	var wide := FenceConfig.new()
	wide.ring_radius = 300.0
	var result := BasePlacementPreview.compute(Vector2(-550.0, 0.0), site, wide)
	assert_false(bool(result["valid"]))
	assert_eq(String(result["reason"]), BasePlacementPreview.REASON_FENCE_RIVER)


func test_locked_base_reports_existing_reason() -> void:
	var result := BasePlacementPreview.compute(Vector2(700.0, 300.0), SITE, FENCE, true)
	assert_false(bool(result["valid"]))
	assert_eq(String(result["reason"]), BaseSiteRules.REASON_LOCKED)


func test_preview_matches_real_ring_after_founding() -> void:
	var harness := IslandHarness.new()
	harness.setup(self)
	var center := Vector2(700.0, 300.0)
	harness.anchor.found(center)
	var ring := harness.island.get_node("CampController/FenceRing") as FenceRing
	var slots := ring.get_slots()
	var result := BasePlacementPreview.compute(center, SITE, FENCE)
	var segments: Array = result["fence_segments"]
	assert_eq(slots.size(), segments.size(), "jumlah segmen preview = ring asli")
	for index in slots.size():
		var expected: Vector2 = segments[index]["position"]
		assert_almost_eq(slots[index].global_position.x, expected.x, 0.5)
		assert_almost_eq(slots[index].global_position.y, expected.y, 0.5)
	harness.teardown()


func test_single_placement_action_is_base_place() -> void:
	InputSetup.ensure_actions()
	assert_true(InputMap.has_action(InputSetup.BASE_PLACE), "base_place terdaftar")
	var events := InputMap.action_get_events(InputSetup.BASE_PLACE)
	var has_b := false
	for event in events:
		var key := event as InputEventKey
		if key != null and key.physical_keycode == KEY_B:
			has_b = true
	assert_true(has_b, "B adalah satu-satunya tombol penempatan")
	assert_eq(InputSetup.BASE_PLACE, &"base_place")

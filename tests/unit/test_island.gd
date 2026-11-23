extends GutTest

## Tes Phase C bagian layout: IslandZones + IslandBuilder (determinisme,
## jumlah node per zona, jarak, keep-out, marker malam).

var builder: IslandBuilder
var layout: IslandLayoutConfig


func before_each() -> void:
	layout = IslandLayoutConfig.new()
	builder = IslandBuilder.new()
	builder.layout = layout
	builder.auto_build = false
	add_child_autofree(builder)


func after_each() -> void:
	builder = null
	layout = null


# --- IslandZones ------------------------------------------------------------

func test_camp_zone_uses_radius_800() -> void:
	assert_eq(IslandZones.zone_at(Vector2.ZERO), IslandZones.Zone.CAMP)
	assert_eq(IslandZones.zone_at(Vector2(800.0, 0.0)), IslandZones.Zone.CAMP)
	assert_eq(IslandZones.zone_at(Vector2(0.0, 799.0)), IslandZones.Zone.CAMP)
	assert_eq(IslandZones.zone_at(Vector2(801.0, 0.0)), IslandZones.Zone.FOREST)


func test_south_beach_uses_y_above_1400() -> void:
	assert_eq(IslandZones.zone_at(Vector2(0.0, 1400.0)), IslandZones.Zone.FOREST)
	assert_eq(IslandZones.zone_at(Vector2(0.0, 1400.5)), IslandZones.Zone.SOUTH_BEACH)


func test_east_beach_boundaries() -> void:
	assert_eq(IslandZones.zone_at(Vector2(1400.0, 0.0)), IslandZones.Zone.FOREST)
	assert_eq(IslandZones.zone_at(Vector2(1400.5, 0.0)), IslandZones.Zone.EAST_BEACH)
	assert_eq(IslandZones.zone_at(Vector2(1400.5, 1400.0)), IslandZones.Zone.EAST_BEACH)
	assert_eq(IslandZones.zone_at(Vector2(1400.5, 1400.5)), IslandZones.Zone.SOUTH_BEACH)
	assert_eq(IslandZones.zone_at(Vector2(2400.0, 0.0)), IslandZones.Zone.EAST_BEACH)


func test_west_cliffs_boundaries() -> void:
	assert_eq(IslandZones.zone_at(Vector2(-1400.0, 0.0)), IslandZones.Zone.FOREST)
	assert_eq(IslandZones.zone_at(Vector2(-1400.5, 0.0)), IslandZones.Zone.WEST_CLIFFS)
	assert_eq(IslandZones.zone_at(Vector2(-1400.5, 1400.5)), IslandZones.Zone.SOUTH_BEACH)


func test_river_strip_and_order() -> void:
	assert_eq(IslandZones.zone_at(Vector2(-950.0, 0.0)), IslandZones.Zone.RIVER)
	assert_eq(IslandZones.zone_at(Vector2(-1050.0, 0.0)), IslandZones.Zone.RIVER)
	assert_eq(IslandZones.zone_at(Vector2(-850.0, 0.0)), IslandZones.Zone.RIVER)
	assert_eq(IslandZones.zone_at(Vector2(-1050.5, 0.0)), IslandZones.Zone.FOREST)
	assert_eq(IslandZones.zone_at(Vector2(-950.0, 1400.0)), IslandZones.Zone.RIVER)
	assert_eq(IslandZones.zone_at(Vector2(-950.0, 1400.5)), IslandZones.Zone.SOUTH_BEACH)


func test_outside_square() -> void:
	assert_eq(IslandZones.zone_at(Vector2(2401.0, 0.0)), IslandZones.Zone.OUTSIDE)
	assert_eq(IslandZones.zone_at(Vector2(0.0, -2401.0)), IslandZones.Zone.OUTSIDE)
	assert_eq(IslandZones.zone_at(Vector2(-2401.0, -2401.0)), IslandZones.Zone.OUTSIDE)


func test_zone_centers_are_inside_their_zone() -> void:
	for zone in [
		IslandZones.Zone.CAMP,
		IslandZones.Zone.SOUTH_BEACH,
		IslandZones.Zone.EAST_BEACH,
		IslandZones.Zone.WEST_CLIFFS,
		IslandZones.Zone.RIVER,
		IslandZones.Zone.FOREST,
	]:
		assert_eq(IslandZones.zone_at(IslandZones.zone_center(zone)), zone, "zona %d" % zone)


# --- Layout -----------------------------------------------------------------

func test_counts_per_zone() -> void:
	var counts := _count_by_zone(_resource_entries(builder.plan()))
	assert_eq(counts.get(IslandZones.Zone.CAMP, 0), 33, "camp starter: 10 twig + 8 rock + 5 fiber + 4 berry + 6 small tree")
	assert_eq(counts.get(IslandZones.Zone.SOUTH_BEACH, 0), 12, "12 coconut palm")
	assert_eq(counts.get(IslandZones.Zone.WEST_CLIFFS, 0), 22, "14 small + 8 big rock")
	assert_eq(counts.get(IslandZones.Zone.RIVER, 0), 14, "14 bamboo")
	assert_eq(counts.get(IslandZones.Zone.FOREST, 0), 72, "30 tree + 24 fiber + 18 berry")


func test_rock_split_in_west_cliffs() -> void:
	var small := 0
	var big := 0
	for entry in builder.plan():
		if entry["zone"] != IslandZones.Zone.WEST_CLIFFS:
			continue
		if entry["definition"].id == &"small_rock":
			small += 1
		elif entry["definition"].id == &"big_rock":
			big += 1
	assert_eq(small, 14)
	assert_eq(big, 8)


func test_every_entry_is_inside_its_own_zone() -> void:
	var mismatches := 0
	for entry in builder.plan():
		if IslandZones.zone_at(entry["position"]) != entry["zone"]:
			mismatches += 1
	assert_eq(mismatches, 0, "zone_at(pos) harus sama dengan zona target")


func test_nodes_respect_min_spacing() -> void:
	var entries := builder.plan()
	var closest := INF
	for i in entries.size():
		var a: Vector2 = entries[i]["position"]
		for j in range(i + 1, entries.size()):
			closest = minf(closest, a.distance_to(entries[j]["position"]))
	assert_gte(closest, layout.min_spacing - 0.01, "jarak minimum antar node/marker")


func test_keep_out_points_and_beacon_are_clear() -> void:
	var entries := builder.plan()
	var closest_spawn := INF
	var closest_beacon := INF
	for entry in entries:
		var point: Vector2 = entry["position"]
		for keep_out in IslandBuilder.KEEP_OUT_POINTS:
			closest_spawn = minf(closest_spawn, point.distance_to(keep_out))
		closest_beacon = minf(closest_beacon, point.distance_to(IslandZones.BEACON_POSITION))
	assert_gte(closest_spawn, layout.keep_out_radius - 0.01, "keep-out spawn/wreckage/koper")
	assert_gte(closest_beacon, layout.beacon_keep_out - 0.01, "keep-out beacon")


func test_camp_starters_stay_in_ring_and_expire_after_day_4() -> void:
	var inside := 0
	var expired := 0
	for entry in builder.plan():
		if entry["zone"] != IslandZones.Zone.CAMP:
			continue
		inside += 1
		var distance: float = entry["position"].length()
		assert_between(distance, layout.camp_ring_min - 0.01, layout.camp_ring_max + 0.01)
		if entry["last_respawn_day"] == layout.camp_starters_last_respawn_day:
			expired += 1
	assert_eq(inside, 33)
	assert_eq(expired, 33, "semua starter Zone 1 hilang setelah hari 4")


func test_layout_is_deterministic_for_same_seed() -> void:
	var first := builder.plan()
	var second := builder.plan()
	var first_positions: Array[Vector2] = []
	for entry in first:
		first_positions.append(entry["position"])
	var differences := 0
	for index in second.size():
		if second[index]["position"] != first_positions[index]:
			differences += 1
	assert_eq(differences, 0, "seed sama -> posisi sama")


func test_other_seed_moves_nodes() -> void:
	var first := builder.plan()
	layout.layout_seed = 7
	var second := builder.plan()
	var differences := 0
	for index in mini(first.size(), second.size()):
		if second[index]["position"] != first[index]["position"]:
			differences += 1
	assert_gt(differences, 100, "seed berbeda -> layout berbeda")


func test_night_spawn_markers() -> void:
	var markers := 0
	for entry in builder.plan():
		if entry["kind"] != IslandBuilder.KIND_MARKER:
			continue
		markers += 1
		assert_eq(entry["zone"], IslandZones.Zone.FOREST)
		assert_gte(entry["position"].length(), layout.markers_min_distance - 0.01)
	assert_eq(markers, layout.night_spawn_markers)


func test_build_spawns_resource_nodes_and_markers() -> void:
	var target := Node2D.new()
	add_child_autofree(target)
	var entries := builder.build(target)

	assert_eq(target.get_child_count(), entries.size())
	var resources := 0
	var markers := 0
	var interactables := 0
	for child in target.get_children():
		if child is ResourceNode:
			resources += 1
			if child.is_in_group(&"interactable"):
				interactables += 1
		elif child is Marker2D and child.is_in_group(IslandBuilder.NIGHT_SPAWN_GROUP):
			markers += 1
	assert_eq(resources, 153)
	assert_eq(markers, 16)
	assert_eq(interactables, 153, "setiap ResourceNode terdaftar di grup interactable")


# --- Helper -----------------------------------------------------------------

func _resource_entries(entries: Array[Dictionary]) -> Array[Dictionary]:
	var resources: Array[Dictionary] = []
	for entry in entries:
		if entry["kind"] == IslandBuilder.KIND_RESOURCE:
			resources.append(entry)
	return resources


func _count_by_zone(entries: Array[Dictionary]) -> Dictionary:
	var counts := {}
	for entry in entries:
		var zone: int = entry["zone"]
		counts[zone] = int(counts.get(zone, 0)) + 1
	return counts

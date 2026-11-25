extends GutTest

## Phase 3 (D2): geometri pagar, ring, dan boar yang sadar pagar.

class StubInteractor extends Node:
	var inventory: InventoryComponent
	func _init() -> void:
		inventory = InventoryComponent.new()
		add_child(inventory)
	func get_inventory() -> InventoryComponent:
		return inventory

class StubClock extends Node:
	func is_night() -> bool: return true
	func get_current_day() -> int: return 1
	func get_time_scale() -> float: return 1.0

class StubPlayer extends Node2D:
	var stats: StatsComponent
	var receiver: PlayerDamageReceiver
	var facing_direction := Vector2.RIGHT
	var knockback_multiplier := 1.0
	func _init() -> void:
		stats = StatsComponent.new()
		stats.name = "StatsComponent"
		add_child(stats)
		receiver = PlayerDamageReceiver.new()
		receiver.name = "PlayerDamageReceiver"
		add_child(receiver)

const FENCE_SCENE: PackedScene = preload("res://src/entities/camp/fence/fence_segment.tscn")
const FENCE_DEF: StructureDefinition = preload("res://src/data/camp/fence_segment.tres")
const FENCE_CONFIG: FenceConfig = preload("res://src/data/configs/fence_config.tres")
const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")
const PLAYER_SCENE: PackedScene = preload("res://src/entities/player/player.tscn")


func _make_segment(at: Vector2, rotation_value: float = 0.0) -> FenceSegment:
	var segment := FENCE_SCENE.instantiate() as FenceSegment
	segment.definition = FENCE_DEF
	add_child_autofree(segment)
	segment.global_position = at
	segment.global_rotation = rotation_value
	return segment


# --- Geometry ---------------------------------------------------------------

func test_geometry_cross_parallel_touch() -> void:
	assert_true(FenceGeometry.segments_cross(Vector2(0, 0), Vector2(10, 0), Vector2(5, -5), Vector2(5, 5)))
	assert_false(FenceGeometry.segments_cross(Vector2(0, 0), Vector2(10, 0), Vector2(0, 5), Vector2(10, 5)))
	assert_true(FenceGeometry.segments_cross(Vector2(0, 0), Vector2(10, 0), Vector2(10, 0), Vector2(20, 0)))


func test_geometry_point_distance() -> void:
	assert_almost_eq(FenceGeometry.point_segment_distance(Vector2(0, 10), Vector2(0, 0), Vector2(10, 0)), 10.0, 0.01)
	assert_almost_eq(FenceGeometry.point_segment_distance(Vector2(-5, 0), Vector2(0, 0), Vector2(10, 0)), 5.0, 0.01)


func test_first_blocking_segment() -> void:
	var blocker := _make_segment(Vector2(50, 0), PI * 0.5)
	var behind := _make_segment(Vector2(120, 0), PI * 0.5)
	var found: Node = FenceGeometry.first_blocking_segment(Vector2(0, 0), Vector2(100, 0), get_tree().get_nodes_in_group(&"fence_segment"))
	assert_eq(found, blocker, "segmen pertama yang memotong garis harus dipilih")
	assert_ne(found, behind)


func test_destroyed_segment_does_not_block() -> void:
	var blocker := _make_segment(Vector2(50, 0), PI * 0.5)
	blocker.take_damage(999.0, null)
	var found: Node = FenceGeometry.first_blocking_segment(Vector2(0, 0), Vector2(100, 0), get_tree().get_nodes_in_group(&"fence_segment"))
	assert_null(found)


# --- Ring -------------------------------------------------------------------

func test_ring_layout_radius_tangent_no_gaps() -> void:
	var anchor := CampAnchor.new()
	add_child_autofree(anchor)
	var ring := FenceRing.new()
	ring.definition = FENCE_DEF
	ring.config = FENCE_CONFIG
	anchor.add_child(ring)
	await get_tree().process_frame

	anchor.found(Vector2(1000.0, 500.0))
	await get_tree().process_frame

	var slots := ring.get_slots()
	assert_eq(slots.size(), FENCE_CONFIG.segment_count)
	var previous: Vector2 = Vector2.ZERO
	for index in slots.size():
		var slot := slots[index]
		assert_almost_eq(slot.global_position.distance_to(Vector2(1000.0, 500.0)), FENCE_CONFIG.ring_radius, 0.5)
		var ends := PackedVector2Array([
			slot.global_position - Vector2.RIGHT.rotated(slot.global_rotation) * FENCE_CONFIG.segment_length * 0.5,
			slot.global_position + Vector2.RIGHT.rotated(slot.global_rotation) * FENCE_CONFIG.segment_length * 0.5,
		])
		assert_almost_eq(ends[0].distance_to(ends[1]), FENCE_CONFIG.segment_length, 0.5)
		if index > 0:
			var chord := previous.distance_to(slot.global_position)
			assert_true(chord - FENCE_CONFIG.segment_length <= 2.0, "celah antar segmen <= 2 px")
		previous = slot.global_position


func test_slot_build_cost_rotation_and_reopen() -> void:
	var anchor := CampAnchor.new()
	add_child_autofree(anchor)
	var ring := FenceRing.new()
	ring.definition = FENCE_DEF
	ring.config = FENCE_CONFIG
	anchor.add_child(ring)
	await get_tree().process_frame
	anchor.found(Vector2(1000.0, 500.0))
	await get_tree().process_frame

	var interactor := StubInteractor.new()
	add_child_autofree(interactor)
	interactor.inventory.add_item(ItemCatalog.WOOD, 5)
	interactor.inventory.add_item(ItemCatalog.FIBER, 5)

	var slot := ring.get_slots()[0]
	assert_true(slot.can_interact(interactor), "slot pagar harus bisa dibangun")
	slot.interact(interactor)
	assert_true(slot.is_built())
	assert_eq(interactor.inventory.count_of(ItemCatalog.WOOD), 4, "biaya 1 wood")
	assert_eq(interactor.inventory.count_of(ItemCatalog.FIBER), 4, "biaya 1 fiber")
	var segment := slot.get_structure() as FenceSegment
	assert_not_null(segment, "struktur hasil harus FenceSegment")
	assert_almost_eq(segment.global_rotation, slot.global_rotation, 0.01, "rotasi slot diwarisi")
	assert_eq(ring.get_built_count(), 1)

	segment.take_damage(999.0, null)
	assert_false(slot.is_built(), "slot terbuka lagi setelah segmen hancur")


func test_fence_definition_numbers() -> void:
	assert_eq(FENCE_DEF.id, &"fence_segment")
	assert_almost_eq(FENCE_DEF.max_hp, 60.0, 0.01)
	assert_almost_eq(FENCE_DEF.repair_hp, 30.0, 0.01)
	assert_almost_eq(FENCE_DEF.build_time, 1.5, 0.01)
	assert_eq(FENCE_DEF.aggro_priority, 3)
	assert_eq(FENCE_DEF.repair_cost[0].count, 1)
	assert_eq(FENCE_DEF.repair_cost[0].item.id, ItemCatalog.WOOD.id)


# --- Layer / player ---------------------------------------------------------

func test_player_is_not_blocked_by_fence_layer() -> void:
	var player := PLAYER_SCENE.instantiate() as CharacterBody2D
	assert_eq(player.collision_mask & PhysicsLayers.FENCE_LAYER, 0, "pemain tidak boleh bertabrakan dengan pagar")
	player.queue_free()
	var segment := _make_segment(Vector2.ZERO)
	assert_eq(segment.get_body().collision_layer, PhysicsLayers.FENCE_LAYER)
	assert_eq(segment.get_body().collision_mask, 0)


# --- Boar vs fence ----------------------------------------------------------

func test_boar_blocked_bites_segment_then_resumes() -> void:
	var clock := StubClock.new()
	add_child_autofree(clock)
	var player := StubPlayer.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2(200.0, 0.0)

	var segments: Array[FenceSegment] = []
	for offset_y in [-120.0, -60.0, 0.0, 60.0, 120.0]:
		segments.append(_make_segment(Vector2(100.0, offset_y), PI * 0.5))
	var segment := segments[2]
	watch_signals(player.receiver)

	var boar := BOAR_SCENE.instantiate() as WildBoar
	boar.clock = clock
	boar.player = player
	# Dash dimatikan supaya tes fokus ke jalur bite/gerak tertahan pagar.
	var boar_config := BoarConfig.new()
	boar_config.dash_min_distance = 9999.0
	boar.config = boar_config
	add_child_autofree(boar)
	boar.global_position = Vector2(0.0, 0.0)
	boar.ensure_ready()

	watch_signals(player.receiver)
	# Fase 1: pagar utuh menahan boar; ia hanya menggigit segmen tengah.
	for _index in 50:
		await get_tree().physics_frame
		boar.tick(0.1)
	assert_signal_not_emitted(player.receiver, "damaged", "pagar utuh menahan boar dari pemain")
	assert_lt(segment.get_current_hp(), segment.max_hp, "boar harus menyerang segmen yang menghalangi")

	# Fase 2: boar menggigit sampai segmen hancur lalu menembus celah.
	for _index in 80:
		await get_tree().physics_frame
		boar.tick(0.1)
	assert_false(is_instance_valid(segment), "segmen tengah harus hancur dan dibebaskan")
	assert_signal_emitted(player.receiver, "damaged", "setelah pagar hancur boar menyerang pemain")

extends GutTest

## Phase 2 (D1): base dinamis, aturan lokasi, dan konsumen pusat camp.

class StubClock extends Node:
	var night: bool = true
	func is_night() -> bool: return night
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

const CHEST_DEF: StructureDefinition = preload("res://src/data/camp/chest.tres")
const BOAR_SCENE: PackedScene = preload("res://src/entities/fauna/wild_boar/wild_boar.tscn")
const BASE_HUD_SCRIPT: Script = preload("res://src/ui/hud/base/base_hud.gd")


func _make_anchor() -> CampAnchor:
	var anchor := CampAnchor.new()
	add_child_autofree(anchor)
	return anchor


func _make_structure(at: Vector2) -> CampStructure:
	var structure := CampStructure.new()
	structure.definition = CHEST_DEF
	add_child_autofree(structure)
	structure.global_position = at
	return structure


# --- Aturan lokasi ----------------------------------------------------------

func test_rules_reasons_and_valid_case() -> void:
	var config := BaseSiteConfig.new()
	assert_eq(BaseSiteRules.evaluate(Vector2(3000.0, 0.0), config)["reason"], BaseSiteRules.REASON_OUTSIDE)
	assert_eq(BaseSiteRules.evaluate(Vector2(2200.0, 0.0), config)["reason"], BaseSiteRules.REASON_COAST)
	assert_eq(BaseSiteRules.evaluate(Vector2(-950.0, 0.0), config)["reason"], BaseSiteRules.REASON_RIVER)
	assert_eq(BaseSiteRules.evaluate(Vector2(-800.0, 0.0), config)["reason"], BaseSiteRules.REASON_RIVER)
	var valid := BaseSiteRules.evaluate(Vector2(1000.0, 500.0), config)
	assert_true(valid["valid"])
	assert_eq(valid["reason"], "")
	assert_eq(
		BaseSiteRules.evaluate(Vector2(1000.0, 500.0), config, true)["reason"],
		BaseSiteRules.REASON_LOCKED
	)


func test_river_distance_helper() -> void:
	assert_almost_eq(BaseSiteRules.distance_to_river(Vector2(-950.0, 0.0)), 0.0, 0.01)
	assert_almost_eq(BaseSiteRules.distance_to_river(Vector2(-800.0, 0.0)), 50.0, 0.01)
	assert_almost_eq(BaseSiteRules.distance_to_river(Vector2(-950.0, 1600.0)), 200.0, 0.01)


# --- Anchor ----------------------------------------------------------------

func test_anchor_unfounded_defaults_to_crash_site() -> void:
	var anchor := _make_anchor()
	assert_false(anchor.is_founded())
	assert_eq(anchor.get_center(), Vector2.ZERO)
	assert_eq(anchor.get_respawn_position(), Vector2(0.0, 64.0))
	assert_eq(CampAnchor.center_of(anchor), Vector2.ZERO)


func test_anchor_found_and_respawn_position() -> void:
	var anchor := _make_anchor()
	watch_signals(anchor)
	assert_true(anchor.found(Vector2(1000.0, 500.0)))
	assert_true(anchor.is_founded())
	assert_eq(anchor.get_center(), Vector2(1000.0, 500.0))
	assert_eq(anchor.get_respawn_position(), Vector2(1000.0, 564.0))
	assert_eq(CampAnchor.center_of(anchor), Vector2(1000.0, 500.0))
	assert_eq(CampAnchor.respawn_position_of(anchor), Vector2(1000.0, 564.0))
	assert_signal_emitted(anchor, "base_founded")


func test_anchor_rejects_invalid_position() -> void:
	var anchor := _make_anchor()
	assert_false(anchor.found(Vector2(2300.0, 0.0)))
	assert_false(anchor.is_founded())
	assert_eq(anchor.get_center(), Vector2.ZERO)


func test_anchor_relocation_locked_after_first_build() -> void:
	var anchor := _make_anchor()
	assert_true(anchor.found(Vector2(1000.0, 500.0)))
	assert_true(anchor.can_found(), "relokasi masih boleh sebelum struktur dibangun")
	_make_structure(Vector2(1000.0, 500.0))
	assert_false(anchor.can_found())
	assert_false(anchor.found(Vector2(-200.0, 300.0)), "base terkunci setelah struktur pertama")
	assert_eq(anchor.get_center(), Vector2(1000.0, 500.0))


func test_static_helpers_without_anchor() -> void:
	var plain := Node2D.new()
	add_child_autofree(plain)
	assert_eq(CampAnchor.center_of(plain), Vector2.ZERO)
	assert_eq(CampAnchor.respawn_position_of(plain), Vector2(0.0, 64.0))


# --- Konsumen pusat camp ----------------------------------------------------

func test_wild_boar_raid_uses_anchor_center() -> void:
	var anchor := _make_anchor()
	anchor.found(Vector2(1000.0, 500.0))
	_make_structure(Vector2(1000.0, 500.0))

	var clock := StubClock.new()
	add_child_autofree(clock)
	var player := StubPlayer.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2(1000.0, 660.0)

	var boar := BOAR_SCENE.instantiate() as WildBoar
	boar.clock = clock
	boar.player = player
	add_child_autofree(boar)
	boar.global_position = Vector2(1000.0, 500.0)
	boar.ensure_ready()
	# Mission 9 (R4): raid struktur hanya untuk raider (mode EVENT_ONLY).
	boar.set_raider(true)
	boar.tick(0.1)
	boar.tick(0.1)
	assert_true(boar.raid_camp, "raid memakai pusat base, bukan origin")


func test_spawn_markers_near_base_are_skipped() -> void:
	var anchor := _make_anchor()
	anchor.found(Vector2(1000.0, 500.0))

	var player := StubPlayer.new()
	player.add_to_group(&"player")
	add_child_autofree(player)
	player.global_position = Vector2.ZERO

	var inside := Node2D.new()
	inside.add_to_group(&"night_spawn_point")
	add_child_autofree(inside)
	inside.global_position = Vector2(1000.0, 500.0)
	var outside := Node2D.new()
	outside.add_to_group(&"night_spawn_point")
	add_child_autofree(outside)
	outside.global_position = Vector2(-400.0, -400.0)

	var quota := FaunaQuota.new()
	add_child_autofree(quota)
	var picked := quota.get_spawn_position()
	assert_eq(picked, Vector2(-400.0, -400.0), "penanda di dalam ring base harus dilewati")


func test_slots_disabled_before_founding_and_enabled_after() -> void:
	var anchor := _make_anchor()
	anchor.config = BaseSiteConfig.new()

	var controller := CampController.new()
	var slot := BlueprintSlot.new()
	slot.definition = CHEST_DEF
	controller.add_child(slot)
	add_child_autofree(controller)
	await get_tree().process_frame

	assert_false(slot.is_enabled(), "slot harus mati sebelum base ditentukan")
	assert_eq(slot.get_block_reason(null), CampController.SLOT_DISABLED_REASON)

	anchor.found(Vector2(1000.0, 500.0))
	assert_true(slot.is_enabled(), "slot aktif setelah base ditentukan")
	assert_eq(anchor.get_center(), controller.global_position, "CampController mengikuti pusat base")


# --- Preview controller -----------------------------------------------------

func test_placement_preview_confirm_cancel_invalid() -> void:
	var player := Node2D.new()
	add_child_autofree(player)
	player.global_position = Vector2(1000.0, 500.0)
	var anchor := _make_anchor()
	var controller := BasePlacementController.new()
	controller.player = player
	controller.anchor = anchor
	player.add_child(controller)
	await get_tree().process_frame

	controller.rules_override = func(_pos: Vector2) -> Dictionary:
		return {"valid": false, "reason": "Uji tolak"}
	controller.start_preview()
	assert_true(controller.is_preview_active())
	controller.set_preview_position(Vector2(1000.0, 500.0))
	assert_eq(controller.get_result()["reason"], "Uji tolak")
	assert_false(controller.confirm(), "preview tidak valid tidak boleh terpasang")
	assert_false(anchor.is_founded())

	controller.rules_override = func(_pos: Vector2) -> Dictionary:
		return {"valid": true, "reason": ""}
	controller.set_preview_position(Vector2(1010.0, 506.0))
	assert_true(controller.confirm(), "preview valid harus terpasang")
	assert_true(anchor.is_founded())
	assert_eq(anchor.get_center(), controller.get_preview_position(), "base memakai posisi preview")
	assert_almost_eq(fmod(anchor.get_center().x, 16.0), 0.0, 0.01, "posisi di-snap ke 16 px (x)")
	assert_almost_eq(fmod(anchor.get_center().y, 16.0), 0.0, 0.01, "posisi di-snap ke 16 px (y)")


func test_placement_cancel_emits_signal() -> void:
	var player := Node2D.new()
	add_child_autofree(player)
	var anchor := _make_anchor()
	var controller := BasePlacementController.new()
	controller.player = player
	controller.anchor = anchor
	player.add_child(controller)
	await get_tree().process_frame

	watch_signals(controller)
	controller.start_preview()
	controller.cancel()
	assert_false(controller.is_preview_active())
	assert_signal_emitted(controller, "placement_cancelled")
	assert_false(anchor.is_founded())


func test_base_hud_hint_then_hidden() -> void:
	var anchor := _make_anchor()
	var hud := BASE_HUD_SCRIPT.new() as BaseHUD
	anchor.add_child(hud)
	await get_tree().process_frame
	hud.anchor = anchor
	hud.refresh()
	assert_eq(hud.get_text(), BaseHUD.HINT)
	anchor.found(Vector2(1000.0, 500.0))
	hud.refresh()
	assert_eq(hud.get_text(), "")
	assert_false(hud.is_showing())

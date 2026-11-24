class_name BasePlacementPreview
extends RefCounted

## Mission 10 Phase 1: model preview base + pagar (murni, tanpa SceneTree).
## compute() -> {valid, reason, base_radius, fence_segments, core_slots}

const REASON_FENCE_RIVER := "Pagar menabrak sungai"
const REASON_FENCE_OUTSIDE := "Pagar keluar pulau"

## Offset 4 struktur inti dari pusat camp (sumber: camp_controller.tscn).
const CORE_SLOTS: Array = [
	{"id": &"campfire", "label": "Api Unggun", "position": Vector2(0.0, 0.0)},
	{"id": &"workbench", "label": "Meja Kerja", "position": Vector2(-96.0, -32.0)},
	{"id": &"chest", "label": "Peti", "position": Vector2(96.0, -32.0)},
	{"id": &"tent", "label": "Tenda", "position": Vector2(0.0, -110.0)},
]


static func compute(
	center: Vector2,
	site_config: BaseSiteConfig,
	fence_config: FenceConfig,
	locked: bool = false,
	angle_offset: float = 0.0
) -> Dictionary:
	var base := BaseSiteRules.evaluate(center, site_config, locked)
	var radius := fence_radius(fence_config)
	var segments: Array[Dictionary] = []
	var valid := bool(base.get("valid", false))
	var reason := String(base.get("reason", ""))

	for entry in FenceRing.layout(center, fence_config, angle_offset):
		var point: Vector2 = entry["position"]
		var inside := inside_island(point, site_config)
		var in_river := inside_river(point)
		var ok := inside and not in_river
		segments.append({"position": point, "rotation": entry["rotation"], "valid": ok})
		if ok:
			continue
		valid = false
		if reason.is_empty():
			reason = REASON_FENCE_RIVER if in_river else REASON_FENCE_OUTSIDE

	var slots: Array[Dictionary] = []
	for slot in CORE_SLOTS:
		slots.append({
			"id": slot["id"],
			"label": slot["label"],
			"position": center + Vector2(slot["position"]),
		})

	return {
		"valid": valid,
		"reason": reason,
		"base_radius": radius,
		"fence_segments": segments,
		"core_slots": slots,
	}


static func fence_radius(fence_config: FenceConfig) -> float:
	if fence_config != null:
		return fence_config.ring_radius
	return FenceConfig.new().ring_radius


## Dalam pulau dan di luar margin pantai.
static func inside_island(point: Vector2, site_config: BaseSiteConfig) -> bool:
	var margin := site_config.coast_margin if site_config != null else BaseSiteConfig.new().coast_margin
	return absf(point.x) <= IslandZones.HALF_SIZE - margin \
		and absf(point.y) <= IslandZones.HALF_SIZE - margin


static func inside_river(point: Vector2) -> bool:
	return point.x >= BaseSiteRules.RIVER_MIN_X and point.x <= BaseSiteRules.RIVER_MAX_X \
		and absf(point.y) <= BaseSiteRules.RIVER_HALF_Y

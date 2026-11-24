class_name BaseSiteRules
extends RefCounted

## Validasi lokasi base (D1), murni statis supaya mudah dites.
## evaluate() -> {valid: bool, reason: String}

const REASON_OUTSIDE := "Di luar pulau"
const REASON_COAST := "Terlalu dekat pantai"
const REASON_RIVER := "Terlalu dekat sungai"
const REASON_LOCKED := "Base terkunci, struktur sudah dibangun"

const RIVER_MIN_X := -1050.0
const RIVER_MAX_X := -850.0
const RIVER_HALF_Y := 1400.0


## Radius ring efektif: FenceConfig adalah satu-satunya sumber angka.
static func ring_radius(config: BaseSiteConfig) -> float:
	if config == null:
		return FenceConfig.new().ring_radius
	if config.fence_config != null:
		return config.fence_config.ring_radius
	return config.ring_radius


static func evaluate(center: Vector2, config: BaseSiteConfig, locked: bool = false) -> Dictionary:
	if locked:
		return {"valid": false, "reason": REASON_LOCKED}
	var rules := config if config != null else BaseSiteConfig.new()

	if not WorldRules.is_walkable(center):
		return {"valid": false, "reason": REASON_OUTSIDE}
	var zone := WorldRules.zone_at(center)
	if zone == IslandZones.Zone.OUTSIDE:
		return {"valid": false, "reason": REASON_OUTSIDE}

	if WorldRules.distance_to_coast(center) < rules.coast_margin:
		return {"valid": false, "reason": REASON_COAST}

	if zone == IslandZones.Zone.RIVER:
		return {"valid": false, "reason": REASON_RIVER}
	if distance_to_river(center) < ring_radius(rules) + rules.river_clearance:
		return {"valid": false, "reason": REASON_RIVER}

	return {"valid": true, "reason": ""}


## Jarak titik ke wilayah sungai dari provider dunia; 0 bila di dalamnya.
## (FormulaWorld menghitungnya dengan persegi strip yang sama seperti dulu.)
static func distance_to_river(point: Vector2) -> float:
	return WorldRules.distance_to_zone(point, IslandZones.Zone.RIVER)

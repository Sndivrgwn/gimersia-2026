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


static func evaluate(center: Vector2, config: BaseSiteConfig, locked: bool = false) -> Dictionary:
	if locked:
		return {"valid": false, "reason": REASON_LOCKED}
	var rules := config if config != null else BaseSiteConfig.new()

	if absf(center.x) > IslandZones.HALF_SIZE or absf(center.y) > IslandZones.HALF_SIZE:
		return {"valid": false, "reason": REASON_OUTSIDE}
	var zone := IslandZones.zone_at(center)
	if zone == IslandZones.Zone.OUTSIDE:
		return {"valid": false, "reason": REASON_OUTSIDE}

	if absf(center.x) > IslandZones.HALF_SIZE - rules.coast_margin \
		or absf(center.y) > IslandZones.HALF_SIZE - rules.coast_margin:
		return {"valid": false, "reason": REASON_COAST}

	if zone == IslandZones.Zone.RIVER:
		return {"valid": false, "reason": REASON_RIVER}
	if distance_to_river(center) < rules.ring_radius + rules.river_clearance:
		return {"valid": false, "reason": REASON_RIVER}

	return {"valid": true, "reason": ""}


## Jarak titik ke persegi panjang strip sungai; 0 bila di dalamnya.
static func distance_to_river(point: Vector2) -> float:
	var dx := 0.0
	if point.x < RIVER_MIN_X:
		dx = RIVER_MIN_X - point.x
	elif point.x > RIVER_MAX_X:
		dx = point.x - RIVER_MAX_X
	var dy := 0.0
	if point.y < -RIVER_HALF_Y:
		dy = -RIVER_HALF_Y - point.y
	elif point.y > RIVER_HALF_Y:
		dy = point.y - RIVER_HALF_Y
	return sqrt(dx * dx + dy * dy)

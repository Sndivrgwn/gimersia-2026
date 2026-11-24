class_name IslandZones
extends RefCounted

## Zona pulau minimum (spec §7.7).
##
## `zone_at()` dievaluasi berurutan: OUTSIDE, CAMP, SOUTH_BEACH, EAST_BEACH,
## WEST_CLIFFS, RIVER, sisanya FOREST. Urutan ini bagian dari perilaku, bukan
## detail implementasi: sudut timur-laut, misalnya, jatuh ke SOUTH_BEACH karena
## `y > 1400` dicek sebelum EAST_BEACH.

enum Zone { CAMP, SOUTH_BEACH, EAST_BEACH, WEST_CLIFFS, RIVER, FOREST, OUTSIDE }

const HALF_SIZE := 2400.0
const CAMP_RADIUS := 800.0
const BEACH_EDGE := 1400.0
const RIVER_MIN_X := -1050.0
const RIVER_MAX_X := -850.0
const BEACON_POSITION := Vector2(0.0, 2100.0)


## Zona dunia aktif (WorldRules). Signature lama dipertahankan.
static func zone_at(position: Vector2) -> Zone:
	var zone: int = WorldRules.zone_at(position)
	return zone


## Matematika zona lama; satu-satunya isi FormulaWorld.zone_at.
static func _formula_zone_at(position: Vector2) -> Zone:
	if absf(position.x) > HALF_SIZE or absf(position.y) > HALF_SIZE:
		return Zone.OUTSIDE
	if position.length() <= CAMP_RADIUS:
		return Zone.CAMP
	if position.y > BEACH_EDGE:
		return Zone.SOUTH_BEACH
	if position.x > BEACH_EDGE and absf(position.y) <= BEACH_EDGE:
		return Zone.EAST_BEACH
	if position.x < -BEACH_EDGE and position.y <= BEACH_EDGE:
		return Zone.WEST_CLIFFS
	if position.x >= RIVER_MIN_X and position.x <= RIVER_MAX_X and absf(position.y) <= BEACH_EDGE:
		return Zone.RIVER
	return Zone.FOREST


## Nama tampilan untuk GatherDebug/HUD.
static func zone_name(zone: int) -> String:
	match zone:
		Zone.CAMP:
			return "Camp"
		Zone.SOUTH_BEACH:
			return "South Beach"
		Zone.EAST_BEACH:
			return "East Beach"
		Zone.WEST_CLIFFS:
			return "West Cliffs"
		Zone.RIVER:
			return "River"
		Zone.FOREST:
			return "Forest"
		_:
			return "Outside"


## Titik tengah tiap zona yang pasti berada di zona itu (teleport debug).
static func zone_center(zone: int) -> Vector2:
	match zone:
		Zone.CAMP:
			return Vector2.ZERO
		Zone.SOUTH_BEACH:
			return Vector2(0.0, 1900.0)
		Zone.EAST_BEACH:
			return Vector2(1900.0, 0.0)
		Zone.WEST_CLIFFS:
			return Vector2(-1900.0, 0.0)
		Zone.RIVER:
			return Vector2(-950.0, 0.0)
		Zone.FOREST:
			return Vector2(700.0, -1000.0)
		_:
			return Vector2.ZERO

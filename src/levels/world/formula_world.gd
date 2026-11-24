class_name FormulaWorld
extends WorldSource

## Dunia FORMULA: reproduksi persis aturan pulau yang lama (IslandZones +
## BaseSiteRules). Angka geometri tetap milik IslandZones/BaseSiteConfig; kelas
## ini hanya memindahkan bentuk geometrinya ke balik antarmuka WorldSource.
##
## POI ditulis sebagai literal dan dijaga tes agar sama dengan konstanta lama
## (IslandBuilder.KEEP_OUT_POINTS dan IslandZones.BEACON_POSITION).

const PLAYER_START := Vector2(0.0, 64.0)
const PLANE_WRECKAGE := Vector2(0.0, -185.0)
const EMERGENCY_SUITCASE := Vector2(-48.0, 40.0)
const SIGNAL_BEACON := Vector2(0.0, 2100.0)


func id() -> StringName:
	return &"formula"


func zone_at(position: Vector2) -> int:
	return IslandZones._formula_zone_at(position)


## Sama dengan cek lama: |x| > HALF_SIZE atau |y| > HALF_SIZE = di luar.
func is_walkable(position: Vector2) -> bool:
	return absf(position.x) <= IslandZones.HALF_SIZE and absf(position.y) <= IslandZones.HALF_SIZE


## Geometri saja (tanpa ambang BaseSiteConfig): di dalam pulau dan bukan sungai.
func is_buildable(position: Vector2) -> bool:
	if not is_walkable(position):
		return false
	var zone := zone_at(position)
	return zone != IslandZones.Zone.OUTSIDE and zone != IslandZones.Zone.RIVER


func bounds() -> Rect2:
	var half := IslandZones.HALF_SIZE
	return Rect2(-half, -half, half * 2.0, half * 2.0)


## Jarak Chebyshev ke tepi kotak pulau; negatif bila di luar.
func distance_to_coast(position: Vector2) -> float:
	return IslandZones.HALF_SIZE - maxf(absf(position.x), absf(position.y))


## Jarak ke wilayah zona. RIVER identik dengan BaseSiteRules.distance_to_river
## (persegi strip); zona lain memakai bentuk wilayahnya (lingkaran camp, persegi
## pantai/tebing, sisa pulau untuk forest).
func distance_to_zone(position: Vector2, zone: int) -> float:
	var half := IslandZones.HALF_SIZE
	var edge := IslandZones.BEACH_EDGE
	match zone:
		IslandZones.Zone.CAMP:
			return maxf(0.0, position.length() - IslandZones.CAMP_RADIUS)
		IslandZones.Zone.SOUTH_BEACH:
			return _distance_to_rect(position, Rect2(-half, edge, half * 2.0, half - edge))
		IslandZones.Zone.EAST_BEACH:
			return _distance_to_rect(position, Rect2(edge, -edge, half - edge, edge * 2.0))
		IslandZones.Zone.WEST_CLIFFS:
			return _distance_to_rect(position, Rect2(-half, -edge, half - edge, edge * 2.0))
		IslandZones.Zone.RIVER:
			return _distance_to_rect(position, Rect2(
				IslandZones.RIVER_MIN_X,
				-edge,
				IslandZones.RIVER_MAX_X - IslandZones.RIVER_MIN_X,
				edge * 2.0
			))
		IslandZones.Zone.FOREST:
			if is_walkable(position):
				return 0.0
			return _distance_to_rect(position, bounds())
		IslandZones.Zone.OUTSIDE:
			if not is_walkable(position):
				return 0.0
			return minf(half - absf(position.x), half - absf(position.y))
		_:
			return INF


func poi(name: StringName) -> Vector2:
	match name:
		WorldSource.POI_PLAYER_START:
			return PLAYER_START
		WorldSource.POI_PLANE_WRECKAGE:
			return PLANE_WRECKAGE
		WorldSource.POI_EMERGENCY_SUITCASE:
			return EMERGENCY_SUITCASE
		WorldSource.POI_SIGNAL_BEACON:
			return SIGNAL_BEACON
		_:
			return Vector2.INF


## Titik tetap per zona. Nilainya sama dengan IslandZones.zone_center (dijaga
## tes) supaya teleport debug tidak berubah; OUTSIDE tetap INF.
func zone_center(zone: int) -> Vector2:
	match zone:
		IslandZones.Zone.CAMP:
			return Vector2.ZERO
		IslandZones.Zone.SOUTH_BEACH:
			return Vector2(0.0, 1900.0)
		IslandZones.Zone.EAST_BEACH:
			return Vector2(1900.0, 0.0)
		IslandZones.Zone.WEST_CLIFFS:
			return Vector2(-1900.0, 0.0)
		IslandZones.Zone.RIVER:
			return Vector2(-950.0, 0.0)
		IslandZones.Zone.FOREST:
			return Vector2(700.0, -1000.0)
		_:
			return Vector2.INF


## night_spawn_points()/water_access_points() memakai default kosong WorldSource:
## marker malam FORMULA tetap dibuat IslandBuilder seperti sebelumnya.
func _distance_to_rect(point: Vector2, rect: Rect2) -> float:
	var dx := 0.0
	if point.x < rect.position.x:
		dx = rect.position.x - point.x
	elif point.x > rect.end.x:
		dx = point.x - rect.end.x
	var dy := 0.0
	if point.y < rect.position.y:
		dy = rect.position.y - point.y
	elif point.y > rect.end.y:
		dy = point.y - rect.end.y
	return sqrt(dx * dx + dy * dy)

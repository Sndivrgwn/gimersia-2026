class_name WorldSource
extends RefCounted

## Sumber kebenaran dunia (Mission 13). Implementasi: `FormulaWorld` (pulau rumus
## lama) dan `AuthoredWorldSource` (scene dunia buatan).
##
## Semua default di sini adalah nilai "tidak tahu" (INF / kosong / false) supaya
## konsumen bisa melewati hasilnya tanpa menebak. Kontrak nama POI juga di sini
## agar pemanggil tidak menulis StringName sendiri.

const POI_PLAYER_START := &"player_start"
const POI_PLANE_WRECKAGE := &"plane_wreckage"
const POI_EMERGENCY_SUITCASE := &"emergency_suitcase"
const POI_SIGNAL_BEACON := &"signal_beacon"


func id() -> StringName:
	return &"world_source"


## -1 = tidak diketahui (bukan nilai enum IslandZones.Zone).
func zone_at(_position: Vector2) -> int:
	return -1


func is_walkable(_position: Vector2) -> bool:
	return true


func is_buildable(_position: Vector2) -> bool:
	return false


## Rect2() kosong = batas tidak diketahui.
func bounds() -> Rect2:
	return Rect2()


func distance_to_coast(_position: Vector2) -> float:
	return INF


func distance_to_zone(_position: Vector2, _zone: int) -> float:
	return INF


## Vector2.INF bila nama tidak dikenal.
func poi(_name: StringName) -> Vector2:
	return Vector2.INF


func night_spawn_points() -> PackedVector2Array:
	return PackedVector2Array()


func water_access_points() -> PackedVector2Array:
	return PackedVector2Array()


## Vector2.INF bila zona tidak punya pusat.
func zone_center(_zone: int) -> Vector2:
	return Vector2.INF


func has_resource_plan() -> bool:
	return false


func resource_plan(_layout: IslandLayoutConfig, _seed_value: int) -> Array:
	return []

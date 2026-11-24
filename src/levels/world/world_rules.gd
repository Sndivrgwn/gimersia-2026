class_name WorldRules
extends RefCounted

## Titik akses tunggal ke dunia aktif (Mission 13). Gameplay tidak pernah
## membuat FormulaWorld sendiri: semua lewat sini, supaya blok G bisa menukar
## sumber tanpa menyentuh konsumen.
##
## `source` sengaja statis (bukan autoload): WorldController mengisinya di
## _ready dan mengosongkannya di _exit_tree.

static var source: WorldSource


## Sumber aktif; membuat FormulaWorld bila belum ada.
static func get_source() -> WorldSource:
	if source == null:
		source = FormulaWorld.new()
	return source


static func set_source(value: WorldSource) -> void:
	source = value


static func reset() -> void:
	source = null


# --- Forwarder --------------------------------------------------------------

static func id() -> StringName:
	return get_source().id()


static func zone_at(position: Vector2) -> int:
	return get_source().zone_at(position)


static func is_walkable(position: Vector2) -> bool:
	return get_source().is_walkable(position)


static func is_buildable(position: Vector2) -> bool:
	return get_source().is_buildable(position)


static func bounds() -> Rect2:
	return get_source().bounds()


static func distance_to_coast(position: Vector2) -> float:
	return get_source().distance_to_coast(position)


static func distance_to_zone(position: Vector2, zone: int) -> float:
	return get_source().distance_to_zone(position, zone)


static func poi(name: StringName) -> Vector2:
	return get_source().poi(name)


static func night_spawn_points() -> PackedVector2Array:
	return get_source().night_spawn_points()


static func water_access_points() -> PackedVector2Array:
	return get_source().water_access_points()


static func zone_center(zone: int) -> Vector2:
	return get_source().zone_center(zone)


static func has_resource_plan() -> bool:
	return get_source().has_resource_plan()


static func resource_plan(layout: IslandLayoutConfig, seed_value: int) -> Array:
	return get_source().resource_plan(layout, seed_value)

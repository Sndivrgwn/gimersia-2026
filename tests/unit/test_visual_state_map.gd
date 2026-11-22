extends GutTest

## Tes pemetaan state -> animasi (murni) dan driver fauna dengan art palsu.

const ROOT := "user://test_assets"

var _registry: AssetRegistry


func before_each() -> void:
	_clean_root()
	Assets.set_roots(PackedStringArray([ROOT]))
	_registry = AssetRegistry.new()
	_registry.slots = _slots()
	Assets.set_registry(_registry)


func after_each() -> void:
	Assets.reset_roots()
	Assets.set_registry(null)
	Assets.reload_assets()
	_clean_root()


func test_player_state_priority() -> void:
	assert_eq(VisualStateMap.player_state(true, true, true, true, true), &"death")
	assert_eq(VisualStateMap.player_state(false, true, true, true, false), &"hurt")
	assert_eq(VisualStateMap.player_state(false, false, true, true, false), &"attack")
	assert_eq(VisualStateMap.player_state(false, false, false, false, false), &"idle")
	assert_eq(VisualStateMap.player_state(false, false, false, true, false), &"walk")
	assert_eq(VisualStateMap.player_state(false, false, false, true, true), &"sprint")


func test_boar_state_mapping() -> void:
	assert_eq(VisualStateMap.boar_state(0, false), &"idle")
	assert_eq(VisualStateMap.boar_state(0, true), &"walk")
	assert_eq(VisualStateMap.boar_state(1, true), &"walk")
	assert_eq(VisualStateMap.boar_state(2, false), &"bite")
	assert_eq(VisualStateMap.boar_state(3, false), &"telegraph")
	assert_eq(VisualStateMap.boar_state(4, true), &"dash")
	assert_eq(VisualStateMap.boar_state(5, false), &"walk")


func test_deer_state_mapping() -> void:
	assert_eq(VisualStateMap.deer_state(0, false), &"idle")
	assert_eq(VisualStateMap.deer_state(0, true), &"walk")
	assert_eq(VisualStateMap.deer_state(1, true), &"flee")
	assert_eq(VisualStateMap.fauna_state("island_deer", 1, false), &"flee")
	assert_eq(VisualStateMap.fauna_state("lain", 0, true), &"walk")


func test_other_state_maps() -> void:
	assert_eq(VisualStateMap.resource_state(false), &"full")
	assert_eq(VisualStateMap.resource_state(true), &"depleted")
	assert_eq(VisualStateMap.campfire_state(true, false), &"lit")
	assert_eq(VisualStateMap.campfire_state(false, true), &"cold")
	assert_eq(VisualStateMap.campfire_state(false, false), &"ember")
	assert_eq(VisualStateMap.chest_state(true), &"open")
	assert_eq(VisualStateMap.tent_state(true), &"sleeping")
	assert_eq(VisualStateMap.beacon_state(true), &"active")


func test_fauna_driver_follows_state_and_art() -> void:
	_write_image("characters/boar/idle.png", 16, 16)
	_write_image("characters/boar/walk.png", 16, 16)

	var boar := StubFauna.new()
	add_child_autofree(boar)
	var polygon := Polygon2D.new()
	polygon.name = "Visual"
	polygon.polygon = PackedVector2Array([Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5)])
	boar.add_child(polygon)

	var slot := VisualSlot.attach(boar, &"boar", [polygon], null, FaunaVisual.new())
	await wait_frames(2)
	assert_true(slot.is_showing_art())
	assert_false(polygon.visible)
	assert_eq(slot.get_state(), &"idle")

	var driver := slot.get_node_or_null("Driver") as FaunaVisual
	assert_not_null(driver)
	boar.state_value = 1
	boar.velocity = Vector2(10.0, 0.0)
	driver.step(0.016)
	assert_eq(slot.get_state(), &"walk")
	driver.step(0.016)
	assert_eq(slot.get_state(), &"walk")

	_remove("characters/boar/walk.png")
	_remove("characters/boar/idle.png")
	Assets.reload_assets()
	slot.refresh()
	assert_true(polygon.visible)


# --- Fixtures ---------------------------------------------------------------

class StubFauna:
	extends CharacterBody2D
	var state_value: int = 0

	func get_state() -> int:
		return state_value


func _slots() -> Array[AssetSlotDefinition]:
	var slots: Array[AssetSlotDefinition] = []
	var boar := AssetSlotDefinition.new()
	boar.key = &"boar"
	boar.category = &"test"
	boar.folder = "characters/boar"
	boar.states = PackedStringArray(["idle", "walk", "bite"])
	boar.directions = AssetSlotDefinition.Direction.FOUR
	boar.display_size = Vector2(32.0, 32.0)
	boar.priority = 1
	slots.append(boar)
	return slots


func _write_image(relative: String, width: int, height: int) -> void:
	var path := ROOT + "/" + relative
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.4, 0.6, 0.2, 1.0))
	image.save_png(path)


func _remove(relative: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ROOT + "/" + relative))


func _clean_root() -> void:
	var absolute := ProjectSettings.globalize_path(ROOT)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	_remove_dir(absolute)


func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for name in dir.get_files():
		DirAccess.remove_absolute(path + "/" + name)
	for sub in dir.get_directories():
		_remove_dir(path + "/" + sub)
	DirAccess.remove_absolute(path)

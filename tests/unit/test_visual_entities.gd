extends GutTest

## Retrofit visual pada scene nyata dengan art palsu di user://:
## placeholder tersembunyi saat art ada, kembali saat art dihapus, dan radius
## cahaya api tidak berubah karena ukuran tekstur.

const ROOT := "user://test_assets"
const CAMPFIRE_SCENE: PackedScene = preload("res://src/entities/camp/campfire/campfire.tscn")
const CHEST_SCENE: PackedScene = preload("res://src/entities/camp/chest/chest.tscn")
const TENT_SCENE: PackedScene = preload("res://src/entities/camp/tent/tent.tscn")


func before_each() -> void:
	_clean_root()
	Assets.set_roots(PackedStringArray([ROOT]))


func after_each() -> void:
	Assets.reset_roots()
	Assets.reload_assets()
	_clean_root()


func test_campfire_art_hides_placeholders_and_keeps_light_radius() -> void:
	_write_image("props/campfire/lit.png", 64, 64)
	var fire := CAMPFIRE_SCENE.instantiate() as Campfire
	add_child_autofree(fire)
	# Mission 9 (R4): api baru COLD; art "lit" hanya dipakai saat menyala.
	fire.ignite()
	fire.tick(0.016)

	var slot := fire.get_node_or_null("VisualSlot") as VisualSlot
	assert_not_null(slot)
	assert_true(slot.is_showing_art())
	assert_false((fire.get_node("Visual") as CanvasItem).visible)
	assert_false((fire.get_node("Flame") as CanvasItem).visible)

	# Radius tetap dari CampfireConfig, bukan dari ukuran tekstur art (64 px).
	assert_almost_eq(fire.get_light_radius(), fire.config.lit_light_radius, 0.001)
	var light := fire.get_light()
	assert_not_null(light)
	var covered := light.texture_scale * float(light.texture.get_width()) * 0.5
	assert_almost_eq(covered, fire.get_light_radius(), 0.5)


func test_chest_art_restores_placeholders_when_removed() -> void:
	_write_image("props/chest/closed.png", 48, 40)
	var chest := CHEST_SCENE.instantiate() as Chest
	add_child_autofree(chest)
	var slot := chest.get_node_or_null("VisualSlot") as VisualSlot
	assert_true(slot.is_showing_art())
	assert_false((chest.get_node("Body") as CanvasItem).visible)

	_remove("props/chest/closed.png")
	Assets.reload_assets()
	slot.refresh()
	assert_false(slot.is_showing_art())
	assert_true((chest.get_node("Body") as CanvasItem).visible)
	assert_true((chest.get_node("Lid") as CanvasItem).visible)


func test_tent_without_art_is_unchanged() -> void:
	var tent := TENT_SCENE.instantiate() as Tent
	add_child_autofree(tent)
	var slot := tent.get_node_or_null("VisualSlot") as VisualSlot
	assert_not_null(slot)
	assert_false(slot.is_showing_art())
	assert_true((tent.get_node("Body") as CanvasItem).visible)
	assert_true((tent.get_node("Door") as CanvasItem).visible)


func test_tent_sleeping_state_after_sleep_signal() -> void:
	var tent := TENT_SCENE.instantiate() as Tent
	add_child_autofree(tent)
	var slot := tent.get_node_or_null("VisualSlot") as VisualSlot
	tent.sleep_completed.emit()
	await wait_frames(2)
	assert_eq(slot.get_state(), &"sleeping")


# --- Fixtures ---------------------------------------------------------------

func _write_image(relative: String, width: int, height: int) -> void:
	var path := ROOT + "/" + relative
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.4, 0.2, 1.0))
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

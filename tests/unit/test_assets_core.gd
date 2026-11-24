extends GutTest

## Tes inti sistem aset: parsing nama file, rantai fallback, mirror, potong
## strip, item icon, reload, dan sanity registry.
## Semua gambar dibuat saat tes di user://test_assets (tidak ada biner di repo).

const ROOT := "user://test_assets"

var _registry: AssetRegistry


func before_each() -> void:
	_clean_root()
	Assets.set_roots(PackedStringArray([ROOT]))
	_registry = AssetRegistry.new()
	_registry.slots = _default_slots()
	Assets.set_registry(_registry)


func after_each() -> void:
	Assets.set_warning_sink(Callable())
	Assets.reset_roots()
	Assets.set_registry(null)
	Assets.reload_assets()
	_clean_root()


# --- Parsing ----------------------------------------------------------------

func test_parse_filename_states() -> void:
	var plain := Assets.parse_filename("idle.png")
	assert_true(plain["ok"])
	assert_eq(plain["state"], "idle")
	assert_eq(plain["dir"], "")
	assert_eq(int(plain["frames"]), 1)

	var directed := Assets.parse_filename("walk_left_4f.png")
	assert_eq(directed["state"], "walk")
	assert_eq(directed["dir"], "left")
	assert_eq(int(directed["frames"]), 4)

	var webp := Assets.parse_filename("run_up_2f.webp")
	assert_true(webp["ok"])
	assert_eq(webp["state"], "run")
	assert_eq(webp["dir"], "up")
	assert_eq(int(webp["frames"]), 2)


func test_parse_filename_rejects_bad_names() -> void:
	assert_false(Assets.parse_filename("idle.txt")["ok"])
	assert_false(Assets.parse_filename("_4f.png")["ok"])
	assert_false(Assets.parse_filename("down.png")["ok"])


# --- Fallback ---------------------------------------------------------------

func test_finds_exact_state_and_direction() -> void:
	_write_image("unit/walk_down.png", 16, 16)
	var resolved := Assets.resolve(&"unit", &"walk", &"down")
	assert_true(resolved.found)
	assert_false(resolved.from_fallback)
	assert_false(resolved.flip_h)
	assert_string_contains(resolved.path, "walk_down.png")


func test_falls_back_to_state_without_direction() -> void:
	_write_image("unit/walk.png", 16, 16)
	var resolved := Assets.resolve(&"unit", &"walk", &"down")
	assert_true(resolved.found)
	assert_true(resolved.from_fallback)
	assert_string_contains(resolved.path, "walk.png")


func test_mirrors_opposite_direction() -> void:
	_write_image("unit/walk_right.png", 16, 16)
	var resolved := Assets.resolve(&"unit", &"walk", &"left")
	assert_true(resolved.found)
	assert_true(resolved.flip_h)
	assert_string_contains(resolved.path, "walk_right.png")


func test_mirror_can_be_disabled() -> void:
	var config := AssetConfig.new()
	config.mirror_fallback = false
	Assets.set_config(config)
	_write_image("unit/walk_right.png", 16, 16)
	var resolved := Assets.resolve(&"unit", &"walk", &"left")
	assert_false(resolved.found)


func test_falls_back_to_idle() -> void:
	_write_image("unit/idle_down.png", 16, 16)
	var idle := Assets.resolve(&"unit", &"hurt", &"down")
	assert_true(idle.found)
	assert_true(idle.from_fallback)
	assert_string_contains(idle.path, "idle_down.png")


func test_falls_back_to_default_state() -> void:
	_write_image("unit/default.png", 8, 8)
	var resolved := Assets.resolve(&"unit", &"hurt", &"left")
	assert_true(resolved.found)
	assert_string_contains(resolved.path, "default.png")
	assert_false(resolved.flip_h)


func test_missing_slot_returns_placeholder() -> void:
	var resolved := Assets.resolve(&"tidak_ada", &"idle", &"down")
	assert_false(resolved.found)
	assert_null(resolved.texture)
	assert_false(Assets.has_art(&"tidak_ada"))


func test_has_art_uses_default_state() -> void:
	assert_false(Assets.has_art(&"unit"))
	_write_image("unit/idle.png", 16, 16)
	Assets.reload_assets()
	assert_true(Assets.has_art(&"unit"))


# --- Strip ------------------------------------------------------------------

func test_strip_is_sliced_into_frames() -> void:
	_write_image("unit/walk_down_4f.png", 64, 16)
	var resolved := Assets.resolve(&"unit", &"walk", &"down")
	assert_true(resolved.found)
	assert_eq(resolved.frame_count, 4)
	assert_true(resolved.is_animated())
	assert_eq(resolved.texture_size(), Vector2(16, 16))
	var frames := resolved.sprite_frames.get_frame_count(&"default")
	assert_eq(frames, 4)
	var first := resolved.sprite_frames.get_frame_texture(&"default", 0) as AtlasTexture
	assert_not_null(first)
	assert_eq(first.region, Rect2(0, 0, 16, 16))
	var last := resolved.sprite_frames.get_frame_texture(&"default", 3) as AtlasTexture
	assert_eq(last.region, Rect2(48, 0, 16, 16))


func test_fps_comes_from_slot_then_config() -> void:
	_write_image("unit/walk_down_2f.png", 32, 16)
	_write_image("unit/hurt_down_2f.png", 32, 16)
	var walk := Assets.resolve(&"unit", &"walk", &"down")
	assert_eq(walk.fps, 12.0)
	assert_true(walk.loop)
	var hurt := Assets.resolve(&"unit", &"hurt", &"down")
	assert_eq(hurt.fps, 10.0)
	assert_false(hurt.loop)


# --- Lain-lain --------------------------------------------------------------

func test_item_icon_lookup() -> void:
	assert_null(Assets.item_icon(&"wood"))
	_write_image("icons/items/wood.png", 16, 16)
	Assets.reload_assets()
	assert_not_null(Assets.item_icon(&"wood"))


func test_reload_picks_up_new_file() -> void:
	assert_false(Assets.resolve(&"unit", &"idle", &"").found)
	_write_image("unit/idle.png", 12, 12)
	Assets.reload_assets()
	assert_true(Assets.resolve(&"unit", &"idle", &"").found)


func test_corrupt_file_warns_once_and_falls_back() -> void:
	var messages: Array[String] = []
	Assets.set_warning_sink(func(message: String) -> void: messages.append(message))

	var path := _write_garbage("unit/walk_down.png")
	assert_false(Assets.resolve(&"unit", &"walk", &"down").found)
	Assets.clear_resolve_cache()
	assert_false(Assets.resolve(&"unit", &"walk", &"down").found)
	assert_eq(messages.size(), 1)
	assert_string_contains(messages[0], "walk_down.png")
	assert_true(path.ends_with("walk_down.png"))


func test_coverage_counts_filled_slots() -> void:
	var empty := Assets.coverage()
	assert_eq(int(empty["filled"]), 0)
	assert_eq(int(empty["total"]), _registry.size())
	assert_true(empty["missing_priority1"].has("unit"))

	_write_image("unit/idle.png", 16, 16)
	Assets.reload_assets()
	var filled := Assets.coverage()
	assert_eq(int(filled["filled"]), 1)
	assert_false(filled["missing_priority1"].has("unit"))


func test_registry_sanity_default_slots() -> void:
	var seen: Dictionary = {}
	for slot in _registry.slots:
		assert_true(slot.is_valid(), "slot %s tidak valid" % slot.key)
		assert_false(seen.has(slot.key), "key duplikat: %s" % slot.key)
		seen[slot.key] = true
		assert_true(slot.display_size.x > 0.0 and slot.display_size.y > 0.0)
		assert_between(slot.priority, 1, 3)


func test_shipped_registry_has_minimum_slots() -> void:
	var shipped := AssetRegistry.new()
	shipped = load("res://src/data/assets/asset_registry.tres") as AssetRegistry
	assert_not_null(shipped)
	var required := [
		&"player", &"wild_boar", &"island_deer",
		&"twig", &"small_tree", &"tree", &"small_rock", &"big_rock",
		&"fiber_bush", &"berry_bush", &"coconut_palm", &"bamboo_clump",
		&"campfire", &"workbench", &"chest", &"tent", &"fence_segment",
		&"blueprint_campfire", &"blueprint_workbench", &"blueprint_chest",
		&"blueprint_tent", &"blueprint_fence_segment", &"light_campfire",
		&"ground_camp", &"ground_south_beach", &"ground_east_beach",
		&"ground_west_cliffs", &"ground_river", &"ground_forest",
		&"plane_wreckage", &"emergency_suitcase", &"signal_beacon",
		&"loot_bag", &"fx_slash", &"fx_hit_spark", &"fx_chip",
	]
	var seen: Dictionary = {}
	for slot in shipped.slots:
		assert_false(seen.has(slot.key), "key duplikat: %s" % slot.key)
		seen[slot.key] = true
		assert_true(slot.is_valid(), "slot %s tidak valid" % slot.key)
	for key in required:
		assert_true(seen.has(key), "slot wajib hilang: %s" % key)


# --- Fixtures ---------------------------------------------------------------

func _default_slots() -> Array[AssetSlotDefinition]:
	var slots: Array[AssetSlotDefinition] = []

	var unit := AssetSlotDefinition.new()
	unit.key = &"unit"
	unit.category = &"test"
	unit.folder = "unit"
	unit.states = PackedStringArray(["idle", "walk", "hurt"])
	unit.directions = AssetSlotDefinition.Direction.FOUR
	unit.display_size = Vector2(32.0, 32.0)
	unit.pivot = AssetSlotDefinition.Pivot.BOTTOM_CENTER
	unit.priority = 1
	unit.fps = {"walk": 12.0, "hurt": 10.0}
	unit.loop_states = PackedStringArray(["idle", "walk"])
	slots.append(unit)

	var fallback := AssetSlotDefinition.new()
	fallback.key = &"unit_default"
	fallback.category = &"test"
	fallback.folder = "unit_default"
	fallback.file_stem = "default"
	fallback.states = PackedStringArray(["default"])
	fallback.display_size = Vector2(16.0, 16.0)
	fallback.priority = 2
	slots.append(fallback)

	var ground := AssetSlotDefinition.new()
	ground.key = &"unit_ground"
	ground.category = &"test"
	ground.folder = "unit_ground"
	ground.states = PackedStringArray(["default"])
	ground.display_size = Vector2(16.0, 16.0)
	ground.tiled = true
	ground.tile_size = Vector2(16.0, 16.0)
	ground.priority = 3
	slots.append(ground)

	return slots


func _write_image(relative: String, width: int, height: int) -> String:
	var path := ROOT + "/" + relative
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.9, 0.2, 0.3, 1.0))
	image.save_png(path)
	return path


func _write_garbage(relative: String) -> String:
	var path := ROOT + "/" + relative
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("bukan gambar")
	file.close()
	return path


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

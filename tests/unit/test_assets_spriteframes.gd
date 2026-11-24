extends GutTest

## Mission 12: aset berbasis SpriteFrames (.tres) didahulukan di atas PNG.
## Semua SpriteFrames dibuat di memori lalu disimpan ke user:// — tidak ada
## file biner di repo.

const ROOT := "user://test_assets"

var _registry: AssetRegistry


func before_each() -> void:
	_clean_root()
	Assets.set_roots(PackedStringArray([ROOT]))
	_registry = AssetRegistry.new()
	_registry.slots = _slot_definitions()
	Assets.set_registry(_registry)
	Assets.reload_assets()


func after_each() -> void:
	Assets.reset_roots()
	Assets.set_registry(null)
	Assets.reload_assets()
	_clean_root()


# --- Rantai fallback --------------------------------------------------------

func test_exact_state_and_direction() -> void:
	_save_frames("unit/unit.tres", {
		"walk_left": {"fps": 12.0, "loop": true},
		"idle_down": {},
	})
	var resolved := Assets.resolve(&"unit", &"walk", &"left")
	assert_true(resolved.found)
	assert_true(resolved.is_sprite_frames())
	assert_false(resolved.from_fallback)
	assert_false(resolved.flip_h)
	assert_eq(resolved.animation, &"walk_left")


func test_falls_back_to_state_without_direction() -> void:
	_save_frames("unit/unit.tres", {"walk": {"fps": 10.0}})
	var resolved := Assets.resolve(&"unit", &"walk", &"left")
	assert_true(resolved.found)
	assert_true(resolved.from_fallback)
	assert_eq(resolved.animation, &"walk")
	assert_false(resolved.flip_h)


func test_mirrors_the_opposite_direction() -> void:
	_save_frames("unit/unit.tres", {"walk_right": {"fps": 9.0}})
	var resolved := Assets.resolve(&"unit", &"walk", &"left")
	assert_true(resolved.found)
	assert_eq(resolved.animation, &"walk_right")
	assert_true(resolved.flip_h, "arah kiri memakai art kanan yang dibalik")
	assert_eq(resolved.dir, &"right")


func test_falls_back_to_idle_with_direction() -> void:
	_save_frames("unit/unit.tres", {"idle_left": {"fps": 6.0}})
	var resolved := Assets.resolve(&"unit", &"hurt", &"left")
	assert_true(resolved.found)
	assert_eq(resolved.animation, &"idle_left")
	assert_eq(resolved.state, &"idle")


func test_falls_back_to_idle() -> void:
	_save_frames("unit/unit.tres", {"idle": {"fps": 6.0}})
	var resolved := Assets.resolve(&"unit", &"hurt", &"up")
	assert_true(resolved.found)
	assert_eq(resolved.animation, &"idle")


func test_falls_back_to_default_animation() -> void:
	_save_frames("unit/unit.tres", {"default": {"fps": 6.0}})
	var resolved := Assets.resolve(&"unit", &"hurt", &"up")
	assert_true(resolved.found)
	assert_eq(resolved.animation, &"default")


func test_placeholder_when_no_animation_matches() -> void:
	_save_frames("unit/unit.tres", {"idle_down": {}})
	var resolved := Assets.resolve(&"unit", &"hurt", &"up")
	assert_false(resolved.found)
	assert_null(resolved.sprite_frames)


# --- Precedence, fps/loop, resource -----------------------------------------

func test_spriteframes_wins_over_png() -> void:
	_write_image("unit/walk_left.png", 16, 16)
	_save_frames("unit/unit.tres", {"walk_left": {"fps": 12.0}})
	var resolved := Assets.resolve(&"unit", &"walk", &"left")
	assert_true(resolved.found)
	assert_true(resolved.is_sprite_frames())
	assert_string_contains(resolved.path, "unit.tres")


func test_authored_fps_and_loop_are_used() -> void:
	_save_frames("unit/unit.tres", {
		"walk_left": {"fps": 17.0, "loop": false},
		"idle_down": {"fps": 3.5, "loop": true},
	})
	var walk := Assets.resolve(&"unit", &"walk", &"left")
	assert_eq(walk.fps, 17.0, "fps dari resource, bukan asset_config")
	assert_false(walk.loop)
	var idle := Assets.resolve(&"unit", &"idle", &"down")
	assert_eq(idle.fps, 3.5)
	assert_true(idle.loop)


func test_resource_is_shared_not_copied() -> void:
	var path := _save_frames("unit/unit.tres", {"walk_left": {"fps": 12.0}})
	var first := Assets.resolve(&"unit", &"walk", &"left")
	var second := Assets.resolve(&"unit", &"walk", &"left")
	var loaded := Assets.sprite_frames_at(path)
	assert_same(first.sprite_frames, second.sprite_frames, "dua resolve memakai resource yang sama")
	assert_same(first.sprite_frames, loaded, "bukan salinan dari file .tres")


func test_art_size_uses_the_first_frame() -> void:
	_save_frames("unit/unit.tres", {"walk_left": {"frames": [Vector2i(16, 16), Vector2i(32, 32)]}})
	var resolved := Assets.resolve(&"unit", &"walk", &"left")
	assert_eq(resolved.texture_size(), Vector2(16, 16), "auto-scale memakai frame pertama")


func test_any_slot_can_use_spriteframes() -> void:
	_save_frames("prop/prop.tres", {
		"lit": {"fps": 8.0, "loop": true},
		"cold": {"fps": 6.0, "loop": false},
	})
	var lit := Assets.resolve(&"prop", &"lit", &"")
	assert_true(lit.found)
	assert_eq(lit.animation, &"lit")
	var cold := Assets.resolve(&"prop", &"cold", &"")
	assert_eq(cold.animation, &"cold")
	assert_false(cold.loop)


# --- Pemeriksaan & registry -------------------------------------------------

func test_audit_flags_bad_names_empty_and_inconsistent_frames() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"walk_down")
	frames.add_frame(&"walk_down", _texture(Vector2i(16, 16)))
	frames.add_frame(&"walk_down", _texture(Vector2i(32, 16)))
	frames.add_animation(&"jump_down")
	frames.add_frame(&"jump_down", _texture(Vector2i(16, 16)))
	frames.add_animation(&"walk_sideways")
	frames.add_frame(&"walk_sideways", _texture(Vector2i(16, 16)))
	frames.add_animation(&"empty_anim")
	var audit := Assets.audit_sprite_frames(_registry.get_slot(&"unit"), frames)
	var problems: PackedStringArray = audit["problems"]
	assert_true(_has(problems, "ukuran frame tidak konsisten"))
	assert_true(_has(problems, "state 'jump' tidak ada"))
	assert_true(_has(problems, "state 'walk_sideways' tidak ada"))
	assert_true(_has(problems, "empty_anim: animasi kosong"))
	assert_true(_has(problems, "tidak ada animasi idle"))
	assert_true(audit["animations"].has("walk_down"))


func test_shipped_registry_has_spriteframes_fields() -> void:
	var shipped := load("res://src/data/assets/asset_registry.tres") as AssetRegistry
	assert_not_null(shipped)
	for key in [&"player", &"wild_boar", &"island_deer"]:
		assert_true(shipped.get_slot(key).prefers_spriteframes, "%s memilih SpriteFrames" % key)
	var showcase := PackedStringArray()
	for slot in shipped.slots:
		if slot != null and slot.showcase:
			showcase.append(String(slot.key))
	assert_eq(showcase.size(), 12, "tepat 12 slot showcase")
	for key in [&"player", &"wild_boar", &"island_deer", &"campfire", &"tree", &"small_tree",
			&"small_rock", &"twig", &"ground_camp", &"ground_forest", &"workbench", &"tent"]:
		assert_true(showcase.has(String(key)), "%s ada di showcase" % key)
	for slot in shipped.slots:
		if slot != null and slot.showcase:
			assert_gt(slot.recommended_animations.size(), 0, "%s punya animasi disarankan" % slot.key)
	assert_true(shipped.get_slot(&"player").recommended_animations.has("walk_down"))


# --- VisualSlot -------------------------------------------------------------

func test_visual_slot_plays_the_shared_spriteframes() -> void:
	var path := _save_frames("unit/unit.tres", {
		"idle_down": {"fps": 6.0},
		"walk_left": {"fps": 12.0},
	})
	var owner := Node2D.new()
	add_child_autofree(owner)
	var placeholder := Polygon2D.new()
	placeholder.polygon = PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	owner.add_child(placeholder)
	var slot := VisualSlot.attach(owner, &"unit", [placeholder])
	var art := slot.get_art() as AnimatedSprite2D
	assert_not_null(art, "SpriteFrames memakai AnimatedSprite2D")
	assert_eq(art.animation, &"idle_down")
	slot.set_state(&"walk", &"left")
	art = slot.get_art() as AnimatedSprite2D
	assert_eq(art.animation, &"walk_left")
	assert_same(art.sprite_frames, Assets.sprite_frames_at(path), "resource dibagi, bukan disalin")
	assert_almost_eq(art.scale.x, 2.0, 0.001, "skala dari frame pertama 16 px ke kotak 32 px")
	assert_almost_eq(art.sprite_frames.get_animation_speed(&"walk_left"), 12.0, 0.001)


# --- Fixtures ---------------------------------------------------------------

func _slot_definitions() -> Array[AssetSlotDefinition]:
	var slots: Array[AssetSlotDefinition] = []
	var unit := AssetSlotDefinition.new()
	unit.key = &"unit"
	unit.category = &"test"
	unit.folder = "unit"
	unit.states = PackedStringArray(["idle", "walk", "hurt"])
	unit.directions = AssetSlotDefinition.Direction.FOUR
	unit.display_size = Vector2(32.0, 32.0)
	unit.priority = 1
	slots.append(unit)

	var prop := AssetSlotDefinition.new()
	prop.key = &"prop"
	prop.category = &"test"
	prop.folder = "prop"
	prop.states = PackedStringArray(["lit", "ember", "cold"])
	prop.display_size = Vector2(32.0, 32.0)
	prop.priority = 1
	slots.append(prop)
	return slots


func _save_frames(relative: String, spec: Dictionary) -> String:
	var frames := SpriteFrames.new()
	for animation in spec.keys():
		var name := StringName(animation)
		var data: Dictionary = spec[animation]
		if not frames.has_animation(name):
			frames.add_animation(name)
		frames.set_animation_speed(name, float(data.get("fps", 6.0)))
		frames.set_animation_loop(name, bool(data.get("loop", true)))
		for size in data.get("frames", [Vector2i(16, 16)]):
			frames.add_frame(name, _texture(size))
	var path := ROOT + "/" + relative
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var error := ResourceSaver.save(frames, path)
	assert_eq(error, OK, "gagal menyimpan SpriteFrames tes")
	Assets.reload_assets()
	return path


func _texture(size: Vector2i) -> ImageTexture:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.8, 0.4, 0.2, 1.0))
	return ImageTexture.create_from_image(image)


func _write_image(relative: String, width: int, height: int) -> String:
	var path := ROOT + "/" + relative
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.9, 0.2, 0.3, 1.0))
	image.save_png(path)
	return path


func _has(problems: PackedStringArray, fragment: String) -> bool:
	for problem in problems:
		if problem.contains(fragment):
			return true
	return false


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

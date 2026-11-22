extends GutTest

## Tes VisualSlot: placeholder disembunyikan/dipulihkan, auto-scale + pivot,
## state non-loop menahan frame dan memancarkan animation_finished, ground tile,
## serta duplikat art untuk efek sementara.

const ROOT := "user://test_assets"

var _registry: AssetRegistry
var _owner: Node2D
var _visual: Polygon2D


func before_each() -> void:
	_clean_root()
	Assets.set_roots(PackedStringArray([ROOT]))
	_registry = AssetRegistry.new()
	_registry.slots = _slot_definitions()
	Assets.set_registry(_registry)

	_owner = Node2D.new()
	add_child_autofree(_owner)
	_visual = Polygon2D.new()
	_visual.name = "Visual"
	_visual.color = Color(0.9, 0.8, 0.2, 1.0)
	_visual.polygon = PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
	_owner.add_child(_visual)


func after_each() -> void:
	Assets.reset_roots()
	Assets.set_registry(null)
	Assets.reload_assets()
	_clean_root()


func test_art_hides_placeholder_and_removal_restores_it() -> void:
	_write_image("unit/idle.png", 16, 16)
	var slot := VisualSlot.attach(_owner, &"unit", [_visual])
	assert_true(slot.is_showing_art())
	assert_false(_visual.visible)
	assert_not_null(slot.get_art())

	_remove("unit/idle.png")
	Assets.reload_assets()
	slot.refresh()
	assert_false(slot.is_showing_art())
	assert_true(_visual.visible)
	assert_null(slot.get_art())


func test_auto_scale_keeps_aspect_and_pivot() -> void:
	_write_image("unit/idle.png", 16, 8)
	var slot := VisualSlot.attach(_owner, &"unit", [_visual])
	var sprite := slot.get_art() as Sprite2D
	assert_not_null(sprite)
	# Kotak 32x32 dengan art 16x8 -> skala 2 (lebar jadi 32, tinggi 16).
	assert_almost_eq(sprite.scale.x, 2.0, 0.001)
	assert_almost_eq(sprite.scale.y, 2.0, 0.001)
	# Pivot BOTTOM_CENTER: offset dalam ruang lokal art (-tinggi/2);
	# setelah skala 2, dasar art tepat di origin node.
	assert_almost_eq(sprite.offset.y, -4.0, 0.001)


func test_placeholder_transform_is_mirrored_to_art() -> void:
	_write_image("unit/idle.png", 16, 16)
	var slot := VisualSlot.attach(_owner, &"unit", [_visual])
	_visual.modulate = Color(1.6, 0.7, 0.7, 1.0)
	_visual.position = Vector2(3.0, 0.0)
	slot._process(0.016)
	var art := slot.get_art()
	assert_eq(art.modulate, Color(1.6, 0.7, 0.7, 1.0))
	assert_eq(art.position, Vector2(3.0, 0.0))


func test_state_switch_uses_mirror_fallback() -> void:
	_write_image("unit/walk_right.png", 16, 16)
	var slot := VisualSlot.attach(_owner, &"unit", [_visual])
	slot.set_state(&"walk", &"left")
	assert_true(slot.is_showing_art())
	assert_true(slot.get_art().flip_h)


func test_non_looping_state_holds_last_frame_and_emits() -> void:
	_write_image("unit/hurt_2f.png", 32, 16)
	var slot := VisualSlot.attach(_owner, &"unit", [_visual])
	watch_signals(slot)
	slot.set_state(&"hurt", &"")
	var animated := slot.get_art() as AnimatedSprite2D
	assert_not_null(animated)
	assert_false(animated.sprite_frames.get_animation_loop(&"default"))
	await wait_seconds(0.6)
	assert_signal_emitted(slot, "animation_finished")
	assert_eq(animated.frame, 1)


func test_ground_slot_tiles_polygon() -> void:
	_write_image("unit_ground/default.png", 16, 16)
	var slot := VisualSlot.attach(_owner, &"unit_ground", [_visual])
	assert_true(slot.is_showing_art())
	# Polygon tetap terlihat (bentuk zona) dan teksturnya diulang.
	assert_true(_visual.visible)
	assert_not_null(_visual.texture)
	assert_eq(_visual.texture_repeat, CanvasItem.TEXTURE_REPEAT_ENABLED)
	assert_almost_eq(_visual.texture_scale.x, 1.0 / 16.0, 0.0001)


func test_duplicate_art_returns_standalone_copy() -> void:
	_write_image("unit/idle.png", 16, 16)
	var slot := VisualSlot.attach(_owner, &"unit", [_visual])
	var copy := slot.duplicate_art()
	assert_not_null(copy)
	assert_ne(copy.get_instance_id(), slot.get_art().get_instance_id())
	copy.free()


func test_missing_registry_slot_keeps_placeholder_visible() -> void:
	var slot := VisualSlot.attach(_owner, &"tidak_ada", [_visual])
	assert_false(slot.is_showing_art())
	assert_true(_visual.visible)


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
	unit.pivot = AssetSlotDefinition.Pivot.BOTTOM_CENTER
	unit.priority = 1
	unit.fps = {"hurt": 10.0}
	unit.loop_states = PackedStringArray(["idle", "walk"])
	slots.append(unit)

	var ground := AssetSlotDefinition.new()
	ground.key = &"unit_ground"
	ground.category = &"test"
	ground.folder = "unit_ground"
	ground.states = PackedStringArray(["default"])
	ground.display_size = Vector2(16.0, 16.0)
	ground.tiled = true
	ground.tile_size = Vector2(16.0, 16.0)
	ground.priority = 2
	slots.append(ground)

	return slots


func _write_image(relative: String, width: int, height: int) -> void:
	var path := ROOT + "/" + relative
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.4, 0.9, 1.0))
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

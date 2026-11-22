class_name VisualSlot
extends Node2D

## Node visual untuk satu slot aset.
##
## Dipasang dengan satu baris di _ready entity:
##   VisualSlot.attach(self, &"player", [$Visual])
##
## Placeholder tetap ada (hanya disembunyikan) saat art tersedia, jadi tes lama
## yang mencari node placeholder tetap jalan. VisualSlot meniru modulate,
## position, scale, dan rotation placeholder pertama, sehingga flash/squash/
## shake/goncangan yang sudah ada tetap terlihat di art tanpa perubahan kode.

signal animation_finished(state: StringName)

const ART_NAME := "Art"
const SLOT_NAME := "VisualSlot"

var key: StringName = &""
var _state: StringName = &""
var _dir: StringName = &""
var _placeholders: Array[CanvasItem] = []
var _driver: Node
var _art: Node2D
var _resolved: ResolvedVisual

var _art_scale: Vector2 = Vector2.ONE
var _art_pivot_offset: Vector2 = Vector2.ZERO
## Diisi saat slot memakai Polygon2D ground yang di-tile.
var _tiled_polygon: Polygon2D
var _tiled_original_texture: Texture2D


## Pasang slot pada `owner`. Parent default = parent placeholder pertama,
## sehingga kode feedback yang menarget node visual lama tidak berubah.
static func attach(owner: Node, key: StringName, placeholders: Array = [], parent: Node = null, driver: Node = null) -> VisualSlot:
	var slot := VisualSlot.new()
	slot.name = SLOT_NAME
	slot.key = key
	for placeholder in placeholders:
		if placeholder is CanvasItem:
			slot._placeholders.append(placeholder)

	var host := parent
	if host == null:
		for placeholder in slot._placeholders:
			host = placeholder.get_parent()
			if host != null:
				break
	if host == null:
		host = owner
	host.add_child(slot)

	if driver != null:
		slot._driver = driver
		if String(driver.name).is_empty() or String(driver.name).begins_with("@"):
			driver.name = "Driver"
		slot.add_child(driver)
		if driver.has_method(&"setup"):
			driver.setup(owner, slot)

	slot.refresh()
	return slot


# --- API --------------------------------------------------------------------

func set_state(state: StringName, dir: StringName = &"") -> void:
	var next_dir := dir
	if String(next_dir).is_empty():
		next_dir = _dir
	if _state == state and _dir == next_dir and (_art != null or _resolved != null):
		return
	_state = state
	_dir = next_dir
	_rebuild()


func play(state: StringName, dir: StringName = &"") -> void:
	set_state(state, dir)
	if _art is AnimatedSprite2D:
		(_art as AnimatedSprite2D).play(&"default")


func get_state() -> StringName:
	return _state


func get_direction() -> StringName:
	return _dir


func is_showing_art() -> bool:
	return _art != null or (_tiled_polygon != null and _tiled_polygon.texture != null)


func get_art() -> Node2D:
	return _art


func get_resolved() -> ResolvedVisual:
	return _resolved


## True bila slot mendefinisikan state ini (mis. "death").
func has_state(state: StringName) -> bool:
	var slot := Assets.registry().get_slot(key)
	return slot != null and slot.states.has(String(state))


## Muat ulang setelah Assets.reload_assets().
func refresh() -> void:
	_resolve_cache_reset()
	_rebuild()


## Salinan node art untuk efek sementara (mis. pohon tumbang / bangkai fauna).
func duplicate_art() -> Node2D:
	if _art == null:
		return null
	var copy := _art.duplicate() as Node2D
	copy.name = ART_NAME
	return copy


func get_placeholder_nodes() -> Array[CanvasItem]:
	return _placeholders


func get_first_placeholder() -> CanvasItem:
	return _placeholders[0] if not _placeholders.is_empty() else null


# --- Siklus hidup -----------------------------------------------------------

func _ready() -> void:
	add_to_group(&"visual_slot")
	if _state == &"":
		var slot := Assets.registry().get_slot(key)
		_state = slot.default_state() if slot != null else &"idle"
		var dirs := slot.dirs() if slot != null else PackedStringArray([""])
		_dir = StringName(dirs[0] if dirs.size() > 0 else "")
	refresh()


func _process(_delta: float) -> void:
	_sync_from_placeholder()


func _exit_tree() -> void:
	_restore_tiled_polygon()


# --- Internal ---------------------------------------------------------------

func _resolve_cache_reset() -> void:
	Assets.clear_resolve_cache()


func _rebuild() -> void:
	_free_art()
	_restore_tiled_polygon()

	var slot := Assets.registry().get_slot(key)
	if slot == null:
		_show_placeholders(true)
		return
	if _state == &"":
		_state = slot.default_state()
	if _dir == &"":
		_dir = StringName(slot.dirs()[0])

	_resolved = Assets.resolve(key, _state, _dir)
	if not _resolved.found:
		_show_placeholders(true)
		return

	if slot.tiled:
		_apply_tiled(slot, _resolved)
		return

	_build_art(slot, _resolved)
	_show_placeholders(false)


func _build_art(slot: AssetSlotDefinition, resolved: ResolvedVisual) -> void:
	var art_size := resolved.texture_size()
	if art_size.x <= 0.0 or art_size.y <= 0.0:
		_show_placeholders(true)
		return

	_art_scale = _compute_scale(slot, art_size)
	_art_pivot_offset = _compute_pivot_offset(slot, art_size)

	if resolved.is_animated():
		var animated := AnimatedSprite2D.new()
		animated.name = ART_NAME
		animated.sprite_frames = resolved.sprite_frames
		animated.animation = &"default"
		animated.centered = true
		animated.offset = _art_pivot_offset + slot.offset
		animated.flip_h = resolved.flip_h
		animated.scale = _art_scale
		animated.texture_filter = _filter()
		animated.z_index = 1
		if not animated.animation_finished.is_connected(_on_animation_finished):
			animated.animation_finished.connect(_on_animation_finished)
		_art = animated
	else:
		var sprite := Sprite2D.new()
		sprite.name = ART_NAME
		sprite.texture = resolved.texture
		sprite.centered = true
		sprite.offset = _art_pivot_offset + slot.offset
		sprite.flip_h = resolved.flip_h
		sprite.scale = _art_scale
		sprite.texture_filter = _filter()
		sprite.z_index = 1
		_art = sprite

	add_child(_art)
	if _art is AnimatedSprite2D:
		(_art as AnimatedSprite2D).play(&"default")
	_sync_from_placeholder()


func _compute_scale(slot: AssetSlotDefinition, art_size: Vector2) -> Vector2:
	# Aspect ratio dipertahankan; kotak display_size adalah batas maksimum.
	var scale_x := slot.display_size.x / art_size.x
	var scale_y := slot.display_size.y / art_size.y
	var uniform := minf(scale_x, scale_y)
	if uniform <= 0.0:
		uniform = 1.0
	return Vector2(uniform, uniform)


func _compute_pivot_offset(slot: AssetSlotDefinition, art_size: Vector2) -> Vector2:
	if slot.pivot == AssetSlotDefinition.Pivot.BOTTOM_CENTER:
		return Vector2(0.0, -art_size.y * 0.5)
	return Vector2.ZERO


func _filter() -> CanvasItem.TextureFilter:
	return CanvasItem.TEXTURE_FILTER_NEAREST if Assets.config().pixel_art else CanvasItem.TEXTURE_FILTER_LINEAR


func _apply_tiled(slot: AssetSlotDefinition, resolved: ResolvedVisual) -> void:
	var polygon := _first_polygon_placeholder()
	if polygon == null:
		_show_placeholders(true)
		return
	if _tiled_polygon == null:
		_tiled_original_texture = polygon.texture
	_tiled_polygon = polygon
	polygon.texture = resolved.texture
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var tile := slot.tile_size
	if tile.x <= 0.0 or tile.y <= 0.0:
		tile = slot.display_size
	polygon.texture_scale = Vector2(1.0 / maxf(tile.x, 1.0), 1.0 / maxf(tile.y, 1.0))
	polygon.texture_filter = _filter()
	# Polygon tetap terlihat: ia adalah bentuk zona, texture hanya mengisinya.
	polygon.visible = true


func _restore_tiled_polygon() -> void:
	if _tiled_polygon == null or not is_instance_valid(_tiled_polygon):
		_tiled_polygon = null
		return
	_tiled_polygon.texture = _tiled_original_texture
	_tiled_polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	_tiled_polygon.texture_scale = Vector2.ONE
	_tiled_polygon = null


func _first_polygon_placeholder() -> Polygon2D:
	for placeholder in _placeholders:
		if placeholder is Polygon2D:
			return placeholder
	return null


func _free_art() -> void:
	if _art == null:
		return
	if is_instance_valid(_art):
		remove_child(_art)
		_art.free()
	_art = null


func _show_placeholders(visible_state: bool) -> void:
	for placeholder in _placeholders:
		if placeholder != null and is_instance_valid(placeholder):
			placeholder.visible = visible_state


func _sync_from_placeholder() -> void:
	if _art == null or _placeholders.is_empty():
		return
	var source := _placeholders[0]
	if source == null or not is_instance_valid(source):
		return
	_art.modulate = source.modulate
	_art.position = source.position
	_art.rotation = source.rotation
	_art.scale = source.scale * _art_scale


func _on_animation_finished() -> void:
	if _state == &"":
		return
	animation_finished.emit(_state)

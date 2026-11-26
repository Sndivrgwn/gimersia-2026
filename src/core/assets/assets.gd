class_name Assets
extends RefCounted

## Jembatan satu-satunya antara file seni di res://assets/ dan gameplay.
##
## Konvensi di atas konfigurasi: user hanya menaruh file dengan nama yang benar
## di assets/, tidak menyentuh .tscn/.tres. Semua pencarian jatuh ke placeholder
## bila file tidak ada, jadi build tanpa art berjalan persis seperti sebelumnya.
##
## Statis, bukan autoload. Tes bisa mengarahkan root ke user:// lewat
## `set_roots()` sehingga tidak ada file biner di repo.

const DEFAULT_ROOT := "res://assets"
const REGISTRY_PATH := "res://src/data/assets/asset_registry.tres"
const CONFIG_PATH := "res://src/data/configs/asset_config.tres"
const EXTENSIONS: Array[String] = ["png", "webp"]
## Mission 12: satu file SpriteFrames per slot, diutamakan di atas PNG.
const SPRITEFRAMES_EXTENSION := "tres"
const ITEM_ICON_FOLDER := "icons/items"
const DEFAULT_STATE := &"default"

static var _roots_override: PackedStringArray = PackedStringArray()
static var _registry_override: bool = false
static var _registry: AssetRegistry
static var _config: AssetConfig
static var _texture_cache: Dictionary = {}
static var _sprite_frames_cache: Dictionary = {}
static var _icon_cache: Dictionary = {}
static var _listing_cache: Dictionary = {}
static var _warned: Dictionary = {}
static var _resolve_cache: Dictionary = {}
static var _warning_sink: Callable = Callable()


# --- Konfigurasi ------------------------------------------------------------

static func registry() -> AssetRegistry:
	if _registry == null:
		if ResourceLoader.exists(REGISTRY_PATH):
			_registry = ResourceLoader.load(REGISTRY_PATH) as AssetRegistry
		if _registry == null:
			_registry = AssetRegistry.new()
	return _registry


static func config() -> AssetConfig:
	if _config == null:
		if ResourceLoader.exists(CONFIG_PATH):
			_config = ResourceLoader.load(CONFIG_PATH) as AssetConfig
		if _config == null:
			_config = AssetConfig.new()
	return _config


## Override registry (tes).
static func set_registry(value: AssetRegistry) -> void:
	_registry = value
	_registry_override = value != null
	_resolve_cache.clear()
	_texture_cache.clear()


static func set_config(value: AssetConfig) -> void:
	_config = value
	_resolve_cache.clear()


## Hanya membuang cache hasil resolve (dipakai VisualSlot.refresh()).
static func clear_resolve_cache() -> void:
	_resolve_cache.clear()


## Tes bisa menangkap peringatan lewat sink; default tetap push_warning.
static func set_warning_sink(sink: Callable) -> void:
	_warning_sink = sink


## Ganti daftar root (tes memakai user://). Harus diakhiri tanpa "/".
static func set_roots(p_roots: PackedStringArray) -> void:
	_roots_override = p_roots
	_texture_cache.clear()
	_sprite_frames_cache.clear()
	_icon_cache.clear()
	_listing_cache.clear()
	_resolve_cache.clear()
	_warned.clear()


static func reset_roots() -> void:
	set_roots(PackedStringArray())


static func roots() -> PackedStringArray:
	if not _roots_override.is_empty():
		return _roots_override
	return PackedStringArray([DEFAULT_ROOT])


## Buang cache dan muat ulang registry/tekstur (tombol reload aset).
## Catatan: namanya bukan `reload` karena bentrok dengan GDScript.reload().
static func reload_assets() -> void:
	_texture_cache.clear()
	_sprite_frames_cache.clear()
	_icon_cache.clear()
	_listing_cache.clear()
	_resolve_cache.clear()
	_warned.clear()
	if not _registry_override:
		_registry = null
	_config = null
	if not _registry_override and ResourceLoader.exists(REGISTRY_PATH):
		_registry = ResourceLoader.load(REGISTRY_PATH, "", ResourceLoader.CACHE_MODE_REPLACE) as AssetRegistry
	if ResourceLoader.exists(CONFIG_PATH):
		_config = ResourceLoader.load(CONFIG_PATH, "", ResourceLoader.CACHE_MODE_REPLACE) as AssetConfig


# --- Resolve ----------------------------------------------------------------

## Cari visual untuk (key, state, dir) mengikuti rantai fallback.
## Tidak pernah null: `found == false` berarti placeholder.
static func resolve(key: StringName, state: StringName = DEFAULT_STATE, dir: StringName = &"") -> ResolvedVisual:
	var cache_key := "%s|%s|%s" % [key, state, dir]
	if _resolve_cache.has(cache_key):
		return _resolve_cache[cache_key]

	var result := ResolvedVisual.new()
	result.key = key
	result.state = state
	result.dir = dir

	var slot := registry().get_slot(key)
	if slot == null:
		_resolve_cache[cache_key] = result
		return result

	result.slot = slot
	# Mission 12: .tres SpriteFrames menang atas strip/PNG statis.
	var frames_path := spriteframes_path(slot)
	if not frames_path.is_empty():
		var frames := sprite_frames_at(frames_path)
		var picked := pick_animation(slot, frames, String(state), String(dir))
		if not picked.is_empty():
			var sprite_visual := _build_sprite_visual(frames_path, frames, picked)
			sprite_visual.key = key
			sprite_visual.slot = slot
			sprite_visual.from_fallback = String(picked["animation"]) != animation_name(String(state), String(dir))
			_resolve_cache[cache_key] = sprite_visual
			return sprite_visual

	for entry in _fallback_chain(slot, String(state), String(dir)):
		var fall_state: String = entry[0]
		var fall_dir: String = entry[1]
		var path := _find_file(slot, fall_state, fall_dir)
		if path.is_empty():
			continue
		var resolved := _build_visual(slot, path, fall_state, fall_dir)
		if resolved == null:
			continue
		resolved.key = key
		resolved.from_fallback = fall_state != String(state) or fall_dir != String(dir) or bool(entry[2])
		resolved.flip_h = bool(entry[2])
		_resolve_cache[cache_key] = resolved
		return resolved

	_resolve_cache[cache_key] = result
	return result


## True bila slot punya art untuk state/arah utamanya.
static func has_art(key: StringName) -> bool:
	var slot := registry().get_slot(key)
	if slot == null:
		return false
	var state := String(slot.default_state())
	var dirs := slot.dirs()
	return resolve(key, StringName(state), StringName(dirs[0] if dirs.size() > 0 else "")).found


## Ikon item dari assets/icons/items/<item_id>.png (atau .webp).
static func item_icon(item_id: StringName) -> Texture2D:
	if String(item_id).is_empty():
		return null
	if _icon_cache.has(item_id):
		return _icon_cache[item_id] as Texture2D
	var found: Texture2D = null
	for root in roots():
		var dir_path := _join(root, ITEM_ICON_FOLDER)
		for extension in EXTENSIONS:
			var path := dir_path + "/" + String(item_id) + "." + extension
			var texture := _texture_at(path)
			if texture != null:
				found = texture
				break
		if found != null:
			break
	_icon_cache[item_id] = found
	return found


## Tekstur UI/satu-frame untuk slot mana pun (state default).
static func ui_texture(key: StringName) -> Texture2D:
	var resolved := resolve(key, DEFAULT_STATE, &"")
	return resolved.texture if resolved.found else null


## Font UI (slot ui_font_main / ui_font_bold: assets/ui/fonts/main.ttf|otf).
static func font(key: StringName) -> Font:
	var slot := registry().get_slot(key)
	if slot == null:
		return null
	for root in roots():
		var dir_path := _join(root, slot.folder)
		var font_extensions: Array[String] = ["ttf", "otf"]
		for extension in font_extensions:
			var path: String = dir_path + "/" + slot.stem_for("default") + "." + extension
			if not _file_exists(path):
				continue
			var res := ResourceLoader.load(path) if path.begins_with("res://") else null
			if res is Font:
				return res
	return null


## Ringkasan cakupan: {filled, total, missing_priority1}.
static func coverage() -> Dictionary:
	var filled := 0
	var missing: PackedStringArray = PackedStringArray()
	var slots := registry().slots
	for slot in slots:
		if slot == null:
			continue
		if has_art(slot.key):
			filled += 1
		elif slot.priority == 1:
			missing.append(String(slot.key))
	return {
		"filled": filled,
		"total": slots.size(),
		"missing_priority1": missing,
	}


# --- Parsing nama file (murni) ---------------------------------------------

## "walk_down_4f.png" -> {ok, state: "walk", dir: "down", frames: 4}.
static func parse_filename(file_name: String) -> Dictionary:
	var result := {"ok": false, "state": "", "dir": "", "frames": 1}
	var extension := file_name.get_extension().to_lower()
	if not EXTENSIONS.has(extension):
		return result

	var base := file_name.get_basename().to_lower()
	if base.is_empty():
		return result

	var parts := base.split("_", false)
	if parts.is_empty():
		return result

	var frames := 1
	var last := parts[parts.size() - 1]
	if last.length() > 1 and last.ends_with("f"):
		var digits := last.substr(0, last.length() - 1)
		if digits.is_valid_int() and not digits.begins_with("0"):
			frames = int(digits)
			parts.remove_at(parts.size() - 1)

	var dir := ""
	if parts.size() > 0:
		var candidate := parts[parts.size() - 1]
		if Dir4.is_direction(candidate):
			dir = candidate
			parts.remove_at(parts.size() - 1)

	if parts.is_empty():
		return result

	result["ok"] = true
	result["state"] = "_".join(parts)
	result["dir"] = dir
	result["frames"] = frames
	return result


## Rantai fallback sebagai Array [[state, dir, flip], ...].
static func fallback_chain(slot: AssetSlotDefinition, state: String, dir: String) -> Array:
	return _fallback_chain(slot, state, dir)


# --- SpriteFrames (.tres) ---------------------------------------------------

## Nama animasi untuk (state, dir): "walk_down" atau "walk".
static func animation_name(state: String, dir: String) -> String:
	return state if dir.is_empty() else state + "_" + dir


## Path .tres slot: <root>/<folder>/<key>.tres (root pertama yang punya file).
static func spriteframes_path(slot: AssetSlotDefinition) -> String:
	if slot == null:
		return ""
	for root in roots():
		var path := _join(root, slot.folder) + "/" + String(slot.key) + ".tres"
		if _file_exists(path):
			return path
	return ""


## Muat SpriteFrames dari .tres. Instance di-cache dan dipakai bersama
## (AnimatedSprite2D memakai resource yang sama, tanpa salinan).
static func sprite_frames_at(path: String) -> SpriteFrames:
	if path.is_empty():
		return null
	if _sprite_frames_cache.has(path):
		return _sprite_frames_cache[path] as SpriteFrames
	if not _file_exists(path):
		return null
	var loaded := ResourceLoader.load(path) if path.begins_with("res://") else ResourceLoader.load(path)
	var frames := loaded as SpriteFrames
	if frames == null:
		_warn_once(path)
		return null
	_sprite_frames_cache[path] = frames
	return frames


## Pilih animasi memakai rantai fallback yang sama dengan PNG:
## state_dir -> state -> state_mirror (flip_h) -> idle_dir -> idle -> default.
## Animasi kosong (0 frame) dianggap tidak ada. {} bila tidak ada yang cocok.
static func pick_animation(slot: AssetSlotDefinition, frames: SpriteFrames, state: String, dir: String) -> Dictionary:
	if frames == null:
		return {}
	for entry in _fallback_chain(slot, state, dir):
		var fall_state: String = entry[0]
		var fall_dir: String = entry[1]
		var anim := animation_name(fall_state, fall_dir)
		if not frames.has_animation(anim):
			continue
		if frames.get_frame_count(anim) <= 0:
			continue
		return {
			"animation": anim,
			"state": fall_state,
			"dir": fall_dir,
			"flip": bool(entry[2]),
		}
	return {}


## Pemeriksaan SpriteFrames satu slot (dipakai tools/check_assets.gd dan tes).
## Mengembalikan {animations, problems} tanpa menyentuh file.
static func audit_sprite_frames(slot: AssetSlotDefinition, frames: SpriteFrames) -> Dictionary:
	var animations := PackedStringArray()
	var problems := PackedStringArray()
	if slot == null or frames == null:
		return {"animations": animations, "problems": problems}
	for name in frames.get_animation_names():
		var anim := String(name)
		animations.append(anim)
		var count := frames.get_frame_count(name)
		if count <= 0:
			problems.append("%s: animasi kosong (0 frame)" % anim)
			continue
		var parts := anim.split("_")
		var dir := ""
		if parts.size() > 1 and Dir4.is_direction(parts[parts.size() - 1]):
			dir = parts[parts.size() - 1]
			parts.remove_at(parts.size() - 1)
		var state := "_".join(parts)
		if not slot.states.has(state):
			problems.append("%s: state '%s' tidak ada di slot" % [anim, state])
		elif not dir.is_empty() and not slot.dirs().has(dir):
			problems.append("%s: slot ini tidak memakai arah '%s'" % [anim, dir])
		var first := frames.get_frame_texture(name, 0)
		var first_size := first.get_size() if first != null else Vector2.ZERO
		for index in range(1, count):
			var texture := frames.get_frame_texture(name, index)
			if texture != null and texture.get_size() != first_size:
				problems.append("%s: ukuran frame tidak konsisten (frame %d %s vs frame 0 %s)" % [
					anim, index, str(texture.get_size()), str(first_size)
				])
				break
	if slot.states.has("idle"):
		var has_idle := false
		for name in frames.get_animation_names():
			var anim := String(name)
			if anim == "idle" or anim.begins_with("idle_"):
				has_idle = true
				break
		if not has_idle:
			problems.append("idle: tidak ada animasi idle")
	return {"animations": animations, "problems": problems}


## Potong strip horizontal N frame menjadi AtlasTexture.
static func frame_textures(texture: Texture2D, frames: int) -> Array[AtlasTexture]:
	var result: Array[AtlasTexture] = []
	if texture == null or frames <= 0:
		return result
	var frame_width := floori(float(texture.get_width()) / float(frames))
	if frame_width <= 0:
		return result
	for index in frames:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(index * frame_width, 0, frame_width, texture.get_height())
		atlas.filter_clip = true
		result.append(atlas)
	return result


## SpriteFrames satu animasi untuk strip.
static func build_sprite_frames(texture: Texture2D, frames: int, fps: float, loop: bool) -> SpriteFrames:
	var sprite_frames := SpriteFrames.new()
	if not sprite_frames.has_animation(&"default"):
		sprite_frames.add_animation(&"default")
	sprite_frames.set_animation_speed(&"default", maxf(fps, 0.0))
	sprite_frames.set_animation_loop(&"default", loop)
	for atlas in frame_textures(texture, frames):
		sprite_frames.add_frame(&"default", atlas)
	return sprite_frames


# --- Internal ---------------------------------------------------------------

static func _fallback_chain(_slot: AssetSlotDefinition, state: String, dir: String) -> Array:
	var chain: Array = []
	var has_dir := not dir.is_empty()
	chain.append([state, dir, false])
	if has_dir:
		chain.append([state, "", false])
		if config().mirror_fallback:
			var mirror := String(Dir4.mirrored(StringName(dir)))
			if not mirror.is_empty():
				chain.append([state, mirror, true])
	if state != "idle":
		if has_dir:
			chain.append(["idle", dir, false])
		chain.append(["idle", "", false])
	chain.append(["default", "", false])
	return chain


## Hasil resolve dari SpriteFrames: fps dan loop ikut resource, bukan config.
static func _build_sprite_visual(path: String, frames: SpriteFrames, picked: Dictionary) -> ResolvedVisual:
	var animation := StringName(picked["animation"])
	var result := ResolvedVisual.new()
	result.path = path
	result.state = StringName(picked["state"])
	result.dir = StringName(picked["dir"])
	result.animation = animation
	result.from_spriteframes = true
	result.sprite_frames = frames
	result.flip_h = bool(picked["flip"])
	result.frame_count = frames.get_frame_count(animation)
	result.fps = frames.get_animation_speed(animation)
	result.loop = frames.get_animation_loop(animation)
	var first := frames.get_frame_texture(animation, 0)
	result.texture = first
	if first != null:
		result.set_art_size(first.get_size())
	result.found = true
	return result


static func _build_visual(slot: AssetSlotDefinition, path: String, state: String, dir: String) -> ResolvedVisual:
	var texture := _texture_at(path)
	if texture == null:
		return null

	var frames := 1
	var info := parse_filename(path.get_file())
	if info["ok"]:
		frames = int(info["frames"])

	var result := ResolvedVisual.new()
	result.path = path
	result.state = StringName(state)
	result.dir = StringName(dir)
	result.frame_count = frames
	result.loop = slot.is_loop(state)
	var fps := slot.state_fps(state)
	if fps <= 0.0:
		fps = config().fps_for(state)
	result.fps = fps
	var safe_frames := maxi(frames, 1)
	result.set_art_size(Vector2(float(texture.get_width()) / float(safe_frames), float(texture.get_height())))

	if frames > 1:
		result.sprite_frames = build_sprite_frames(texture, frames, fps, result.loop)
		result.texture = texture
	else:
		result.texture = texture
	result.found = true
	return result


## Cari file pertama yang cocok (state, dir) di salah satu root.
static func _find_file(slot: AssetSlotDefinition, state: String, dir: String) -> String:
	var stem := slot.stem_for(state)

	for root in roots():
		var dir_path := _join(root, slot.folder)
		if not _directory_exists(dir_path):
			continue
		var names := _list_files(dir_path)
		var single := ""
		for name in names:
			var info := parse_filename(String(name))
			if not bool(info["ok"]):
				continue
			if String(info["state"]) != stem or String(info["dir"]) != dir:
				continue
			var path := dir_path + "/" + String(name)
			if not _file_exists(path):
				continue
			if int(info["frames"]) > 1:
				return path
			if single.is_empty():
				single = path
		if not single.is_empty():
			return single
	return ""


static func _texture_at(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	if not _file_exists(path):
		# File tidak ada = normal (fallback), bukan peringatan.
		return null

	var texture: Texture2D = null
	if path.begins_with("res://") and ResourceLoader.exists(path):
		var loaded := ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REPLACE)
		if loaded is Texture2D:
			texture = loaded
	elif _file_exists(path):
		var image := _load_image(path)
		if image != null and not image.is_empty():
			texture = ImageTexture.create_from_image(image)

	if texture == null:
		_warn_once(path)
	else:
		_texture_cache[path] = texture
	return texture


static func _load_image(path: String) -> Image:
	# Membaca byte lalu men-decode sendiri: file rusak menghasilkan error code,
	# bukan pesan error engine (dan tidak pernah membuat engine crash).
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var extension := path.get_extension().to_lower()
	if not _has_valid_signature(bytes, extension):
		# Bukan file gambar (mis. hasil rename / file rusak): jangan decode.
		return null
	var image := Image.new()
	var error := ERR_FILE_CORRUPT
	if extension == "png":
		error = image.load_png_from_buffer(bytes)
	elif extension == "webp":
		error = image.load_webp_from_buffer(bytes)
	return image if error == OK else null


static func _has_valid_signature(bytes: PackedByteArray, extension: String) -> bool:
	if extension == "png":
		if bytes.size() < 8:
			return false
		var signature: Array[int] = [137, 80, 78, 71, 13, 10, 26, 10]
		for index in signature.size():
			if bytes[index] != signature[index]:
				return false
		return true
	if extension == "webp":
		if bytes.size() < 12:
			return false
		return bytes.slice(0, 4).get_string_from_ascii() == "RIFF" \
			and bytes.slice(8, 12).get_string_from_ascii() == "WEBP"
	return false


static func _warn_once(path: String) -> void:
	if _warned.has(path):
		return
	_warned[path] = true
	var message := "Assets: file tidak bisa dibaca, memakai placeholder: %s" % path
	if _warning_sink.is_valid():
		_warning_sink.call(message)
	else:
		push_warning(message)


## Daftar file per folder di-cache sampai reload (dipakai pencarian slot).
static func _list_files(dir_path: String) -> Array:
	if _listing_cache.has(dir_path):
		return _listing_cache[dir_path]
	var names := Array(DirAccess.get_files_at(dir_path))
	names.sort()
	_listing_cache[dir_path] = names
	return names


static func _directory_exists(path: String) -> bool:
	return DirAccess.dir_exists_absolute(path)


static func _file_exists(path: String) -> bool:
	if path.begins_with("res://"):
		if ResourceLoader.exists(path):
			return true
		return FileAccess.file_exists(path)
	return FileAccess.file_exists(path)


static func _join(root: String, folder: String) -> String:
	var clean_root := root.trim_suffix("/")
	var clean_folder := folder.trim_prefix("/").trim_suffix("/")
	if clean_folder.is_empty():
		return clean_root
	return clean_root + "/" + clean_folder

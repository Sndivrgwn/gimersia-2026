extends SceneTree

## Pemeriksa aset (read-only, tidak menulis apa pun ke repo).
## Jalankan: GODOT --headless --path . -s tools/check_assets.gd
##
## Melaporkan: cakupan slot, slot prioritas 1 yang kosong, cakupan + typo +
## duplikat + bentuk ikon item (`assets/icons/items`) dan art item di tangan
## (`assets/held`), file di assets/ yang tidak cocok dengan slot mana pun (plus
## petunjuk typo), strip yang lebarnya tidak habis dibagi jumlah frame, dan
## rasio aspek yang menyimpang > 25%.

const EXTENSIONS: Array[String] = ["png", "webp"]
const ASPECT_TOLERANCE := 0.25


func _init() -> void:
	var registry := Assets.registry()
	var coverage := Assets.coverage()
	print("=== Cakupan aset: %d/%d slot terisi ===" % [coverage["filled"], coverage["total"]])

	var missing: PackedStringArray = coverage["missing_priority1"]
	if missing.is_empty():
		print("Prioritas 1: semua terisi.")
	else:
		print("Prioritas 1 kosong (%d): %s" % [missing.size(), ", ".join(missing)])

	_report_item_assets()
	_report_unmatched(registry)
	_report_strips(registry)
	_report_aspect(registry)
	quit(0)


func _report_unmatched(registry: AssetRegistry) -> void:
	var known: Dictionary = {}
	for slot in registry.slots:
		if slot != null:
			known[slot.folder] = true
	# Ikon item dan held item punya folder sendiri di luar registry.
	var item_folders := _item_folders_relative()

	var folder_names: Array[String] = []
	for folder in known.keys():
		folder_names.append(_normalize(folder))

	var problems: Array[String] = []
	for file_path in _walk(Assets.DEFAULT_ROOT):
		if not EXTENSIONS.has(file_path.get_extension().to_lower()):
			continue
		var relative := file_path.trim_prefix(Assets.DEFAULT_ROOT + "/")
		var folder := relative.get_base_dir()
		if item_folders.has(folder):
			continue
		if not known.has(folder):
			problems.append("%s (folder tidak dikenal; mirip: %s)" % [relative, _closest(folder, folder_names)])
			continue
		var slot := _slot_for_folder(registry, folder)
		if slot == null:
			continue
		var info := Assets.parse_filename(file_path.get_file())
		if not bool(info["ok"]):
			problems.append("%s (nama file tidak bisa dibaca)" % relative)
			continue
		if not slot.states.has(String(info["state"])):
			problems.append("%s (state '%s' tidak ada di slot %s)" % [relative, info["state"], slot.key])
		var dir := String(info["dir"])
		if not dir.is_empty() and not slot.dirs().has(dir):
			problems.append("%s (arah '%s' tidak dipakai slot %s)" % [relative, dir, slot.key])

	if problems.is_empty():
		print("File tak dikenal: tidak ada.")
	else:
		print("File tak dikenal (%d):" % problems.size())
		for problem in problems:
			print("  - " + problem)


func _report_strips(registry: AssetRegistry) -> void:
	var problems: Array[String] = []
	for file_path in _walk(Assets.DEFAULT_ROOT):
		if not EXTENSIONS.has(file_path.get_extension().to_lower()):
			continue
		var info := Assets.parse_filename(file_path.get_file())
		if not bool(info["ok"]) or int(info["frames"]) <= 1:
			continue
		var texture := _load_texture(file_path)
		if texture == null:
			continue
		var frames := int(info["frames"])
		if texture.get_width() % frames != 0:
			problems.append("%s (lebar %d tidak habis dibagi %d)" % [
				file_path.trim_prefix(Assets.DEFAULT_ROOT + "/"), texture.get_width(), frames
			])

	if problems.is_empty():
		print("Strip frame: semua lebar habis dibagi jumlah frame.")
	else:
		print("Strip bermasalah (%d):" % problems.size())
		for problem in problems:
			print("  - " + problem)


func _report_aspect(registry: AssetRegistry) -> void:
	var problems: Array[String] = []
	for slot in registry.slots:
		if slot == null:
			continue
		var resolved := Assets.resolve(slot.key, slot.default_state(), StringName(slot.dirs()[0]))
		if not resolved.found:
			continue
		var size := resolved.texture_size()
		if size.x <= 0.0 or size.y <= 0.0 or slot.display_size.x <= 0.0 or slot.display_size.y <= 0.0:
			continue
		var art_ratio := size.x / size.y
		var box_ratio := slot.display_size.x / slot.display_size.y
		var deviation := absf(art_ratio - box_ratio) / box_ratio
		if deviation > ASPECT_TOLERANCE:
			problems.append("%s (art %.0fx%.0f vs kotak %.0fx%.0f, beda %.0f%%)" % [
				String(slot.key), size.x, size.y, slot.display_size.x, slot.display_size.y, deviation * 100.0
			])

	if problems.is_empty():
		print("Rasio aspek: semua dalam toleransi %.0f%%." % (ASPECT_TOLERANCE * 100.0))
	else:
		print("Rasio aspek menyimpang (%d):" % problems.size())
		for problem in problems:
			print("  - " + problem)


# --- Ikon item & held item ---------------------------------------------------

## Ikon item dan held item tidak lewat registry, jadi dicek terpisah: cakupan,
## typo nama file, duplikat .png/.webp, dan bentuk yang tidak persegi.
func _report_item_assets() -> void:
	var items: Array = ItemCatalog.ALL
	var icon_dir := _item_icon_dir()
	var held_dir := _held_item_dir()
	var missing_icons := PackedStringArray()
	var missing_held := PackedStringArray()
	var problems: Array[String] = []
	var icon_have := 0
	var held_have := 0

	for item in items:
		if item == null:
			continue
		var icon_path := _find_item_asset(icon_dir, item.id)
		if item.icon != null:
			# ItemDefinition.icon menang atas file; tetap dihitung terisi.
			icon_have += 1
			if not icon_path.is_empty():
				problems.append("ikon %s (file ada tapi .tres punya texture; file diabaikan)" % String(item.id))
		elif icon_path.is_empty():
			missing_icons.append(String(item.id))
		else:
			icon_have += 1
			_check_icon_asset(icon_path, "ikon " + String(item.id), problems)

		var held_path := _find_item_asset(held_dir, item.id, ["png"])
		if held_path.is_empty():
			missing_held.append(String(item.id))
		else:
			held_have += 1
			_check_icon_asset(held_path, "held " + String(item.id), problems)

	print("=== Ikon item: %d/%d terisi (%s) ===" % [icon_have, items.size(), _relative(icon_dir)])
	if missing_icons.is_empty():
		print("Ikon item: semua terisi.")
	else:
		print("Ikon item kosong (%d): %s" % [missing_icons.size(), ", ".join(missing_icons)])

	print("=== Item di tangan: %d/%d terisi (%s) ===" % [held_have, items.size(), _relative(held_dir)])
	if missing_held.is_empty():
		print("Item di tangan: semua terisi.")
	else:
		print("Item di tangan kosong (%d): %s" % [missing_held.size(), ", ".join(missing_held)])

	# HeldItemVisual hanya membaca .png; .webp dengan id valid tidak akan termuat.
	var ids := _item_ids()
	for file_path in _walk(held_dir):
		if file_path.get_extension().to_lower() != "webp":
			continue
		var stem := file_path.get_file().get_basename()
		if not ids.has(stem):
			continue
		if _find_item_asset(held_dir, StringName(stem), ["png"]).is_empty():
			problems.append("%s (held item hanya membaca .png)" % _relative(file_path))

	var unknown := _unknown_item_files()
	if unknown.is_empty():
		print("File ikon/held tak dikenal: tidak ada.")
	else:
		print("File ikon/held tak dikenal (%d):" % unknown.size())
		for problem in unknown:
			print("  - " + problem)

	if problems.is_empty():
		print("Ikon & held item: bentuk/duplikat aman.")
	else:
		print("Ikon & held item perlu perhatian (%d):" % problems.size())
		for problem in problems:
			print("  - " + problem)


func _check_icon_asset(path: String, label: String, problems: Array[String]) -> void:
	if _has_png_and_webp(path):
		problems.append("%s (duplikat .png + .webp; .png dipakai)" % label)
	var texture := _load_texture(path)
	if texture == null:
		problems.append("%s (tidak bisa dibaca)" % label)
		return
	var width := texture.get_width()
	var height := texture.get_height()
	if width <= 0 or height <= 0:
		return
	var deviation := absf(float(width) / float(height) - 1.0)
	if deviation > ASPECT_TOLERANCE:
		problems.append("%s (%dx%d, bukan kotak; slot persegi)" % [label, width, height])


func _item_ids() -> Array[String]:
	var ids: Array[String] = []
	for item in ItemCatalog.ALL:
		if item != null:
			ids.append(String(item.id))
	ids.sort()
	return ids


func _unknown_item_files() -> Array[String]:
	var ids := _item_ids()
	var known: Dictionary = {}
	var normalized_ids: Array[String] = []
	for id in ids:
		known[id] = true
		normalized_ids.append(_normalize(id))
	normalized_ids.sort()

	var problems: Array[String] = []
	for directory in [_item_icon_dir(), _held_item_dir()]:
		for file_path in _walk(directory):
			if not EXTENSIONS.has(file_path.get_extension().to_lower()):
				continue
			var stem := file_path.get_file().get_basename()
			if known.has(stem):
				continue
			problems.append("%s (tidak cocok dengan item id; mirip: %s)" % [
				_relative(file_path), _closest(stem, normalized_ids)
			])
	return problems


func _find_item_asset(directory: String, item_id: StringName, extensions: Array = EXTENSIONS) -> String:
	if String(item_id).is_empty():
		return ""
	for extension in extensions:
		var path := "%s/%s.%s" % [directory, String(item_id), extension]
		if FileAccess.file_exists(path):
			return path
	return ""


func _has_png_and_webp(path: String) -> bool:
	var base := path.get_basename()
	return FileAccess.file_exists(base + ".png") and FileAccess.file_exists(base + ".webp")


func _item_icon_dir() -> String:
	return Assets.DEFAULT_ROOT + "/" + Assets.ITEM_ICON_FOLDER


func _held_item_dir() -> String:
	return HeldItemVisual.HELD_DIR.trim_suffix("/")


func _item_folders_relative() -> Array[String]:
	var folders: Array[String] = [
		Assets.ITEM_ICON_FOLDER,
		HeldItemVisual.HELD_DIR.trim_prefix(Assets.DEFAULT_ROOT + "/").trim_suffix("/"),
	]
	return folders


func _relative(path: String) -> String:
	return path.trim_prefix(Assets.DEFAULT_ROOT + "/")


# --- Helper -----------------------------------------------------------------

func _slot_for_folder(registry: AssetRegistry, folder: String) -> AssetSlotDefinition:
	for slot in registry.slots:
		if slot != null and slot.folder == folder:
			return slot
	return null


func _walk(path: String) -> PackedStringArray:
	var files := PackedStringArray()
	var dir := DirAccess.open(path)
	if dir == null:
		return files
	for name in dir.get_files():
		files.append(path + "/" + name)
	for sub in dir.get_directories():
		if sub.begins_with("."):
			continue
		files.append_array(_walk(path + "/" + sub))
	return files


func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path)
		if res is Texture2D:
			return res
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return null
	return ImageTexture.create_from_image(image)


func _normalize(text: String) -> String:
	return text.to_lower().replace("-", "_").replace(" ", "_")


func _closest(folder: String, known: Array[String]) -> String:
	var normalized := _normalize(folder)
	var best := "(tidak ada)"
	var best_score := 0
	for candidate in known:
		var score := _common_prefix(normalized, candidate)
		if score > best_score:
			best_score = score
			best = candidate
	return best if best_score >= 3 else "(tidak ada)"


func _common_prefix(a: String, b: String) -> int:
	var limit := mini(a.length(), b.length())
	var index := 0
	while index < limit and a[index] == b[index]:
		index += 1
	return index

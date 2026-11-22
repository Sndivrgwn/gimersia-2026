extends SceneTree

## Pemeriksa aset (read-only, tidak menulis apa pun ke repo).
## Jalankan: GODOT --headless --path . -s tools/check_assets.gd
##
## Melaporkan: cakupan slot, slot prioritas 1 yang kosong, file di assets/ yang
## tidak cocok dengan slot mana pun (plus petunjuk typo), strip yang lebarnya
## tidak habis dibagi jumlah frame, dan rasio aspek yang menyimpang > 25%.

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

	_report_unmatched(registry)
	_report_strips(registry)
	_report_aspect(registry)
	quit(0)


func _report_unmatched(registry: AssetRegistry) -> void:
	var known: Dictionary = {}
	for slot in registry.slots:
		if slot != null:
			known[slot.folder] = true

	var folder_names: Array[String] = []
	for folder in known.keys():
		folder_names.append(_normalize(folder))

	var problems: Array[String] = []
	for file_path in _walk(Assets.DEFAULT_ROOT):
		if not EXTENSIONS.has(file_path.get_extension().to_lower()):
			continue
		var relative := file_path.trim_prefix(Assets.DEFAULT_ROOT + "/")
		var folder := relative.get_base_dir()
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

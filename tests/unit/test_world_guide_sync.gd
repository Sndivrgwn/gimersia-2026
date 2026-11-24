extends GutTest

## BLOCK I (Mission 13): docs/editable/WORLD_BUILDING_GUIDE.md harus sama dengan
## keluaran generator, dan tidak boleh menyebut kode/nama/path yang tidak ada.

const GeneratorScript = preload("res://src/core/docs/world_guide_generator.gd")
const GUIDE_PATH := "res://docs/editable/WORLD_BUILDING_GUIDE.md"
const RESOURCE_DIR := "res://src/data/gathering"
const PATH_PATTERN := "res://[A-Za-z0-9_./<>*-]+"

var _guide: String


func before_all() -> void:
	_guide = _read(GUIDE_PATH)


func test_guide_is_up_to_date_with_generator() -> void:
	var generator := GeneratorScript.new()
	var expected: String = generator.build_guide()
	assert_false(_guide.is_empty(), "%s tidak ada" % GUIDE_PATH)
	assert_eq(_normalize(_guide), _normalize(expected), "jalankan tools/generate_guides.gd")
	assert_true(_guide.contains("\r\n"), "dokumen ditulis CRLF seperti dokumen tangan lain")


func test_guide_lists_every_validator_code() -> void:
	var missing := PackedStringArray()
	for code in WorldValidator.CODES.keys():
		if not _guide.contains("`%s`" % String(code)):
			missing.append(String(code))
	assert_true(missing.is_empty(), "kode validator belum ada di panduan: %s" % ", ".join(missing))


func test_guide_lists_required_nodes_and_markers() -> void:
	var missing := PackedStringArray()
	for child in AuthoredWorld.CHILD_NAMES:
		if not _guide.contains("`%s`" % String(child)):
			missing.append(String(child))
	for marker in AuthoredWorld.REQUIRED_MARKERS:
		if not _guide.contains("`%s`" % String(marker)):
			missing.append("Markers/%s" % String(marker))
	for extra in [AuthoredWorld.NIGHT_SPAWNS, AuthoredWorld.WATER_ACCESS]:
		if not _guide.contains(String(extra)):
			missing.append(String(extra))
	assert_true(missing.is_empty(), "node/penanda belum ada di panduan: %s" % ", ".join(missing))


func test_guide_lists_every_zone() -> void:
	var missing := PackedStringArray()
	for key in WorldZoneType.Zone.keys():
		if not _guide.contains("`%s`" % String(key)):
			missing.append(String(key))
		if not _guide.contains(WorldZoneType.label_id(int(WorldZoneType.Zone[key]))):
			missing.append(WorldZoneType.label_id(int(WorldZoneType.Zone[key])))
	assert_true(missing.is_empty(), "zona belum ada di panduan: %s" % ", ".join(missing))


func test_guide_lists_every_resource_definition() -> void:
	var missing := PackedStringArray()
	for definition in _resource_definitions():
		if not _guide.contains("`%s`" % String(definition.id)):
			missing.append(String(definition.id))
	assert_false(missing.is_empty() == false and _resource_definitions().is_empty(), "tidak ada .tres resource")
	assert_true(missing.is_empty(), "resource belum ada di panduan: %s" % ", ".join(missing))


func test_every_path_named_in_guide_exists() -> void:
	var regex := RegEx.new()
	regex.compile(PATH_PATTERN)
	var missing := PackedStringArray()
	for result in regex.search_all(_guide):
		var path := result.get_string()
		if path.contains("<") or path.contains("*"):
			continue
		path = path.trim_suffix(".")
		if not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(path):
			missing.append(path)
	assert_true(missing.is_empty(), "path di panduan tidak ada: %s" % ", ".join(missing))


# --- Helpers ----------------------------------------------------------------

func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _normalize(text: String) -> String:
	return text.replace("\r\n", "\n").replace("\r", "\n")


func _resource_definitions() -> Array:
	var result: Array = []
	var dir := DirAccess.open(RESOURCE_DIR)
	if dir == null:
		return result
	var names: Array = dir.get_files()
	names.sort()
	for name in names:
		if not String(name).ends_with(".tres"):
			continue
		var definition := load(RESOURCE_DIR.path_join(String(name))) as ResourceNodeDefinition
		if definition != null:
			result.append(definition)
	return result

extends GutTest

## Tes docs (read-only): kedua panduan harus identik dengan hasil generator, dan
## semua item yang wajib didokumentasikan harus muncul di dokumennya.

const ASSET_GUIDE := "res://docs/editable/ASSET_GUIDE.md"
const CONFIG_GUIDE := "res://docs/editable/CONFIG_GUIDE.md"
const MODULE_GUIDE := "res://docs/editable/PANDUAN_MODUL.md"
const HINT := "jalankan tools/generate_guides.gd"
const GeneratorScript = preload("res://src/core/docs/guides_generator.gd")

var _generator = GeneratorScript.new()


func before_each() -> void:
	Assets.reset_roots()
	Assets.reload_assets()


func test_asset_guide_is_up_to_date() -> void:
	var expected := _generator.build_asset_guide()
	var actual := _read(ASSET_GUIDE)
	assert_false(actual.is_empty(), "%s: %s tidak ada" % [HINT, ASSET_GUIDE])
	assert_eq(actual.strip_edges(), expected.strip_edges(), HINT)


func test_config_guide_is_up_to_date() -> void:
	var expected := _generator.build_config_guide()
	var actual := _read(CONFIG_GUIDE)
	assert_false(actual.is_empty(), "%s: %s tidak ada" % [HINT, CONFIG_GUIDE])
	assert_eq(actual.strip_edges(), expected.strip_edges(), HINT)


func test_every_registry_key_appears_in_asset_guide() -> void:
	var guide := _read(ASSET_GUIDE)
	var registry := Assets.registry()
	var missing := PackedStringArray()
	for slot in registry.slots:
		if slot == null:
			continue
		if not guide.contains("`%s`" % slot.key):
			missing.append(String(slot.key))
	assert_true(missing.is_empty(), "%s: slot belum ada di panduan: %s" % [HINT, ", ".join(missing)])


func test_every_tres_appears_in_config_guide() -> void:
	var guide := _read(CONFIG_GUIDE)
	var missing := PackedStringArray()
	for path in _collect_tres():
		if not guide.contains(path):
			missing.append(path)
	assert_true(missing.is_empty(), "%s: .tres belum tercatat: %s" % [HINT, ", ".join(missing)])


func test_every_generator_is_mentioned() -> void:
	var guide := _read(CONFIG_GUIDE)
	var missing := PackedStringArray()
	var dir := DirAccess.open("res://tools")
	if dir != null:
		var names: Array = dir.get_files()
		names.sort()
		for name in names:
			if String(name).begins_with("generate_") and String(name).ends_with(".gd"):
				if not guide.contains("tools/" + String(name)):
					missing.append(String(name))
	assert_true(missing.is_empty(), "%s: generator belum disebut: %s" % [HINT, ", ".join(missing)])


func test_every_input_action_is_documented() -> void:
	InputSetup.ensure_actions()
	var guide := _read(MODULE_GUIDE)
	var missing := PackedStringArray()
	for action in InputMap.get_actions():
		var name := String(action)
		if name.begins_with("ui_"):
			continue
		if name == "godot_editor":
			continue
		if not guide.contains("`%s`" % name):
			missing.append(name)
	assert_true(missing.is_empty(), "action belum ada di tabel Input Map PANDUAN_MODUL.md: %s" % ", ".join(missing))


# --- Helper -----------------------------------------------------------------

func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _collect_tres() -> PackedStringArray:
	var files := PackedStringArray()
	_walk("res://", files)
	files.sort()
	return files


func _walk(path: String, out: PackedStringArray) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for name in dir.get_files():
		if name.ends_with(".tres"):
			out.append(path.path_join(name) if path != "res://" else "res://" + name)
	for sub in dir.get_directories():
		if sub.begins_with("."):
			continue
		var child := path.path_join(sub) if path != "res://" else "res://" + sub
		if child.begins_with("res://addons") or child.begins_with("res://.godot"):
			continue
		_walk(child, out)

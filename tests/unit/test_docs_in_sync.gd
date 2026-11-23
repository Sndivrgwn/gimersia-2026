extends GutTest

## Tes docs (read-only): kedua panduan harus identik dengan hasil generator, dan
## semua item yang wajib didokumentasikan harus muncul di dokumennya.

const ASSET_GUIDE := "res://docs/editable/ASSET_GUIDE.md"
const CONFIG_GUIDE := "res://docs/editable/CONFIG_GUIDE.md"
const INPUT_GUIDE := "res://docs/editable/PANDUAN_INPUT.md"
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
	assert_eq(actual.strip_edges(), _normalize(expected).strip_edges(), HINT)


func test_config_guide_is_up_to_date() -> void:
	var expected := _generator.build_config_guide()
	var actual := _read(CONFIG_GUIDE)
	assert_false(actual.is_empty(), "%s: %s tidak ada" % [HINT, CONFIG_GUIDE])
	assert_eq(actual.strip_edges(), _normalize(expected).strip_edges(), HINT)


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


## Mission 9 (7a): generator yang menyimpan .tres tidak boleh tercatat sebagai
## "tidak menulis .tres", dan setiap .tres di src/data harus punya entri pemilik.
func test_generator_with_resource_saver_owns_at_least_one_tres() -> void:
	var tools: Array = _generator._scan_tools()
	var offenders := PackedStringArray()
	for tool in tools:
		var source_file := FileAccess.open(tool["path"], FileAccess.READ)
		if source_file == null:
			continue
		var source := source_file.get_as_text()
		source_file.close()
		if not source.contains("ResourceSaver.save"):
			continue
		if (tool["owns"] as PackedStringArray).is_empty():
			offenders.append(String(tool["path"]))
	assert_true(offenders.is_empty(), "generator menyimpan .tres tapi tercatat kosong: %s" % ", ".join(offenders))


func test_every_tres_under_src_data_has_an_owner_entry() -> void:
	var guide := _read(CONFIG_GUIDE)
	var missing := PackedStringArray()
	for path in _collect_tres():
		if not String(path).begins_with("res://src/data/"):
			continue
		if not guide.contains("### `%s`" % path):
			missing.append(String(path))
	assert_true(missing.is_empty(), "%s: .tres belum punya entri pemilik: %s" % [HINT, ", ".join(missing)])


## Mission 9: panduan Input Map (tombol + fungsi tiap action) ikut dijaga tes.
func test_input_guide_is_up_to_date() -> void:
	var generator := InputGuideGenerator.new()
	var expected := generator.build_input_guide()
	var actual := _read(INPUT_GUIDE)
	assert_false(actual.is_empty(), "%s: %s tidak ada" % [HINT, INPUT_GUIDE])
	assert_eq(actual.strip_edges(), _normalize(expected).strip_edges(), HINT)


func test_every_input_action_has_a_documented_purpose() -> void:
	var generator := InputGuideGenerator.new()
	var missing := generator.missing_purposes()
	assert_true(missing.is_empty(), "%s: action belum punya tujuan: %s" % [HINT, ", ".join(missing)])


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

## Mission 9: dokumen tangan memakai CRLF, generator menulis CRLF juga, tetapi
## perbandingan dinormalisasi ke LF supaya gaya akhir baris tidak jadi sumber
## kegagalan palsu (tanpa menambah .gitattributes).
func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return _normalize(text)


func _normalize(text: String) -> String:
	return text.replace("\r\n", "\n").replace("\r", "\n")


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

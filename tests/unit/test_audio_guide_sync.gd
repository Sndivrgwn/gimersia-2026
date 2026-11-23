extends GutTest

## Mission 10 fase 6: sinkronisasi AudioRegistry <-> AUDIO_GUIDE.md dan cakupan
## semua kind `feedback_event` yang benar-benar dipancarkan di src/.
## Data dan dokumentasi saja; tidak ada playback.

const GUIDE := "res://docs/editable/AUDIO_GUIDE.md"
const REGISTRY_PATH := "res://src/data/audio/audio_registry.tres"
const GeneratorScript = preload("res://src/core/docs/audio_guide_generator.gd")
const EMIT_PATTERN := "feedback_event\\.emit\\(&\"([a-z_]+)\""
const KIND_PATTERN := "FEEDBACK_KIND\\s*:=\\s*&\"([a-z_]+)\""

var _registry: AudioRegistry
var _generator = GeneratorScript.new()


func before_all() -> void:
	_registry = load(REGISTRY_PATH) as AudioRegistry


func test_registry_exists_and_has_cues() -> void:
	assert_not_null(_registry, "audio_registry.tres harus ada")
	assert_gt(_registry.size(), 0, "registry tidak boleh kosong")


func test_guide_is_up_to_date() -> void:
	var expected := _generator.build_audio_guide()
	var actual := _read(GUIDE)
	assert_false(actual.is_empty(), "%s tidak ada; jalankan tools/generate_guides.gd" % GUIDE)
	assert_eq(actual.strip_edges(), _normalize(expected).strip_edges(), "jalankan tools/generate_guides.gd")


func test_every_registry_key_appears_in_guide() -> void:
	var guide := _read(GUIDE)
	var missing := PackedStringArray()
	for cue in _registry.cues:
		if cue == null:
			continue
		if not guide.contains("`%s`" % cue.key):
			missing.append(String(cue.key))
	assert_true(missing.is_empty(), "cue belum ada di panduan: %s" % ", ".join(missing))


func test_registry_keys_are_unique() -> void:
	var seen := {}
	var duplicates := PackedStringArray()
	for cue in _registry.cues:
		if cue == null:
			continue
		if seen.has(cue.key):
			duplicates.append(String(cue.key))
		seen[cue.key] = true
	assert_true(duplicates.is_empty(), "key dobel: %s" % ", ".join(duplicates))


func test_every_cue_is_sane() -> void:
	var offenders := PackedStringArray()
	for cue in _registry.cues:
		if cue == null:
			offenders.append("<null>")
			continue
		if not cue.is_valid():
			offenders.append(String(cue.key))
	assert_true(offenders.is_empty(), "cue tidak valid (field/pola file): %s" % ", ".join(offenders))


func test_every_cue_uses_a_valid_bus_and_priority() -> void:
	var offenders := PackedStringArray()
	for cue in _registry.cues:
		if cue == null:
			continue
		if cue.bus < AudioCueDefinition.Bus.MASTER or cue.bus > AudioCueDefinition.Bus.UI:
			offenders.append("%s:bus" % cue.key)
		if cue.priority < 1 or cue.priority > 3:
			offenders.append("%s:priority" % cue.key)
	assert_true(offenders.is_empty(), "bus/prioritas tidak valid: %s" % ", ".join(offenders))


func test_file_patterns_follow_the_category_folder() -> void:
	var offenders := PackedStringArray()
	for cue in _registry.cues:
		if cue == null:
			continue
		var expected := "res://assets/audio/%s/" % cue.category_key()
		if not cue.file_pattern.begins_with(expected) or not cue.file_pattern.ends_with(".ogg"):
			offenders.append(String(cue.key))
	assert_true(offenders.is_empty(), "pola file salah folder/format: %s" % ", ".join(offenders))


## Setiap kind yang dipancarkan `feedback_event` di src/ harus punya minimal
## satu cue yang menyebut kind itu di hook-nya.
func test_every_feedback_event_kind_has_a_cue() -> void:
	var kinds := _collect_feedback_kinds()
	assert_gt(kinds.size(), 0, "tidak ada kind feedback yang terbaca")
	var missing := PackedStringArray()
	for kind in kinds:
		var found := false
		for cue in _registry.cues:
			if cue != null and cue.hook.contains(kind):
				found = true
				break
		if not found:
			missing.append(kind)
	assert_true(missing.is_empty(), "kind feedback belum punya cue: %s" % ", ".join(missing))


func test_minimum_list_matches_priority_one() -> void:
	var guide := _read(GUIDE)
	var missing := PackedStringArray()
	for cue in _registry.cues_with_priority(1):
		if cue != null and not guide.contains("- `%s`" % cue.key):
			missing.append(String(cue.key))
	assert_true(missing.is_empty(), "cue prioritas 1 belum ada di daftar minimum: %s" % ", ".join(missing))


# --- Helper -----------------------------------------------------------------

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


## Kind dibaca dari sumber nyata, bukan daftar tangan.
func _collect_feedback_kinds() -> PackedStringArray:
	var kinds := {}
	var emit_regex := RegEx.new()
	emit_regex.compile(EMIT_PATTERN)
	var kind_regex := RegEx.new()
	kind_regex.compile(KIND_PATTERN)
	_scan("res://src", kinds, emit_regex, kind_regex)
	var result := PackedStringArray()
	var names: Array = kinds.keys()
	names.sort()
	for name in names:
		result.append(String(name))
	return result


func _scan(path: String, kinds: Dictionary, emit_regex: RegEx, kind_regex: RegEx) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for name in dir.get_files():
		if not String(name).ends_with(".gd"):
			continue
		_collect_from_file(path.path_join(String(name)), kinds, emit_regex, kind_regex)
	for sub in dir.get_directories():
		if String(sub).begins_with("."):
			continue
		_scan(path.path_join(String(sub)), kinds, emit_regex, kind_regex)


func _collect_from_file(path: String, kinds: Dictionary, emit_regex: RegEx, kind_regex: RegEx) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var source := file.get_as_text()
	file.close()
	for regex in [emit_regex, kind_regex]:
		for found in regex.search_all(source):
			kinds[found.get_string(1)] = true

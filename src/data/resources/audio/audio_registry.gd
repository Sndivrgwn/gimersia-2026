class_name AudioRegistry
extends Resource

## Mission 10 fase 6: daftar semua cue audio. Digenerate oleh
## tools/generate_audio_registry.gd; jangan diedit tangan.
## Belum ada playback: ini kontrak data untuk tim audio dan test sinkronisasi.

@export var cues: Array[AudioCueDefinition] = []


func get_cue(key: StringName) -> AudioCueDefinition:
	for cue in cues:
		if cue != null and cue.key == key:
			return cue
	return null


func keys() -> PackedStringArray:
	var result := PackedStringArray()
	for cue in cues:
		if cue != null:
			result.append(String(cue.key))
	return result


func cues_in_category(category: String) -> Array[AudioCueDefinition]:
	var result: Array[AudioCueDefinition] = []
	for cue in cues:
		if cue != null and cue.category_key() == category:
			result.append(cue)
	return result


func cues_with_priority(priority: int) -> Array[AudioCueDefinition]:
	var result: Array[AudioCueDefinition] = []
	for cue in cues:
		if cue != null and cue.priority == priority:
			result.append(cue)
	return result


func missing_hook_cues() -> Array[AudioCueDefinition]:
	var result: Array[AudioCueDefinition] = []
	for cue in cues:
		if cue != null and not cue.has_hook():
			result.append(cue)
	return result


func size() -> int:
	return cues.size()

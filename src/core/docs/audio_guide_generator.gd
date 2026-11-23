extends RefCounted

## Mission 10 fase 6: membangun docs/editable/AUDIO_GUIDE.md dari
## AudioRegistry (src/data/audio/audio_registry.tres). Deterministik: urut,
## tanpa timestamp. Dipakai tools/generate_guides.gd dan tes sinkronisasi.
## Tidak ada playback dan tidak ada file audio di repo ini.

const AUDIO_GUIDE_PATH := "res://docs/editable/AUDIO_GUIDE.md"
const REGISTRY_PATH := "res://src/data/audio/audio_registry.tres"
const BEGIN := "<!-- BEGIN GENERATED -->"
const END := "<!-- END GENERATED -->"
const CATEGORY_ORDER: Array[String] = ["sfx", "music", "ambience", "ui"]
const CATEGORY_LABEL := {
	"sfx": "SFX",
	"music": "Musik",
	"ambience": "Ambience",
	"ui": "UI",
}


func _lf(text: String) -> String:
	return text.replace("\r\n", "\n").replace("\r", "\n")


func build_audio_guide() -> String:
	var registry = _registry()
	var text := _intro()
	text += "\n" + BEGIN + "\n"
	text += _minimum(registry)
	text += _tables(registry)
	text += _hook_lists(registry)
	text += END + "\n"
	return _lf(text)


func _registry() -> AudioRegistry:
	if not ResourceLoader.exists(REGISTRY_PATH):
		return null
	return load(REGISTRY_PATH) as AudioRegistry


func _intro() -> String:
	return """# Panduan Audio

Dokumen ini untuk tim audio. Isinya kebutuhan bunyi game, bukan file audio:
repo **belum** punya playback, `AudioManager`, atau file `.ogg`. Semua yang ada
di sini adalah kontrak data (`AudioRegistry`) supaya pekerjaan audio bisa
dimulai tanpa menebak-nebak.

## Cara pemasangan nanti

1. Satu cue = satu key stabil (`player_hurt`, `campfire_loop`). Key tidak
   berubah walau nama file berubah.
2. Taruh file di folder kategori: `res://assets/audio/sfx/`,
   `res://assets/audio/music/`, `res://assets/audio/ambience/`,
   `res://assets/audio/ui/`.
3. Nama file = key, tambah `_1`..`_N` untuk varian. Contoh:
   `res://assets/audio/sfx/player_hurt_2.ogg`.
4. Pemasangan kode nanti memakai registry ini: satu cue dipetakan ke satu
   pemutar (2D untuk `spatial`, 1D/non-posisional untuk sisanya).
5. Sampai playback ada, cue tanpa titik sambung ditandai `HOOK BELUM ADA` dan
   tidak boleh dianggap sudah terdengar di game.

## Spesifikasi teknis

- Format: **OGG Vorbis** (`.ogg`), satu file per varian.
- Sample rate: **44.1 kHz**.
- Channel: **mono** untuk SFX dan semua cue `spatial`; **stereo** untuk musik
  dan ambience.
- Peak maksimum: **-3 dBFS**, tanpa clipping.
- Musik: sekitar **-18 LUFS** terintegrasi; SFX pendek boleh lebih keras
  sesaat, tetapi tetap di bawah peak.
- Ekor bunyi pendek dan bersih; hindari reverb panjang pada SFX.
- Cue loop: **loop point seamless** (awal dan akhir sampel menyambung),
  tanpa fade di tengah file.
- Ukuran: SFX < 200 KB per varian, musik < 4 MB per menit, ambience loop
  < 3 MB.
- Beri jeda sunyi minimal 5 ms di awal dan akhir file satu-tembak supaya tidak
  terpotong saat diputar.

## Bus dan ducking (saran)

- `Master` -> `Music`, `SFX`, `Ambience`, `UI`.
- `Music` di-duck **-6 dB** selama sting kematian, banner, dan panel jeda.
- `SFX` di-duck **-3 dB** saat musik menang diputar.
- `UI` tidak di-duck; volumenya paling rendah di antara semua bus.
- `Ambience` di-duck **-6 dB** saat raid horn berbunyi.
- Semua nilai di atas adalah titik awal; tuning akhir setelah playtest.

"""


func _minimum(registry: AudioRegistry) -> String:
	var text := "## Minimum audio untuk build pertama (prioritas 1)\n\n"
	text += "Cue berikut yang paling menentukan rasa build pertama. Tanpa file-nya,\n"
	text += "game tetap jalan, tetapi terasa bisu.\n\n"
	if registry == null:
		return text + "_Registry belum ada._\n\n"
	var rows: Array[AudioCueDefinition] = registry.cues_with_priority(1)
	rows.sort_custom(_sort_by_category_then_key)
	for cue in rows:
		text += "- `%s` — %s\n" % [cue.key, cue.description_id]
	text += "\n"
	return text


func _tables(registry: AudioRegistry) -> String:
	if registry == null:
		return "_Registry belum ada._\n\n"
	var text := ""
	for category in CATEGORY_ORDER:
		var cues: Array[AudioCueDefinition] = registry.cues_in_category(category)
		if cues.is_empty():
			continue
		cues.sort_custom(func(a, b): return String(a.key) < String(b.key))
		text += "## %s\n\n" % CATEGORY_LABEL.get(category, category)
		text += "| Cue | Pola file | Wajib/Opsional | Loop | Spatial | Durasi | Varian | Bus | Dipakai di (trigger + hook) | Prioritas |\n"
		text += "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
		for cue in cues:
			text += _cue_row(cue)
		text += "\n"
	return text


func _cue_row(cue: AudioCueDefinition) -> String:
	return "| `%s` | `%s` | %s | %s | %s | %s | %d | %s | %s<br>Hook: %s | %d |\n" % [
		cue.key,
		cue.file_pattern,
		_wajib(cue),
		"ya" if cue.loop else "tidak",
		"ya" if cue.spatial else "tidak",
		cue.duration_hint,
		cue.variants_recommended,
		cue.bus_name(),
		cue.trigger,
		cue.hook,
		cue.priority,
	]


func _wajib(cue: AudioCueDefinition) -> String:
	if cue.optional or cue.priority == 3:
		return "Opsional"
	return "Wajib" if cue.priority == 1 else "Penting"


func _hook_lists(registry: AudioRegistry) -> String:
	var text := "## Hook yang sudah ada\n\n"
	var missing := "## Hook yang belum ada\n\n"
	if registry == null:
		return text + "_Registry belum ada._\n\n" + missing + "_Registry belum ada._\n"
	var available: Array[AudioCueDefinition] = []
	var absent: Array[AudioCueDefinition] = []
	for cue in registry.cues:
		if cue == null:
			continue
		if cue.has_hook():
			available.append(cue)
		else:
			absent.append(cue)
	available.sort_custom(_sort_by_category_then_key)
	absent.sort_custom(_sort_by_category_then_key)
	for cue in available:
		text += "- `%s` -> %s\n" % [cue.key, cue.hook]
	for cue in absent:
		missing += "- `%s` — %s\n" % [cue.key, cue.description_id]
	if available.is_empty():
		text += "- belum ada\n"
	text += "\n"
	return text + missing + "\n"


func _sort_by_category_then_key(a: AudioCueDefinition, b: AudioCueDefinition) -> bool:
	var left := CATEGORY_ORDER.find(a.category_key())
	var right := CATEGORY_ORDER.find(b.category_key())
	if left != right:
		return left < right
	return String(a.key) < String(b.key)

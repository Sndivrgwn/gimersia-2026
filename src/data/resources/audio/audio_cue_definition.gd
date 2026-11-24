class_name AudioCueDefinition
extends Resource

## Mission 10 fase 6: satu cue audio = satu key stabil. Data dan dokumentasi
## saja; tidak ada playback, AudioManager, atau file audio di repo ini.
##
## `file_pattern` diturunkan dari kategori + key: varian ke-N memakai akhiran
## `_N` (mulai 1). Cue tanpa varian memakai nama polos.

enum Category { SFX, MUSIC, AMBIENCE, UI }
enum Bus { MASTER, MUSIC, SFX, AMBIENCE, UI }

const CATEGORY_KEYS: Array[String] = ["sfx", "music", "ambience", "ui"]
const BUS_NAMES: Array[String] = ["Master", "Music", "SFX", "Ambience", "UI"]
const HOOK_MISSING := "HOOK BELUM ADA"

## Kunci unik stabil (snake_case). Satu cue = satu key.
@export var key: StringName = &""
## Kelompok besar; menentukan folder file dan tabel panduan.
@export var category: Category = Category.SFX
## Penjelasan singkat untuk tim audio (Indonesia).
@export var description_id: String = ""
## Kapan bunyi ini terdengar (Indonesia, bahasa desainer).
@export var trigger: String = ""
## Hook persis di kode: sinyal, kind `feedback_event`, atau path script.
## `HOOK_MISSING` bila belum ada titik sambung.
@export var hook: String = ""
## True = diputar berulang selama kondisi aktif (butuh loop point seamless).
@export var loop: bool = false
## True = bunyi berasal dari posisi dunia (AudioStreamPlayer2D nanti).
@export var spatial: bool = false
## Jumlah varian yang disarankan supaya tidak terdengar berulang; 1 = tanpa varian.
@export var variants_recommended: int = 1
## Saran panjang file, mis. "0.2-0.4 s" atau "loop".
@export var duration_hint: String = ""
## Bus mixer tujuan.
@export var bus: Bus = Bus.SFX
## 1 = wajib build pertama, 2 = penting, 3 = opsional.
@export var priority: int = 3
## Pola path file, mis. res://assets/audio/sfx/player_hurt[_1.._4].ogg
@export var file_pattern: String = ""
## True = game tetap enak dimainkan tanpa cue ini.
@export var optional: bool = false
## Catatan teknis untuk tim audio.
@export var notes: String = ""


## Nama kategori yang dipakai folder dan panduan ("sfx", "music", ...).
func category_key() -> String:
	return CATEGORY_KEYS[clampi(int(category), 0, CATEGORY_KEYS.size() - 1)]


## Nama bus yang dipakai panduan ("SFX", "Music", ...).
func bus_name() -> String:
	return BUS_NAMES[clampi(int(bus), 0, BUS_NAMES.size() - 1)]


## True bila hook sudah punya titik sambung di kode.
func has_hook() -> bool:
	return not hook.is_empty() and hook != HOOK_MISSING


## Pola path yang diharapkan untuk cue ini (dihitung dari kategori + key).
func expected_pattern() -> String:
	var folder := "res://assets/audio/%s/" % category_key()
	if variants_recommended > 1:
		return "%s%s[_1.._%d].ogg" % [folder, String(key), variants_recommended]
	return "%s%s.ogg" % [folder, String(key)]


## True bila data cue masuk akal dan konsisten dengan polanya.
func is_valid() -> bool:
	if String(key).is_empty():
		return false
	if description_id.is_empty() or trigger.is_empty() or hook.is_empty():
		return false
	if priority < 1 or priority > 3:
		return false
	if variants_recommended < 1:
		return false
	if duration_hint.is_empty():
		return false
	if file_pattern.is_empty() or not file_pattern.ends_with(".ogg"):
		return false
	if not file_pattern.begins_with("res://assets/audio/%s/" % category_key()):
		return false
	if file_pattern != expected_pattern():
		return false
	return true

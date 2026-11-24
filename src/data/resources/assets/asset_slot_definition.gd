class_name AssetSlotDefinition
extends Resource

## Definisi satu slot aset (satu visual yang bisa diganti art).
##
## Nama file diturunkan dari slot: `res://assets/<folder>/<state>[_<dir>][_<N>f].<ext>`.
## `file_stem` hanya dipakai untuk slot yang nama filenya bukan nama state
## (mis. ground per zona: world/ground/camp.png).

enum Direction { NONE, FOUR }
enum Pivot { CENTER, BOTTOM_CENTER }

const DIRECTIONS: Array[String] = ["down", "up", "left", "right"]

## Kunci unik stabil (snake_case). Dipakai kode: VisualSlot.attach(..., &"player").
@export var key: StringName = &""
## Kelompok untuk dokumentasi: characters, resources, camp, world, effects, ui.
@export var category: StringName = &"props"
## Folder relatif terhadap res://assets/ (mis. "props/campfire").
@export var folder: String = ""
## Bila diisi, nama file memakai ini, bukan nama state (mis. zona ground).
@export var file_stem: String = ""
## Id teks Indonesia untuk panduan kreatif.
@export var description_id: String = ""
## Dipakai oleh (scene/script) untuk panduan.
@export var used_by: String = ""
## State yang dikenali slot ini.
@export var states: PackedStringArray = PackedStringArray(["default"])
## NONE = satu arah; FOUR = down/up/left/right dengan mirror kiri-kanan.
@export var directions: Direction = Direction.NONE
## Ukuran tampil maksimum (px game). Art diskalakan proporsional ke kotak ini.
@export var display_size: Vector2 = Vector2(32.0, 32.0)
## Titik jangkar art terhadap origin node.
@export var pivot: Pivot = Pivot.CENTER
## Geser tambahan visual (px game).
@export var offset: Vector2 = Vector2.ZERO
## State yang diputar berulang; sisanya menahan frame terakhir.
@export var loop_states: PackedStringArray = PackedStringArray()
## fps per state (kosong = pakai AssetConfig.default_fps).
@export var fps: Dictionary = {}
## Margin nine-slice (kiri, atas, kanan, bawah); Vector4.ZERO = tanpa nine-slice.
@export var nine_slice: Vector4 = Vector4.ZERO
## True untuk ground/air: tekstur diulang (tile) di dunia.
@export var tiled: bool = false
## Ukuran satu tile di dunia (px game).
@export var tile_size: Vector2 = Vector2.ZERO
## 1 = wajib untuk build pertama, 2 = penting, 3 = opsional.
@export var priority: int = 3
## Ukuran sumber yang disarankan (px seni).
@export var recommended_px: Vector2i = Vector2i.ZERO
## Opsional: game tetap enak dimainkan tanpa slot ini.
@export var optional: bool = false
## Catatan untuk tim seni.
@export var notes: String = ""
## Mission 12: art utama slot ini sebaiknya berupa SpriteFrames (.tres).
@export var prefers_spriteframes: bool = false
## Nama animasi yang disarankan di dalam SpriteFrames (state atau state_dir).
@export var recommended_animations: PackedStringArray = PackedStringArray()
## True untuk 12 slot yang paling menentukan kesan pertama build.
@export var showcase: bool = false


## Nama file dasar: file_stem bila ada, kalau tidak nama state.
func stem_for(state: String) -> String:
	if not file_stem.is_empty():
		return file_stem
	return state


## Daftar arah yang dipakai slot ini ("" untuk slot satu arah).
func dirs() -> PackedStringArray:
	if directions == Direction.FOUR:
		return PackedStringArray(DIRECTIONS)
	return PackedStringArray([""])


## State default saat slot dipasang.
func default_state() -> StringName:
	if states.is_empty():
		return &"default"
	if states.has("idle"):
		return &"idle"
	return StringName(states[0])


## fps untuk state; 0 berarti "pakai default AssetConfig".
func state_fps(state: String) -> float:
	if fps.has(state):
		return float(fps[state])
	return 0.0


## True bila state diputar berulang.
func is_loop(state: String) -> bool:
	return loop_states.has(state)


## True bila konfigurasi slot masuk akal.
func is_valid() -> bool:
	if String(key).is_empty() or folder.is_empty():
		return false
	if display_size.x <= 0.0 or display_size.y <= 0.0:
		return false
	if priority < 1 or priority > 3:
		return false
	if states.is_empty():
		return false
	for state in states:
		if state.is_empty():
			return false
	if tiled and (tile_size.x <= 0.0 or tile_size.y <= 0.0):
		return false
	return true


## Nama animasi yang disarankan: `<state>_<dir>` untuk slot 4 arah, `<state>`
## untuk slot satu arah. Dipakai generator registry dan panduan.
func animation_names() -> PackedStringArray:
	var result := PackedStringArray()
	for state in states:
		if directions == Direction.FOUR:
			for dir in DIRECTIONS:
				result.append("%s_%s" % [state, dir])
		else:
			result.append(state)
	return result


## Pola path untuk panduan (contoh nama file lengkap).
func pattern_text(state: String = "", dir: String = "", frames: int = 0) -> String:
	var use_state := state
	if use_state.is_empty():
		use_state = String(default_state())
	var stem := stem_for(use_state)
	var suffix := ""
	if not dir.is_empty():
		suffix += "_" + dir
	if frames > 1:
		suffix += "_%df" % frames
	return "res://assets/%s/%s%s.png" % [folder, stem, suffix]

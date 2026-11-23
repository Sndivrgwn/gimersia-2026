extends RefCounted

## Membangun teks docs/editable/ASSET_GUIDE.md dan CONFIG_GUIDE.md secara
## deterministik (urut, tanpa timestamp) dari resource yang hidup di repo.
##
## Dipakai oleh tools/generate_guides.gd (menulis file) dan oleh
## tests/unit/test_docs_in_sync.gd (membandingkan tanpa menulis).

const ASSET_GUIDE_PATH := "res://docs/editable/ASSET_GUIDE.md"
const CONFIG_GUIDE_PATH := "res://docs/editable/CONFIG_GUIDE.md"
const BEGIN := "<!-- BEGIN GENERATED -->"
const END := "<!-- END GENERATED -->"
const SKIP_DIRS: Array[String] = ["res://addons", "res://.godot"]
const CATEGORY_ORDER: Array[String] = ["characters", "resources", "camp", "world", "effects", "ui"]
const CATEGORY_LABEL := {
	"characters": "Karakter",
	"resources": "Node resource",
	"camp": "Camp & struktur",
	"world": "Dunia",
	"effects": "Efek",
	"ui": "UI & ikon",
}
const ITEM_HINT := "src/data/items/*.tres"


# --- ASSET_GUIDE ------------------------------------------------------------

## Mission 9 (7b): teks panduan selalu LF di memori. String literal GDScript
## mewarisi akhir baris file sumber, jadi normalisasi eksplisit di sini; disk
## ditulis CRLF oleh `write_file()`.
func _lf(text: String) -> String:
	return text.replace("\r\n", "\n").replace("\r", "\n")


func build_asset_guide() -> String:
	var text := _asset_intro()
	text += "\n" + BEGIN + "\n"
	text += _asset_tables()
	text += END + "\n"
	return _lf(text)


func _asset_intro() -> String:
	return """# Panduan Aset

Dokumen ini untuk tim kreatif: cara mengganti tampilan game tanpa menyentuh kode.

## Cara kerja (5 baris)

1. Semua visual punya "slot" bernama, mis. `player`, `campfire`, `ground_camp`.
2. Slot mencari file di `res://assets/` sesuai namanya; tidak ada art = placeholder lama.
3. Nama file menentukan state (`lit`, `walk`) dan arah (`down`, `up`, `left`, `right`).
4. UI otomatis memakai art bila ada; tanpa art tampilan tetap seperti sekarang.
5. Art hanya ikut ke build kalau sudah di-import Godot dan di-commit oleh owner.

## Tiga langkah mengganti satu visual

1. Taruh file di path yang benar, mis. `res://assets/props/campfire/lit.png`
   (ukuran bebas, sebaiknya mendekati "ukuran sumber disarankan").
2. Import sekali: `GODOT --headless --import --path .` (atau buka editor sekali).
3. Tekan **F1** di island (atau jalankan ulang scene) untuk memuat ulang art
   tanpa restart. Hapus file + F1 untuk kembali ke placeholder.

## Aturan global

- Format: `.png` atau `.webp`, latar transparan, tanpa padding transparan besar.
- Nama file: lowercase, hanya huruf/angka/underscore (`_`). Jangan pakai spasi
  atau tanda hubung.
- Pixel-art: filter nearest otomatis (lihat `asset_config.tres`).
- Strip animasi: `_<N>f` di akhir nama, N frame berderet horizontal dengan lebar
  sama. Contoh `walk_down_4f.png` = 4 frame, lebar gambar harus habis dibagi 4.
- Arah: `down`, `up`, `left`, `right`. Art `left` tidak wajib: game membalik
  `right` secara horizontal bila perlu.
- Ukuran tampil = kotak maksimum di game; art diskalakan proporsional (aspect
  ratio dipertahankan). Ukuran sumber hanya saran.
- Pivot: `CENTER` (titik tengah art di origin node) atau `BOTTOM_CENTER`
  (dasar art di origin, umum untuk pohon/bangunan).
- Ground harus seamless: teksturnya diulang tiap ukuran tile di daftar slot.
- Tidak ada file biner yang masuk repo sampai owner meng-commit-nya; agen tidak
  pernah menambahkan gambar.

## Catatan build ekspor

Hanya file yang sudah di-import Godot yang ikut di-pack. File yang baru
diletakkan tapi belum di-import akan hilang di build ekspor. Jalankan
`--headless --import` (atau buka editor) sebelum ekspor.

## Alat bantu

- `GODOT --headless --path . -s tools/check_assets.gd` — cek cakupan, file typo,
  strip yang salah, dan rasio aspek menyimpang.
- **F1** di island — muat ulang semua art.
- **Home** di island — tampilkan kotak slot + pivot + toast "Aset: X/Y terisi".
- `res://assets/README.md` — pengingat singkat.

## Minimum untuk build pertama (prioritas 1)

Slot prioritas 1 adalah yang paling menentukan "enak dilihat". Bila kosong,
game tetap jalan dengan placeholder.

"""


func _asset_tables() -> String:
	var registry := Assets.registry()
	var text := ""
	var priority1 := PackedStringArray()
	for slot in registry.slots:
		if slot != null and slot.priority == 1:
			priority1.append("`%s`" % slot.key)
	text += "- " + ", ".join(priority1) + "\n\n"

	for category in CATEGORY_ORDER:
		var slots := _sorted_slots(registry, category)
		if slots.is_empty():
			continue
		text += "## %s\n\n" % CATEGORY_LABEL.get(category, category)
		text += "| Slot | Pola file | Wajib/Opsional | Ukuran tampil | Sumber disarankan | Pivot | Arah | State | Dipakai di | Fallback |\n"
		text += "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
		for slot in slots:
			text += _asset_row(slot)
		text += "\n"
	return text


func _asset_row(slot: AssetSlotDefinition) -> String:
	var pattern := "`res://assets/%s/%s[_dir][_Nf].png`" % [
		slot.folder, _stem_example(slot)
	]
	var example_state := String(slot.default_state())
	var example := slot.pattern_text(example_state, _example_dir(slot), _example_frames(slot))
	var optional := "Opsional" if slot.optional or slot.priority == 3 else ("Wajib" if slot.priority == 1 else "Penting")
	var pivot := "BOTTOM_CENTER" if slot.pivot == AssetSlotDefinition.Pivot.BOTTOM_CENTER else "CENTER"
	var dirs := "4 arah" if slot.directions == AssetSlotDefinition.Direction.FOUR else "satu arah"
	return "| `%s` | %s<br>contoh: `%s` | %s | %s | %s | %s | %s | %s | %s | state → arah → mirror → idle → default → placeholder |\n" % [
		slot.key,
		pattern,
		example,
		optional,
		_size_text(slot.display_size),
		"%d × %d" % [slot.recommended_px.x, slot.recommended_px.y] if slot.recommended_px != Vector2i.ZERO else "—",
		pivot,
		dirs,
		", ".join(slot.states),
		slot.used_by if not slot.used_by.is_empty() else "—",
	]


func _stem_example(slot: AssetSlotDefinition) -> String:
	return slot.stem_for(String(slot.default_state()))


func _example_dir(slot: AssetSlotDefinition) -> String:
	return "down" if slot.directions == AssetSlotDefinition.Direction.FOUR else ""


func _example_frames(slot: AssetSlotDefinition) -> int:
	return 4 if slot.is_loop(String(slot.default_state())) else 0


# --- CONFIG_GUIDE -----------------------------------------------------------

func build_config_guide() -> String:
	var text := _config_intro()
	text += "\n" + BEGIN + "\n"
	text += _config_tables()
	text += END + "\n"
	return _lf(text)


func _config_intro() -> String:
	return """# Panduan Konfigurasi

Dokumen ini untuk desainer: semua angka gameplay disimpan di Resource `.tres`
supaya bisa diubah dari Inspector Godot tanpa menyentuh kode.

## Mengapa Resource

- Satu sumber angka: kode membaca `config.field`, tidak menyalin nilai.
- Bisa di-tune di Inspector, lalu dijalankan ulang — tanpa rebuild.
- Tes memakai nilai yang sama, jadi balance dan tes tidak bisa berbeda.

## Mengedit `.tres` dengan aman

1. Buka file `.tres` di Godot (double click) — Inspector menampilkan field.
2. Ubah nilai, `Ctrl+S`. Jangan edit teks `.tres` dengan editor teks biasa
   kecuali Anda paham formatnya (urutan properti dan id sub-resource bisa rusak).
3. Jalankan tes terkait (kolom "Tes terkait") sebelum commit.

## PERINGATAN: generator menimpa edit tangan

Menjalankan `tools/generate_*.gd` MENULIS ULANG file yang dimilikinya. Jangan
mengedit file tersebut di Inspector tanpa memindahkan angkanya ke generator.

"""


func _config_tables() -> String:
	var tools := _scan_tools()
	var owned := _owned_paths(tools)
	var files := _collect_tres()
	var text := ""

	text += "## Peta pemilik file\n\n"
	text += "| Generator | Perintah | File `.tres` yang ditulis |\n| --- | --- | --- |\n"
	for tool in tools:
		var owns: PackedStringArray = tool["owns"]
		text += "| `%s` | `%s` | %s |\n" % [
			tool["path"], tool["command"],
			", ".join(owns) if not owns.is_empty() else "— (tidak menulis .tres)",
		]
	text += "\n"

	var groups := _group_paths(files)
	for group in groups:
		text += "## %s\n\n" % group
		var paths: Array = groups[group]
		for path in paths:
			text += _config_entry(path, owned)
		text += "\n"

	text += "## Resource tanpa `.tres` (nilai default di script)\n\n"
	text += "Kelas berikut hanya punya default di kode; ubah lewat kode atau dengan membuat `.tres` baru.\n\n"
	text += "| Kelas | Default | Catatan |\n| --- | --- | --- |\n"
	text += "| `PlayerBaseStats` | `src/data/stats/player_base_stats.gd` | Stat dasar pemain; dipakai `StatsComponent.base_stats` bila tidak diisi. |\n"
	text += "| `AssetConfig` | `src/data/configs/asset_config.tres` | Ada `.tres`; nilai default script jadi cadangan. |\n"
	text += "\n"

	text += "## Generator di `tools/`\n\n"
	text += "| Generator | Perintah |\n| --- | --- |\n"
	for tool in tools:
		text += "| `%s` | `%s` |\n" % [tool["path"], tool["command"]]
	text += "\n"
	return text


func _config_entry(path: String, owned: Dictionary) -> String:
	var resource: Resource = ResourceLoader.load(path) if ResourceLoader.exists(path) else null
	var script_path := ""
	var class_name_text := "Resource"
	if resource != null:
		var script: Script = resource.get_script()
		if script != null:
			script_path = (script as Script).resource_path
			if not script_path.is_empty():
				class_name_text = script_path.get_file()
	var meta: Dictionary = _tres_meta().get(path, {})
	var owner_text := "generator"
	if not owned.has(path):
		owner_text = "edit tangan"
	return "### `%s`\n\n- Kelas: `%s`%s\n- Tujuan: %s\n- Dipakai oleh: %s\n- Pemilik: %s\n- Efek tuning: %s\n- Tes terkait: %s\n\n%s\n" % [
		path,
		class_name_text,
		(" (`%s`)" % script_path) if not script_path.is_empty() else "",
		meta.get("purpose", "belum didokumentasikan"),
		meta.get("used_by", "—"),
		owner_text,
		meta.get("effect", "—"),
		meta.get("tests", "—"),
		_fields_table(resource),
	]


func _fields_table(resource: Resource) -> String:
	if resource == null:
		return "_Tidak bisa dimuat._\n"
	var rows := PackedStringArray()
	rows.append("| Field | Tipe | Nilai |\n| --- | --- | --- |")
	for property in resource.get_property_list():
		var usage: int = property["usage"]
		if not (usage & PROPERTY_USAGE_EDITOR):
			continue
		var name: String = property["name"]
		if name in ["script", "resource_path", "resource_name"]:
			continue
		rows.append("| `%s` | %s | %s |" % [
			name,
			_type_text(property["type"]),
			_value_text(resource.get(name)),
		])
	if rows.size() == 1:
		rows.append("| — | — | tidak ada field yang diekspor |")
	return "\n".join(rows) + "\n"


# --- Metadata ---------------------------------------------------------------

func _tres_meta() -> Dictionary:
	return {
		"res://src/data/configs/asset_config.tres": {
			"purpose": "Filter pixel-art, fallback mirror, fps default animasi.",
			"used_by": "Assets, VisualSlot",
			"effect": "Mematikan mirror membuat arah tanpa art jatuh ke placeholder.",
			"tests": "test_assets_core.gd",
		},
		"res://src/data/assets/asset_registry.tres": {
			"purpose": "Daftar semua slot aset (digenerate).",
			"used_by": "Assets, VisualSlot, UiSkin, check_assets",
			"effect": "Menambah slot membuat visual baru bisa diganti art.",
			"tests": "test_assets_core.gd",
		},
		"res://src/data/configs/needs_config.tres": {
			"purpose": "Laju Hunger/Thirst/Fatigue dan ambang tier.",
			"used_by": "NeedsComponent, NeedsHUD",
			"effect": "Mengubah seberapa cepat kebutuhan turun dan kapan tier LOW/ZERO.",
			"tests": "test_needs_component.gd",
		},
		"res://src/data/configs/inventory_config.tres": {
			"purpose": "Ukuran tas, radius pickup, jeda pickup.",
			"used_by": "InventoryComponent, ItemPickup",
			"effect": "Jumlah slot dan seberapa mudah item terambil.",
			"tests": "test_inventory_component.gd",
		},
		"res://src/data/configs/combat_config.tres": {
			"purpose": "Damage, jangkauan, cooldown, knockback.",
			"used_by": "CombatComponent, PlayerDamageReceiver",
			"effect": "Rasa tempur: seberapa cepat dan keras serangan.",
			"tests": "test_combat_component.gd",
		},
		"res://src/data/configs/juice_config.tres": {
			"purpose": "Hit-stop, shake, flash, squash, intensitas efek.",
			"used_by": "CombatFeedback",
			"effect": "Seberapa berat pukulan terasa (tanpa mengubah damage).",
			"tests": "test_combat_feedback.gd",
		},
		"res://src/data/configs/interaction_config.tres": {
			"purpose": "Jarak interaksi dan waktu tahan E.",
			"used_by": "InteractorComponent, Interactable",
			"effect": "Seberapa dekat pemain harus berdiri dan berapa lama menahan E.",
			"tests": "test_interactor_component.gd",
		},
		"res://src/data/configs/island_layout.tres": {
			"purpose": "Titik spawn resource, fauna, dan zona pulau.",
			"used_by": "IslandBuilder, NightSpawner",
			"effect": "Isi dan kepadatan pulau.",
			"tests": "test_island_builder.gd",
		},
		"res://src/data/configs/proficiency_config.tres": {
			"purpose": "Ambang level proficiency dan debuff kematian.",
			"used_by": "ProficiencyComponent, ProficiencyHUD",
			"effect": "Kecepatan naik level dan besar penalti saat mati.",
			"tests": "test_proficiency_component.gd",
		},
		"res://src/data/configs/fire_starter_config.tres": {
			"purpose": "Minigame gesek batu untuk menyalakan api.",
			"used_by": "FireStarterController",
			"effect": "Seberapa sulit menyalakan api COLD.",
			"tests": "test_fire_starter.gd",
		},
		"res://src/data/configs/fence_config.tres": {
			"purpose": "Jumlah segmen, radius ring, dan daya tahan pagar.",
			"used_by": "FenceRing, FenceSegment",
			"effect": "Bentuk dan kekuatan pagar base.",
			"tests": "test_fence.gd",
		},
	}


# --- Pemindaian file --------------------------------------------------------

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
		if not name.ends_with(".tres"):
			continue
		var full := path.path_join(name) if path != "res://" else "res://" + name
		out.append(full)
	for sub in dir.get_directories():
		if sub.begins_with("."):
			continue
		var child := path.path_join(sub) if path != "res://" else "res://" + sub
		var skip := false
		for skipped in SKIP_DIRS:
			if child == skipped or child.begins_with(skipped + "/"):
				skip = true
				break
		if not skip:
			_walk(child, out)


func _group_paths(files: PackedStringArray) -> Dictionary:
	var groups: Dictionary = {}
	for path in files:
		var group := path.get_base_dir().trim_prefix("res://")
		if not groups.has(group):
			groups[group] = []
		groups[group].append(path)
	var sorted_groups: Dictionary = {}
	var names: Array = groups.keys()
	names.sort()
	for name in names:
		sorted_groups[name] = groups[name]
	return sorted_groups


## Generator yang path tujuannya dibangun dinamis ("%s/%s.tres") tidak punya
## literal res:// di sumbernya. Peta direktori kecil ini menutup celah tersebut;
## isinya dicek tes (tidak boleh ada generator ber-ResourceSaver.save yang
## "tidak menulis .tres").
const TOOL_DIRECTORIES: Dictionary = {
	"res://tools/generate_recipes.gd": "res://src/data/recipes/",
	"res://tools/generate_hints.gd": "res://src/data/hints/",
	"res://tools/generate_structures.gd": "res://src/data/camp/",
}


func _scan_tools() -> Array:
	var result: Array = []
	var dir := DirAccess.open("res://tools")
	if dir == null:
		return result
	var files := _collect_tres()
	var names: Array = dir.get_files()
	names.sort()
	for name in names:
		if not (String(name).begins_with("generate_") and String(name).ends_with(".gd")):
			continue
		var path := "res://tools/" + String(name)
		var owns := PackedStringArray()
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var source := file.get_as_text()
			file.close()
			for line in source.split("\n"):
				var index := line.find("res://")
				if index < 0:
					continue
				var start := index
				var end := line.find("\"", start)
				if end < 0:
					continue
				var candidate := line.substr(start, end - start)
				if candidate.ends_with(".tres") and not owns.has(candidate):
					owns.append(candidate)
		var owned_dir: String = TOOL_DIRECTORIES.get(path, "")
		if not owned_dir.is_empty():
			for tres_path in files:
				if String(tres_path).begins_with(owned_dir) and not owns.has(tres_path):
					owns.append(tres_path)
		owns.sort()
		result.append({
			"path": path,
			"command": "GODOT --headless --path . -s " + path.trim_prefix("res://"),
			"owns": owns,
		})
	return result


func _owned_paths(tools: Array) -> Dictionary:
	var owned: Dictionary = {}
	for tool in tools:
		for path in tool["owns"]:
			owned[path] = tool["path"]
	return owned


# --- Format -----------------------------------------------------------------

func _sorted_slots(registry: AssetRegistry, category: String) -> Array[AssetSlotDefinition]:
	var result: Array[AssetSlotDefinition] = []
	for slot in registry.slots:
		if slot != null and String(slot.category) == category:
			result.append(slot)
	result.sort_custom(func(a, b): return String(a.key) < String(b.key))
	return result


func _size_text(value: Vector2) -> String:
	return "%d × %d" % [int(roundf(value.x)), int(roundf(value.y))]


func _value_text(value: Variant) -> String:
	if value is float:
		return "%.2f" % float(value)
	if value is Vector2:
		return "%s × %s" % [str(snappedf(value.x, 0.01)), str(snappedf(value.y, 0.01))]
	if value is Array:
		if value.is_empty():
			return "[]"
		return "[%s item]" % value.size()
	if value is Dictionary:
		if value.is_empty():
			return "{}"
		return "{%d entri}" % value.size()
	if value is PackedStringArray:
		return "[%s]" % ", ".join(value)
	if value == null:
		return "—"
	var text := str(value).replace("\n", " ")
	if text.length() > 48:
		text = text.substr(0, 45) + "..."
	return text


func _type_text(type_id: int) -> String:
	match type_id:
		TYPE_BOOL:
			return "bool"
		TYPE_INT:
			return "int"
		TYPE_FLOAT:
			return "float"
		TYPE_STRING:
			return "String"
		TYPE_STRING_NAME:
			return "StringName"
		TYPE_VECTOR2:
			return "Vector2"
		TYPE_VECTOR2I:
			return "Vector2i"
		TYPE_VECTOR4:
			return "Vector4"
		TYPE_ARRAY:
			return "Array"
		TYPE_DICTIONARY:
			return "Dictionary"
		TYPE_OBJECT:
			return "Resource"
		_:
			return "lain"


## Panduan ditulis dengan SATU gaya akhir baris: CRLF, sama seperti dokumen
## tangan lain di docs/editable. Tes membandingkan setelah normalisasi ke LF.
static func write_file(path: String, text: String) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var normalized := text.replace("\r\n", "\n").replace("\n", "\r\n")
	file.store_string(normalized)
	file.close()
	return true

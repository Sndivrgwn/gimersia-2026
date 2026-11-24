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
## Aman untuk slot hotbar 48 px; baris resep mengecilkan art secara proporsional.
const ITEM_ICON_RECOMMENDED := Vector2i(48, 48)
## Sama dengan HeldItemConfig.hand_size bawaan.
const HELD_ITEM_DISPLAY := Vector2(14.0, 14.0)
const HELD_ITEM_RECOMMENDED := Vector2i(32, 32)


# --- ASSET_GUIDE ------------------------------------------------------------

## Mission 9 (7b): teks panduan selalu LF di memori. String literal GDScript
## mewarisi akhir baris file sumber, jadi normalisasi eksplisit di sini; disk
## ditulis CRLF oleh `write_file()`.
func _lf(text: String) -> String:
	return text.replace("\r\n", "\n").replace("\r", "\n")


func build_asset_guide() -> String:
	var text := _asset_intro()
	text += _spriteframes_section()
	text += _minimum_tiers()
	text += BEGIN + "\n"
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

## Bagian dokumen ini

- **Karakter, Node resource, Camp & struktur, Dunia, Efek, UI & ikon** — slot
  visual dari `src/data/assets/asset_registry.tres`, lengkap dengan pola file,
  ukuran, pivot, state, dan pemakainya.
- **Ikon item** — semua ikon barang (tas, hotbar, baris resep, dan item pickup).
- **Item di tangan** — art barang yang dipegang pemain saat dipilih di hotbar.
- **Resep crafting** — setiap resep beserta ikon hasil yang dipakai panel
  Meja Kerja/Api Unggun.
- **Cakupan file** — berapa slot dan ikon yang sudah punya file, dan mana yang
  masih kosong.
- **Visual runtime** — efek yang sengaja dibuat kode, jadi tim aset tidak perlu
  membuat file untuk itu.
- **Audio** — tidak di dokumen ini; lihat `docs/editable/AUDIO_GUIDE.md` untuk
  daftar cue suara.

## Peta cepat: mau mengubah apa?

| Ingin mengubah | Lihat bagian |
| --- | --- |
| Pemain, babi hutan, rusa | Karakter |
| Pohon, batu, semak beri, bambu, kelapa | Node resource |
| Api unggun, meja kerja, peti, tenda, blueprint, pagar | Camp & struktur |
| Tanah per zona, pantai, sungai, bangkai pesawat, suar, koper | Dunia |
| Serpihan, debu, percikan hit, slash | Efek |
| Panel, tombol, bar, font, ikon kebutuhan, layar mati | UI & ikon |
| Ikon barang di tas/peti/hotbar/pickup | Ikon item |
| Barang yang dipegang pemain | Item di tangan |
| Nama, bahan, dan stasiun tiap resep | Resep crafting |

## Tiga langkah mengganti satu visual

1. Taruh file di path yang benar, mis. `res://assets/props/campfire/lit.png`
   (ukuran bebas, sebaiknya mendekati "ukuran sumber disarankan").
2. Import sekali: `GODOT --headless --import --path .` (atau buka editor sekali).
3. Tekan **Backtick (`)** di island (`debug_reload_assets`) untuk memuat ulang
   art tanpa restart. Hapus file + tombol itu untuk kembali ke placeholder.

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

## Aturan ikon item

- Semua item memakai satu ikon: `res://assets/icons/items/<id>.png`.
  Contoh: `res://assets/icons/items/stone_axe.png`.
- Nama file wajib sama dengan `id` item di `src/data/items/<id>.tres` (English,
  snake_case), bukan `display_name`, tanpa spasi.
- Ukuran sumber disarankan 48 × 48 px, latar transparan (game memperkecilnya di
  slot tas ~28 px dan hotbar ~20 px). Ikon yang sama dipakai di tas, panel peti,
  hotbar, dan item pickup. Baris resep di panel stasiun hanya menampilkan teks
  (nama, bahan, waktu), jadi tidak butuh ikon tambahan.
- Tanpa file, ikon memakai placeholder; game tetap jalan.
- Daftar lengkap item ada di bagian **Ikon item**; resep yang memakainya ada di
  bagian **Resep crafting**.

## Catatan build ekspor

Hanya file yang sudah di-import Godot yang ikut di-pack. File yang baru
diletakkan tapi belum di-import akan hilang di build ekspor. Jalankan
`--headless --import` (atau buka editor) sebelum ekspor.

## Alat bantu

- `GODOT --headless --path . -s tools/check_assets.gd` — cek cakupan slot,
  **ikon item & held item**, file typo, duplikat `.png`/`.webp`, strip yang salah,
  dan rasio aspek menyimpang.
- **Backtick (`)** di island (`debug_reload_assets`) — muat ulang semua art.
- **Home** di island — tampilkan kotak slot + pivot + toast "Aset: X/Y terisi".
- `res://assets/README.md` — pengingat singkat.

"""


## Mission 12: bagian puncak alur SpriteFrames + tabel nama animasi showcase.
func _spriteframes_section() -> String:
	var registry := Assets.registry()
	var text := "## Pakai SpriteFrames (disarankan untuk karakter)\n\n"
	text += "Satu file `.tres` berisi semua animasi slot. Game memakai file ini lebih dulu daripada PNG, jadi strip tidak perlu dipotong manual.\n\n"
	text += "### Langkah di editor\n\n"
	text += "1. Buat resource `SpriteFrames`: klik kanan di FileSystem → **New Resource...** → `SpriteFrames` (atau lewat panel **Animation** pada `AnimatedSprite2D`, tombol **New SpriteFrames**).\n"
	text += "2. Tambah animasi dengan nama PERSIS seperti tabel di bawah: `<state>` atau `<state>_<dir>` dengan `dir` = `down`, `up`, `left`, `right`. Contoh: `idle_down`, `walk_left`, `lit`, `cold`.\n"
	text += "3. Isi frame tiap animasi: **Add frames from sprite sheet** (pilih PNG strip + jumlah frame) atau tambah file per frame.\n"
	text += "4. Atur **fps** dan **loop** tiap animasi di panel Animation. Nilai inilah yang dipakai game; `asset_config.tres` hanya berlaku untuk strip PNG.\n"
	text += "5. Simpan ke path di tabel: `res://assets/<folder>/<slot>.tres`.\n"
	text += "6. Import sekali (`GODOT --headless --import --path .` atau buka editor), lalu tekan **Backtick (`)** di island (`debug_reload_assets`) tanpa restart.\n\n"
	text += "### Urutan prioritas\n\n"
	text += "1. `res://assets/<folder>/<slot>.tres` (SpriteFrames) — **paling diutamakan**.\n"
	text += "2. Strip PNG `_<N>f` atau PNG satu frame di folder slot (metode lama, tetap didukung).\n"
	text += "3. Placeholder bawaan scene.\n\n"
	text += "Di dalam SpriteFrames, animasi dicari berurutan: `<state>_<dir>` → `<state>` → `<state>_<arah cermin>` (flip_h) → `idle_<dir>` → `idle` → `default` → placeholder. Auto-scale dan pivot memakai frame PERTAMA animasi terpilih, sama seperti PNG.\n\n"
	text += "### Nama animasi disarankan (12 slot showcase)\n\n"
	text += "| Slot | Path .tres | Animasi disarankan |\n| --- | --- | --- |\n"
	for slot in _showcase_slots(registry):
		text += "| `%s` | `res://assets/%s/%s.tres` | %s |\n" % [
			slot.key, slot.folder, slot.key, _animation_cell(slot)
		]
	text += "\n"
	return text


func _showcase_slots(registry: AssetRegistry) -> Array[AssetSlotDefinition]:
	var result: Array[AssetSlotDefinition] = []
	for slot in registry.slots:
		if slot != null and slot.showcase:
			result.append(slot)
	return result


func _animation_cell(slot: AssetSlotDefinition) -> String:
	if slot.recommended_animations.is_empty():
		return "—"
	if slot.directions == AssetSlotDefinition.Direction.FOUR:
		var states := PackedStringArray()
		for state in slot.states:
			states.append("%s_<dir>" % state)
		return ", ".join(states) + " (`<dir>` = down/up/left/right)"
	return ", ".join(slot.recommended_animations)


## Mission 12: "Minimum untuk build pertama" dipecah jadi Showcase + Sisanya.
func _minimum_tiers() -> String:
	var registry := Assets.registry()
	var showcase := PackedStringArray()
	var rest := PackedStringArray()
	for slot in registry.slots:
		if slot == null or slot.priority != 1:
			continue
		if slot.showcase:
			showcase.append("`%s`" % slot.key)
		else:
			rest.append("`%s`" % slot.key)
	var text := "## Minimum untuk build pertama — tier Showcase (%d slot)\n\n" % showcase.size()
	text += "Slot yang paling menentukan kesan pertama. Karakter sebaiknya SpriteFrames; sisanya PNG sudah cukup. Bila kosong, game tetap jalan dengan placeholder.\n\n"
	text += "- " + (", ".join(showcase) if not showcase.is_empty() else "—") + "\n\n"
	text += "## Minimum untuk build pertama — tier Sisanya\n\n"
	text += "Slot prioritas 1 di luar showcase.\n\n"
	text += "- " + (", ".join(rest) if not rest.is_empty() else "—") + "\n\n"
	return text


func _asset_tables() -> String:
	var registry := Assets.registry()
	var text := ""

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
	text += _item_icon_table()
	text += _held_item_table()
	text += _recipe_table()
	text += _asset_coverage(registry)
	text += _runtime_art_notes()
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


# --- Ikon item, resep, cakupan ----------------------------------------------

func _item_icon_table() -> String:
	var items := _item_definitions()
	var text := "## Ikon item (%d item)\n\n" % items.size()
	text += "Satu file per item: `res://assets/icons/items/<id>.png` (`.webp` juga dibaca; `.png` diprioritaskan bila keduanya ada). Ikon yang sama dipakai di tas, panel peti, hotbar, dan item pickup (diperkecil otomatis). Baris resep tidak memakai ikon. Ukuran sumber disarankan %d × %d px, latar transparan.\n\n" % [
		ITEM_ICON_RECOMMENDED.x, ITEM_ICON_RECOMMENDED.y
	]
	text += "| Ikon | Path file | Item | ID | Kategori | Stack | Ukuran disarankan | Dipakai di | Status file |\n"
	text += "| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
	for item in items:
		# `ItemDefinition.icon` menang atas file; status harus mencerminkan sumber efektif.
		var status := "Texture di .tres" if item.icon != null else _icon_file_status(item.id)
		text += "| `icon_%s` | `%s` | %s | `%s` | %s | %d | %d × %d | tas, peti, hotbar, pickup | %s |\n" % [
			String(item.id),
			_item_icon_path(item.id),
			item.display_name,
			String(item.id),
			_item_category_name(item.category),
			item.max_stack,
			ITEM_ICON_RECOMMENDED.x,
			ITEM_ICON_RECOMMENDED.y,
			status,
		]
	text += "\n"
	return text


func _held_item_table() -> String:
	var items := _item_definitions()
	var text := "## Item di tangan (%d item)\n\n" % items.size()
	text += "Art barang yang dipegang pemain saat item dipilih di hotbar: `res://assets/held/<id>.png` (hanya `.png`; `.webp` tidak dibaca). Tanpa file, pemain memakai bentuk placeholder per kategori.\n\n"
	text += "| File | Item | ID | Ukuran tampil | Sumber disarankan | Dipakai di | Status file |\n"
	text += "| --- | --- | --- | --- | --- | --- | --- |\n"
	var hand_size := _held_display_size()
	for item in items:
		var path := "%s/%s.png" % [_held_item_dir(), String(item.id)]
		var status := "Ada" if FileAccess.file_exists(path) else "Belum ada (placeholder)"
		text += "| `%s` | %s | `%s` | %.0f × %.0f | %d × %d | `src/components/visual/held_item_visual.gd` | %s |\n" % [
			path,
			item.display_name,
			String(item.id),
			hand_size.x,
			hand_size.y,
			HELD_ITEM_RECOMMENDED.x,
			HELD_ITEM_RECOMMENDED.y,
			status,
		]
	text += "\n"
	return text


func _recipe_table() -> String:
	var recipes := _recipe_definitions()
	var text := "## Resep crafting (%d resep)\n\n" % recipes.size()
	text += "Panel Meja Kerja/Api Unggun menampilkan baris dari data ini sebagai teks (nama, bahan, waktu). Kolom ikon di bawah menunjuk file ikon barang hasil yang dipakai saat barang itu ada di tas/peti/hotbar/pickup.\n\n"
	text += "| Resep | ID | Stasiun | Bahan | Waktu | Ikon hasil | Status ikon |\n"
	text += "| --- | --- | --- | --- | --- | --- | --- |\n"
	for recipe in recipes:
		var ingredients := PackedStringArray()
		for amount in recipe.ingredients:
			if amount != null and amount.item != null:
				ingredients.append("%s ×%d" % [amount.item.display_name, amount.count])
		var result_name := "—"
		var icon_path := "—"
		var icon_status := "—"
		if recipe.result != null:
			result_name = "%s ×%d" % [recipe.result.display_name, recipe.result_count]
			icon_path = "`%s`" % _item_icon_path(recipe.result.id)
			icon_status = "Texture di .tres" if recipe.result.icon != null else _icon_file_status(recipe.result.id)
		text += "| %s | `%s` | %s | %s | %.1f s | %s | %s |\n" % [
			result_name,
			String(recipe.id),
			recipe.get_station_name(),
			", ".join(ingredients) if not ingredients.is_empty() else "—",
			recipe.craft_time,
			icon_path,
			icon_status,
		]
	text += "\n"
	return text


func _asset_coverage(registry: AssetRegistry) -> String:
	var text := "## Cakupan file saat panduan dibuat\n\n"
	text += "Dihitung dari file `.png`/`.webp` yang ada di folder tiap slot. Jalankan ulang generator setelah menambah art.\n\n"
	text += "| Kategori | Slot | Sudah ada file | Belum ada |\n| --- | --- | --- | --- |\n"
	var total := 0
	var filled := 0
	for category in CATEGORY_ORDER:
		var slots := _sorted_slots(registry, category)
		if slots.is_empty():
			continue
		var have := 0
		for slot in slots:
			# Sumber sama dengan tools/check_assets.gd dan HUD "Aset: X/Y".
			if Assets.has_art(slot.key):
				have += 1
		total += slots.size()
		filled += have
		text += "| %s | %d | %d | %d |\n" % [CATEGORY_LABEL.get(category, category), slots.size(), have, slots.size() - have]
	text += "| **Total** | %d | %d | %d |\n\n" % [total, filled, total - filled]

	var items := _item_definitions()
	var item_have := 0
	for item in items:
		if _item_icon_exists(item.id):
			item_have += 1
	text += "- Ikon item: **%d/%d** ada di `res://assets/icons/items/`.\n" % [item_have, items.size()]
	var held_have := 0
	for item in items:
		if not _find_item_asset(_held_item_dir(), item.id, ["png"]).is_empty():
			held_have += 1
	text += "- Item di tangan: **%d/%d** ada di `res://assets/held/`.\n" % [held_have, items.size()]
	text += "- Slot/ikon yang belum ada tetap memakai placeholder; game tidak crash.\n\n"
	return text


func _runtime_art_notes() -> String:
	var text := "## Visual yang dibuat runtime (tidak perlu file)\n\n"
	text += "| Visual | Dibuat oleh | Catatan |\n| --- | --- | --- |\n"
	text += "| Gradien arah matahari | `src/levels/components/environment/sun_overlay.gd` | Gradien runtime; arah dan intensitas ikut waktu |\n"
	text += "| Titik debu & kunang-kunang | `src/levels/components/environment/ambient_life.gd` | Tekstur titik dibuat `ImageTexture` |\n"
	text += "| Partikel Fireflies/DayMotes | `src/levels/components/environment/day_night_visual.tscn` | `GradientTexture2D` bawaan scene |\n"
	text += "| Placeholder pemain/fauna/props | Polygon2D di scene | Otomatis diganti slot art bila file tersedia |\n"
	text += "| Tema UI fallback | `src/ui/ui_skin.gd` | Tema default sampai `ui_panel`/`ui_button_*` diisi |\n\n"
	return text


## Sumber sama dengan gameplay dan tools/check_assets.gd: ItemCatalog.ALL.
## Item baru wajib didaftarkan di sana (dijaga test_docs_in_sync.gd).
func _item_definitions() -> Array:
	var items: Array = []
	for item in ItemCatalog.ALL:
		if item != null:
			items.append(item)
	items.sort_custom(func(a: ItemDefinition, b: ItemDefinition) -> bool:
		if a.category != b.category:
			return int(a.category) < int(b.category)
		return String(a.id) < String(b.id))
	return items


## Sumber sama dengan panel stasiun: CraftingComponent.RECIPE_FILES.
## Resep baru wajib didaftarkan di sana (dijaga test_docs_in_sync.gd).
func _recipe_definitions() -> Array:
	var recipes: Array = []
	for path in CraftingComponent.RECIPE_FILES:
		var recipe := load(path) as RecipeDefinition
		if recipe != null:
			recipes.append(recipe)
	recipes.sort_custom(func(a: RecipeDefinition, b: RecipeDefinition) -> bool:
		return String(a.id) < String(b.id))
	return recipes


func _item_icon_path(item_id: StringName) -> String:
	return "%s/%s.png" % [_item_icon_dir(), String(item_id)]


func _item_icon_exists(item_id: StringName) -> bool:
	return not _find_item_asset(_item_icon_dir(), item_id).is_empty()


func _icon_file_status(item_id: StringName) -> String:
	for extension in ["png", "webp"]:
		if FileAccess.file_exists("%s/%s.%s" % [_item_icon_dir(), String(item_id), extension]):
			return "Ada (.%s)" % extension
	return "Belum ada"


## Ukuran tampil dari config yang benar-benar dipakai HeldItemVisual.
func _held_display_size() -> Vector2:
	var config := load(HeldItemVisual.CONFIG_PATH) as HeldItemConfig
	if config != null and config.hand_size.x > 0.0 and config.hand_size.y > 0.0:
		return config.hand_size
	return HELD_ITEM_DISPLAY


## Folder mengikuti konstanta runtime supaya panduan dan kode tidak menyimpang.
func _item_icon_dir() -> String:
	return Assets.DEFAULT_ROOT + "/" + Assets.ITEM_ICON_FOLDER


func _held_item_dir() -> String:
	return HeldItemVisual.HELD_DIR.trim_suffix("/")


func _find_item_asset(directory: String, item_id: StringName, extensions: Array = ["png", "webp"]) -> String:
	if String(item_id).is_empty():
		return ""
	for extension in extensions:
		var path := "%s/%s.%s" % [directory, String(item_id), extension]
		if FileAccess.file_exists(path):
			return path
	return ""


func _item_category_name(category: int) -> String:
	match category:
		ItemDefinition.Category.CONSUMABLE:
			return "Consumable"
		ItemDefinition.Category.WEAPON:
			return "Weapon"
		ItemDefinition.Category.TOOL:
			return "Tool"
		ItemDefinition.Category.ARMOR:
			return "Armor"
		ItemDefinition.Category.SPECIAL:
			return "Special"
		_:
			return "Resource"





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
		"res://src/data/configs/daily_goals.tres": {
			"purpose": "Daftar tujuan harian (HUD kiri bawah) untuk Hari 1-7.",
			"used_by": "DailyGoalHUD, DailyGoalConfig, DailyGoal",
			"effect": "Mengubah teks/urutan tujuan; kondisi dibaca dari tas, struktur, dan base.",
			"tests": "test_daily_goals_and_light.gd",
		},
		"res://src/data/configs/dawn_recap_config.tres": {
			"purpose": "Durasi panel rekap fajar.",
			"used_by": "DawnRecapHUD, DawnRecapConfig",
			"effect": "Berapa lama panel rekap tampil sebelum menutup sendiri.",
			"tests": "test_daily_goals_and_light.gd",
		},
		"res://src/data/configs/player_light_config.tres": {
			"purpose": "Radius dan energi cahaya pemain malam (110 px, obor 190 px).",
			"used_by": "PlayerLight, PlayerLightConfig",
			"effect": "Mengubah terang/radius cahaya pemain; tidak mengubah tint dunia.",
			"tests": "test_daily_goals_and_light.gd",
		},
		"res://src/data/configs/environment/clock_format.tres": {
			"purpose": "Jam dunia nyata: jam terbit/terbenam, format 12/24 jam, label periode, flag HUD.",
			"used_by": "DayNightManager, GameClockFormat, TimeHUD, NightSurvivalHUD",
			"effect": "Menggeser jam terbit/terbenam atau format jam; durasi fase dan siklus tidak berubah.",
			"tests": "test_game_clock_format.gd",
		},
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
		"res://src/data/configs/physics/body_player.tres": {
			"purpose": "Profil massa/kolisi badan pemain (LIGHT, radius 12).",
			"used_by": "BodyProfileApplier (Player._ready), BodySeparation",
			"effect": "Menentukan siapa yang bisa ditembus, jarak kontak, dan pengali knockback yang diterima.",
			"tests": "test_mission10_physics_matrix.gd, test_mission10_mass_deer.gd",
		},
		"res://src/data/configs/physics/body_wild_boar.tres": {
			"purpose": "Profil massa/kolisi babi hutan (HEAVY, knockback 0.35).",
			"used_by": "BodyProfileApplier (FaunaBase._ready), BodySeparation",
			"effect": "Babi memblokir pemain, tetap bisa dipisah saat bertumpuk, dan hanya menerima 35% knockback.",
			"tests": "test_mission10_physics_matrix.gd, test_boar_mass.gd",
		},
		"res://src/data/configs/physics/body_island_deer.tres": {
			"purpose": "Profil massa/kolisi rusa pulau (MEDIUM, knockback 0.6).",
			"used_by": "BodyProfileApplier (FaunaBase._ready), BodySeparation",
			"effect": "Rusa kini padat dan menerima 60% knockback; jarak kontak dijaga pemisah badan.",
			"tests": "test_mission10_physics_matrix.gd, test_mission10_body_separation.gd",
		},
		"res://src/data/audio/audio_registry.tres": {
			"purpose": "Daftar semua cue audio (key, kategori, hook, bus, prioritas). Data dan dokumentasi saja.",
			"used_by": "AUDIO_GUIDE (generator), test_audio_guide_sync; belum ada playback",
			"effect": "Menambah cue berarti satu key baru di panduan audio; tidak mengubah gameplay.",
			"tests": "test_audio_guide_sync.gd, test_docs_in_sync.gd",
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

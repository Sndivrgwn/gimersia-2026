# Panduan Aset

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
- Tileset dunia AUTHORED (mode pulau buatan) **tidak memakai slot aset**: simpan
  di `assets/world/tilesets/` dan lihat
  [`WORLD_BUILDING_GUIDE.md`](WORLD_BUILDING_GUIDE.md) bagian 10. Slot di bawah
  hanya untuk pulau FORMULA dan prop yang dipasang kode.

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

## Pakai SpriteFrames (disarankan untuk karakter)

Satu file `.tres` berisi semua animasi slot. Game memakai file ini lebih dulu daripada PNG, jadi strip tidak perlu dipotong manual.

### Langkah di editor

1. Buat resource `SpriteFrames`: klik kanan di FileSystem → **New Resource...** → `SpriteFrames` (atau lewat panel **Animation** pada `AnimatedSprite2D`, tombol **New SpriteFrames**).
2. Tambah animasi dengan nama PERSIS seperti tabel di bawah: `<state>` atau `<state>_<dir>` dengan `dir` = `down`, `up`, `left`, `right`. Contoh: `idle_down`, `walk_left`, `lit`, `cold`.
3. Isi frame tiap animasi: **Add frames from sprite sheet** (pilih PNG strip + jumlah frame) atau tambah file per frame.
4. Atur **fps** dan **loop** tiap animasi di panel Animation. Nilai inilah yang dipakai game; `asset_config.tres` hanya berlaku untuk strip PNG.
5. Simpan ke path di tabel: `res://assets/<folder>/<slot>.tres`.
6. Import sekali (`GODOT --headless --import --path .` atau buka editor), lalu tekan **Backtick (`)** di island (`debug_reload_assets`) tanpa restart.

### Urutan prioritas

1. `res://assets/<folder>/<slot>.tres` (SpriteFrames) — **paling diutamakan**.
2. Strip PNG `_<N>f` atau PNG satu frame di folder slot (metode lama, tetap didukung).
3. Placeholder bawaan scene.

Di dalam SpriteFrames, animasi dicari berurutan: `<state>_<dir>` → `<state>` → `<state>_<arah cermin>` (flip_h) → `idle_<dir>` → `idle` → `default` → placeholder. Auto-scale dan pivot memakai frame PERTAMA animasi terpilih, sama seperti PNG.

### Nama animasi disarankan (12 slot showcase)

| Slot | Path .tres | Animasi disarankan |
| --- | --- | --- |
| `player` | `res://assets/characters/player/player.tres` | idle_<dir>, walk_<dir>, sprint_<dir>, attack_<dir>, hurt_<dir>, death_<dir> (`<dir>` = down/up/left/right) |
| `wild_boar` | `res://assets/characters/wild_boar/wild_boar.tres` | idle_<dir>, walk_<dir>, telegraph_<dir>, dash_<dir>, bite_<dir>, death_<dir> (`<dir>` = down/up/left/right) |
| `island_deer` | `res://assets/characters/island_deer/island_deer.tres` | idle_<dir>, walk_<dir>, flee_<dir>, death_<dir> (`<dir>` = down/up/left/right) |
| `twig` | `res://assets/props/twig/twig.tres` | full, depleted |
| `small_tree` | `res://assets/props/small_tree/small_tree.tres` | full, depleted |
| `tree` | `res://assets/props/tree/tree.tres` | full, depleted |
| `small_rock` | `res://assets/props/small_rock/small_rock.tres` | full, depleted |
| `campfire` | `res://assets/props/campfire/campfire.tres` | lit, ember, cold |
| `workbench` | `res://assets/props/workbench/workbench.tres` | default |
| `tent` | `res://assets/props/tent/tent.tres` | default, sleeping |
| `ground_camp` | `res://assets/world/ground/ground_camp.tres` | default |
| `ground_forest` | `res://assets/world/ground/ground_forest.tres` | default |

## Minimum untuk build pertama — tier Showcase (12 slot)

Slot yang paling menentukan kesan pertama. Karakter sebaiknya SpriteFrames; sisanya PNG sudah cukup. Bila kosong, game tetap jalan dengan placeholder.

- `player`, `wild_boar`, `island_deer`, `twig`, `small_tree`, `tree`, `small_rock`, `campfire`, `workbench`, `tent`, `ground_camp`, `ground_forest`

## Minimum untuk build pertama — tier Sisanya

Slot prioritas 1 di luar showcase.

- `big_rock`, `fiber_bush`, `berry_bush`, `coconut_palm`, `bamboo_clump`, `chest`, `ground_south_beach`, `ground_east_beach`, `ground_west_cliffs`, `ground_river`, `plane_wreckage`, `emergency_suitcase`, `signal_beacon`, `ui_panel`

<!-- BEGIN GENERATED -->
## Karakter

| Slot | Pola file | Wajib/Opsional | Ukuran tampil | Sumber disarankan | Pivot | Arah | State | Dipakai di | Fallback |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `island_deer` | `res://assets/characters/island_deer/idle[_dir][_Nf].png`<br>contoh: `res://assets/characters/island_deer/idle_down_4f.png` | Wajib | 36 × 30 | 48 × 40 | CENTER | 4 arah | idle, walk, flee, death | src/entities/fauna/island_deer/island_deer.tscn | state → arah → mirror → idle → default → placeholder |
| `player` | `res://assets/characters/player/idle[_dir][_Nf].png`<br>contoh: `res://assets/characters/player/idle_down_4f.png` | Wajib | 26 × 30 | 32 × 32 | CENTER | 4 arah | idle, walk, sprint, attack, hurt, death | src/entities/player/player.tscn (Player) | state → arah → mirror → idle → default → placeholder |
| `wild_boar` | `res://assets/characters/wild_boar/idle[_dir][_Nf].png`<br>contoh: `res://assets/characters/wild_boar/idle_down_4f.png` | Wajib | 34 × 24 | 48 × 32 | CENTER | 4 arah | idle, walk, telegraph, dash, bite, death | src/entities/fauna/wild_boar/wild_boar.tscn | state → arah → mirror → idle → default → placeholder |

## Node resource

| Slot | Pola file | Wajib/Opsional | Ukuran tampil | Sumber disarankan | Pivot | Arah | State | Dipakai di | Fallback |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `bamboo_clump` | `res://assets/props/bamboo_clump/full[_dir][_Nf].png`<br>contoh: `res://assets/props/bamboo_clump/full.png` | Wajib | 38 × 68 | 48 × 80 | BOTTOM_CENTER | satu arah | full, depleted | src/entities/props/resource_node/resource_node.tscn (definisi di src/data/gathering/) | state → arah → mirror → idle → default → placeholder |
| `berry_bush` | `res://assets/props/berry_bush/full[_dir][_Nf].png`<br>contoh: `res://assets/props/berry_bush/full.png` | Wajib | 34 × 28 | 40 × 32 | BOTTOM_CENTER | satu arah | full, depleted | src/entities/props/resource_node/resource_node.tscn (definisi di src/data/gathering/) | state → arah → mirror → idle → default → placeholder |
| `big_rock` | `res://assets/props/big_rock/full[_dir][_Nf].png`<br>contoh: `res://assets/props/big_rock/full.png` | Wajib | 46 × 34 | 48 × 40 | BOTTOM_CENTER | satu arah | full, depleted | src/entities/props/resource_node/resource_node.tscn (definisi di src/data/gathering/) | state → arah → mirror → idle → default → placeholder |
| `coconut_palm` | `res://assets/props/coconut_palm/full[_dir][_Nf].png`<br>contoh: `res://assets/props/coconut_palm/full.png` | Wajib | 60 × 84 | 64 × 96 | BOTTOM_CENTER | satu arah | full, depleted | src/entities/props/resource_node/resource_node.tscn (definisi di src/data/gathering/) | state → arah → mirror → idle → default → placeholder |
| `fiber_bush` | `res://assets/props/fiber_bush/full[_dir][_Nf].png`<br>contoh: `res://assets/props/fiber_bush/full.png` | Wajib | 34 × 26 | 40 × 32 | BOTTOM_CENTER | satu arah | full, depleted | src/entities/props/resource_node/resource_node.tscn (definisi di src/data/gathering/) | state → arah → mirror → idle → default → placeholder |
| `small_rock` | `res://assets/props/small_rock/full[_dir][_Nf].png`<br>contoh: `res://assets/props/small_rock/full.png` | Wajib | 28 × 22 | 32 × 24 | BOTTOM_CENTER | satu arah | full, depleted | src/entities/props/resource_node/resource_node.tscn (definisi di src/data/gathering/) | state → arah → mirror → idle → default → placeholder |
| `small_tree` | `res://assets/props/small_tree/full[_dir][_Nf].png`<br>contoh: `res://assets/props/small_tree/full.png` | Wajib | 40 × 52 | 48 × 64 | BOTTOM_CENTER | satu arah | full, depleted | src/entities/props/resource_node/resource_node.tscn (definisi di src/data/gathering/) | state → arah → mirror → idle → default → placeholder |
| `tree` | `res://assets/props/tree/full[_dir][_Nf].png`<br>contoh: `res://assets/props/tree/full.png` | Wajib | 60 × 76 | 64 × 80 | BOTTOM_CENTER | satu arah | full, depleted | src/entities/props/resource_node/resource_node.tscn (definisi di src/data/gathering/) | state → arah → mirror → idle → default → placeholder |
| `twig` | `res://assets/props/twig/full[_dir][_Nf].png`<br>contoh: `res://assets/props/twig/full.png` | Wajib | 26 × 18 | 32 × 24 | BOTTOM_CENTER | satu arah | full, depleted | src/entities/props/resource_node/resource_node.tscn (definisi di src/data/gathering/) | state → arah → mirror → idle → default → placeholder |

## Camp & struktur

| Slot | Pola file | Wajib/Opsional | Ukuran tampil | Sumber disarankan | Pivot | Arah | State | Dipakai di | Fallback |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `blueprint_campfire` | `res://assets/props/blueprint_campfire/default[_dir][_Nf].png`<br>contoh: `res://assets/props/blueprint_campfire/default.png` | Penting | 44 × 44 | 48 × 48 | CENTER | satu arah | default | src/entities/camp/blueprint_slot.gd | state → arah → mirror → idle → default → placeholder |
| `blueprint_chest` | `res://assets/props/blueprint_chest/default[_dir][_Nf].png`<br>contoh: `res://assets/props/blueprint_chest/default.png` | Penting | 44 × 44 | 48 × 48 | CENTER | satu arah | default | src/entities/camp/blueprint_slot.gd | state → arah → mirror → idle → default → placeholder |
| `blueprint_fence_segment` | `res://assets/props/blueprint_fence_segment/default[_dir][_Nf].png`<br>contoh: `res://assets/props/blueprint_fence_segment/default.png` | Penting | 44 × 44 | 48 × 48 | CENTER | satu arah | default | src/entities/camp/blueprint_slot.gd | state → arah → mirror → idle → default → placeholder |
| `blueprint_tent` | `res://assets/props/blueprint_tent/default[_dir][_Nf].png`<br>contoh: `res://assets/props/blueprint_tent/default.png` | Penting | 44 × 44 | 48 × 48 | CENTER | satu arah | default | src/entities/camp/blueprint_slot.gd | state → arah → mirror → idle → default → placeholder |
| `blueprint_workbench` | `res://assets/props/blueprint_workbench/default[_dir][_Nf].png`<br>contoh: `res://assets/props/blueprint_workbench/default.png` | Penting | 44 × 44 | 48 × 48 | CENTER | satu arah | default | src/entities/camp/blueprint_slot.gd | state → arah → mirror → idle → default → placeholder |
| `campfire` | `res://assets/props/campfire/lit[_dir][_Nf].png`<br>contoh: `res://assets/props/campfire/lit_4f.png` | Wajib | 44 × 34 | 48 × 40 | CENTER | satu arah | lit, ember, cold | src/entities/camp/campfire/campfire.tscn | state → arah → mirror → idle → default → placeholder |
| `chest` | `res://assets/props/chest/closed[_dir][_Nf].png`<br>contoh: `res://assets/props/chest/closed.png` | Wajib | 52 × 40 | 56 × 48 | BOTTOM_CENTER | satu arah | closed, open | src/entities/camp/chest/chest.tscn | state → arah → mirror → idle → default → placeholder |
| `fence_segment` | `res://assets/props/fence_segment/default[_dir][_Nf].png`<br>contoh: `res://assets/props/fence_segment/default.png` | Penting | 40 × 40 | 40 × 40 | CENTER | satu arah | default | src/levels/camp/fence_ring.gd (FenceSegment) | state → arah → mirror → idle → default → placeholder |
| `light_campfire` | `res://assets/fx/light/campfire_light[_dir][_Nf].png`<br>contoh: `res://assets/fx/light/campfire_light.png` | Penting | 128 × 128 | 256 × 256 | CENTER | satu arah | default | src/entities/camp/campfire/campfire.gd (PointLight2D) | state → arah → mirror → idle → default → placeholder |
| `tent` | `res://assets/props/tent/default[_dir][_Nf].png`<br>contoh: `res://assets/props/tent/default.png` | Wajib | 68 × 50 | 80 × 56 | BOTTOM_CENTER | satu arah | default, sleeping | src/entities/camp/tent/tent.tscn | state → arah → mirror → idle → default → placeholder |
| `workbench` | `res://assets/props/workbench/default[_dir][_Nf].png`<br>contoh: `res://assets/props/workbench/default.png` | Wajib | 56 × 44 | 64 × 48 | BOTTOM_CENTER | satu arah | default | src/entities/camp/workbench/workbench.tscn | state → arah → mirror → idle → default → placeholder |

## Dunia

| Slot | Pola file | Wajib/Opsional | Ukuran tampil | Sumber disarankan | Pivot | Arah | State | Dipakai di | Fallback |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `emergency_suitcase` | `res://assets/props/emergency_suitcase/closed[_dir][_Nf].png`<br>contoh: `res://assets/props/emergency_suitcase/closed.png` | Wajib | 40 × 32 | 48 × 40 | CENTER | satu arah | closed, open | src/entities/props/suitcase/emergency_suitcase.tscn | state → arah → mirror → idle → default → placeholder |
| `ground_camp` | `res://assets/world/ground/camp[_dir][_Nf].png`<br>contoh: `res://assets/world/ground/camp.png` | Wajib | 32 × 32 | 32 × 32 | CENTER | satu arah | default | src/levels/island/island.tscn (node Ground) | state → arah → mirror → idle → default → placeholder |
| `ground_east_beach` | `res://assets/world/ground/east_beach[_dir][_Nf].png`<br>contoh: `res://assets/world/ground/east_beach.png` | Wajib | 32 × 32 | 32 × 32 | CENTER | satu arah | default | src/levels/island/island.tscn (node Ground) | state → arah → mirror → idle → default → placeholder |
| `ground_forest` | `res://assets/world/ground/forest[_dir][_Nf].png`<br>contoh: `res://assets/world/ground/forest.png` | Wajib | 32 × 32 | 32 × 32 | CENTER | satu arah | default | src/levels/island/island.tscn (node Ground) | state → arah → mirror → idle → default → placeholder |
| `ground_river` | `res://assets/world/ground/river[_dir][_Nf].png`<br>contoh: `res://assets/world/ground/river.png` | Wajib | 32 × 32 | 32 × 32 | CENTER | satu arah | default | src/levels/island/island.tscn (node Ground) | state → arah → mirror → idle → default → placeholder |
| `ground_south_beach` | `res://assets/world/ground/south_beach[_dir][_Nf].png`<br>contoh: `res://assets/world/ground/south_beach.png` | Wajib | 32 × 32 | 32 × 32 | CENTER | satu arah | default | src/levels/island/island.tscn (node Ground) | state → arah → mirror → idle → default → placeholder |
| `ground_west_cliffs` | `res://assets/world/ground/west_cliffs[_dir][_Nf].png`<br>contoh: `res://assets/world/ground/west_cliffs.png` | Wajib | 32 × 32 | 32 × 32 | CENTER | satu arah | default | src/levels/island/island.tscn (node Ground) | state → arah → mirror → idle → default → placeholder |
| `item_pickup_shadow` | `res://assets/props/item_pickup_shadow/default[_dir][_Nf].png`<br>contoh: `res://assets/props/item_pickup_shadow/default.png` | Opsional | 20 × 10 | 24 × 12 | CENTER | satu arah | default | src/entities/props/item_pickup.gd | state → arah → mirror → idle → default → placeholder |
| `loot_bag` | `res://assets/props/loot_bag/default[_dir][_Nf].png`<br>contoh: `res://assets/props/loot_bag/default.png` | Penting | 30 × 22 | 32 × 24 | CENTER | satu arah | default | src/entities/props/loot_bag/loot_bag.gd | state → arah → mirror → idle → default → placeholder |
| `plane_wreckage` | `res://assets/props/plane_wreckage/default[_dir][_Nf].png`<br>contoh: `res://assets/props/plane_wreckage/default.png` | Wajib | 140 × 70 | 160 × 80 | CENTER | satu arah | default | src/levels/island/island.tscn (Wreckage/Visual) | state → arah → mirror → idle → default → placeholder |
| `river_edge` | `res://assets/props/river_edge/default[_dir][_Nf].png`<br>contoh: `res://assets/props/river_edge/default.png` | Opsional | 22 × 22 | 24 × 24 | CENTER | satu arah | default | src/entities/props/river_edge/river_edge.tscn | state → arah → mirror → idle → default → placeholder |
| `signal_beacon` | `res://assets/props/signal_beacon/idle[_dir][_Nf].png`<br>contoh: `res://assets/props/signal_beacon/idle.png` | Wajib | 40 × 48 | 48 × 56 | CENTER | satu arah | idle, active | src/entities/props/beacon/signal_beacon.gd (node Beacon di island.tscn) | state → arah → mirror → idle → default → placeholder |
| `world_water` | `res://assets/world/ground/water[_dir][_Nf].png`<br>contoh: `res://assets/world/ground/water.png` | Opsional | 32 × 32 | 32 × 32 | CENTER | satu arah | default | opsional, di belakang semua ground | state → arah → mirror → idle → default → placeholder |

## Efek

| Slot | Pola file | Wajib/Opsional | Ukuran tampil | Sumber disarankan | Pivot | Arah | State | Dipakai di | Fallback |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `fx_chip` | `res://assets/fx/chip/default[_dir][_Nf].png`<br>contoh: `res://assets/fx/chip/default.png` | Penting | 6 × 6 | 8 × 8 | CENTER | satu arah | default | src/entities/props/resource_node/chop_feedback.gd (serpihan) | state → arah → mirror → idle → default → placeholder |
| `fx_dust` | `res://assets/fx/dust/default[_dir][_Nf].png`<br>contoh: `res://assets/fx/dust/default.png` | Opsional | 8 × 8 | 8 × 8 | CENTER | satu arah | default | src/entities/fauna/fauna_base.gd (debu saat kabur) | state → arah → mirror → idle → default → placeholder |
| `fx_hit_spark` | `res://assets/fx/hit_spark/default[_dir][_Nf].png`<br>contoh: `res://assets/fx/hit_spark/default.png` | Penting | 8 × 8 | 8 × 8 | CENTER | satu arah | default | src/components/combat/combat_feedback.gd (pecahan hit) | state → arah → mirror → idle → default → placeholder |
| `fx_slash` | `res://assets/fx/slash/default[_dir][_Nf].png`<br>contoh: `res://assets/fx/slash/default.png` | Penting | 48 × 48 | 64 × 64 | CENTER | satu arah | default | src/components/combat/combat_feedback.gd (arc slash) | state → arah → mirror → idle → default → placeholder |

## UI & ikon

| Slot | Pola file | Wajib/Opsional | Ukuran tampil | Sumber disarankan | Pivot | Arah | State | Dipakai di | Fallback |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `ui_bar_bg` | `res://assets/ui/bar_bg[_dir][_Nf].png`<br>contoh: `res://assets/ui/bar_bg.png` | Penting | 120 × 12 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_bar_fill_fatigue` | `res://assets/ui/bar_fill_fatigue[_dir][_Nf].png`<br>contoh: `res://assets/ui/bar_fill_fatigue.png` | Penting | 120 × 12 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_bar_fill_hp` | `res://assets/ui/bar_fill_hp[_dir][_Nf].png`<br>contoh: `res://assets/ui/bar_fill_hp.png` | Penting | 120 × 12 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_bar_fill_hunger` | `res://assets/ui/bar_fill_hunger[_dir][_Nf].png`<br>contoh: `res://assets/ui/bar_fill_hunger.png` | Penting | 120 × 12 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_bar_fill_thirst` | `res://assets/ui/bar_fill_thirst[_dir][_Nf].png`<br>contoh: `res://assets/ui/bar_fill_thirst.png` | Penting | 120 × 12 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_bg_death` | `res://assets/ui/bg_death[_dir][_Nf].png`<br>contoh: `res://assets/ui/bg_death.png` | Opsional | 1280 × 720 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_bg_game_over` | `res://assets/ui/bg_game_over[_dir][_Nf].png`<br>contoh: `res://assets/ui/bg_game_over.png` | Opsional | 1280 × 720 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_bg_main_menu` | `res://assets/ui/bg_main_menu[_dir][_Nf].png`<br>contoh: `res://assets/ui/bg_main_menu.png` | Penting | 1280 × 720 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_bg_victory` | `res://assets/ui/bg_victory[_dir][_Nf].png`<br>contoh: `res://assets/ui/bg_victory.png` | Opsional | 1280 × 720 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_button_disabled` | `res://assets/ui/button_disabled[_dir][_Nf].png`<br>contoh: `res://assets/ui/button_disabled.png` | Opsional | 160 × 40 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_button_hover` | `res://assets/ui/button_hover[_dir][_Nf].png`<br>contoh: `res://assets/ui/button_hover.png` | Penting | 160 × 40 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_button_normal` | `res://assets/ui/button_normal[_dir][_Nf].png`<br>contoh: `res://assets/ui/button_normal.png` | Penting | 160 × 40 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_button_pressed` | `res://assets/ui/button_pressed[_dir][_Nf].png`<br>contoh: `res://assets/ui/button_pressed.png` | Penting | 160 × 40 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_clock_moon` | `res://assets/ui/icons/clock_moon[_dir][_Nf].png`<br>contoh: `res://assets/ui/icons/clock_moon.png` | Opsional | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_clock_sun` | `res://assets/ui/icons/clock_sun[_dir][_Nf].png`<br>contoh: `res://assets/ui/icons/clock_sun.png` | Opsional | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_font_bold` | `res://assets/ui/fonts/bold[_dir][_Nf].png`<br>contoh: `res://assets/ui/fonts/bold.png` | Penting | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_font_main` | `res://assets/ui/fonts/main[_dir][_Nf].png`<br>contoh: `res://assets/ui/fonts/main.png` | Penting | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_icon_fatigue` | `res://assets/ui/icons/fatigue[_dir][_Nf].png`<br>contoh: `res://assets/ui/icons/fatigue.png` | Penting | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_icon_hp` | `res://assets/ui/icons/hp[_dir][_Nf].png`<br>contoh: `res://assets/ui/icons/hp.png` | Penting | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_icon_hunger` | `res://assets/ui/icons/hunger[_dir][_Nf].png`<br>contoh: `res://assets/ui/icons/hunger.png` | Penting | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_icon_thirst` | `res://assets/ui/icons/thirst[_dir][_Nf].png`<br>contoh: `res://assets/ui/icons/thirst.png` | Penting | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_logo` | `res://assets/ui/logo[_dir][_Nf].png`<br>contoh: `res://assets/ui/logo.png` | Penting | 480 × 160 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_moon` | `res://assets/ui/icons/moon[_dir][_Nf].png`<br>contoh: `res://assets/ui/icons/moon.png` | Opsional | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_panel` | `res://assets/ui/panel[_dir][_Nf].png`<br>contoh: `res://assets/ui/panel.png` | Wajib | 256 × 128 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_slot_frame` | `res://assets/ui/slot_frame[_dir][_Nf].png`<br>contoh: `res://assets/ui/slot_frame.png` | Penting | 48 × 48 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_sun` | `res://assets/ui/icons/sun[_dir][_Nf].png`<br>contoh: `res://assets/ui/icons/sun.png` | Opsional | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_vignette_low_hp` | `res://assets/ui/vignette_low_hp[_dir][_Nf].png`<br>contoh: `res://assets/ui/vignette_low_hp.png` | Opsional | 1280 × 720 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |

## Ikon item (24 item)

Satu file per item: `res://assets/icons/items/<id>.png` (`.webp` juga dibaca; `.png` diprioritaskan bila keduanya ada). Ikon yang sama dipakai di tas, panel peti, hotbar, dan item pickup (diperkecil otomatis). Baris resep tidak memakai ikon. Ukuran sumber disarankan 48 × 48 px, latar transparan.

| Ikon | Path file | Item | ID | Kategori | Stack | Ukuran disarankan | Dipakai di | Status file |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `icon_bamboo` | `res://assets/icons/items/bamboo.png` | Bambu | `bamboo` | Resource | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_bone` | `res://assets/icons/items/bone.png` | Tulang | `bone` | Resource | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_fiber` | `res://assets/icons/items/fiber.png` | Serat | `fiber` | Resource | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_hide` | `res://assets/icons/items/hide.png` | Kulit | `hide` | Resource | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_stone` | `res://assets/icons/items/stone.png` | Batu | `stone` | Resource | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_wood` | `res://assets/icons/items/wood.png` | Kayu | `wood` | Resource | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_berry` | `res://assets/icons/items/berry.png` | Beri | `berry` | Consumable | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_boiled_water` | `res://assets/icons/items/boiled_water.png` | Air Matang | `boiled_water` | Consumable | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_bone_broth` | `res://assets/icons/items/bone_broth.png` | Kaldu Tulang | `bone_broth` | Consumable | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_coconut` | `res://assets/icons/items/coconut.png` | Kelapa | `coconut` | Consumable | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_cooked_meat` | `res://assets/icons/items/cooked_meat.png` | Daging Matang | `cooked_meat` | Consumable | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_herbal_bandage` | `res://assets/icons/items/herbal_bandage.png` | Perban Herbal | `herbal_bandage` | Consumable | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_raw_meat` | `res://assets/icons/items/raw_meat.png` | Daging Mentah | `raw_meat` | Consumable | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_waterskin` | `res://assets/icons/items/waterskin.png` | Kantung Air Kulit | `waterskin` | Consumable | 1 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_bone_spear` | `res://assets/icons/items/bone_spear.png` | Tombak Tulang | `bone_spear` | Weapon | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_stone_spear` | `res://assets/icons/items/stone_spear.png` | Tombak Batu | `stone_spear` | Weapon | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_wooden_spear` | `res://assets/icons/items/wooden_spear.png` | Tombak Kayu | `wooden_spear` | Weapon | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_stone_axe` | `res://assets/icons/items/stone_axe.png` | Kapak Batu | `stone_axe` | Tool | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_stone_pickaxe` | `res://assets/icons/items/stone_pickaxe.png` | Beliung Batu | `stone_pickaxe` | Tool | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_leather_vest` | `res://assets/icons/items/leather_vest.png` | Rompi Kulit | `leather_vest` | Armor | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_cockpit_notes` | `res://assets/icons/items/cockpit_notes.png` | Catatan Kokpit | `cockpit_notes` | Special | 1 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_signal_flare` | `res://assets/icons/items/signal_flare.png` | Suar Darurat | `signal_flare` | Special | 1 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_torch` | `res://assets/icons/items/torch.png` | Obor | `torch` | Special | 20 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |
| `icon_waterskin_empty` | `res://assets/icons/items/waterskin_empty.png` | Kantung Air Kosong | `waterskin_empty` | Special | 1 | 48 × 48 | tas, peti, hotbar, pickup | Belum ada |

## Item di tangan (24 item)

Art barang yang dipegang pemain saat item dipilih di hotbar: `res://assets/held/<id>.png` (hanya `.png`; `.webp` tidak dibaca). Tanpa file, pemain memakai bentuk placeholder per kategori.

| File | Item | ID | Ukuran tampil | Sumber disarankan | Dipakai di | Status file |
| --- | --- | --- | --- | --- | --- | --- |
| `res://assets/held/bamboo.png` | Bambu | `bamboo` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/bone.png` | Tulang | `bone` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/fiber.png` | Serat | `fiber` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/hide.png` | Kulit | `hide` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/stone.png` | Batu | `stone` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/wood.png` | Kayu | `wood` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/berry.png` | Beri | `berry` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/boiled_water.png` | Air Matang | `boiled_water` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/bone_broth.png` | Kaldu Tulang | `bone_broth` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/coconut.png` | Kelapa | `coconut` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/cooked_meat.png` | Daging Matang | `cooked_meat` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/herbal_bandage.png` | Perban Herbal | `herbal_bandage` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/raw_meat.png` | Daging Mentah | `raw_meat` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/waterskin.png` | Kantung Air Kulit | `waterskin` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/bone_spear.png` | Tombak Tulang | `bone_spear` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/stone_spear.png` | Tombak Batu | `stone_spear` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/wooden_spear.png` | Tombak Kayu | `wooden_spear` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/stone_axe.png` | Kapak Batu | `stone_axe` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/stone_pickaxe.png` | Beliung Batu | `stone_pickaxe` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/leather_vest.png` | Rompi Kulit | `leather_vest` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/cockpit_notes.png` | Catatan Kokpit | `cockpit_notes` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/signal_flare.png` | Suar Darurat | `signal_flare` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/torch.png` | Obor | `torch` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |
| `res://assets/held/waterskin_empty.png` | Kantung Air Kosong | `waterskin_empty` | 14 × 14 | 32 × 32 | `src/components/visual/held_item_visual.gd` | Belum ada (placeholder) |

## Resep crafting (13 resep)

Panel Meja Kerja/Api Unggun menampilkan baris dari data ini sebagai teks (nama, bahan, waktu). Kolom ikon di bawah menunjuk file ikon barang hasil yang dipakai saat barang itu ada di tas/peti/hotbar/pickup.

| Resep | ID | Stasiun | Bahan | Waktu | Ikon hasil | Status ikon |
| --- | --- | --- | --- | --- | --- | --- |
| Air Matang ×1 | `boiled_water` | Api Unggun | Bambu ×1 | 2.0 s | `res://assets/icons/items/boiled_water.png` | Belum ada |
| Kaldu Tulang ×1 | `bone_broth` | Api Unggun | Tulang ×2, Daging Mentah ×1 | 2.5 s | `res://assets/icons/items/bone_broth.png` | Belum ada |
| Tombak Tulang ×1 | `bone_spear` | Workbench | Tombak Kayu ×1, Tulang ×2, Serat ×2 | 3.0 s | `res://assets/icons/items/bone_spear.png` | Belum ada |
| Daging Matang ×1 | `cooked_meat` | Api Unggun | Daging Mentah ×1 | 2.0 s | `res://assets/icons/items/cooked_meat.png` | Belum ada |
| Perban Herbal ×1 | `herbal_bandage` | Tangan | Serat ×3, Beri ×2 | 1.5 s | `res://assets/icons/items/herbal_bandage.png` | Belum ada |
| Rompi Kulit ×1 | `leather_vest` | Workbench | Kulit ×3, Serat ×3 | 3.0 s | `res://assets/icons/items/leather_vest.png` | Belum ada |
| Suar Darurat ×1 | `signal_flare` | Workbench | Kayu ×5, Tulang ×3, Kulit ×2, Serat ×2 | 4.0 s | `res://assets/icons/items/signal_flare.png` | Belum ada |
| Kapak Batu ×1 | `stone_axe` | Workbench | Kayu ×2, Batu ×2, Serat ×1 | 2.5 s | `res://assets/icons/items/stone_axe.png` | Belum ada |
| Beliung Batu ×1 | `stone_pickaxe` | Workbench | Kayu ×2, Batu ×3, Serat ×1 | 2.5 s | `res://assets/icons/items/stone_pickaxe.png` | Belum ada |
| Tombak Batu ×1 | `stone_spear` | Workbench | Tombak Kayu ×1, Batu ×2, Serat ×2 | 3.0 s | `res://assets/icons/items/stone_spear.png` | Belum ada |
| Obor ×1 | `torch` | Tangan | Kayu ×2, Serat ×1 | 1.5 s | `res://assets/icons/items/torch.png` | Belum ada |
| Kantung Air Kulit ×1 | `waterskin` | Workbench | Kulit ×2, Serat ×1 | 2.5 s | `res://assets/icons/items/waterskin.png` | Belum ada |
| Tombak Kayu ×1 | `wooden_spear` | Tangan | Kayu ×3, Serat ×2 | 2.0 s | `res://assets/icons/items/wooden_spear.png` | Belum ada |

## Cakupan file saat panduan dibuat

Dihitung dari file `.png`/`.webp` yang ada di folder tiap slot. Jalankan ulang generator setelah menambah art.

| Kategori | Slot | Sudah ada file | Belum ada |
| --- | --- | --- | --- |
| Karakter | 3 | 1 | 2 |
| Node resource | 9 | 0 | 9 |
| Camp & struktur | 11 | 0 | 11 |
| Dunia | 13 | 0 | 13 |
| Efek | 4 | 0 | 4 |
| UI & ikon | 27 | 0 | 27 |
| **Total** | 67 | 1 | 66 |

- Ikon item: **0/24** ada di `res://assets/icons/items/`.
- Item di tangan: **0/24** ada di `res://assets/held/`.
- Slot/ikon yang belum ada tetap memakai placeholder; game tidak crash.

## Visual yang dibuat runtime (tidak perlu file)

| Visual | Dibuat oleh | Catatan |
| --- | --- | --- |
| Gradien arah matahari | `src/levels/components/environment/sun_overlay.gd` | Gradien runtime; arah dan intensitas ikut waktu |
| Titik debu & kunang-kunang | `src/levels/components/environment/ambient_life.gd` | Tekstur titik dibuat `ImageTexture` |
| Partikel Fireflies/DayMotes | `src/levels/components/environment/day_night_visual.tscn` | `GradientTexture2D` bawaan scene |
| Placeholder pemain/fauna/props | Polygon2D di scene | Otomatis diganti slot art bila file tersedia |
| Tema UI fallback | `src/ui/ui_skin.gd` | Tema default sampai `ui_panel`/`ui_button_*` diisi |

<!-- END GENERATED -->

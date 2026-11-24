# Panduan Membangun Dunia

Dokumen ini untuk **project manager / desainer level** yang memakai editor Godot
tetapi tidak menulis kode. Semua langkah di sini memakai klik editor atau satu
perintah terminal.

## Apa yang bisa Anda ubah dari sini

- Bentuk pulau, zona, dan warna zona.
- Tempat pemain mulai, bangkai pesawat, koper, suar, dan titik spawn malam.
- Sebaran pohon, batu, fiber, beri, bambu, dan kelapa.
- Visual tanah dan properti (hanya tampilan; tidak ada logika di tile).

## Dua mode dunia

| Mode | Isi pulau | Cocok untuk | Angka |
| --- | --- | --- | --- |
| **FORMULA** | Pulau persegi 4800 x 4800 yang dibangun kode dari `island_layout.tres` | Cepat, uji gameplay, tidak butuh desain level | Semua angka di tabel FORMULA |
| **AUTHORED** | Scene dunia buatan Anda (`world.tscn`), berisi polygon zona, penanda, area resource | Desain pulau final, bentuk bebas | Semua angka tetap dibaca dari `world_config.tres` |

Aturan memilih:

1. Sedang menguji mekanik (crafting, malam, raid)? Pakai **FORMULA**.
2. Sedang mendesain pulau yang akan dipakai pemain? Pakai **AUTHORED**.
3. Ragu? Mulai dari AUTHORED; kalau scene belum siap, game otomatis kembali ke
   FORMULA (lihat bagian 2).

## Cara berpindah mode

1. Buka `res://src/data/configs/world/world_config.tres` di Godot (double click).
2. Di Inspector, ubah field **Mode**: `FORMULA` atau `AUTHORED`.
3. Kalau memilih AUTHORED, isi **Authored Scene Path** dengan path scene dunia,
   mis. `res://src/levels/worlds/sample_island/world.tscn`.
4. Biarkan **Fallback To Formula** = `true` selama pengembangan: kalau scene
   gagal dimuat, game memakai pulau FORMULA dan menulis peringatan di Output.
5. Jalankan `island.tscn` (F6/F5). Tidak perlu menyalakan ulang editor.

Cara mencoba cepat:

- Dunia contoh siap pakai: `res://src/levels/worlds/sample_island/world.tscn`.
- Kerangka kosong untuk dunia baru: `res://src/levels/worlds/_template/world.tscn`.
- Validasi tanpa membuka game:
  `GODOT --headless --path . -s tools/validate_world.gd -- res://src/levels/worlds/<nama>/world.tscn`

Tabel field mode (dibuat dari `world_config.tres`):

<!-- BEGIN GENERATED -->
| Field | Arti | Dampak | Nilai sekarang |
| --- | --- | --- | --- |
| `mode` | Mode dunia: FORMULA = pulau rumus lama, AUTHORED = scene dunia buatan. | Menentukan seluruh isi pulau setelah boot. | FORMULA |
| `authored_scene_path` | Path scene dunia AUTHORED yang dimuat. | Hanya dipakai saat mode = AUTHORED. | res://src/levels/worlds/sample_island/world.tscn |
| `fallback_to_formula` | Kalau scene AUTHORED gagal dimuat, pakai pulau FORMULA. | True = game tetap jalan (dengan peringatan di Output); False = boot gagal. | true |
<!-- END GENERATED -->

## Mode FORMULA

Pulau FORMULA adalah kotak `half_size` x `half_size` yang diisi kode. Bentuk
zonanya **tidak bisa diubah** dari sini: camp selalu di tengah, pantai di
selatan/timur, tebing di barat, dan sungai membelah pulau.

Yang bisa diubah: jumlah dan sebaran resource serta titik spawn malam di
`res://src/data/configs/island_layout.tres`.

Cara mengubah:

1. Buka `res://src/data/configs/island_layout.tres`.
2. Ubah angka di Inspector (mis. `camp_twig`, `forest_tree`).
3. Simpan, jalankan `island.tscn`, lalu jalankan tes `test_island` dan
   `test_world_golden` untuk memastikan tidak ada yang rusak.
4. **Jangan** mengubah file ini lewat editor teks: nilainya juga ditulis ulang
   oleh `tools/generate_island_layout.gd` bila angka baru diputuskan.

Yang TIDAK bisa diubah di mode FORMULA:

- Bentuk dan posisi zona (camp, pantai, tebing, sungai).
- Posisi bangkai pesawat, koper, suar, dan start pemain.
- Bentuk pulau (selalu persegi).

Tabel parameter (dibuat dari `island_layout.tres`, `half_size` = 2400):

<!-- BEGIN GENERATED -->
| Field | Arti | Dampak | Nilai sekarang |
| --- | --- | --- | --- |
| `layout_seed` | Seed acak layout. | Seed sama = posisi resource sama. | 20260101 |
| `half_size` | Setengah sisi pulau FORMULA. | Besar pulau persegi. | 2400 |
| `coast_margin` | Margin dari tepi yang tidak diisi node. | Menjauhkan resource dari bibir pantai. | 150 |
| `min_spacing` | Jarak minimum antar node. | Kepadatan maksimum resource. | 70 |
| `keep_out_radius` | Radius bebas di sekitar start, wreckage, koper. | Tidak ada resource yang menutupi POI. | 140 |
| `beacon_keep_out` | Radius bebas di sekitar Signal Beacon. | Beacon tidak tertutup resource. | 150 |
| `camp_ring_min` | Radius dalam cincin starter camp. | Zona 1 mulai di luar angka ini. | 220 |
| `camp_ring_max` | Radius luar cincin starter camp. | Batas resource awal. | 700 |
| `max_attempts` | Percobaan penempatan per node. | Lebih besar = lebih rapat, lebih lambat. | 2000 |
| `markers_min_distance` | Jarak minimum marker spawn malam dari (0,0). | Mencegah spawn di camp. | 1100 |
| `camp_starters_last_respawn_day` | Hari terakhir resource starter camp muncul lagi. | Setelah hari ini resource awal habis permanen. | 4 |
| `camp_twig` | Jumlah ranting di camp. | Sumber kayu awal. | 10 |
| `camp_small_rock` | Jumlah batu kecil di camp. | Sumber batu awal. | 8 |
| `camp_fiber_bush` | Jumlah semak fiber di camp. | Sumber fiber awal. | 5 |
| `camp_berry_bush` | Jumlah semak beri di camp. | Sumber makanan awal. | 4 |
| `camp_small_tree` | Jumlah pohon kecil di camp. | Sumber kayu awal. | 6 |
| `south_coconut_palm` | Jumlah pohon kelapa di pantai selatan. | Sumber kelapa (opsional). | 12 |
| `west_small_rock` | Jumlah batu kecil di tebing barat. | Sumber batu. | 14 |
| `west_big_rock` | Jumlah batu besar di tebing barat. | Sumber batu (butuh pickaxe). | 8 |
| `river_bamboo` | Jumlah rumpun bambu di sungai. | Sumber bambu. | 14 |
| `forest_tree` | Jumlah pohon di hutan. | Sumber kayu utama. | 30 |
| `forest_fiber_bush` | Jumlah semak fiber di hutan. | Sumber fiber utama. | 24 |
| `forest_berry_bush` | Jumlah semak beri di hutan. | Sumber makanan utama. | 18 |
| `night_spawn_markers` | Jumlah marker spawn malam di FORMULA. | Banyak titik kemunculan hewan malam. | 16 |
<!-- END GENERATED -->

## Mode AUTHORED: konsepnya

Satu dunia AUTHORED adalah **satu scene** (`world.tscn`) yang berisi tiga hal:

1. **Area zona** — polygon yang memberi tahu game "di sini camp", "di sini
   sungai", "di sini tidak bisa dilewati".
2. **Penanda** — titik penting: start pemain, bangkai, koper, suar, titik spawn
   malam, titik air.
3. **Area resource** — polygon yang diisi pohon/batu/semak otomatis, atau node
   resource yang Anda taruh sendiri.

Visual (TileMapLayer) hanya **tampilan**. Game membaca polygon dan penanda, bukan
tile. Jadi pulau bisa terlihat bagus tanpa mengubah gameplay, dan gameplay tetap
sama walau art belum ada.

Alur peta:

```
Anda menggambar di editor
        |
        v
world.tscn (AuthoredWorld)
        |
        +--> Zones     -> ZoneGrid -> walkable / buildable / zona
        +--> Markers   -> POI, spawn malam, titik air
        +--> Resources -> daftar node resource (area + manual)
        |
        v
WorldController membuat WorldSource, lalu WorldRules menjawab
pertanyaan gameplay: zona apa di titik ini? bisa dilewati? bisa dibangun?
```

Angka global tetap dari `res://src/data/configs/world/world_config.tres`
(cell size 32 px, jarak spawn 1100 px, lebar koridor 96 px).

## Anatomi scene dunia

Pohon node wajib (nama harus persis; dibuat dari kontrak `AuthoredWorld`):

```
World (AuthoredWorld)
├── Visual          (TileMapLayer, dekorasi visual)
├── Zones           (ZoneArea: polygon zona)
│   ├── IslandOutline   <- tepat satu, is_island_outline = true
│   ├── Forest
│   ├── Camp
│   └── ...
├── Markers         (Marker2D)
│   ├── PlayerStart
│   ├── PlaneWreckage
│   ├── EmergencySuitcase
│   ├── SignalBeacon
│   ├── NightSpawns/    (NightSpawn1, NightSpawn2, ...)
│   └── WaterAccess/    (WaterAccess1, ...)
├── Resources       (ResourceArea, atau node resource manual)
└── Decor           (Node2D bebas: batu hias, rumput, puing)
```

Isi tiap node:

<!-- BEGIN GENERATED -->
| Node | Wajib? | Isi |
| --- | --- | --- |
| `Visual` | wajib | Tempat semua TileMapLayer dan art tanah. Tanpa logika. |
| `Zones` | wajib | Wadah ZoneArea; tiap anak adalah satu polygon zona. |
| `Zones/IslandOutline` | wajib (tepat satu) | Polygon batas pulau; tandai Is Island Outline. |
| `Markers` | wajib | Wadah penanda (Marker2D). |
| `Markers/PlayerStart` | wajib | Penanda POI; lihat tabel penanda di bagian 8. |
| `Markers/PlaneWreckage` | wajib | Penanda POI; lihat tabel penanda di bagian 8. |
| `Markers/EmergencySuitcase` | wajib | Penanda POI; lihat tabel penanda di bagian 8. |
| `Markers/SignalBeacon` | wajib | Penanda POI; lihat tabel penanda di bagian 8. |
| `Markers/NightSpawns` | disarankan | Wadah titik spawn malam (minimal angka di world_config). |
| `Markers/WaterAccess` | disarankan | Wadah titik minum/isi kantung air. |
| `Resources` | wajib | ResourceArea dan/atau node resource manual. |
| `Decor` | wajib | Dekorasi bebas tanpa logika. |
<!-- END GENERATED -->

## Alur kerja 12 langkah

Nama file nyata dipakai di bawah. `<nama>` = nama dunia Anda, mis. `pulau_utama`.

1. **Duplikat template.** Di FileSystem, klik kanan
   `res://src/levels/worlds/_template/` → Duplicate → ganti nama foldernya jadi
   `res://src/levels/worlds/<nama>/`. Buka `world.tscn` di dalamnya.
2. **Ganti nama dunia.** Pilih node akar `World`, isi **World Name** = `<nama>`
   dan **Layout Seed** (angka bebas; seed sama = sebaran resource sama).
3. **Gambar outline pulau.** Pilih `Zones/IslandOutline` (ZoneArea), pastikan
   **Is Island Outline** = `true`, lalu gambar polygon dengan tool polygon di
   viewport 2D. Bentuk bebas, minimal 3 titik, tidak boleh memotong diri sendiri.
4. **Gambar area zona.** Duplikat `IslandOutline`, ganti nama (mis. `Camp`),
   matikan **Is Island Outline**, pilih **Zone** dan **Priority** (lihat bagian
   7). Area yang digambar belakangan menimpa area sebelumnya.
5. **Tandai area yang tidak bisa dilewati.** Untuk danau/batu: **Walkable** =
   `false` dan **Build Rule** = `FORBID`. Ini satu-satunya cara membuat
   penghalang solid.
6. **Taruh penanda.** Di `Markers`, buat `Marker2D` dengan nama persis
   `PlayerStart`, `PlaneWreckage`, `EmergencySuitcase`, `SignalBeacon`. Semua
   wajib dan harus di tanah yang bisa dilewati.
7. **Tentukan jalur air.** Buat `Node2D` bernama `WaterAccess`, isi `Marker2D`
   `WaterAccess1`, `WaterAccess2`, ... di tepi sungai/danau. Alternatif: satu
   area `Zone = RIVER` sudah cukup.
8. **Isi resource.** Di `Resources`, buat `Node2D` bernama `ResourceArea`,
   tambahkan `ResourceSpawnEntry` (definition + count + min spacing) lewat
   Inspector, gambar polygon areanya. Atau taruh node resource manual di
   `Resources` (scene ResourceNode) — keduanya boleh dicampur lewat
   **Resource Mode**.
9. **Pasang visual.** Di `Visual`, tambahkan `TileMapLayer` dengan tileset
   `assets/world/tilesets/`. Urutan z: tanah di belakang, properti di atas,
   `Decor` paling atas. Tile tidak membawa logika.
10. **Klik Validasi dunia.** Pilih node akar `World`, klik tombol **Validasi
    dunia** di Inspector. Laporan lengkap muncul di panel Output; ringkasan
    satu baris tersimpan di **Last Validation Summary**.
11. **Perbaiki sampai tanpa ERROR.** WARN boleh sementara (tercatat), ERROR
    wajib nol. Lihat tabel kode di bagian 12.
12. **Ubah mode dan main.** Set `mode = AUTHORED` + `authored_scene_path` di
    `world_config.tres`, jalankan `island.tscn`, lalu mainkan 3 menit: jalan ke
    suar, ambil resource, tidur sampai malam.

## Tabel ZoneArea

Semua field di bawah bisa diubah di Inspector saat sebuah `ZoneArea` dipilih.

<!-- BEGIN GENERATED -->
| Field | Arti | Nilai awal | Contoh |
| --- | --- | --- | --- |
| `polygon` | Titik-titik polygon di ruang induk (Zones). | 0 titik | 4 titik untuk pulau kotak, 24-48 untuk bentuk halus |
| `zone` | Zona yang dipaksakan ke sel di dalam polygon. | `FOREST` (Hutan) | Camp, Pantai Selatan, Hutan, ... |
| `priority` | Urutan menimpa: angka besar menang. | 0 | Outline -100, hutan -50, camp 10, sungai 20 |
| `walkable` | False = penghalang solid. | true | Danau dan formasi batu: false |
| `build_rule` | DEFAULT ikut zona; ALLOW boleh dibangun; FORBID tidak boleh. | DEFAULT | Sungai: FORBID |
| `is_island_outline` | Tandai tepat satu area sebagai outline pulau. | false | Hanya IslandOutline: true |
<!-- END GENERATED -->

Catatan penting: **polygon terakhir yang menimpa** (priority lebih besar)
menentukan zona sel. `Priority` yang sama pada dua zona berbeda yang saling
menimpa memicu peringatan W013 — biasanya tanda area yang lupa diatur.

## Jenis zona

Kejujuran dulu: dari semua zona, hanya **RIVER** (jalan lambat / wading),
**OUTSIDE** (laut, tidak bisa dilewati), dan **aturan build** yang benar-benar
mengubah gameplay. Sisanya adalah label + warna untuk editor, overlay, dan UI.

<!-- BEGIN GENERATED -->
| Zona | Efek gameplay sebenarnya | Bisa dibangun (default) | Warna editor |
| --- | --- | --- | --- |
| `CAMP` (Camp) | Bisa dibangun (aturan build). Selain itu hanya label + warna. | ya | `#596640` |
| `SOUTH_BEACH` (Pantai Selatan) | Hanya label + warna. Tidak mengubah kecepatan, spawn, atau resource. | ya | `#c7b880` |
| `EAST_BEACH` (Pantai Timur) | Hanya label + warna. | ya | `#c2b37a` |
| `WEST_CLIFFS` (Tebing Barat) | Hanya label + warna. | ya | `#666673` |
| `RIVER` (Sungai) | Dilewati dengan lambat (wading) dan tidak bisa dibangun. Satu-satunya zona dengan efek gerak. | tidak | `#407399` |
| `FOREST` (Hutan) | Hanya label + warna; tempat fauna dan resource hutan. | ya | `#385233` |
| `OUTSIDE` (Luar Pulau) | Laut: tidak walkable dan tidak bisa dibangun (pemain tidak bisa keluar pulau). | tidak | `#808080` |
<!-- END GENERATED -->

## Tabel penanda

Semua penanda adalah `Marker2D` dengan nama persis di bawah, di dalam `Markers`.
Penanda yang salah nama dianggap tidak ada (validator memberi W003).

<!-- BEGIN GENERATED -->
| Penanda | Wajib? | Aturan | Dipakai oleh |
| --- | --- | --- | --- |
| `PlayerStart` | wajib | Titik spawn pemain. Harus walkable dan di dalam outline. | WorldController, validasi jarak spawn malam |
| `PlaneWreckage` | wajib | Bangkai pesawat; harus terjangkau dari PlayerStart. | WorldController, HUD kompas |
| `EmergencySuitcase` | wajib | Koper awal; harus terjangkau dari PlayerStart. | WorldController, loot awal |
| `SignalBeacon` | wajib | Suar penyelamat; harus terjangkau, juga setelah erosi koridor (W012). | WorldController, urutan rescue |
| `NightSpawns` | opsional* | Wadah Marker2D titik spawn malam; minimal min_spawn_points, jarak >= min_spawn_distance dari PlayerStart. | WorldController._spawn_night_markers |
| `WaterAccess` | opsional* | Titik minum/isi kantung air; minimal satu, atau harus ada area RIVER. | WorldController, RiverDrinkZone |

* Sangat disarankan: tanpa spawn malam atau titik air, validator memberi W005/W010.
<!-- END GENERATED -->

## ResourceArea dan isinya

Dua cara mengisi resource, boleh dicampur:

| Cara | Di mana | Kelebihan | Kekurangan |
| --- | --- | --- | --- |
| Area otomatis | `Resources/ResourceArea` + `ResourceSpawnEntry` | Cepat untuk pulau besar; jumlah diatur angka | Posisi tepat tidak bisa diatur |
| Node manual | Scene resource di `Resources/` | Posisi bisa diatur persis | Repot untuk banyak node |

Field `ResourceArea`:

| Field | Arti | Contoh |
| --- | --- | --- |
| `definition` di entry | Jenis resource (lihat tabel di bawah) | `tree` |
| `count` di entry | Berapa node dicoba ditempatkan | 30 |
| `min_spacing` | Jarak minimum antar node di area ini | 70 |
| `enabled` | Matikan area tanpa menghapus | true |

Aturan jumlah: node hanya diletakkan di dalam polygon area, di tanah walkable,
tidak menimpa POI (radius bebas dari `island_layout.tres`), dan tidak lebih rapat
dari `min_spacing`. Kalau tidak muat, validator memberi W015 dan sisanya hilang.

Mode resource (`Resource Mode` di node akar):

| Nilai | Arti |
| --- | --- |
| `AREAS_AND_MANUAL` | Pakai area otomatis DAN node manual (default). |
| `AREAS_ONLY` | Hanya area otomatis; node manual diabaikan. |
| `MANUAL_ONLY` | Hanya node manual; area otomatis diabaikan. |

Jenis node resource (dibuat dari `res://src/data/gathering/*.tres`):

<!-- BEGIN GENERATED -->
| ID node | Nama | Hasil | Alat | Waktu panen | Muncul kembali |
| --- | --- | --- | --- | --- | --- |
| `bamboo_clump` | Rumpun Bambu | Bambu | Tangan | 1.5 s | Harian |
| `berry_bush` | Semak Beri | Beri | Tangan | 0.8 s | Harian |
| `big_rock` | Batu Besar | Batu | Pickaxe | 3.0 s | Harian |
| `coconut_palm` | Pohon Kelapa | Kelapa | Tangan | 1.2 s | 2 hari |
| `fiber_bush` | Semak Serat | Serat | Tangan | 1.0 s | Harian |
| `small_rock` | Batu Kecil | Batu | Tangan | 1.5 s | Harian |
| `small_tree` | Pohon Kecil | Kayu | Tangan | 4.0 s | Harian |
| `tree` | Pohon | Kayu | Kapak | 2.5 s | Harian |
| `twig` | Ranting | Kayu | Tangan | 1.0 s | Harian |
<!-- END GENERATED -->

## Visual dan tileset

- Taruh `TileMapLayer` di dalam node `Visual`. Boleh lebih dari satu (tanah,
  jalan, air) selama semuanya anak `Visual`.
- Ukuran tile yang disarankan **32 x 32 px**, sama dengan `cell_size` di
  `world_config.tres` (memudahkan mencocokkan tampilan dengan grid validasi).
- Urutan gambar (z): tanah paling belakang, lalu detail tanah, lalu properti
  besar (pohon, batu), lalu `Decor` paling atas. Semua anak `Visual` berada di
  bawah pemain.
- Simpan tileset di `assets/world/tilesets/` (bukan `res://src/`).
- Tile **tidak membawa logika**: tidak ada kolisi, damage, atau spawn dari tile.
  Penghalang dibuat oleh `ZoneArea` dengan `walkable = false`.
- `Decor` untuk dekorasi bebas (rumput, puing, batu hias) yang tidak boleh
  menghalangi. Jangan menaruh skrip gameplay di `Visual` atau `Decor`.
- Kalau art belum ada, dunia tetap bisa dimainkan; validator tidak peduli visual.

## Aturan desain: hewan tidak punya pathfinding

Hewan dan spawn malam bergerak lurus menuju target, tanpa mencari jalan. Karena
itu bentuk pulau harus "murah dilewati":

1. **Lebar koridor minimal 96 px** (sekitar 3 tile 32 px). Koridor lebih sempit
   dari ini memicu W012.
2. **Hindari jalan buntu sempit**: hewan akan menabrak dinding dan berhenti.
3. **Hindari pulau kecil terpisah** yang hanya bisa dicapai lewat celah tipis.
4. **Rintangan lebar dan sederhana** (danau bulat, batu besar). Rintangan
   bergerigi membuat hewan tersangkut.
5. **Jarak titik spawn malam >= 1100 px** dari start pemain, dan minimal 8 titik.
6. Sisakan hutan yang bisa dilewati seluas minimal 1000000 px persegi (sekitar
   1000 x 1000 px) supaya fauna punya ruang.

Angka rekomendasi (dibuat dari `world_config.tres`):

<!-- BEGIN GENERATED -->
| Aturan | Angka | Sumber |
| --- | --- | --- |
| Lebar koridor minimum | 96 px | `world_config.min_corridor_width` |
| Jarak spawn malam dari start | >= 1100 px | `world_config.min_spawn_distance` |
| Jumlah spawn malam minimum | 8 titik | `world_config.min_spawn_points` |
| Luas hutan terjangkau minimum | 1000000 px persegi | `world_config.min_forest_area` |
| Batas vertex polygon | 2000 titik | `world_config.polygon_vertex_limit` |
| Ukuran sel validasi | 32 px | `world_config.cell_size` |
| Radius bersih base | ring pagar + 50 px | `world_config.base_clearance_extra` |
| Jarak minimum antar resource | 70 px | `island_layout.min_spacing` |
| Radius bebas sekitar POI | 140 px | `island_layout.keep_out_radius` |
<!-- END GENERATED -->

## Validasi: tiga cara

1. **Tombol di editor.** Pilih node akar `World` → Inspector → tombol
   **Validasi dunia**. Laporan lengkap masuk ke panel Output. Node juga
   menampilkan peringatan konfigurasi untuk ERROR struktural (tanpa flood fill).
2. **Perintah terminal.**
   ```
   GODOT --headless --path . -s tools/validate_world.gd -- res://src/levels/worlds/<nama>/world.tscn
   ```
   Tanpa argumen, perintah memvalidasi `authored_scene_path` di
   `world_config.tres`. Exit code 0 = tanpa ERROR, 1 = ada ERROR.
3. **Overlay di game.** Jalankan `island.tscn`, tekan **O**. Warna zona tampil per
   sel, sel terlarang gelap, sel yang tidak terjangkau dari start berwarna merah,
   POI/spawn/air ditandai. Panel kiri atas menampilkan nama dunia, mode, jumlah
   ERROR/WARN, dan 8 pesan pertama. Tekan **O** lagi untuk mematikan. Overlay
   juga jalan di mode FORMULA (tanpa cek reachability).

Cara membaca laporan:

- Satu baris per temuan: `[ERROR] W00X: pesan (posisi)`.
- Perbaiki ERROR dulu, WARN kemudian.
- Posisi memakai koordinat dunia; klik kanan di viewport 2D untuk melihat
  koordinat kursor, atau pakai overlay untuk menemukan selnya.

Semua kode (dibuat dari `WorldValidator.CODES`):

<!-- BEGIN GENERATED -->
| Kode | Severity | Arti | Cara memperbaiki |
| --- | --- | --- | --- |
| `W001` | ERROR | Outline pulau hilang, kurang dari 3 titik, atau memotong dirinya sendiri. | Perbaiki polygon ZoneArea outline. |
| `W002` | ERROR | Ada lebih dari satu ZoneArea outline. | Sisakan tepat satu area dengan is_island_outline. |
| `W003` | ERROR | Marker wajib belum ada. | Tambahkan marker di Markers. |
| `W004` | ERROR | Marker wajib di luar pulau atau tidak walkable. | Pindahkan marker ke tanah yang bisa dilewati. |
| `W005` | ERROR | Jumlah night spawn kurang dari minimum. | Tambah Marker2D di NightSpawns. |
| `W006` | ERROR | Night spawn berada di sel yang tidak walkable. | Pindahkan night spawn ke tanah walkable. |
| `W007` | WARN | Night spawn terlalu dekat dengan PlayerStart. | Jauhkan night spawn dari titik spawn pemain. |
| `W008` | ERROR | Titik/area tidak terjangkau dari PlayerStart. | Buka koridor atau pindahkan titiknya. |
| `W009` | ERROR | Tidak ada tanah datar yang bisa dibangun di dekat PlayerStart. | Longgarkan area walkable+buildable di sekitar start. |
| `W010` | ERROR | Sumber resource wajib (atau akses air) tidak ada. | Tambah entry ResourceArea / marker WaterAccess. |
| `W011` | WARN | Jumlah resource terjangkau jauh di bawah angka FORMULA. | Tambah area atau jumlah entry. |
| `W012` | WARN | Koridor terlalu sempit setelah erosi: hewan tidak bisa lewat. | Lebarkan koridor minimal min_corridor_width. |
| `W013` | WARN | ZoneArea berbeda zona saling menimpa dengan prioritas sama. | Ubah priority salah satu area. |
| `W014` | WARN | Polygon melebihi batas jumlah vertex. | Sederhanakan polygon. |
| `W015` | WARN | ResourceArea tidak bisa menempatkan semua node. | Perbesar area atau kecilkan count. |
| `W016` | WARN | Area FOREST terjangkau terlalu kecil untuk fauna. | Perluas hutan yang bisa dilewati. |
| `W017` | WARN | Resource manual berada di area terlarang atau di luar pulau. | Pindahkan node resource manual. |
<!-- END GENERATED -->

## Daftar periksa serah terima

### Ke programmer

- [ ] `world.tscn` ada di `res://src/levels/worlds/<nama>/` dan bisa dibuka tanpa
      error di Output.
- [ ] `world_config.tres`: `mode = AUTHORED`, `authored_scene_path` menunjuk scene
      itu, `fallback_to_formula = true`.
- [ ] Validasi dunia: **0 ERROR**. WARN yang tersisa sudah dijelaskan.
- [ ] `tools/validate_world.gd` mengembalikan exit code 0 untuk scene itu.
- [ ] Nama file dan node tidak memakai spasi; hanya huruf, angka, underscore.
- [ ] Tileset disimpan di `assets/world/tilesets/` dan sudah di-import.
- [ ] Seed layout dicatat (supaya sebaran resource bisa diulang).

### Ke tim uji

- [ ] Spawn di `PlayerStart`, tidak terjebak di dalam batu atau air.
- [ ] Jalan dari start ke bangkai, koper, dan suar tanpa terhalang.
- [ ] Danau/batu tidak bisa ditembus; sungai bisa dilewati (lebih lambat).
- [ ] Ketemu minimal satu sumber kayu, batu, fiber, beri, bambu, dan air.
- [ ] Camp bisa dibangun (ring pagar hijau) di dekat start.
- [ ] Malam: hewan muncul, tidak tersangkut di dinding danau/batu.
- [ ] Overlay **O**: tidak ada wilayah besar berwarna merah.
- [ ] Main 10 menit tanpa pesan error di Output.

## Masalah umum

| Gejala | Penyebab biasanya | Cara memperbaiki |
| --- | --- | --- |
| Pemain macet di tempat | Start berada di sel tidak walkable, atau Polygon zone menutup start | Pindahkan `PlayerStart`; cek W004. Overlay O: sel start tidak boleh gelap/merah |
| Hewan tersangkut di tepi danau | Koridor sempit atau rintangan bergerigi | Lebarkan koridor (W012), sederhanakan polygon penghalang |
| Node resource tidak muncul | Area terlalu kecil, `min_spacing` terlalu besar, atau definition kosong | Perbesar polygon, kecilkan `min_spacing`/`count`; cek W015 |
| Camp tidak bisa dibangun | Tidak ada tanah walkable + buildable radius cukup dekat start | Longgarkan `Camp` (build_rule DEFAULT), cek W009 dan W013 |
| Beacon tidak terjangkau | Penghalang memotong pulau | Buka koridor; cek W008; overlay O untuk melihat sel merah |
| Dunia tidak mau dimuat, kembali ke pulau FORMULA | Path salah, scene rusak, atau mode masih FORMULA | Lihat Output: "gagal memuat scene"; cek `authored_scene_path`; cek W001 |
| Validator bilang outline hilang | `IslandOutline` tidak ada atau kurang dari 3 titik | Tandai tepat satu ZoneArea sebagai outline; cek W001/W002 |
| Semua sel merah di overlay | Start tidak walkable sehingga flood fill kosong | Perbaiki start dulu (W004) |
| Pesan error panjang di Output | Laporan validator, bukan crash | Baca dari atas: `[ERROR]` lebih penting daripada `[WARN]` |

Cara membaca Output: baris pertama laporan adalah ringkasan
(`Validasi dunia: X ERROR, Y WARN`). Setelah itu satu baris per temuan. Klik
baris `res://...` untuk membuka file terkait.

## Glosarium

| Istilah | Arti |
| --- | --- |
| AUTHORED | Mode dunia yang memakai scene buatan (`world.tscn`). |
| FORMULA | Mode dunia lama: pulau persegi yang dibangun kode. |
| ZoneArea | Polygon yang menentukan zona, walkable, dan aturan build. |
| Outline | ZoneArea khusus yang menjadi batas pulau (tepat satu). |
| ZoneGrid | Grid sel yang dipakai validator dan overlay. |
| Walkable | Bisa dilewati pemain dan hewan. |
| Buildable | Boleh didirikan base/struktur. |
| POI | Point of interest: start, bangkai, koper, suar. |
| NightSpawn | Titik kemunculan hewan malam. |
| WaterAccess | Titik minum / isi ulang kantung air. |
| ResourceArea | Polygon yang diisi node resource otomatis. |
| ResourceNode | Satu pohon/batu/semak yang bisa dipanen. |
| Flood fill | Cara validator menandai sel yang bisa dicapai dari start. |
| Erosi | Mengecilkan area walkable untuk menguji koridor sempit. |
| Validator | Pemeriksa otomatis yang menghasilkan kode W001-W017. |
| Sheet / atlas | Satu gambar berisi banyak tile. |

## Lampiran teknis (untuk programmer)

### API WorldSource

Semua gameplay bertanya lewat `WorldRules`, yang meneruskan ke `WorldSource`
aktif (`FormulaWorld` atau `AuthoredWorldSource`). Jangan memanggil
`IslandZones` langsung dari kode baru.

| Method `WorldSource` | Arti |
| --- | --- |
| `id()` | `formula` atau `authored`; dipakai log dan tes. |
| `zone_at(pos)` | Zona di titik itu (`WorldZoneType.Zone`). |
| `is_walkable(pos)` | Bisa dilewati? |
| `is_buildable(pos)` | Boleh dibangun? |
| `bounds()` | Kotak batas dunia (untuk kamera/clamp). |
| `distance_to_coast(pos)` | Jarak ke tepi pulau (px). |
| `distance_to_zone(pos, zone)` | Jarak ke zona terdekat. |
| `poi(name)` | Posisi POI, `Vector2.INF` bila tidak ada. |
| `night_spawn_points()` | Daftar titik spawn malam. |
| `water_access_points()` | Daftar titik air. |
| `zone_center(zone)` | Titik acuan zona. |
| `has_resource_plan()` | Dunia punya rencana resource otomatis? |
| `resource_plan(layout, seed)` | Daftar node resource yang akan/ sudah ada. |

Helper `WorldRules`: `get_source`, `set_source`, `reset`, `id`, `zone_at`,
`is_walkable`, `is_buildable`, `bounds`, `distance_to_coast`,
`distance_to_zone`, `poi`, `night_spawn_points`, `water_access_points`,
`zone_center`, `has_resource_plan`, `resource_plan`.

### Berkas kunci

| Berkas | Isi |
| --- | --- |
| `res://src/levels/world/world_source.gd` | Kontrak sumber dunia. |
| `res://src/levels/world/formula_world.gd` | Dunia FORMULA (pulau lama). |
| `res://src/levels/world/authored_world.gd` | Kontrak scene AUTHORED + tombol validasi. |
| `res://src/levels/world/authored_world_source.gd` | Sumber AUTHORED (grid, polygon, plan). |
| `res://src/levels/world/zone_grid.gd` | Rasterisasi polygon ke grid sel. |
| `res://src/levels/world/world_rules.gd` | Fasad yang dipakai gameplay. |
| `res://src/levels/world/world_controller.gd` | Memuat sumber, spawn POI/air/malam. |
| `res://src/levels/world/world_validator.gd` | Validator W001-W017 + flood fill. |
| `res://src/levels/world/world_debug_overlay.gd` | Overlay debug (tombol O). |
| `res://tools/validate_world.gd` | CLI validator (exit code 0/1). |

### Konstanta yang masih hard-coded (kandidat pindah ke resource)

Tabel ini hasil pemindaian ulang kode; belum dipindah karena mengubahnya akan
mengubah perilaku pulau FORMULA yang sudah diuji golden.

| Lokasi | Nilai | Catatan |
| --- | --- | --- |
| `res://src/levels/island/island_zones.gd:18` | `BEACON_POSITION = (0, 2100)` | Suar FORMULA. |
| `res://src/levels/island/island_zones.gd:69-77` | pusat zona `(0,1900)`, `(1900,0)`, `(-1900,0)`, `(-950,0)`, `(700,-1000)` | Pusat zona FORMULA. |
| `res://src/utils/base_site_rules.gd:34-36` | `(0,64)`, `(0,-185)`, `(-48,40)` | Start, wreckage, koper FORMULA. |
| `res://src/levels/island/island_builder.gd:160,190,192` | posisi marker/lingkaran resource | Jitter bentuk marker FORMULA. |
| `res://src/core/managers/camp_anchor.gd:10` | `DEFAULT_RESPAWN_OFFSET = (0, 64)` | Offset respawn camp. |
| `res://src/core/managers/death_controller.gd:24` | `RESPAWN_POSITION = (0, 64)` | Respawn cadangan di luar camp. |
| `res://src/components/camera/camera_feel.gd:17` | `DEFAULT_HALF_SIZE = 2400` | Batas kamera cadangan bila builder tidak ada. |
| `res://src/levels/island/island.tscn:151,161,164,212` | posisi `(0,-185)`, `(-48,40)`, `(0,2100)`, `(0,64)` | Node scene island FORMULA. |

### Tes yang menjaga lapisan dunia

| Tes | Isi |
| --- | --- |
| `test_world_golden` | Angka FORMULA tidak berubah setelah refactor. |
| `test_world_rules` | Fasad WorldRules dan fallback AUTHORED. |
| `test_world_zone_grid` | Rasterisasi polygon ke grid. |
| `test_authored_world` | Kontrak scene AUTHORED. |
| `test_world_controller_authored` | Boot AUTHORED, fallback, POI. |
| `test_world_validator` | 25 tes: W001-W017, flood fill, CLI, overlay. |
| `test_world_guide_sync` | Dokumen ini sama dengan generator. |

### Angka global (`world_config.tres`)

<!-- BEGIN GENERATED -->
| Field | Arti | Dampak | Nilai sekarang |
| --- | --- | --- | --- |
| `mode` | Mode dunia: FORMULA = pulau rumus lama, AUTHORED = scene dunia buatan. | Menentukan seluruh isi pulau setelah boot. | FORMULA |
| `authored_scene_path` | Path scene dunia AUTHORED yang dimuat. | Hanya dipakai saat mode = AUTHORED. | res://src/levels/worlds/sample_island/world.tscn |
| `fallback_to_formula` | Kalau scene AUTHORED gagal dimuat, pakai pulau FORMULA. | True = game tetap jalan (dengan peringatan di Output); False = boot gagal. | true |
| `cell_size` | Ukuran sel grid untuk validasi reachability dan overlay. | Lebih kecil = lebih teliti tapi lebih lambat. | 32 |
| `min_spawn_points` | Jumlah minimum titik spawn malam. | Di bawah angka ini validator memberi W005 (ERROR). | 8 |
| `min_spawn_distance` | Jarak minimum titik spawn malam dari PlayerStart. | Lebih dekat dari ini = W007 (WARN). | 1100 |
| `min_corridor_width` | Lebar koridor minimum yang masih dianggap bisa dilewati. | Menentukan erosi grid untuk W012 (hewan tidak punya pathfinding). | 96 |
| `base_clearance_extra` | Tambahan radius bersih base di luar ring pagar. | Dipakai W009 untuk mencari tanah datar dekat start. | 50 |
| `reachability_required_ratio` | Rasio sel walkable yang harus terjangkau dari start. | Belum dipakai validator (disimpan untuk tuning); reachability saat ini dicek per titik/area lewat W008. | 0.98 |
| `warn_node_ratio` | Batas bawah jumlah resource dibanding pulau FORMULA. | Di bawah rasio ini = W011 (WARN). | 0.50 |
| `polygon_vertex_limit` | Jumlah vertex maksimum satu polygon. | Lebih dari ini = W014 (WARN). | 2000 |
| `min_forest_area` | Luas minimum hutan terjangkau (px persegi). | Lebih kecil = W016 (WARN): hewan dan spawn malam tidak punya ruang. | 1000000 |
| `overlay_cell_px` | Ukuran sel overlay debug di layar. | Hanya memengaruhi tampilan overlay (tombol O), bukan gameplay. | 64 |
<!-- END GENERATED -->


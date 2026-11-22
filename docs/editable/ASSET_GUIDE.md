# Panduan Aset

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


<!-- BEGIN GENERATED -->
- `player`, `wild_boar`, `island_deer`, `twig`, `small_tree`, `tree`, `small_rock`, `big_rock`, `fiber_bush`, `berry_bush`, `coconut_palm`, `bamboo_clump`, `campfire`, `workbench`, `chest`, `tent`, `ground_camp`, `ground_south_beach`, `ground_east_beach`, `ground_west_cliffs`, `ground_river`, `ground_forest`, `plane_wreckage`, `emergency_suitcase`, `signal_beacon`, `ui_panel`

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
| `ui_font_bold` | `res://assets/ui/fonts/bold[_dir][_Nf].png`<br>contoh: `res://assets/ui/fonts/bold.png` | Penting | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_font_main` | `res://assets/ui/fonts/main[_dir][_Nf].png`<br>contoh: `res://assets/ui/fonts/main.png` | Penting | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_icon_fatigue` | `res://assets/ui/icons/fatigue[_dir][_Nf].png`<br>contoh: `res://assets/ui/icons/fatigue.png` | Penting | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_icon_hp` | `res://assets/ui/icons/hp[_dir][_Nf].png`<br>contoh: `res://assets/ui/icons/hp.png` | Penting | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_icon_hunger` | `res://assets/ui/icons/hunger[_dir][_Nf].png`<br>contoh: `res://assets/ui/icons/hunger.png` | Penting | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_icon_thirst` | `res://assets/ui/icons/thirst[_dir][_Nf].png`<br>contoh: `res://assets/ui/icons/thirst.png` | Penting | 16 × 16 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_logo` | `res://assets/ui/logo[_dir][_Nf].png`<br>contoh: `res://assets/ui/logo.png` | Penting | 480 × 160 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_panel` | `res://assets/ui/panel[_dir][_Nf].png`<br>contoh: `res://assets/ui/panel.png` | Wajib | 256 × 128 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_slot_frame` | `res://assets/ui/slot_frame[_dir][_Nf].png`<br>contoh: `res://assets/ui/slot_frame.png` | Penting | 48 × 48 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |
| `ui_vignette_low_hp` | `res://assets/ui/vignette_low_hp[_dir][_Nf].png`<br>contoh: `res://assets/ui/vignette_low_hp.png` | Opsional | 1280 × 720 | — | CENTER | satu arah | default | src/ui/ui_skin.gd (UiSkin) | state → arah → mirror → idle → default → placeholder |

<!-- END GENERATED -->

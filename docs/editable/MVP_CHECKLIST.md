# Checklist MVP — Gimersia 2026

Dokumen ini adalah checklist kerja yang bisa dicentang. Sumber scope:

- [`docs/noneditable/MVP_dan_Daftar_Pekerjaan_RTRw_Studio.docx.md`](../noneditable/MVP_dan_Daftar_Pekerjaan_RTRw_Studio.docx.md)
- [`docs/noneditable/spesifikasi_teknis_mekanisme_gameplay_V8.md`](../noneditable/spesifikasi_teknis_mekanisme_gameplay_V8.md)
- [`docs/editable/architecture.md`](architecture.md)
- [`docs/editable/PANDUAN_MODUL.md`](PANDUAN_MODUL.md)

## Legenda

- `[x]` — implementasi kode sudah ada dan sudah ditinjau secara statis.
- `[ ]` — belum ada, belum lengkap, atau belum diverifikasi end-to-end.
- `[x]` **bukan** berarti sudah lulus playtest atau build final. Godot 4.7.2 dan GUT 9.7.1 tersedia; unit test lulus dan `practice1.tscn` smoke test headless bersih, tetapi playtest dan build final belum diverifikasi.

> **Status saat ini:** loop survival inti dapat dimainkan dari awal sampai akhir — bukti
> `test_island_survival.gd`, `test_island_night.gd`, `test_island_death.gd`,
> `test_island_endgame.gd`, `test_island_soak.gd`. Yang belum: build/export, audio,
> art final (0/63 slot), dan playtest manual owner.

---

## 0. Ringkasan Kesiapan

| Area | Status | Catatan |
|---|---|---|
| Fondasi project & struktur | Sebagian besar ada | Godot 4.7.2, folder, scene practice, autoload |
| Kontrol & movement | Ada | Top-down, sprint, collision dasar |
| Stats & proficiency | Ada | Komponen + tes tertulis; XP/level-up/passive/debuff ada di `ProficiencyComponent` |
| Siklus waktu | Ada | Manager, config, HUD, visual; config default 600 dtk |
| Survival needs | Ada | Komponen + HUD + 27 tes (termasuk plafon Fatigue, regen diam); konsumsi item lewat `use_slot()` sudah ada (efek instan). Rest Campfire dan tidur Tenda sudah ada |
| Inventory & gathering | Ada | Inventory 12 slot + hotbar 1-5, definisi item, pickup, efek makan/minum, bag UI (Tab/I, drag-drop, klik kanan, tooltip), hold-E interaction, dan 9 resource node + respawn/tool gate; panel Peti 24 slot dua arah; crafting Workbench/Campfire dan drop saat mati (`LootBag`) sudah ada |
| Peta pulau | Minimum | `src/levels/island/island.tscn`: zona sesuai spec §7.7, 139 node resource, 16 marker night spawn (dibaca `NightSpawner`), wreckage, koper darurat, `SignalBeacon` fungsional, 9 river edge, `DeathScreen`/`GameOverScreen`/`EndgameHUD`. Art produksi dan level loader belum |
| Crafting & camp | Ada | 13 resep + `CraftingComponent`, tab Crafting di `BagPanel`, 4 definisi struktur, `CampStructure`/`BlueprintSlot`/`Campfire`/`Workbench`/`Chest`/`Tent`, repair hold-R, Night Watch, dan `CampController` (terpasang di `island.tscn`) dan panel Peti ada dan teruji |
| Combat & enemy | Ada | Auto-attack + manual klik/Space 90°, dodge (tanpa i-frame), knockback, bleed, teks damage; Boar (gigit, dash, camp aggro) + Rusa; 33 tes combat + 27 tes fauna |
| Night survival loop | Sebagian | Spawner malam + tabel scaling 1-7, Dazzled, Ember Snuff, kuota fajar; timer gagal/survival masih label HUD |
| Death & respawn | Ada | DeathController, LootBag di lokasi kematian, debuff proficiency, DeathScreen dengan Respawn & Menu Utama (8 tes) |
| Win condition | Ada | EndgameController, SignalBeacon, banner Hari 7, arrow ke beacon, layar Victory (7 tes); integrasi HUD ada |
| UI & audio final | Sebagian | HUD waktu, needs, stats, hotbar, interaksi, banner, recap debuff, pause/settings/help, peti ada; audio belum; visual belum dicek manual |
| Aset & visual | Fondasi ada | `Assets`/`VisualSlot`/`UiSkin` + registry 63 slot; coverage 0/63 (tim seni) |
| Build & playtest | Belum | Belum ada build/export yang diverifikasi |

---

## 1. Fondasi Teknis

- [x] Project Godot 4.7.2 dengan `project.godot` dan renderer GL Compatibility.
- [x] Struktur folder `src/core`, `src/components`, `src/data`, `src/entities`, `src/levels`, `src/ui`, `src/utils`, `tests`, `docs`.
- [x] Scene utama sementara: `scenes/practice/practice1.tscn`.
- [x] Autoload `DayNightManager` terdaftar di `project.godot`.
- [x] Input Map di `project.godot` `[input]` untuk `move_up/down/left/right`, `sprint`, `hotbar_1..5`, dan action `debug_*`; semua kode membaca action, bukan `_unhandled_input`/keycode mentah.
- [x] Player top-down dengan `CharacterBody2D`, collision, dan `move_and_slide()`.
- [x] Sprint dengan kecepatan dari `StatsComponent`.
- [x] `StatsComponent`, `StatModifier`, dan `PlayerBaseStats` sebagai fondasi stat.
- [x] `DayNightManager` dengan config, sinyal, getter, Night Watch, `skip_time`, dan final dawn.
- [x] `DayNightVisual` dengan `CanvasModulate`, transisi warna, dan partikel.
- [x] `TimeHUD` read-only untuk hari, fase, sisa waktu, progress, dan label Survival.
- [x] `SafeZone` practice sebagai contoh modifier dan zoom kamera.
- [x] Tes GUT ditulis dan dijalankan: **529 tes (522 unit + 7 integration), 3089 assert, 67 skrip tes**.
- [x] Sandbox manual stats: `tests/sandbox/stats_sandbox.tscn`.
- [x] GUT 9.7.1 terpasang di `addons/gut` dan tes benar-benar dijalankan.
- [x] Smoke test runtime `practice1.tscn` setelah semua perubahan clock.
  - Headless `--quit-after 120` selesai tanpa error (exit 0).
- [ ] Build/export Windows — belum dijalankan; ekspor butuh import aset milik owner (di luar scope misi ini).

---

## 2. Siklus Waktu dan Hari

- [x] `DayNightConfig` menyimpan `cycle_duration`, `max_days`, `time_scale`, dan daftar periode.
- [x] `DayNightPeriod` menyimpan rentang hari dan rasio siang.
- [x] Rasio periode: Hari 1–3 `0.5`, Hari 4–5 `0.4`, Hari 6–7 `0.3`.
- [x] Config default memakai 600 detik sesuai spesifikasi 1.D.
  - `cycle_duration` bawaan script = **600 detik**; `day_night_default.tres` tidak lagi menimpanya, jadi total live 4200 detik.
- [x] Mulai di Hari 1 pagi; `start()` mereset hari/fase.
- [x] `advance(delta)` dan `skip_time(seconds)` tersedia untuk pengujian dan tidur Tenda.
- [x] Carry-over satu fase dan multi-fase benar pada `advance()`/`skip_time()`.
- [x] `_process` juga mempertahankan overflow multi-fase.
  - `_process` memakai carry-over loop (`while`), sama seperti jalur `_advance_game_seconds()`.
- [x] `dusk_started(day)` muncul pada 15 detik terakhir siang, sekali per hari.
- [x] Dusk tetap muncul saat lompatan besar melewati batas siang.
- [x] Night Watch hanya aktif saat malam dan mengalikan waktu 2×.
- [x] Night Watch mati otomatis saat fajar/final dawn dan bisa dimatikan dari luar.
- [x] `skip_time(45)` menambah 45 detik game tanpa pengali Night Watch.
- [x] Final dawn membekukan clock, skala 0, hari tetap 7, `advance`/`skip_time` tidak berefek.
- [x] `rescue_started` tersedia sebagai penanda final dawn.
- [x] Integrasi waktu dengan Hunger/Thirst/fuel (drain fuel Campfire 0.25/s siang, 1.0/s malam x get_time_scale()).

---

## 3. Player dan Kontrol

- [x] Movement 8 arah dengan keyboard dan collision.
- [x] Kamera top-down mengikuti pemain (Phantom Camera).
- [x] Sprint (Shift) dengan speed dari stats.
- [x] `can_sprint` dapat dikunci modul luar.
- [x] `facing_direction` menyimpan arah hadap terakhir.
- [x] Animasi sprite/arah hadap — sistem `VisualSlot` (strip `_Nf`, 4 arah, mirror) teruji; art produksi 0/63 slot.
- Attack otomatis dan cooldown — status di §9.
- [x] Interaksi dengan resource/objek (E).
- Inventory dan item — status di §6.
  - `InventoryComponent` 12 slot (5 pertama hotbar), stacking 20, `use_slot()`, `add_or_drop()`, equipment WEAPON/TOOL/ARMOR; dibuktikan `tests/unit/test_inventory_component.gd`.
  - Bag UI (Tab/I) + drag-and-drop ada di `src/ui/panels/inventory/bag_panel.tscn` + `bag_slot.tscn` (action `inventory_toggle`), dibuktikan `tests/unit/test_bag_panel.gd`.
- [x] Respawn di camp.
- Debuff setelah respawn — status di §11.

---

## 4. Stats dan Progression

- [x] Base stats: HP, move speed, sprint, attack damage/speed, dodge, damage reduction.
- [x] Proficiency STR/SPD/MAS/AGI dengan clamp 1..10.
- [x] Modifier FLAT/PERCENT additive dengan `source_id`.
- [x] HP clamp saat `max_hp` berubah; `hp_changed`.
- [x] Dodge hard cap dan damage reduction cap.
- [x] Faktor craft/gather/sprint fatigue.
- [x] XP gain dari aktivitas (gather, craft, combat) — `ProficiencyComponent`.
- [x] Level-up otomatis dan batas XP (100 x level, overflow, lock di Lv 10).
- [x] Passive ability yang terhubung ke level (Heavy Strike, Sturdy, Second Wind, Quick Reflex, Swift Counter; Light Footed di `StatsComponent`).
- [x] Death debuff permanen dengan batas maksimal (2 proficiency).
- [x] Integrasi `max_respawn_tokens` dan `fatigue_sprint_threshold` ke gameplay. Catatan: `DeathController` memakai konstanta internal `RESPAWN_TOKENS = 3`; `PlayerBaseStats.max_respawn_tokens` belum dibaca (angkanya sama). Ambang sprint sudah di `NeedsComponent`.

---

## 5. Hunger, Thirst, dan Fatigue

- [x] Data hunger/thirst/fatigue dan nilai awal.
- [x] Laju pengurangan sesuai spesifikasi 3.A–3.C.
  - Bar, angka, dan warna peringatan ada di `src/ui/hud/needs/`, tetapi belum diverifikasi visual; ikon menyusul.
- [x] Efek status saat nilai rendah.
- [x] Sprint terkunci saat Fatigue <= 25.
- [x] Fatigue pulih saat diam (regen +1.0/s sampai plafon).
- [x] Sprint menurunkan plafon Fatigue (-0.4/s); jalan tidak menurunkan plafon.
- [x] API pemulihan plafon untuk makan (`restore_fatigue_capacity()`) dan tidur (`+25` pada `time_skipped`).
- [x] Rest di dekat Campfire menyala.
  - `Campfire` menyala dalam 120 px memanggil `NeedsComponent.set_idle_regen_override(&"campfire", 5.0)` tiap 0.25 s dan membersihkannya saat keluar radius / api padam; dibuktikan `tests/unit/test_campfire.gd` + `test_needs_rest_override.gd`.
- [x] Tidur di Tenda Daun: pulihkan Fatigue, `skip_time(45)`, cooldown, syarat sisa siang > 60 detik.
  - `Tent` + `TentConfig`: hold E 1.5 s, hanya siang, sisa siang > 60 dtk, cooldown 60 dtk game, `skip_time(45.0)` sekali; Needs menangani `time_skipped`. Dibuktikan `tests/unit/test_tent.gd`.
- [x] Konsumsi makanan/minuman memulihkan nilai.
  - Item `.tres` + `InventoryComponent.use_slot()`; field `fatigue` (Berry/Kelapa +10) diterapkan lewat `restore_fatigue_capacity()`, item lain 0 (tes lulus).
- [x] Integrasi `get_time_scale()` agar drain ikut 2× saat Night Watch dan 0 saat final dawn.
- [x] Clamp agar tidur tidak membunuh pemain (minimal 1.0).

---

## 6. Inventory dan Item

- [x] Definisi item/data item.
  - `ItemDefinition` + `ItemEffect` + `ItemStack` + `InventoryConfig` di `src/data/resources/items/`, 22 `.tres` di `src/data/items/`, diakses lewat `ItemCatalog`; setiap file divalidasi `tests/unit/test_item_definitions.gd`.
- [x] Inventory pemain dan kapasitas.
  - 12 slot, 5 slot pertama hotbar, stack maksimal 20 (Waterskin/Flare = 1); angka dari `inventory_config.tres`; dicek tes kapasitas dan stacking.
- [x] Equipment slot dasar (senjata, tool, armor).
  - Weapon/Armor menyimpan satu item; TOOL adalah kepemilikan Stone Axe + Stone Pickaxe; hanya Leather Vest yang mengubah stat (tes lulus).
- [x] Pickup resource ke inventory.
  - `ItemPickup` memasukkan item ke `InventoryComponent` saat disentuh body grup `player`, mengabaikan overlap selama `pickup_delay`, dan menyisakan yang tidak muat; dicek tes dan dipasang di `DemoPickups` `practice1.tscn`.
  - Resource node (hold E) juga ada: `ResourceNode` + `InteractorComponent` di `tests/unit/test_resource_node.gd`.
- [x] UI inventory sederhana.
  - Hotbar 5 slot (`HotbarHUD`) dan panel tas 12 slot + kolom equipment (Tab/I, drag-drop, klik kanan pakai, tooltip) ada; tab Crafting menampilkan 13 resep dengan bahan `punya/butuh` dan progres craft.
- [x] Item drop di lokasi kematian.
- [x] Pengambilan kembali item drop.
- [x] Item Suar Darurat.
- [x] Efek instan makanan/minuman (Hunger/Thirst/HP/plafon Fatigue).
  - Berry, Coconut, Raw/Cooked Meat, Bone Broth, Boiled Water, Herbal Bandage; efek Hunger/Thirst/HP/plafon Fatigue dicek tes.
- [x] Regen HP Bone Broth (+1 HP/s, 20 dtk) — `StatusEffectsComponent` (`test_status_effects.gd`: durasi, refresh, time scale 0/2, mati).
  - `regen_hp_per_second`/`regen_duration` baru disimpan di `ItemEffect`; belum ada sistem status effect yang menerapkannya.
- [x] Senjata/tools dasar — resep + `test_crafting_component.gd` (kapak, pickaxe, senjata).

---

## 7. Resource Gathering

- [x] Node resource yang bisa diinteraksi.
  - `Interactable` + `InteractorComponent` (hold E, range 64, progres real-time) dan 8 `ResourceNodeDefinition` (`twig`, `tree`, `small_rock`, `big_rock`, `fiber_bush`, `berry_bush`, `coconut_palm`, `bamboo_clump`). `tests/unit/test_interaction.gd`, `test_resource_node.gd`.
- [x] Waktu gathering + feedback progress bar.
  - Lama hold per resource (0.8–3.0 s) dikali `get_gather_time_factor()`, plus progress bar `InteractionHUD`.
- [ ] Animasi gathering per node — butuh art slot `full`/`depleted`; getar + pohon tumbang sudah ada (`chop_feedback.gd`).
  - Sprite/animasi belum ada (placeholder polygon).
- [x] Respawn resource.
  - `DAILY` (hari >= 2) dan `EVERY_OTHER_DAY` (hari ganjil >= 3) lewat `day_started(day)`; node `last_respawn_day` hilang permanen setelah hari itu. Tes stub clock di `test_resource_node.gd`.
- [x] Tool requirement (jika ada).
  - `tree` butuh `stone_axe`, `big_rock` butuh `stone_pickaxe`; alasan blokir "Butuh Kapak Batu" / "Butuh Beliung Batu".
- [x] Integrasi `get_gather_time_factor()`.
  - `ResourceNode.get_hold_time()` mengalikan `gather_time` dengan faktor dari `StatsComponent`; tes dengan modifier PERCENT +0.5.
- [x] Integrasi fatigue per aksi gathering.
  - `NeedsComponent.spend_fatigue(2.0)` sekali per panen; cap Fatigue tidak disentuh (tes).
- [x] Resource masuk inventory.
  - `InventoryComponent.add_or_drop()`; sisa yang tidak muat menjadi `ItemPickup` (tes overflow).

---

## 8. Crafting dan Camp

- [x] Resep hand-crafting MVP.
  - Wooden Spear 3 wood + 2 fiber (2.0 s), Torch 2 wood + 1 fiber (1.5 s), Herbal Bandage 3 fiber + 2 berry (1.5 s); `.tres` di `src/data/recipes/`, dicek `tests/unit/test_recipes.gd`.
- [x] Resep Workbench MVP.
  - Stone Axe, Stone Pickaxe, Stone Spear, Bone Spear, Leather Vest, Waterskin, Signal Flare; Stone/Bone Spear mengambil Wooden Spear dari slot WEAPON.
- [x] Resep Campfire MVP.
  - Cooked Meat, Boiled Water, Bone Broth; hanya bisa di Campfire yang menyala (dibuktikan `test_island_survival.gd` S2: masak lalu makan menaikkan hunger).
- [x] UI crafting.
  - Tab Crafting di `BagPanel`: 3 resep tangan aktif sesuai bahan, 10 resep terkunci redup dengan nama stasiun, teks bahan `punya/butuh` (merah bila kurang), tombol Craft, bar progres, status, dan Batalkan; dibuktikan `tests/unit/test_crafting_panel.gd` (8 tes). `CraftingComponent` dan `RepairComponent` terpasang di Player `island.tscn`, `CampController` ada di scene, F5 memberi kit bahan uji.
- [x] Workbench sebagai struktur camp.
  - `Workbench` (grup `crafting_station`, `station_type` WORKBENCH, selalu aktif) + `workbench.tres`; dibangun lewat `BlueprintSlot`, dibuktikan `tests/unit/test_blueprint_slot.gd`.
- [x] Campfire dengan fuel dan radius cahaya.
  - 240 s awal / 600 maksimum, drain 0.25/s siang dan 1.0/s malam x `get_time_scale()`, refuel 2 kayu -> +180 s (blokir di >= 580), cahaya 240 px / ember 80 px; dibuktikan `tests/unit/test_campfire.gd`.
- [x] Tenda Daun dengan interaksi tidur.
  - `tent.tscn` + `tent.tres` (120 HP, 6 kayu + 6 serat + 2 bambu) + `NightWatchController` untuk malam; dibuktikan `test_tent.gd` dan `test_night_watch_controller.gd`.
- [x] Peti camp.
  - Logika penyimpanan 24 slot (`ChestComponent`) + Peti yang menjatuhkan isinya saat hancur; dibuktikan `test_chest_component.gd` + `test_chest.gd`. Panel UI peti belum (stretch).
- [x] Tiang Suar di Pantai Selatan.
- [x] Daya tahan struktur camp (destructible).
  - `CampStructure.take_damage()/repair()/destroyed`, HP bar hanya saat rusak, dan hold-R `RepairComponent` (1 kayu + 1 batu -> +80 untuk Campfire, dst.); dibuktikan `test_camp_structure.gd` + `test_repair_component.gd`.
- [x] Light debuff `Dazzled` untuk musuh di radius campfire.
  - `FaunaBase` mengecek `Campfire.is_lit()` + `get_dazzle_radius()` tiap tick: speed x0.70, attack speed x0.75, dibuktikan `tests/unit/test_fauna_base.gd`.
- [x] Ember Snuff malam 5–7.
  - `Campfire.remove_fuel()` + reaksi `take_damage()` dari sumber grup `fauna` saat malam hari >= 5 (8 detik, `ember_snuff_config.tres`), dibuktikan `tests/unit/test_ember_snuff.gd`.

---

## 9. Combat dan Enemy

- [x] Auto-attack pemain.
  - `CombatComponent` hanya menyerang target HOSTILE/PROVOKED; manual tidak mengubah target netral selain memprovokasi; `tests/unit/test_combat_component.gd`.
- [x] Damage, knockback, dan feedback hit.
  - Damage lewat `calc_incoming_damage()`, knockback 60 px/0.2 s, teks melayang + flash; `test_player_damage_receiver.gd`, `test_player_knockback.gd`.
- [x] Dodge tanpa i-frame — **tidak termasuk spec V8 (sengaja)**; `PlayerDamageReceiver.dodged` + Quick Reflex teruji.
  - Dodge roll RNG pasif, damage 0 + "DODGE!"; **tanpa i-frame** (sesuai spec).
- [x] Satu jenis hewan liar MVP.
  - Wild Boar dan Island Deer; `test_wild_boar.gd`, `test_island_deer.gd`.
- [x] AI berkeliaran, mendeteksi, mengejar, menyerang.
  - WANDER/CHASE/BITE/DASH_TELEGRAPH/DASH/RECOVER/FLEE, deteksi 300 px malam, leash 380 px siang.
- [x] Spawn musuh siang/malam.
  - Kuota siang 2 Boar + 3 Deer; `NightSpawner` saat `night_started`; `test_fauna_quota.gd`, `test_night_spawner.gd`.
- [x] Scaling jumlah/stat malam berdasarkan hari.
  - `NightScalingConfig` tabel 1-7 (3..12 musuh, 45..15 s, x1.0..1.5); `test_night_scaling_config.gd`.
- [x] Target prioritas pemain vs struktur camp.
  - Pemain <=140 px, lalu struktur (raid_camp), lalu pemain terdeteksi; struktur diurut `get_aggro_priority()`.
- [x] Serangan ke Campfire/Workbench/Peti/Tenda.
  - Gigitan 12 dan dash 40 lewat `CampStructure.take_damage()`; `test_wild_boar.gd`.
- [x] Dash Charge Babi Hutan dan damage 2× ke struktur.
  - Telegraf 0.8 s, 330 px/s, 20 ke pemain + knockback, 40 ke struktur.
- [x] Bonus XP +50% untuk combat malam.
- [x] Anti-softlock spawn 2 Babi Hutan setelah fajar Hari 7.
  - `FaunaQuota` rescue: setidaknya 2 Boar NEUTRAL, respawn 45 detik nyata, maksimal 4 tambahan; `test_fauna_quota.gd`.

---

## 10. Night Survival Loop

- [x] Survival Timer malam terhubung ke gameplay — `NightSurvivalHUD` membaca `NightSpawner`/`FaunaQuota` (musuh X/Y, progres malam).
- [x] Gelombang musuh malam.
  - `NightSpawner` menambah Boar sampai batas tabel, satu langsung saat malam mulai.
- [x] Peningkatan ancaman per hari.
  - Jumlah/interval/HP-damage mengikuti `night_scaling_config.tres`.
- [x] Pemain bisa bertahan sampai 00:00 tanpa membunuh semua musuh — pembersihan fajar (`test_island_night.gd`).
- [x] Fajar berikutnya reset ke hari baru — `DayNightManager.advance`/`skip_time` (`test_daynight_restart.gd`).
- [x] Mati di malam hari = kondisi gagal — `DeathController` + `DeathScreen`; clock tetap jalan (`test_island_death.gd`).
- [ ] Feedback malam mulai/berakhir — audio di luar scope misi ini; banner visual sudah ada (`NightBanner`).

---

## 11. Death dan Respawn

- [x] Deteksi kematian pemain (`DeathController` lewat `hp_changed`).
- [x] Layar kematian dengan pilihan **Respawn** dan **Main Menu**.
- [x] Respawn mengembalikan pemain ke camp (0, 64) dengan 70% HP dan 60/60/80 needs.
- [x] Semua item yang dibawa jatuh di lokasi kematian (`LootBag`, equipment tetap).
- [x] Item drop bisa diambil kembali (hold E).
- [x] Debuff skill permanen setelah respawn.
- [x] Batas maksimal debuff (2 proficiency, algoritma spec §7.6).
- [x] Sisa kesempatan respawn (3 token; kematian ke-4 = game over).
- [x] Edge case: clock tidak dipause saat layar mati, jadi fajar Hari 7 tetap terjadi dan state rescue bertahan setelah respawn.

---

## 12. UI, Menu, dan Audio

- [x] HUD hari/fase/sisa waktu/progress.
- [x] Label Survival malam (mencerminkan sisa malam).
- [x] HUD Hunger/Thirst/Fatigue — `NeedsHUD` (bar + tier warna, ikon opsional dari art).
  - Scene dan skrip ada; tampilan belum dicek secara visual.
- [x] HUD inventory — `HotbarHUD` 5 slot + `BagPanel` 12 slot (Tab/I).
- [x] HUD debuff setelah respawn — `RespawnRecapHUD` + baris `ProficiencyHUD` memerah.
- [x] Indikator siang/malam — `TimeHUD` (fase + sisa waktu), `NightBanner`, `NightSurvivalHUD`.
- [x] Menu utama dan navigasi (`main_menu.tscn`, bukan main scene; `RunController`).
- [x] Pause menu — `PauseMenu` (P, guard, restore time scale) + settings/help.
- [x] Layar kematian.
- [x] Layar Victory (panel di `EndgameHUD`).
- [x] Banner Hari 7 dan panah Beacon (placeholder Label).
- [ ] Audio ambience siang/malam — audio tidak ditambahkan di misi ini.
- [ ] SFX langkah/gather/combat/hit/mati/respawn — audio tidak ditambahkan di misi ini.
- [ ] Audio peringatan senja — audio tidak ditambahkan di misi ini.
- [ ] Mixing/volume balance — menunggu audio ada.

---

## 13. Kondisi Menang dan Hari ke-7

- [x] Banner pagi Hari 7 (`EndgameController` + `EndgameHUD`).
- [x] Gelombang maksimal malam Hari 7 (tabel `NightSpawner` sudah ada; playtest belum).
- [x] Final dawn membekukan waktu dan menghentikan Hunger/Thirst.
- [x] Musuh malam ekstra kabur/despawn (aturan rescue `FaunaQuota`).
- [x] Arrow pointer ke Tiang Suar.
- [x] Item Suar Darurat di inventory (resep Workbench sudah ada).
- [x] Interaksi tahan E 1.5 detik di Tiang Suar.
- [x] Layar Victory setelah suar dinyalakan.
- [x] Anti-softlock Babi Hutan (minimal 2 ekor, respawn terbatas — `FaunaQuota`).
- [x] Tidak ada softlock jika pemain mati tepat saat 00:00 (clock berjalan terus).

## 14. Integrasi Test Harness & Semua Scenario

- [x] S1 Wiring: 139 resource nodes, 16 night_spawn_point markers, 9 RiverEdge, 4 BlueprintSlot — verified in test_island_wiring.gd
- [x] S2 Survival Loop: 4 blueprint builds, tree gathering, workbench axe crafting, campfire meat cooking/eating, tent day-sleeping — verified in test_island_survival.gd
- [x] S3 Night Loop: night spawner scaling (nights 1, 4, 7), camp raiding priorities, campfire dazzle debuff, ember snuff (night >= 5), dawn fauna cleanup — verified in test_island_night.gd
- [x] S4 Death Loop: player lethal damage, loot bag creation, bag slot clearing, equipment retention, debuff application, 3-token respawn limit, game_over emission — verified in test_island_death.gd
- [x] S5 Endgame Loop: jump to rescue, signal flare beacon usage, victory emission, rescue state persistence across death, flare/rescue requirements — verified in test_island_endgame.gd
- [x] B2 Soak Test: 7-day loop (0.5s/1.0s step) asserting bounded nodes (<20% growth) and state invariants — verified in test_island_soak.gd

## 15. Fitur Post-MVP (Jangan Dikerjakan Sebelum Inti Stabil)

Sengaja belum dikerjakan; bukan bagian MVP.

- [ ] NPC penyintas / spesialisasi / otomatis di camp.
- [ ] Variasi hewan liar tambahan.
- [ ] Area pulau tambahan.
- [ ] Crafting/building di luar kebutuhan inti.

---

---

## 16. Tambahan di luar spec — Mission 7 (keputusan & kelengkapan)

Changelog keputusan Mission 7; status fitur ada di seksi fiturnya
(Master Chef §4, HUD §12, panel Peti §8).

Hanya yang sudah terbukti lewat tes otomatis:

- [x] Rusa dijamin saat rescue (min 2, respawn 45 s nyata, counter terpisah, maks 4).
- [x] Suar darurat dikonsumsi saat Victory (victory tetap sekali).
- [x] Batu api hanya dipakai saat percobaan gagal (sukses/batal tidak).
- [x] Master Chef sederhana: +10 need terkait untuk cooked_meat / bone_broth / boiled_water.
- [x] Pohon kecil bisa ditebang tangan (2 kayu, 3 fatigue) + chop feedback penuh.
- [x] Ekonomi kayu starter baru (twig 10, batu kecil 8, pohon kecil 6; total 153 node).
- [x] Settings (intensitas/guncangan/petunjuk) + help (H); entri Pause Menu ada di §12.
- [x] Hint manager sekali-per-run + reset; chest panel dua arah + ambil semua.
- [x] HUD: recap debuff, baris proficiency memerah, banner malam/fajar, panel survival malam.

Belum: audio, art, dan rasa permainan (butuh playtest manual).

## 17. Tambahan di luar spec — Mission 6 (Base & Feel)

Hanya yang sudah terbukti lewat tes otomatis:

- [x] Boar siang NEUTRAL (temperament diturunkan tiap tick), aggro butuh `can_be_auto_targeted()`; F6 (paksa hostile) dan Insert (label) untuk uji manual.
- [x] Base dinamis: `CampAnchor`, validasi situs, mode B, HUD, slot blueprint bergantung anchor.
- [x] Ring pagar: segmen di layer fisika sendiri, blokir/unyah/tembus, perbaikan R.
- [x] Campfire COLD + QTE nyalakan api (3 gebrakan batu / 1.1 s, `Butuh Batu`).
- [x] Juice: hit-stop, shake, flash/squash, partikel, event, garis telegraph, input buffer, animasi jasad.

Belum: audio (di luar izin), playtest rasa (harus manual), verifikasi visual.

## 18. Gerbang Akhir MVP

Seluruh butir di bawah **belum dicentang** sampai playtest manual owner selesai.

Status: **belum dicentang** - needs manual playtest.

Checklist ini mengikuti kriteria selesai di dokumen MVP. Semua harus tercentang sebelum build dianggap MVP.

**Butir di bagian ini needs manual playtest:** tidak satu pun dicentang oleh tes otomatis; centang hanya setelah bermain manual.

- [ ] Pemain dapat memulai permainan dan mengendalikan karakter di area pulau.
- [ ] Pemain dapat mengumpulkan sumber daya dan kembali ke camp.
- [ ] Sistem waktu menampilkan hari serta pergantian siang/malam sesuai rasio.
- [ ] Pemain dapat memantau hunger, thirst, dan fatigue.
- [ ] Hewan liar menjadi ancaman dan dapat dihadapi dengan combat sederhana.
- [ ] Pemain dapat bertahan melewati Survival Timer malam.
- [ ] Kematian menampilkan pilihan Respawn atau Main Menu.
- [ ] Respawn mengembalikan pemain ke camp, menjatuhkan item, dan menerapkan debuff yang dibatasi.
- [ ] Pemain dapat mencapai Hari 7 dan memicu kondisi diselamatkan.
- [ ] Build dapat dimainkan dan diuji tanpa bug penghambat utama.

---

## 19. Backlog per Divisi (Ringkas)

### Rafli — PM & Game Designer

- [ ] Backlog, target mingguan, angka final, dan flow start → rescue — menunggu keputusan owner.
- [ ] Playtest dan catat bug/balance — needs manual playtest (belum ada sesi).
- [ ] Build final dan materi presentasi — belum ada build/export.

### Sandi — Main Programmer & Game Designer

Tidak ada backlog terbuka. Semua pekerjaan sudah tercatat di §1–§16 (satu entri per
fitur): project/struktur, kontrol+kamera, stats/proficiency, siang-malam+HUD,
interaksi+inventory, combat+AI fauna, death/respawn/debuff, needs, integrasi UI.
Audio milik Riyan, aset milik Wandi.

### Nun — Programmer & UI/UX

Selesai dan tercatat di §12: HUD waktu/hari + indikator siang-malam, HUD needs,
menu utama, UI kematian, UI inventory, feedback debuff, Survival Timer malam. Sisa:

- [ ] Penyesuaian UI hasil playtest — needs manual playtest.

### Riyan — Programmer & Sound Engineer

> Belum ada audio di project dan misi ini dilarang menambah audio, jadi semua butir
> di bawah menunggu keputusan owner (satu-satunya pekerjaan yang benar-benar kosong).

- [ ] Daftar kebutuhan audio inti.
- [ ] Ambience siang/malam.
- [ ] SFX langkah, gather, interaksi, combat, serangan hewan.
- [ ] Audio feedback hunger/thirst/fatigue/kematian/respawn.
- [ ] Audio menu dan suasana pulau.
- [ ] Mixing dan volume balance.

### Wandi — Game Artist / 2D Artist

> Pipeline siap dan terdokumentasi (`docs/editable/ASSET_GUIDE.md`, registry 63 slot;
> coverage 0/63). Butir di bawah murni kerja seni — kode tidak perlu diubah lagi.

- [ ] Style visual konsisten.
- [ ] Sprite dan animasi dasar pemain.
- [ ] Tileset/aset pulau dan camp.
- [ ] Aset resource.
- [ ] Aset hewan liar MVP.
- [ ] Aset item drop dan objek interaksi.
- [ ] Ikon needs dan elemen HUD.
- [ ] Ekspor aset dengan ukuran/pivot/format konsisten.

---

## 20. Playtest Script Minimum

Ini **skrip manual**, bukan status fitur — status implementasi ada di §1–§24. Semua
butir sengaja `[ ]` sampai pemilik menjalankannya dalam satu sesi penuh.

- [ ] Mulai game → Hari 1 siang, HUD menampilkan 05:00 (setelah config 600).
- [ ] Gerak 8 arah, sprint, dan collision berjalan.
- [ ] Stats berubah saat level/modifier diuji; HP clamp benar.
- [ ] Senja muncul di 15 detik terakhir; Night Watch 2×; `skip_time(45)` sesuai.
- [ ] Kumpulkan resource → masuk inventory → kembali ke camp.
- [ ] Craft item inti → gunakan → efeknya terlihat.
- [ ] Malam: Survival Timer berjalan, musuh menyerang, pemain bisa bertahan.
- [x] Mati → item jatuh → pilih Respawn → kembali ke camp → ambil item → debuff terlihat (tes otomatis; visual belum dicek).
- [x] Hari 7: final dawn, flare, Victory (tes otomatis; visual belum dicek).
- [ ] Tidak ada crash/softlock yang menghambat.

---

## 21. Blocker dan Keputusan yang Harus Diselesaikan

1. **[Selesai] Config default 600 detik.** `cycle_duration` bawaan script = 600 detik dan `day_night_default.tres` tidak lagi menimpanya; acceptance “rasio 5:5/4:6/3:7 dengan durasi 300/300” kini terpenuhi di game live.
2. **[Selesai] `_process` mempertahankan overflow multi-fase.** `_process` memakai carry-over loop; jalur `advance()`/`skip_time()` tetap memakai `_advance_game_seconds()`.
3. **[Selesai] `set_time_scale(-1)` reset ke config.** Nilai negatif mengembalikan `DayNightConfig.time_scale`; `0.0` tetap override nyata untuk freeze final dawn.
4. **`phase_changed` tidak membawa `day`.** Jangan ubah sinyal lama; tambahkan sinyal baru bila perlu.
5. **[Selesai] GUT 9.7.1 terpasang.** Tes clock/stats sudah dijalankan lewat GUT command line.
6. **[Sebagian] Modul inti belum lengkap.** Needs (komponen + HUD + 27 tes), inventory (12 slot + hotbar + equipment, 23 tes), bag panel (17 tes), gathering (8 resource node + hold-E, 14 tes), peta pulau minimum, crafting (13 resep + `CraftingComponent` + tab Crafting), struktur camp (Campfire/Workbench/BlueprintSlot + repair + rest, Peti 24 slot, Tenda tidur, Night Watch, `CampController` terpasang di `island.tscn`) sudah ada; panel Peti, combat, enemy, death, menu, audio, victory belum.
7. **`get_time_scale()` berubah saat final dawn.** Modul survival harus memakai getter ini agar ikut berhenti.
8. **`SafeZone` masih practice-only.** Jangan anggap ini sistem camp produksi.

---

## 22. Urutan Prioritas yang Disarankan

1. **[Selesai] P0 — Fondasi yang menghambat verifikasi:** GUT 9.7.1 terpasang, tes dijalankan, config 600, `_process` carry-over, smoke test `practice1` headless bersih.
2. **[Sebagian] P1 — Loop survival minimum:** needs + HUD selesai; inventory + gathering, crafting/camp dasar, combat + satu hewan, night survival belum.
3. **[Selesai] P2 — Kematian dan akhir permainan:** death/respawn, item drop, debuff, Hari 7, flare, Victory, menu utama.
4. **P3 — Polish:** menu, audio, animasi, balancing, playtest, build final.

---

## 23. Cara Merawat Checklist Ini

- Centang item hanya setelah kode **dan** verifikasi runtime/tes yang relevan selesai.
- Jika sebuah item hanya sebagian, biarkan `[ ]` dan tulis catatan “sebagian” di bawahnya.
- Setiap perubahan arsitektur/modul baru: perbarui `docs/editable/architecture.md` dan `docs/editable/PANDUAN_MODUL.md`.
- Setiap keputusan angka final: perbarui `.tres` dan checklist ini, jangan hanya mengubah kode.

## 24. Aset dan visual

Sistem aset siap dipakai tetapi **0/63 slot terisi** (coverage Mission 8).
Panduan lengkap: `docs/editable/ASSET_GUIDE.md`.

- [ ] Prioritas 1 (26 slot) terisi art final — menunggu tim seni.
- [x] Konvensi nama file + fallback + auto-scale + reload tanpa restart.
- [x] `tools/check_assets.gd` melaporkan typo, strip salah, rasio menyimpang,
  sekaligus cakupan/typo/duplikat/bentuk ikon item dan held item.
- [x] UI skin (theme, ikon item, latar menu) aktif otomatis bila art ada.
- [x] Senjata/tools dasar: dibuktikan `test_crafting_component.gd`.

### Definition of Done

- [ ] **Definition of Done**: needs manual playtest — belum ada sesi playtest owner.

## 25. Polish pass (Mission 9)

Rasa/feedback, bukan fitur baru. Semua butir terverifikasi lewat
`tests/unit/test_polish.gd` (9 tes) dan boot island.

- [x] Fade antar scene (`RunController`, menu → island) + fade masuk island/menu.
- [x] Kilat putih saat Victory dan slow-mo singkat saat kematian (mengikuti setelan Guncangan layar).
- [x] Vignette merah berdenyut saat HP < 25% (slot art `ui_vignette_low_hp` opsional).
- [x] Bar Needs bergerak halus; panel tas/peti muncul dengan animasi; slot hotbar "pop".
- [x] Debu siang + kunang-kunang malam mengikuti pemain.
- [x] Kamera look-ahead + zoom siang/malam.
- [x] 3 prompt pembuka lewat saluran HintManager yang sama, berprioritas di atas hint gameplay (tidak bisa dipotong gather/low-need), sekali per sesi, bisa dilewati.
- [x] Penunjuk arah camp saat jauh dari base (anchor viewport, bukan piksel tetap).
- [x] Baris "Layar penuh" di Pengaturan (disimpan di `user://settings.cfg`).
- [x] Binding gamepad dasar (stik kiri, A/X/Y/START/RB, D-pad hotbar 1–4).
- [ ] Uji rasa secara manual: fade, slow-mo, vignette, ambience — needs manual playtest.

## 26. Feedback channel (Mission 10)

- [x] Toast channel tunggal: tas penuh, crafting batal, api padam, bahan bakar hampir habis.
- [x] Angka damage melayang (warna berbeda untuk heavy; kill memakai penanda `KO`, bukan 0).
- [x] Busur merah di tepi layar saat pemain terkena serangan.
- [x] Sinyal `InventoryComponent.add_blocked` (additive) supaya kegagalan tidak senyap.
- [x] Tes: `tests/unit/test_feedback_hud.gd` (7 tes).
- [ ] Uji rasa manual: toast saat tas penuh, angka damage saat berburu, busur saat diserang malam.

## 27. Balance pass 2 (Mission 9, fase 1-3)

Fase 0-3 jalan; fase 4-6 belum (lihat bagian terpisah di bawah).

- [x] Raid sebagai event terjadwal (`RaidDirector` + `RaidConfig`), peringatan sebelum raid, raider dipilih dari boar terdekat ke base.
- [x] Cap populasi malam dan siang dibaca dari `RaidConfig`; cap tidak pernah membunuh fauna yang sudah ada.
- [x] Boar punya massa: pemain tidak bisa menembus/mendorongnya; knockback memakai `move_and_collide` x `knockback_resistance`.
- [x] Api unggun dibangun COLD; bahan bakar diam, cahaya 0 sampai pernah dinyalakan, hint `campfire_cold` muncul otomatis.
- [x] Kematian membekukan game (`FreezeController`); jeda menu memakai jalur yang sama.
- [x] Perlindungan respawn 5 dtk (kebal, kedip, fauna berhenti mengejar, batal bila menyerang).
- [x] Needs dikalibrasi ulang (Hunger/Thirst 0.6/0.57), Hunger <= 30 mengunci sprint + hint, HP pulih lambat dengan jeda.
- [x] Tes baru: `test_raid_director.gd`, `test_boar_mass.gd`, `test_campfire_cold.gd`, `test_freeze_controller.gd`, `test_respawn_protection.gd`, `test_needs_balance.gd`, `test_sprint_blocks.gd`, `test_health_regen.gd`.
- [x] Fase 4: jongkok (Ctrl) memperlambat + menyamarkan + memblokir sprint; rusa waspada dulu sebelum kabur dan radius deteksinya mengecil saat pemain jongkok; air sungai memperlambat dan memblokir sprint (`WadingComponent`). Tes: `test_sneak.gd`, `test_deer_alert.gd`, `test_wading.gd`.
- [ ] Fase 5: sweep arah matahari + tab Profil.
- [ ] Fase 6: SpriteFrames-first + data audio (`AUDIO_GUIDE.md` belum ada).
- [ ] Uji rasa manual: berat raid, rasa lapar, jeda regen — needs playtest.

## 28. Umpan balik pemain (Mission 9 lanjutan)

- [x] Pohon hanya bergetar saat benar-benar ditebang, berirama 0.22 s (getaran 0.12 s), bukan saat pemain hanya berjalan dekat.
- [x] Menu Jeda berisi tombol Lanjutkan / Pengaturan / Bantuan / Menu Utama (sebelumnya CanvasLayer kosong).
- [x] Daftar profisiensi ada di panel Tab/I sebagai tab ketiga (level, XP, passive).
- [x] Overlay `PlaceholderLabels` menampilkan nama slot yang art-nya masih kosong di dekat pemain (maks 12 label, dipindai tiap 0,25 s).
- [x] `docs/editable/PANDUAN_INPUT.md` — arti setiap tombol, dibuat dari Input Map hidup.
- [ ] Verifikasi rasa: getaran pohon dan tampilan menu jeda — needs playtest.

## 29. Mission 10 — Fisika badan, rusa, dan audio (data)

- [x] `BodyProfile` + `BodyProfileApplier` + tiga `.tres` (player/babi/rusa) — `test_mission10_mass_deer.gd`.
- [x] Matriks fisika dengan badan nyata: A kontak, B lepas, C jarak stabil, D knockback, E jepitan, F anti-tumpuk — `test_mission10_physics_matrix.gd` (8 tes) + `test_boar_mass.gd` (8 tes).
- [x] `BodySeparation` (tidak menembus dinding/pagar/sungai, tidak mendorong ke pemain) — `test_mission10_body_separation.gd`.
- [x] Aturan spawn 60 px dari pemain/badan fauna, fallback tidak memakai penanda di ring base — `test_camp_anchor.gd`, `test_night_spawner.gd`, `test_fauna_quota.gd`.
- [x] Rusa ALERT -> STARTLE -> FLEE, hit-stun 0.35 s, ramp kecepatan 0.5 s — `test_mission10_mass_deer.gd`, `test_deer_alert.gd`.
- [x] Simulasi first-hit S1-S5 (tangan kosong, Tombak Kayu, sprint, jendela hit kedua, rusa lelah) — `test_mission10_deer_first_hit.gd`.
- [x] Registri audio 103 cue + `AUDIO_GUIDE.md` + tes sinkronisasi — `test_audio_guide_sync.gd`, `test_docs_in_sync.gd`.
- [ ] Playback audio, `AudioManager`, mixing/volume — sengaja belum ada; hanya data + panduan.
- [ ] Playtest manual Mission 10 (dorong rusa/babi, sneak, startle, spawn dekat pemain).
- [ ] Art rusa/babi (masih placeholder).

## 30. Perbaikan panel stasiun, sungai, dan atmosfer (Mission 10 lanjutan)

- [x] Panel Meja Kerja/Api Unggun mengunci gerak pemain tanpa mem-pause dunia.
- [x] Craft dari panel stasiun berjalan (tidak batal sendiri karena tombol gerak).
- [x] Panel peti tidak lagi menyambung ke sinyal stasiun (error 2 argumen hilang).
- [x] Minum bisa dilakukan di mana saja di zona sungai dan tepinya (32 px).
- [x] Sore mulai di menit ke-4 dan malam tepat di menit ke-5 (fajar kebalikannya),
  memakai sisa waktu fase, bukan tween terpisah.
- [x] Transisi memakai arah matahari (`SunOverlay` + `DayLightCurve`).
- [x] Kunang-kunang hanya muncul di malam hari.
- [x] Cahaya api unggun meredup saat siang dan penuh saat malam.
- [x] Warning editor di screenshot dibersihkan (shadowing, parameter, unreachable,
  meta tween).
- [x] Tes baru untuk keempat area di atas.

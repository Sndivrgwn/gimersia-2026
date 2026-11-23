# Panduan Modul — Gimersia 2026

> Semua modul di bawah ini **sudah jadi dan sudah jalan** di `practice1.tscn`.
> Panduan ini bukan tutorial merancang sistem, tapi cara memasang dan memakainya.
> Kalau dokumen ini berbeda dengan kode, **kode yang menang**.

Godot 4.7.2 · GDScript · GUT 9.7.1

---

## 0. Cara pakai dalam 60 detik

Ada tiga jenis modul, dan cara pasangnya cuma tiga pola:

| Jenis | Contoh | Cara pasang |
|---|---|---|
| **Autoload** (global) | `DayNightManager` | Sudah otomatis aktif di `project.godot`. Tinggal panggil `get_node("/root/DayNightManager")`. |
| **Node / scene** | `Player`, `StatsComponent`, `NeedsComponent`, `InventoryComponent`, `ItemPickup`, `DayNightVisual` | Instance scene-nya, atau tambahkan sebagai child node. |
| **HUD** | `TimeHUD`, `NeedsHUD`, `StatsHUD`, `HotbarHUD` | Instance scene `.tscn`-nya di scene permainan. Selesai. |
| **Panel interaktif** | `BagPanel` | Instance `src/ui/panels/inventory/bag_panel.tscn`; dibuka dengan Tab/I. |

Aturan besarnya cuma satu:

> **Baca lewat getter, dengar lewat sinyal, ubah lewat API publik.**
> Jangan hitung waktu sendiri, jangan tulis base stats langsung.

---

## 1. Contoh lengkap: pasang Player + Needs + HUD

Ini pola yang dipakai `practice1.tscn` dan `tests/sandbox/stats_sandbox.tscn`:

```gdscript
const PLAYER_SCENE := preload("res://src/entities/player/player.tscn")
const NEEDS_HUD_SCENE := preload("res://src/ui/hud/needs/needs_hud.tscn")

var player := PLAYER_SCENE.instantiate()
player.add_to_group(&"player")        # HUD mencari lewat grup ini
add_child(player)

var hud := NEEDS_HUD_SCENE.instantiate()
hud.set(&"needs_component", player.get_node_or_null("NeedsComponent"))
add_child(hud)
```

Selesai — Player sudah bisa jalan, Hunger/Thirst/Fatigue sudah turun sendiri, dan bar-nya sudah tampil.

---

## 2. `DayNightManager` — jam game

**Gunanya:** satu-satunya sumber waktu game (hari, fase, sisa waktu, Night Watch, final dawn).

**Cara pakai:** tidak perlu dipasang, ini autoload.

```gdscript
var clock := get_node("/root/DayNightManager")

if clock.is_night():
    print("malam, sisa ", clock.get_remaining_text())   # "04:12"
```

**Yang sering dipakai:**

| Butuh | Panggil |
|---|---|
| Cek siang/malam | `is_day()`, `is_night()`, `get_phase_name()` |
| Sisa waktu fase | `get_remaining_seconds()`, `get_remaining_text()` |
| Progress fase (0..1) | `get_phase_progress()` |
| Hari sekarang | `get_current_day()`, `get_max_days()` |
| Loncat waktu (tidur) | `skip_time(45.0)` |
| Tick manual (tes) | `advance(delta)` |
| Kecepatan waktu | `get_time_scale()`, `set_time_scale(2.0)` |

**Sinyal:** `started`, `day_started(day)`, `night_started(day)`, `day_changed(day)`, `phase_changed(phase)`, `time_updated(day, phase, remaining)`, `dusk_started(day)`, `night_ended(day)`, `time_scale_changed(scale)`, `night_watch_changed(active)`, `time_skipped(seconds)`, `rescue_started`.

**Penting:**
- `get_time_scale()` bernilai **2× saat Night Watch**, **0 saat final dawn**. Kalau drain-mu dikalikan nilai ini, semuanya ikut benar otomatis.
- `set_time_scale(-1)` = kembali ke default config. `set_time_scale(0.0)` = bekukan.
- `phase_changed` hanya membawa **satu** argumen (`phase`). Jangan sambungkan callback dua argumen.

**Jangan:** bikin timer waktu game kedua, atau jam sendiri di modul survival.

---

## 3. `DayNightConfig` — angka siklus

**Gunanya:** menyimpan `cycle_duration`, `max_days`, `time_scale`, dan rasio siang/malam per rentang hari.

**Cara pakai:** sudah dipakai otomatis (default 600 detik, 7 hari: 5:5, 4:6, 3:7).

- Angka default: `src/data/resources/environment/day_night_config.gd`
- Config aktif: `src/data/configs/environment/day_night_default.tres`
- Config cepat untuk debug: `day_night_debug_fast.tres` (60 detik) — pasang di `debug_config`, lalu `use_debug_config = true`.

Mau bikin config baru? Duplikat `.tres`-nya, ubah angkanya, pasang ke field `config` milik `DayNightManager`. Tidak perlu sentuh kode.

---

## 4. `DayNightVisual` — tint dunia

**Gunanya:** mewarnai dunia sesuai fase (pagi/siang/senja/malam) + partikel.

**Cara pakai:** instance `src/levels/components/environment/day_night_visual.tscn` di scene. Warnanya diatur di `src/data/configs/environment/day_night_visual_default.tres`.

Getter: `get_atmosphere()`, `get_atmosphere_name()`. Sinyal: `atmosphere_changed(atmosphere)`.

**Jangan:** menambah `CanvasModulate` kedua — tint hanya boleh dari komponen ini.

---

## 5. `TimeHUD` — jam di layar

**Cara pakai:** instance `src/ui/hud/time/time_hud.tscn`. Selesai. Isinya hari, fase, sisa waktu, progress, dan label Survival saat malam.

HUD ini read-only: dia membaca manager, tidak menyimpan state gameplay.

---

## 6. `NeedsComponent` — Hunger, Thirst, Fatigue

**Gunanya:** nilai 0..100 yang turun sendiri, plus efek tier ke stats.

**Cara pakai:** sudah menempel di `player.tscn` sebagai child `Player`. Untuk entity lain, tambahkan node `NeedsComponent` sebagai child, dan `StatsComponent` sebagai saudaranya.

```gdscript
var needs := player.get_node("NeedsComponent")

needs.get_value(NeedsComponent.Need.HUNGER)      # 0..100
needs.add(NeedsComponent.Need.HUNGER, 12.0)      # makan berry
needs.spend_fatigue(2.0)                         # biaya gather
needs.get_tier(NeedsComponent.Need.FATIGUE)      # NORMAL / LOW / ZERO
needs.get_fatigue_cap()                          # plafon Fatigue sekarang (<= 100)
needs.restore_fatigue_capacity(10.0)             # makan/minum: plafon +10
needs.set_idle_regen_override(&"campfire", 5.0)  # bonus rest: regen diam jadi 5/s
needs.clear_idle_regen_override(&"campfire")
needs.get_idle_regen()                           # max(base, override tertinggi)
```

**Dengar perubahannya:**

```gdscript
needs.value_changed.connect(func(need, value): print(need, " -> ", value))
needs.tier_changed.connect(func(need, tier): print(need, " tier ", tier))
needs.fatigue_cap_changed.connect(func(cap): print("plafon Fatigue ", cap))
```

**Tier otomatis:**

| Nilai | Tier | Efek |
|---|---|---|
| > 25 | NORMAL | tidak ada |
| ≤ 25 | LOW | Hunger: move −15%, damage −15% · Thirst: sprint drain +30%, attack speed −20% · Fatigue: sprint terkunci, move −20%, gather +30% |
| ≤ 0 | ZERO | efek LOW tetap + HP hilang (Hunger 1.5/s, Thirst 2.0/s; bisa menumpuk). Fatigue: move −45%, attack speed −50% |

**Aturan main:**
- Jangan tulis nilai need dari modul lain. Pakai `add()` / `spend_fatigue()`.
- Efek tier dipasang otomatis ke `StatsComponent` dengan `source_id` `&"lapar"`, `&"haus"`, `&"lelah"` (satu id per need, boleh banyak stat).
- Angka tuning ada di `src/data/resources/needs/needs_config.gd`; instance `src/data/configs/needs_config.tres` tidak menimpa apa pun.
- Drain memakai `get_time_scale()` dan `is_night()`, jadi tidak perlu timer sendiri.
- **Fatigue punya plafon sendiri**, mulai 100:
  - **Sprint** (Shift + gerak): nilai −2.5/s × faktor stat **dan** plafon −0.4/s. Sprint 50 detik membuat plafon jadi 80, jadi 80 itulah maksimum baru.
  - **Jalan biasa**: nilai −0.08/s, plafon **tidak** berubah.
  - **Diam**: nilai pulih +1.0/s sampai plafon.
  - **Makan/minum**: panggil `restore_fatigue_capacity(10.0)` (angka `fatigue_meal_cap_restore`) untuk menaikkan plafon lagi.
  - **Tidur** (`time_skipped`): plafon +25 dan Fatigue langsung penuh sampai plafon itu.
  - Semua angka ada di `needs_config.gd` (`fatigue_sprint_drain`, `fatigue_sprint_cap_drain`, `fatigue_walk_drain`, `fatigue_idle_regen`). Set angka ke `0.0` kalau mau mematikan salah satu efek.
- `time_skipped` (tidur) menguras Hunger/Thirst tapi tidak pernah di bawah 1.0.
- Sprint dikunci dengan menulis `player.can_sprint`; `velocity` dan base stats tidak disentuh.

---

## 7. `InventoryComponent` — tas 12 slot + hotbar

**Gunanya:** pemilik isi tas pemain. 12 slot, 5 slot pertama dipakai sebagai hotbar (tombol 1-5).

**Cara pakai:** di `practice1.tscn` node ini ditambahkan ke **instance** `Player`, bukan ke `player.tscn` — sandbox dan tes stat memakai tombol 1-4, jadi jangan menaruhnya di scene dasar. Komponen mencari `NeedsComponent` dan `StatsComponent` dari parent-nya sendiri.

```gdscript
var inv := player.get_node("InventoryComponent") as InventoryComponent

inv.add_item(ItemCatalog.BERRY, 3)   # 0 = semua masuk; > 0 = sisa yang tidak muat
inv.count_of(&"berry")               # total di semua slot
inv.get_slot(0)                      # ItemStack atau null
inv.get_slot_item(0)                 # ItemDefinition atau null
inv.get_slot_count(0)
inv.use_slot(0)                      # pakai item slot hotbar pertama
inv.remove_item(&"berry", 1)         # bool; atomik (semua atau tidak sama sekali)
inv.move_slot(0, 1)                  # tukar, atau gabung bila item sama
inv.add_or_drop(ItemCatalog.WOOD, 5) # sisa meluber jadi ItemPickup di kaki pemain
inv.equip(ItemCatalog.LEATHER_VEST)  # WEAPON/ARMOR menggantikan, TOOL menambah
inv.has_tool(&"stone_axe")
```

**API:** `add_item(item, count) -> int`, `remove_item(item, count) -> bool` (terima `ItemDefinition` atau id), `has_item(item, count)`, `count_of(item)` / `count_item(id)`, `get_slot(index)`, `get_slot_item(index)`, `get_slot_count(index)`, `is_slot_empty(index)`, `is_full()`, `move_slot(from, to) -> bool`, `use_slot(index) -> bool`, `add_or_drop(item, count) -> int`, `equip(item) -> bool`, `unequip(slot) -> bool`, `has_tool(item)`, `get_equipped(slot)`, `get_capacity()`, `get_hotbar_size()`, `clear()`, `setup(player, needs = null, stats = null)`.

**Sinyal:** `slot_changed(index)`, `equipment_changed(slot)`, `inventory_changed()`.

**Aturan main:**
- Item menumpuk ke stack yang sama lebih dulu, lalu mengisi slot kosong paling kiri; `max_stack` definisi item (default 20). Urutan slot tidak diacak.
- `use_slot()` hanya untuk `ItemDefinition.Category.CONSUMABLE`. Hunger/Thirst lewat `NeedsComponent.add()`, HP lewat `StatsComponent.heal()/set_hp()`, dan Fatigue lewat `NeedsComponent.restore_fatigue_capacity()`. Item tetap terpakai walau stat sudah penuh.
- **Jangan** memanggil `add(Need.FATIGUE, ...)` untuk item; Fatigue item selalu lewat plafon.
- Armor memakai modifier `StatsComponent` dengan `source_id` tetap `&"equip_armor"` (damage reduction + max HP); mengganti/menanggalkan armor menghapus modifier lama dulu. Weapon dan tool tidak mengubah stat sekarang.
- Slot TOOL adalah **kepemilikan** (Stone Axe + Stone Pickaxe), dicek lewat `has_tool()`.
- Ukuran tas/hotbar, `pickup_delay` (0.5 s) dan `pickup_radius` ada di `src/data/configs/inventory_config.tres`, bukan di script.
- Tombol **1-5** (`hotbar_1..hotbar_5`) memakai slot 0-4. Debug needs memakai **F1 / X / C / V / B / M**, jadi tidak bentrok.

---

## 8. `ItemDefinition`, `ItemEffect`, `ItemCatalog` — data item

**Gunanya:** definisi item dan efek konsumsinya. Angka tinggal di Resource, bukan di kode gameplay.

**Cara pakai:** item adalah `.tres` di `src/data/items/<id>.tres` dan diakses lewat katalog:

```gdscript
var berry := ItemCatalog.BERRY          # ItemDefinition
berry.id                        # &"berry"
berry.display_name              # "Beri"
berry.category                  # ItemDefinition.Category.CONSUMABLE
berry.max_stack                 # 20
berry.equipment_slot            # ItemDefinition.EquipmentSlot.NONE
berry.consume_effect.hunger     # 12.0
berry.consume_effect.fatigue    # 10.0
```

`ItemCatalog` punya 23 konstanta (`WOOD`…`LEATHER_VEST`), array `ALL`, dan `get_by_id(id)`. Field `ItemDefinition`: `id`, `display_name`, `description`, `category` {RESOURCE, CONSUMABLE, WEAPON, TOOL, ARMOR, SPECIAL}, `max_stack`, `icon`, `consume_effect`, `equipment_slot` {NONE, WEAPON, TOOL, ARMOR}, `weapon_damage`, `weapon_range`, `armor_damage_reduction`, `armor_max_hp_bonus`. `ItemEffect`: `hunger`, `thirst`, `fatigue`, `hp`, `regen_hp_per_second`, `regen_duration`.

**Penting soal `fatigue`:** field ini **bukan** delta Fatigue biasa.
`InventoryComponent` menerapkannya lewat
`NeedsComponent.restore_fatigue_capacity(fatigue)`, jadi nilainya **menaikkan
plafon Fatigue** sekaligus mengisi nilai Fatigue sebanyak itu (dibatasi plafon
baru). Nama field dipertahankan demi kompatibilitas `.tres`; jangan menambah
`add(Need.FATIGUE, ...)` untuk item.

| Item | Kategori | Efek (`ItemEffect`) |
|---|---|---|
| Beri (Berry) | CONSUMABLE | +12 Hunger, +10 Fatigue |
| Kelapa (Coconut) | CONSUMABLE | +10 Hunger, +30 Thirst, +10 Fatigue |
| Daging Mentah (Raw Meat) | CONSUMABLE | +15 Hunger, −10 Thirst |
| Daging Matang (Cooked Meat) | CONSUMABLE | +45 Hunger, +15 HP |
| Kaldu Tulang (Bone Broth) | CONSUMABLE | +35 Hunger, +40 Thirst; regen 1 HP/s 20 dtk **disimpan, belum diterapkan** |
| Air Rebus (Boiled Water) | CONSUMABLE | +60 Thirst |
| Perban Herbal (Herbal Bandage) | CONSUMABLE | +35 HP |
| Kayu/Batu/Serat/Bambu/Tulang/Kulit | RESOURCE | stack 20, tanpa efek |
| Kantung Air Kulit / Suar Darurat | SPECIAL | stack 1, tanpa perilaku |
| Obor (Torch) | SPECIAL | stack 20, tanpa perilaku |
| Tombak Kayu/Batu/Tulang | WEAPON | 18/75, 28/85, 30/85 |
| Kapak Batu / Beliung Batu | TOOL | kepemilikan, tanpa efek stat |
| Rompi Kulit (Leather Vest) | ARMOR | damage reduction 0.20, max HP +15 |

**Menambah item baru:** buat `.tres` di `src/data/items/` (script `item_definition.gd`, sub-resource `item_effect.gd`), lalu tambahkan `const` di `item_catalog.gd`. `tests/unit/test_item_definitions.gd` memuat setiap file di folder itu.

**Jangan:** menulis angka efek di script gameplay, memanggil `add(FATIGUE, ...)` untuk item, atau mengubah `.tres` saat runtime.

---

## 9. `ItemPickup` — ambil item di dunia

**Gunanya:** Area2D yang memasukkan item ke `InventoryComponent` pemain yang menyentuhnya. Di practice ini cara menguji makan/minum tanpa sistem resource.

**Cara pakai:** instance `src/entities/props/item_pickup.tscn`, isi `item` (ItemDefinition) dan `count`:

```text
DemoPickups (Node2D, practice only)
└── BerryPickup (ItemPickup)
    position = Vector2(-90, 82)
    item = res://src/data/items/berry.tres
    count = 2
```

Hanya body di grup `player` yang mengambil. Pickup diabaikan selama `pickup_delay` (0.5 s, dari `InventoryConfig`) sejak spawn, jadi item yang baru dijatuhkan tidak langsung terambil lagi; radius shape ikut `pickup_radius`. Kalau tas penuh, sisa item tetap di pickup; kalau semua masuk, node menghapus dirinya (`queue_free()`).

**Jangan:** menaruh pickup di `player.tscn`, atau menambah item langsung ke tiap scene pemain — cukup sentuh Area2D-nya.

---

## 10. `HotbarHUD` — bar 5 slot di layar

**Cara pakai:** instance `src/ui/hud/inventory/hotbar_hud.tscn`. HUD mencari `InventoryComponent` lewat grup `player`; isi `@export inventory` kalau mau eksplisit.

Tampilan: lima kartu slot, masing-masing nomor tombol, nama item (atau `icon` bila diisi; tanpa ikon jatuh ke nama), dan jumlah `x3`. HUD mendengar `slot_changed(index)`, read-only, dan tidak bisa dipakai untuk memakai item — pemakaian lewat tombol 1-5 (`InventoryComponent`).

**Jangan:** menyimpan isi tas atau menghitung ulang stack di HUD.

---

## 11. `BagPanel` — tas interaktif (Tab/I)

**Cara pakai:** instance `src/ui/panels/inventory/bag_panel.tscn` di scene permainan. CanvasLayer-nya `layer = 20` (di atas HUD `layer = 10`) dan panel tersembunyi secara default. Toggle lewat action Input Map `inventory_toggle` (Tab atau I), ditangani panel sendiri di `_unhandled_input`. Saat panel terbuka, **Esc** (`ui_cancel`) juga menutupnya; Esc tidak membuka panel.

Tab **Tas**: grid 12 slot (`bag_slot.tscn`, minimal 64×64, slot 0-4 diberi nomor hotbar 1-5) plus kolom Peralatan read-only (Senjata, Alat = Kapak Batu/Beliung Batu yang dimiliki, Armor). Tab **Crafting**: daftar 13 resep (3 tangan di atas, 10 terkunci di bagian redup "TERKUNCI" dengan nama stasiunnya), teks bahan `punya/butuh` per bahan (merah bila kurang), waktu craft, dan tombol **Craft** per baris. Saat craft berjalan: bar progres, label status ("Membuat …", "Selesai: …", "Batal: …"), dan tombol **Batalkan**. Panel hanya memanggil `CraftingComponent.start_craft()` / `cancel_craft()`; angka dibaca ulang lewat sinyal inventaris + `craft_started/progress/completed/cancelled` + `stations_changed()`.

| Aksi | Efek |
|---|---|
| Klik kiri + drag slot ke slot lain | `InventoryComponent.move_slot(from, to)` — tukar, atau gabung bila item sama dan target masih muat |
| Klik kanan slot | `InventoryComponent.use_slot(index)`; slot kosong / non-CONSUMABLE diabaikan tanpa error |
| Hover slot | tooltip: nama, deskripsi, satu baris efek (Hunger/Thirst/Fatigue/HP, damage senjata, armor) |

Panel **tidak mem-pause** game: DayNightManager, drain Needs, dan gerakan pemain tetap berjalan. Panel tidak punya state sendiri; semua isi dibaca dari `InventoryComponent` dan refresh hanya lewat `slot_changed`, `equipment_changed`, dan `inventory_changed`, jadi `HotbarHUD` dan tas selalu sinkron.

Panel mencari `InventoryComponent` lewat grup `player`; isi `@export inventory` kalau mau eksplisit (pola yang sama dengan `NeedsHUD`).

**Jangan:** menambah equip/unequip, drop ke dunia, atau resep crafting di panel. Panel hanya memanggil `move_slot()` dan `use_slot()`.

---

## 12. `NeedsHUD` — bar Hunger/Thirst/Fatigue

**Cara pakai:** instance `src/ui/hud/needs/needs_hud.tscn` di scene. HUD mencari komponen lewat grup `player` → `NeedsComponent`, atau isi `@export needs_component` kalau mau eksplisit.

Warna normal di atas 25, warna peringatan saat LOW/ZERO. Read-only: tidak menulis nilai need.

---

## 13. `StatsComponent` + `PlayerBaseStats` — angka stat

**Gunanya:** semua angka turunan (HP, kecepatan, damage, dodge, waktu craft/gather).

**Cara pakai:** child dari `Player`. Jangan tambah `StatsComponent` kedua.

```gdscript
player.stats.add_modifier(&"kopi", &"move_speed", StatModifier.Kind.PERCENT, 0.10)
player.stats.remove_modifier(&"kopi")

player.stats.get_move_speed()
player.stats.get_attack_damage()
player.stats.heal(20.0)
player.stats.set_hp(50.0)
```

Stat yang didukung: `max_hp`, `damage_reduction`, `move_speed`, `sprint_speed`, `attack_damage`, `attack_speed`, `dodge`, `craft_time`, `gather_time`, `sprint_fatigue_drain`.

Angka dasar ada di `src/data/stats/player_base_stats.gd` (HP 100, move 160, sprint 240, damage 8, attack speed 1.2).

**Jangan:** mengubah `current_hp` langsung (pakai `set_hp()`/`heal()`), atau menulis nilai turunan.

### `StatsHUD` — lihat angkanya langsung

Instance `src/ui/hud/stats/stats_hud.tscn` di scene. Panel kiri bawah menampilkan HP, move/sprint speed, attack damage & speed, gather time, sprint drain, plus **tier Hunger/Thirst/Fatigue**. Paling enak untuk melihat efek ZERO:

- Hunger ZERO → attack dmg turun, HP mulai berkurang 1.5/s
- Thirst ZERO → attack speed turun, HP berkurang 2.0/s
- Fatigue ZERO → move speed 55% dari dasar, attack speed −50%, gather x1.30, sprint terkunci

HUD mencari Player lewat grup `player`; isi `@export player` kalau mau eksplisit. Read-only.

---

## 14. `Player` — karakter

**Gunanya:** gerak top-down + sprint, semuanya membaca StatsComponent.

- `can_sprint` — boleh dikunci dari luar (Needs memakainya).
- `sprint_state_changed(is_sprinting)` — sinyal untuk modul yang peduli sprint.
- `facing_direction` — arah hadap terakhir.
- `stats` — referensi ke `StatsComponent`.

**Penting:** grup `player` dipasang di **scene pemakai**, bukan di `player.tscn`. Scene baru harus menambahkan `player.add_to_group(&"player")`.

---

## 14b. Base dinamis — `CampAnchor`, `BasePlacementController`, `BaseHUD`

**Gunanya:** markas tidak lagi di titik mati; pemain mendirikannya sekali, lalu
semua sistem membaca pusat/radius dari anchor.

- `CampAnchor` (`src/core/managers/camp_anchor.gd`): `founded`, `get_center()`,
  `get_ring_radius()`, statis `find_anchor(node)`, `camp_center(node)`,
  `ring_radius(node)`. Bila belum ada anchor, statis mengembalikan
  `Vector2.ZERO` / 180 px sehingga scene lama dan tes tetap sama.
- `BasePlacementController` + `BaseHUD`: tekan **B**, ghost mengikuti kursor,
  situs tidak valid diblokir dengan alasan Indonesia (air/sungai/pantai),
  klik kiri mendirikan base (`base_founded(center, radius)`).
- `CampController` mengikat anchor (`get_anchor()`), memindahkan/mengaktifkan
  slot blueprint, dan mematikan slot saat base belum berdiri.
- Konsumen yang ikut anchor: raid boar, radius Speed di `ProficiencyComponent`,
  titik respawn `DeathController`, keep-out spawn `FaunaQuota`/`NightSpawner`
  (`ring_radius + 100`).

## 14c. Pagar — `FenceRing`, `FenceSegment`, `FenceConfig`

**Gunanya:** ring pagar 200 px (≈20 segmen 66 px) yang menghalangi boar; boar
menggit/mengunyah segmen yang menghalangi lalu bisa menerobos. Segmen memakai
`PhysicsLayers.FENCE_LAYER` (bit 3 = 8) dan merupakan `CampStructure`, jadi bisa
diperbaiki dengan R (1 wood → 30 hp). Celah pagar tetap valid; pemain tidak
tertahan pagar.

## 14d. Menyalakan api — `FireStarterController` + QTE

**Gunanya:** campfire yang sudah mati (fuel 0) dan diisi bahan bakar tetap
**COLD**; api harus dinyalakan dengan 3 gebrakan batu dalam 1.1 s.

- `Campfire.needs_ignition()`, `can_ignite()`, `get_ignite_block_reason()`
  (`Butuh Batu`), `ignite()`, `request_ignition()`.
- `CampfireRefuel` menampilkan prompt sesuai state (isi bahan bakar vs nyalakan).
- QTE batal bila pemain menjauh > 96 px; RNG di-inject agar tes deterministik.
- **Perubahan perilaku:** refuel tidak lagi otomatis menyalakan api yang mati.

## 14e. Juice tempur — `CombatFeedback` + `JuiceConfig`

**Gunanya:** umpan balik visual murni, tanpa mengubah balance:

- hit-stop lokal (`freeze_for` pada fauna yang dipukul), shake kamera lewat
  `Camera2D.offset`, flash + squash, partikel satu-kali, `feedback_event(kind, position)`.
- kematian memakai "jasad" visual terpisah; fauna tetap langsung dibebaskan agar
  kuota/spawn/soak tidak bergeser.
- boar menampilkan garis merah + tanda `!` saat telegraph dash.
- input buffer: `CombatComponent.swing_buffer_time` (dari
  `JuiceConfig.manual_swing_buffer`, 0.15 s) menyimpan ayunan yang ditekan saat cooldown.

### Susunan node baru di `island.tscn`

```text
Island
├── CampAnchor                (sebelum CampController)
├── CampController
│   └── FenceRing
└── Player
    ├── BasePlacementController
    ├── FireStarterController
    └── CombatFeedback
CanvasLayer (HUD)
├── BaseHUD
└── FireStarterHUD
```

## 14f. Pengaturan, pause, bantuan — `SettingsService`, `PauseMenu`, `HelpPanel`

- `SettingsService` (Node di island & menu, grup `settings_service`, **bukan**
  autoload): `juice_intensity` (0..1.5), `screenshake_enabled`, `hints_enabled`;
  `get_value/set_value`, sinyal `changed`, simpan di `user://settings.cfg`
  (file hilang/rusak → default). `CombatFeedback` membaca service ini.
- `PauseMenu` (CanvasLayer 40, `PROCESS_MODE_ALWAYS`): **P** membuka/menutup;
  tidak terbuka bila DeathScreen, game over, Victory, BaseHUD, FireStarterHUD,
  BagPanel, atau ChestPanel sedang tampil. Menyimpan `get_time_scale()` lalu
  memulihkannya tepat (Night Watch x2 / final dawn 0 tetap aman).
- `SettingsPanel`: slider intensitas, toggle guncangan & petunjuk (dipakai
  PauseMenu dan tombol "Pengaturan" di MainMenu).
- `HelpPanel`: daftar kontrol statis, toggle **H**, tidak mem-pause.

## 14g. Peti — `ChestPanel`

`ChestPanel` (CanvasLayer 21) terbuka dari `Chest.interaction_requested`:
24 slot peti + cermin 12 slot tas, klik kanan memindahkan, tombol "Ambil semua".
Tutup dengan Esc/E, peti hancur, atau pemain > 120 px. Tidak mem-pause dan
mengunci toggle BagPanel selama terbuka.

## 14h. Petunjuk & HUD malam

- `HintManager`: satu hint sekaligus, 5 s, sekali per run, reset saat restart,
  mati bila `hints_enabled` false. Resource `src/data/hints/*.tres` dibuat oleh
  `tools/generate_hints.gd`.
- `RespawnRecapHUD`: toast 8 s "Debuff kematian: Kekuatan Lv 4 -> 3" atau
  "Tidak ada debuff"; `ProficiencyHUD` memerahkan baris 3 s.
- `NightBanner`: "Malam N dimulai" (+ "Ember Snuff aktif" dari malam 5) dan
  "Fajar hari N - kamu selamat dari malam N-1" 4 s; fajar dilewati saat rescue.
- `NightSurvivalHUD`: "Malam N | Bertahan mm:ss | Musuh X/Y" + progress bar,
  hanya malam. `TimeHUD.show_survival_label = false` di island agar tidak ganda.

### Pohon kecil — `small_tree` + `ChopFeedback`

`small_tree` (tangan kosong 4.0 s, 2 kayu, 3 fatigue; dengan kapak 2.0 s) ada 6 di
ring camp dan hilang permanen setelah hari 4. `ChopFeedback` hanya menempel pada
definisi dengan `chop_feedback_enabled`: goyang visual, serpihan tiap 0.25 s,
tumbang 85° / 0.6 s, tunggul sampai respawn, lalu tumbuh lagi 0.3 → 1.0 / 0.5 s.

### Susunan node baru Mission 7 (island)

```text
Island
├── SettingsService
├── PauseMenu (CanvasLayer 40)
│   ├── SettingsPanel
│   └── HelpPanel
├── HintManager
└── HUD CanvasLayer
    ├── ChestPanel (CanvasLayer 21)
    ├── NightBanner · NightSurvivalHUD · RespawnRecapHUD · ProficiencyHUD
    └── TimeHUD (show_survival_label = false)
```

## 15. Input Map

> Tabel lengkap dan tunggal ada di §22. Tabel lama di bawah dipertahankan
> sebagai riwayat; bila berbeda, §22 yang benar (semua action didaftarkan
> `InputSetup.ensure_actions()`, bukan `project.godot`).

**Sumber kebenaran:** sebagian besar action ada di `project.godot` bagian `[input]`,
jadi terlihat dan bisa diubah di **Project Settings → Input Map**. Action yang
ditambahkan setelah itu (`interact`, `debug_island_*`) didaftarkan
`InputSetup.ensure_actions()` saat runtime supaya `project.godot` tidak berubah;
idempotent, jadi tidak menimpa Project Settings.

**Aturan input (berlaku di seluruh proyek):** komponen gameplay **polling**
action Input (`Input.is_action_pressed()`, `Input.is_action_just_pressed()`,
`Input.get_vector()`) di dalam `_process`/tick dan **tidak** mencocokkan
`physical_keycode` sendiri. Panel UI seperti `BagPanel` boleh memakai
`_unhandled_input`, dan hanya untuk toggle/tutup. Tidak ada kode gameplay yang
memakai `_unhandled_input`.

| Action | Tombol | Dipakai |
|---|---|---|
| `move_left` / `move_right` / `move_up` / `move_down` | A/D/W/S + panah | `Player` |
| `sprint` | Shift | `Player` |
| `hotbar_1` … `hotbar_5` | 1–5 | `InventoryComponent` |
| `hotbar_next` / `hotbar_prev` | scroll bawah / atas | `HotbarSelectionComponent` |
| `use_held` | klik kanan / F | `HotbarSelectionComponent` |
| `inventory_toggle` | Tab / I | `BagPanel` (`_unhandled_input`) |
| `interact` | E (tahan) | `InteractorComponent` — didaftarkan `InputSetup` |
| `repair` | R (tahan) | `RepairComponent` — didaftarkan `InputSetup` |
| `debug_island_toggle` / `debug_island_zone` / `debug_island_morning` / `debug_island_kit` | F2 / F3 / F4 / F5 | `GatherDebug` (island only) — didaftarkan `InputSetup`; F5 memberi kit bahan uji crafting |
| `debug_island_boar` / `debug_island_deer` / `debug_island_night` / `debug_island_heal` / `debug_island_weapon` | F6 / F7 / F8 / F9 / F10 | `GatherDebug` (island only) — spawn Boar HOSTILE / Rusa 250 px di depan, lompat ke awal malam, heal penuh + needs, siklus senjata none→wooden→stone→bone |
| `attack_click` | Klik kiri | `CombatComponent` — ayunan manual ke arah kursor (diabaikan saat kursor di UI/BagPanel terbuka) |
| `attack_space` | Space | `CombatComponent` — ayunan manual ke arah `facing_direction` |
| `debug_island_kill` | F11 | `GatherDebug` — HP 0 untuk menguji death screen (island saja) |
| `debug_island_rescue` | F12 | `GatherDebug` — lompat fase sampai rescue/fajar Hari 7 (island saja) |
| `base_place` | B | `BasePlacementController` — masuk/keluar mode pendirian base (didaftarkan `InputSetup`) |
| `debug_fauna_labels` | Insert | `GatherDebug` — label temperament/HP fauna di atas kepala (island saja), termasuk tanda RAIDER/normal |
| `debug_raid` | J | `GatherDebug` — picu satu raid sekarang lewat `RaidDirector` (island saja) |
| `pause_toggle` | P | `PauseMenu` — buka/tutup pause (didaftarkan `InputSetup`) |
| `help_toggle` | H | `HelpPanel` — buka/tutup daftar kontrol (didaftarkan `InputSetup`) |
| `ui_cancel` (bawaan) | Esc | `BagPanel` — hanya menutup saat terbuka |
| `debug_needs_toggle` | F1 | `NeedsDebug` (practice only) |
| `debug_cycle_hunger` / `debug_cycle_thirst` / `debug_cycle_fatigue` | X / C / V | `NeedsDebug`, sandbox |
| `debug_refill_needs` | B | `NeedsDebug`, sandbox |
| `debug_eat` | M | `NeedsDebug` |
| `debug_str_up`/`debug_spd_up`/`debug_mas_up`/`debug_agi_up` | 1–4 | sandbox |
| `debug_str_down`/`debug_spd_down`/`debug_mas_down`/`debug_agi_down` | Ctrl + 1–4 | sandbox |
| `debug_toggle_zirah` · `debug_heal` · `debug_set_hp` · `debug_toggle_sprint` · `debug_reset` | Z · H · J · T · R | sandbox |

`InputSetup.ensure_actions()` masih boleh dipanggil di `_ready()` sebagai jaring
pengaman: fungsi ini hanya menambah action/tombol yang belum ada, jadi tidak
menduplikasi dan tidak menimpa Project Settings.

---

## 16. `SafeZone` — contoh area efek (practice only)

Area2D yang mengubah zoom kamera dan kecepatan pemain saat dimasuki. Contoh paling gampang untuk melihat cara kerja modifier.

Export: `phantom_camera`, `normal_zoom`, `safe_zone_zoom`, `zoom_duration`, `slow_multiplier`. Ini bukan sistem camp produksi.

---

## 17. Tes dan sandbox

### Uji manual Mission 7 (island)

1. **Pohon:** tebang `small_tree` dengan tangan (4 s) dan dengan kapak (2 s);
   lihat goyang, serpihan, tumbang, tunggul, lalu tumbuh lagi pagi berikutnya.
   Hitung kayu hari 1 (starter ring sekarang: 10 twig, 8 batu kecil, 6 pohon kecil).
2. **Suar:** bawa flare ke Beacon saat rescue; setelah Victory flare hilang dari tas.
3. **Batu api:** biarkan api padam, siapkan 1 batu; percobaan gagal memakai batu,
   sukses/batal tidak. Tanpa batu → "Butuh Batu".
4. **Pause:** P saat malam (Night Watch x2) dan saat final dawn (0); setelah
   lanjut, skala waktu kembali tepat.
5. **Settings:** ubah slider intensitas dan toggle guncangan; pukul boar dan
   rasakan perbedaannya. Matikan petunjuk → hint tidak muncul.
6. **Peti:** buka peti, klik kanan untuk memindahkan dua arah, "Ambil semua" dengan
   tas penuh, lalu menjauh > 120 px (panel menutup).
7. **Hint & HUD:** baca tiap hint sekali; awasi panel survival sepanjang malam,
   banner malam/fajar, recap debuff saat respawn, dan baris proficiency memerah.

### Uji manual Mission 6 (island)

1. **Siang:** boar tidak menyerang walau pemain berdiri di area camp (label Insert
   menunjukkan NEUTRAL); provokasi (klik) tetap membuatnya menyerang.
2. **Base:** tekan B → ghost mengikuti kursor; klik di darat jauh dari air → base
   berdiri, slot blueprint aktif. Klik di air/pantai → alasan blokir muncul.
3. **Pagar:** setelah base berdiri, ring pagar terbentuk; biarkan boar mengejar —
   ia berhenti di segmen, mengunyah, lalu menerobos saat segmen hancur. R memperbaiki.
4. **Api:** biarkan campfire mati, isi 2 wood (tetap COLD, prompt `Butuh Batu`),
   tahan E → 3 gebrakan batu dalam 1.1 s → api menyala.
5. **Juice:** pukul boar (hit-stop + shake + percikan), perhatikan garis merah dan
   `!` sebelum dash, dan animasi jasad saat boar mati.


**Jalankan unit test:**

```bash
D:\Programming\Gamedev\Godot_v4.7.2-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

Tes ada di `tests/unit/`: clock, stats, needs (termasuk override rest), inventory/item, bag panel, crafting panel, item slot store, interaction, resource node, island, resep, crafting, struktur camp, blueprint slot, campfire, repair, peti, tenda, jaga malam, camp controller, health, player damage receiver, knockback, combat, fauna base, wild boar, island deer, night scaling, fauna quota, night spawner, ember snuff, proficiency, death controller, loot bag, signal beacon, endgame, restart clock, serta seam hit modifier/idle-regen. Saat ini **386/386 tes unit lulus** (2178 assert); dengan integrasi total **393/393** (2327 assert). Tambah tes baru di folder yang sama dengan `extends GutTest`.

**Tes integrasi (scene `island.tscn`):**

```bash
D:\Programming\Gamedev\Godot_v4.7.2-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit,res://tests/integration -gexit
```

`tests/integration/island_harness.gd` (preload, tanpa `class_name`) menaruh `island.tscn` di tree, mengambil komponen aslinya (`Player`, `StatsComponent`, `NeedsComponent`, `InventoryComponent`, `InteractorComponent`, `CraftingComponent`, `RepairComponent`, `CombatComponent`, `ProficiencyComponent`, `CampController`, `FaunaQuota`, `NightSpawner`, `DeathController`, `EndgameController`, `Beacon`), lalu menggerakkan waktu lewat `clock.advance(dt)` + `tick(dt)` publik tiap node. Autoload: bila `/root/DayNightManager` sudah ada (normal saat GUT berjalan) harness memakainya dan memanggil `restart()`; bila tidak ada, harness membuatnya dari scene, menamainya `DayNightManager`, dan membebaskannya di `teardown()`. Tidak ada input keyboard yang disimulasikan.

| File | Cakupan |
|---|---|
| `test_island_wiring.gd` (S1) | 139 ResourceNode, 16 marker night spawn, 9 RiverEdge, 4 BlueprintSlot, EmergencySuitcase, SignalBeacon, tepat 1 node grup `player`, Interactor me-resolve stats/inventory/needs, Crafting/Repair menemukan inventory |
| `test_island_survival.gd` (S2) | Bangun 4 struktur lewat BlueprintSlot (biaya habis, terdaftar di CampController), gather pohon dengan kapak, craft `stone_axe` di Workbench, masak + makan daging di Campfire menyala, tidur di Tenda (skip_time, plafon Fatigue naik) |
| `test_island_night.gd` (S3) | NightSpawner >= 1 hostile dan <= max tabel (malam 1/4/7), boar jauh tidak raid, boar di camp menyerang struktur prioritas, Dazzled dekat Campfire, Ember Snuff hanya malam >= 5, aturan fajar <= 2 boar + rusa top-up 3 |
| `test_island_death.gd` (S4) | LootBag di lokasi mati, tas kosong, equipment tetap, debuff, respawn 70% HP + 60/60/80 + (0,64), token 1-3 respawn, kematian 4 `game_over`, clock tetap berjalan saat mati |
| `test_island_endgame.gd` (S5) | Beacon menolak sebelum rescue dan tanpa suar, victory sekali saat suar dipakai, rescue tetap aktif setelah mati + respawn |
| `test_island_soak.gd` (B2) | Simulasi 7 hari penuh langkah 0.5 s: tanpa NaN, needs 0-100, HP 0..max, hostile <= max tabel, struktur >= 0 HP, rescue tercapai, pertumbuhan node <= 20% |

**Sandbox manual** (`tests/sandbox/stats_sandbox.tscn`) untuk mencoba stat dan needs tanpa main game:

```bash
D:\Programming\Gamedev\Godot_v4.7.2-stable_win64.exe --path D:\Programming\Gamedev\gimersia-2026 res://tests/sandbox/stats_sandbox.tscn
```

Tombol sandbox juga action Input Map (`debug_*`), bukan keycode mentah.

| Tombol | Efek |
|---|---|
| `1` / `2` / `3` / `4` | +1 STR / SPD / MAS / AGI |
| `Ctrl + 1..4` | −1 level |
| `Z` | Toggle Zirah Kulit |
| `X` / `C` / `V` | Hunger / Thirst / Fatigue: 100 → 25 (LOW) → 0 (ZERO) → 100 |
| `B` | Isi semua needs ke 100 |
| `H` / `J` | Heal +20 / HP = 50 |
| `T` | Toggle `can_sprint` |
| `R` | Reset semua |

**Debug cepat di practice:** tekan **F1** (`debug_needs_toggle`) untuk mengaktifkan debug needs, lalu
`X` / `C` / `V` memutar Hunger / Thirst / Fatigue `100 → 25 (LOW) → 0 (ZERO) → 100`,
`B` mengisi semua ke 100 (plus plafon Fatigue), dan `M` meniru makan (plafon Fatigue
+10). Efeknya langsung terlihat di `StatsHUD` (attack, move speed, gather time, HP,
serta Fatigue `nilai / plafon`). Untuk melihat plafon turun: sprint sampai Fatigue
rendah, lalu `M` untuk menaikkannya lagi. Default mati supaya gameplay normal tidak
berubah; nodenya `NeedsDebug` di `practice1.tscn` (practice-only).

---

## 18. Wiring `practice1.tscn`

```text
world (Node2D)
├── ground (TileMapLayer)
├── Player (instance player.tscn, group "player")
│   ├── StatsComponent
│   ├── NeedsComponent
│   ├── InventoryComponent (12 slot; node 1-5 = hotbar)
│   └── InteractorComponent (hold E; range dari interaction_config.tres)
├── TileMapLayer
├── Camera2D
│   └── PhantomCameraHost
│       └── PhantomCamera2D (follow Player)
├── SafeZone (Area2D)
├── DayNightVisual (instance day_night_visual.tscn)
├── TimeHUD (CanvasLayer)
├── NeedsHUD (CanvasLayer)
├── StatsHUD (CanvasLayer)
├── HotbarHUD (CanvasLayer)
├── InteractionHUD (CanvasLayer: prompt + progress bar + alasan blokir)
├── BagPanel (CanvasLayer layer 20, tersembunyi; toggle Tab/I)
├── Pickups (Node2D)
│   ├── BerryPickup (ItemPickup, item = berry.tres, amount 2)
│   ├── CoconutPickup (ItemPickup)
│   ├── RawMeatPickup (ItemPickup)
│   ├── CookedMeatPickup (ItemPickup)
│   ├── BoneBrothPickup (ItemPickup)
│   ├── BoiledWaterPickup (ItemPickup)
│   └── HerbalBandagePickup (ItemPickup)
├── GatherDemo (Node2D: 4 ResourceNode contoh — twig, small rock, fiber bush, berry bush)
└── NeedsDebug (Node, practice-only: F1 + X/C/V/B/M)
```

`InventoryComponent` sengaja hanya ada di instance Player pada `practice1.tscn`, bukan di `player.tscn`, supaya `tests/sandbox/stats_sandbox.tscn` tetap bebas memakai tombol 1-4. Item contoh di `Pickups` bisa diambil dengan berjalan menimpanya, lalu dipakai dengan tombol 1-5.

---

## 19. Kalau menambah modul baru

1. Jangan membuat jam sendiri — baca `DayNightManager`.
2. Jangan menulis base stats — pakai `add_modifier()` dengan `source_id` yang jelas.
3. Jangan mengubah `Player` untuk tiap efek — panggil API publiknya.
4. Jangan mengubah sinyal lama — tambahkan sinyal baru.
5. Angka tuning masuk Resource/`.tres`, bukan konstanta tersebar.
6. Tes baru masuk `tests/unit/`, lalu jalankan GUT.

---

## 20. Kalau ada yang aneh

| Gejala | Penyebab biasanya |
|---|---|
| HUD Needs tidak muncul / bar diam | Player belum masuk grup `player`, atau node komponennya bukan bernama `NeedsComponent`. |
| Needs tidak turun | `DayNightManager` tidak ada di `/root`, atau `time_scale` sedang 0 (final dawn). |
| Sprint tidak bisa | Fatigue ≤ 25 (memang dikunci Needs). |
| Fatigue tidak pulih saat diam | Regenerasi diam memang +1.0/s (`fatigue_idle_regen`) dan berhenti di plafon. Kalau plafon sudah turun karena sprint, makan (`restore_fatigue_capacity()`) atau tidur untuk menaikkannya. |
| Fatigue turunnya lambat | Normal: jalan −0.08/s, sprint −2.5/s. Diam malah +1.0/s. Naikkan `fatigue_walk_drain` / `fatigue_sprint_drain` di `needs_config.gd` kalau kurang cepat. |
| Item tidak bisa dipakai dari hotbar | Player belum punya node `InventoryComponent`, atau slot 1-5 kosong. `HotbarHUD` hanya membaca; pemakaian lewat tombol 1-5. |
| Tab/I tidak membuka tas | `BagPanel` belum di-instance di scene, atau `InventoryComponent` tidak ada di bawah node grup `player`. Cek juga action `inventory_toggle` ada di Project Settings → Input Map. |
| `Could not find type "..."` setelah menambah script baru | Cache kelas belum diperbarui — jalankan `Godot_v4.7.2-stable_win64_console.exe --headless --import` sekali. |
| Tes gagal karena autoload | Jangan andalkan autoload di unit test: `preload` script dan buat instance sendiri. |

---

## 21. `Interactable` + `InteractorComponent` + `InteractionHUD` — hold E

**Gunanya:** satu kerangka interaksi untuk gather, loot, bangun, dan beacon.

`Interactable` (`src/components/interaction/interactable.gd`) adalah Node2D yang
otomatis masuk grup `interactable`. API yang di-override turunan:

| Method | Arti |
|---|---|
| `get_prompt(interactor) -> String` | teks prompt, mis. "Tahan E: Ranting" |
| `get_hold_time(interactor) -> float` | lama hold dalam detik nyata |
| `can_interact(interactor) -> bool` | boleh dimulai atau tidak (default true) |
| `get_block_reason(interactor) -> String` | alasan saat `can_interact` false |
| `interact(interactor) -> void` | dipanggil sekali saat progres penuh |

`InteractorComponent` dipasang sebagai anak Player (di **instance scene**, bukan
`player.tscn`). Ia memindai grup `interactable` tiap 0.1 s (`InteractionConfig`),
memilih target terdekat dalam `interaction_range` (default 64 px), menambah
progres dengan delta nyata (bukan time scale), dan memanggil `interact()` saat
`hold_time` tercapai. Lepas E, target hilang, atau keluar jangkauan → progres 0;
setelah selesai harus lepas lalu tekan lagi (tidak auto-chain). Sinyal:
`target_changed(target)`, `progress_changed(ratio)`,
`interaction_completed(target)`, `interaction_blocked(target, reason)`,
`interaction_cancelled(target)`. Helper: `cancel()`, `get_stats()`,
`get_inventory()`, `get_needs()`.

`InteractionHUD` hanya membaca sinyal itu: prompt, ProgressBar, dan pesan alasan
blokir. Tidak menyimpan state gameplay.

---

## 22. `ResourceNodeDefinition` + `ResourceNode` — gathering

Definisi ada di `src/data/gathering/*.tres` (8 file); angka tidak ditanam di
kode. Field: `id`, `display_name`, `item`, `yield_min`/`yield_max`,
`required_tool` {NONE, AXE, PICKAXE}, `gather_time`, `fatigue_cost`,
`respawn_rule` {DAILY, EVERY_OTHER_DAY, NEVER}.

| File | Item | Yield | Tool | Hold | Respawn |
|---|---|---|---|---|---|
| `twig` | wood | 1 | tangan | 1.0 s | DAILY |
| `tree` | wood | 3 | Stone Axe | 2.5 s | DAILY |
| `small_rock` | stone | 1 | tangan | 1.5 s | DAILY |
| `big_rock` | stone | 3 | Stone Pickaxe | 3.0 s | DAILY |
| `fiber_bush` | fiber | 2 | tangan | 1.0 s | DAILY |
| `berry_bush` | berry | 2 | tangan | 0.8 s | DAILY |
| `coconut_palm` | coconut | 1–2 | tangan | 1.2 s | EVERY_OTHER_DAY (ganjil, hari >= 3) |
| `bamboo_clump` | bamboo | 2 | tangan | 1.5 s | DAILY |

Semua memakai `fatigue_cost` 2.0 dibayar sekali lewat
`NeedsComponent.spend_fatigue()` (cap tidak disentuh) dan `add_or_drop()` ke tas.
`get_hold_time()` = `gather_time` x `StatsComponent.get_gather_time_factor()`.
Saat habis: node disembunyikan, keluar dari grup `interactable`, lalu mendengarkan
`DayNightManager.day_started(day)` (`clock` bisa di-inject untuk tes).
`last_respawn_day` > 0 mematikan node permanen setelah hari itu (starter Zone 1
memakai 4 → hilang pada hari 5). Sinyal `gathered(definition, amount, interactor)`
belum dipakai apa pun; hook untuk Proficiency nanti.

---

## 23. `IslandZones` + `IslandLayoutConfig` + `IslandBuilder` — pulau minimum

- `IslandZones.zone_at(pos)` → `CAMP` (jarak <= 800 dari 0,0), `SOUTH_BEACH`
  (y > 1400), `EAST_BEACH` (x > 1400, |y| <= 1400), `WEST_CLIFFS`
  (x < -1400, y <= 1400), `RIVER` (-1050..-850, |y| <= 1400), `FOREST`, atau
  `OUTSIDE` di luar kotak ±2400. Urutan ini bagian dari perilaku.
- `IslandLayoutConfig` (`src/data/configs/island_layout.tres`): `seed`, ukuran,
  `min_spacing` 70, `keep_out_radius` 140, `beacon_keep_out` 150, cincin camp
  220–700, jumlah node per zona, dan 16 marker malam.
- `IslandBuilder` mengisi zona dengan rejection sampling ber-seed (posisi harus
  di zona target, di luar keep-out spawn/wreckage/koper/beacon, dan berjarak
  >= `min_spacing`). `plan()` mengembalikan daftar entri tanpa SceneTree;
  `build()` men-spawn `ResourceNode` dan `Marker2D` (grup `night_spawn_point`).
  Marker hanya penanda — belum ada spawner.

---

## 24. Wiring `island.tscn`

```text
Island (Node2D, island.gd: pemain menghadap utara)
├── Ground (Polygon2D per zona: forest, south/east beach, west cliffs, river, camp)
├── Coastline (StaticBody2D: 4 CollisionShape2D di ±2450)
├── Wreckage (StaticBody2D di (0,-185))
├── Suitcase (EmergencySuitcase di (-48,40))
├── Beacon (SignalBeacon di (0,2100): hold E 1.5 s saat rescue + `signal_flare`)
├── RiverEdges (9 RiverEdge, x=-950, y -1400..1400 tiap 350)
├── Player (group "player", (0,64))
│   ├── InventoryComponent
│   ├── InteractorComponent
│   ├── CraftingComponent
│   ├── RepairComponent
│   ├── PlayerDamageReceiver
│   ├── CombatComponent
│   └── ProficiencyComponent
│   (StatsComponent/NeedsComponent berasal dari player.tscn)
├── Camera2D + PhantomCameraHost + PhantomCamera2D (follow Player, zoom 3)
├── IslandBuilder (layout = island_layout.tres)
├── CampController (4 blueprint slot + NightWatchController)
├── Fauna (Node2D: semua Boar/Rusa)
├── FaunaQuota (2 Boar + 3 Deer, aturan fajar/rescue)
├── NightSpawner (spawn + scaling saat night_started)
├── DeathController + DeathScreen (Respawn/Menu Utama)
├── RunController (request_restart / request_main_menu)
├── EndgameController + EndgameHUD (banner Hari 7, panah beacon, Victory + Mulai Baru/Menu Utama)
├── GameOverScreen (kematian ke-4: Mulai Baru/Menu Utama)
├── DayNightVisual
├── TimeHUD / NeedsHUD / StatsHUD / HotbarHUD / InteractionHUD / BagPanel
└── GatherDebug (F2 tools, F3 zona, F4 pagi, F5 kit, F6 Boar, F7 Rusa, F8 malam,
    F9 heal, F10 senjata)
```

`island.tscn` **bukan** main scene; `run/main_scene` tetap `practice1.tscn`.
Clock tidak diurus scene ini — `DayNightManager` autoload sudah `auto_start`,
sama seperti `practice1.tscn`.

---

## 25. `RecipeDefinition` + `CraftingComponent` — logika crafting

**Gunanya:** data resep + menjalankan satu craft pada satu waktu. Sudah dipasang
di `island.tscn` (node `CraftingComponent` di bawah Player) dan ditampilkan di
tab Crafting `BagPanel`.

**Data resep:** 13 file `.tres` di `src/data/recipes/`, dibuat lewat generator
(bukan ditulis tangan, supaya referensi item/uids benar):

```bash
godot --headless --path . -s tools/generate_recipes.gd
```

`RecipeDefinition`: `id`, `display_name`, `result`, `result_count`,
`ingredients` (`Array[ItemAmount]`), `station` {HAND, WORKBENCH, CAMPFIRE},
`craft_time`. `ItemAmount` (`src/data/resources/items/item_amount.gd`) hanya
`item` + `count`.

| Stasiun | Resep |
|---|---|
| HAND | Wooden Spear 3 wood + 2 fiber (2.0 s) · Torch 2 wood + 1 fiber (1.5 s) · Herbal Bandage 3 fiber + 2 berry (1.5 s) |
| WORKBENCH | Stone Axe 2 wood + 2 stone + 1 fiber (2.5 s) · Stone Pickaxe 2 wood + 3 stone + 1 fiber (2.5 s) · Stone Spear 1 Wooden Spear + 2 stone + 2 fiber (3.0 s) · Bone Spear 1 Wooden Spear + 2 bone + 2 fiber (3.0 s) · Leather Vest 3 hide + 3 fiber (3.0 s) · Waterskin 2 hide + 1 fiber (2.5 s) · Signal Flare 5 wood + 3 bone + 2 hide + 2 fiber (4.0 s) |
| CAMPFIRE (menyala) | Cooked Meat 1 raw meat (2.0 s) · Boiled Water 1 bamboo (2.0 s) · Bone Broth 2 bone + 1 raw meat (2.5 s) |

**Cara pakai:** tambahkan node `CraftingComponent` ke instance Player, di
scene (bukan `player.tscn`). Komponen mencari `InventoryComponent` dan
`StatsComponent` dari parent-nya.

```gdscript
var crafting := player.get_node("CraftingComponent") as CraftingComponent

crafting.get_available_recipes()   # Array[RecipeDefinition] yang stasiunnya ada
crafting.get_block_reason(recipe)  # "Butuh Workbench", "Bahan kurang", ...
crafting.can_craft(recipe)
crafting.start_craft(recipe)
crafting.cancel_craft("Batal")
crafting.tick(delta)               # _process sudah memanggil ini (delta nyata)
```

**Stasiun:** node di grup `crafting_station` dalam jarak `station_range`
(default 140 px) dari pemain, dengan properti `station_type`
(`RecipeDefinition.Station`) dan method `is_station_active() -> bool`.
HAND selalu tersedia; WORKBENCH butuh `station_type` WORKBENCH aktif;
CAMPFIRE butuh Campfire yang menyala.

**Aturan craft:**
- Satu craft pada satu waktu. Bahan dicek dan **dikonsumsi atomik saat selesai**.
- Bahan yang item-nya `equipment_slot == WEAPON` diambil dari slot WEAPON dan
  harus sama dengan senjata yang sedang dipasang (`unequip()` dipakai).
- Waktu = `craft_time` x `StatsComponent.get_craft_time_factor()`, memakai delta
  nyata (bukan jam game).
- Batal tanpa kehilangan bahan bila: tombol `move_*` ditekan, HP turun, atau
  stasiun keluar jangkauan / padam.
- Hasil WEAPON/ARMOR/TOOL dipasang lewat `equip()`; WEAPON hanya bila damage-nya
  lebih tinggi (kalau tidak: "Sudah punya senjata yang lebih baik"), TOOL hanya
  bila belum dimiliki ("Alat sudah dimiliki"), ARMOR hanya bila slot kosong
  ("Zirah sudah terpasang"). Hasil lain lewat `add_or_drop()`.

**Sinyal:** `craft_started(recipe)`, `craft_progress(ratio)`,
`craft_completed(recipe)`, `craft_cancelled(recipe, reason)`,
`crafted(recipe, count)` (dipakai `ProficiencyComponent` untuk XP craft), `stations_changed()`
(stasiun dalam jangkauan berubah; UI memakai ini untuk membuka/mengunci resep).

**Helper biaya bersama:** `ItemAmount.has_all(amounts, inventory)`,
`ItemAmount.consume_all(amounts, inventory)` (cek semua dulu, lalu refund bila
ada yang gagal), `without_weapon_slot(amounts)`, `weapon_slot_amounts(amounts)`.
Dipakai `CraftingComponent`, `BlueprintSlot._consume_cost()` dan
`RepairComponent._consume_cost()` — jangan menulis loop cek/konsumsi sendiri.

**Jangan:** menyimpan state craft di UI, atau memberi makan `crafted` dengan XP
sebelum sistem Proficiency ada.

---

## 26. Struktur camp — `StructureDefinition`, `CampStructure`, `BlueprintSlot`, `Campfire`, `Workbench`, repair

**Gunanya:** struktur camp yang bisa dibangun, dirusak, dan diperbaiki.
Struktur **non-blocking** (Node2D tanpa collision) dan hanya dibangun lewat slot
blueprint, bukan dirakit manual.

**Data:** 4 file `.tres` di `src/data/camp/`, dibuat lewat generator:

```bash
godot --headless --path . -s tools/generate_structures.gd
```

| id | posisi | HP | biaya bangun | waktu | aggro | repair -> HP |
|---|---|---:|---|---:|---:|---|
| `campfire` | (0,0) | 250 | 4 kayu + 3 batu + 2 serat | 2.5 s | 0 | 1 kayu + 1 batu -> +80 |
| `workbench` | (-96,-32) | 180 | 5 kayu + 2 batu + 3 serat | 3.0 s | 1 | 1 kayu + 1 serat -> +70 |
| `chest` | (96,-32) | 200 | 6 kayu + 2 serat | 2.5 s | 1 | 2 kayu -> +80 |
| `tent` | (0,-110) | 120 | 6 kayu + 6 serat + 2 bambu | 4.0 s | 2 | 1 kayu + 2 serat -> +60 |

`StructureDefinition`: `id`, `display_name`, `scene`, `max_hp`, `build_cost`,
`build_time`, `aggro_priority`, `repair_cost`, `repair_hp`, `slot_position`,
`get_build_cost_text()`, `get_repair_cost_text()`.

**`CampStructure`** (grup `camp_structure`): `take_damage(amount, source)`,
`repair(amount) -> float`, `is_damaged()`, `get_aggro_priority()`,
`get_hp_bar()`, `apply_definition()`, `get_definition()`, `get_display_name()`.
Sinyal: `damaged(amount, source)`, `repaired(amount)`, `destroyed`,
`hp_changed(current, max)`. HP bar hanya terlihat saat `current_hp < max_hp`.
HP 0 -> `destroyed` lalu `queue_free()`.

**`BlueprintSlot`** (`src/entities/camp/blueprint_slot.tscn`, extends
`Interactable`): isi `definition`, letakkan di posisi slot. Placeholder
transparan tampil saat kosong. Hold-E membangun (`build_time` x faktor waktu
craft), biaya dicek dulu lalu dikonsumsi; prompt
`"Bangun Api Unggun (4 Kayu, 3 Batu, 2 Serat)"`. `get_structure()`,
`is_built()`, sinyal `built(structure)`. Saat struktur hancur, placeholder
muncul lagi dan slot bisa dibangun ulang.

**`Campfire`** (`campfire.tscn`, juga stasiun `crafting_station`): mulai 240 s
bahan bakar, maks 600, drain 0.25/s siang dan 1.0/s malam x `get_time_scale()`.
Refuel lewat anak `CampfireRefuel` (hold E 0.5 s): 2 kayu -> +180 s, diblokir
`"Bahan bakar penuh"` mulai 580 dan `"Butuh 2 Kayu"` bila kayu kurang.
Menyala = `is_lit()`; cahaya 240 px, ember 80 px, `get_dazzle_radius()` 180 px
(getter saja). Saat menyala, pemain dalam 120 px mendapat regen diam 5/s lewat
`NeedsComponent.set_idle_regen_override(&"campfire", 5.0)` (dicek tiap 0.25 s,
dibersihkan saat keluar radius/api padam/hancur). Sinyal: `fuel_changed(seconds)`,
`lit_changed(is_lit)`, `fuel_depleted`. Tes memakai clock stub dan `set_fuel()`.

**`Workbench`** (`workbench.tscn`): stasiun WORKBENCH yang selalu aktif
(`is_station_active()` true) selama berdiri.

**`RepairComponent`** (anak instance Player): tahan **R** 1.0 s pada struktur
terdekat dalam 96 px. Biaya `repair_cost` dikonsumsi atomik saat selesai, lalu
`repair(repair_hp)`. Reset saat R dilepas atau keluar jangkauan. Alasan blokir:
`"Bahan kurang"`, `"Struktur sudah penuh"`. Sinyal `progress_changed(ratio)`,
`repair_completed(structure)`, `repair_blocked(structure, reason)`,
`target_changed(structure)`. `InteractionHUD` menampilkan
`"Tahan R: Perbaiki Api Unggun (1 Kayu, 1 Batu)"` + progress bar secara
additive (perilaku HUD lama tidak berubah).

**Jangan:** menaruh collision di struktur, menulis HP langsung (pakai
`take_damage()`/`repair()`), atau membuat jam sendiri untuk bahan bakar.

---

## 27. Peti, Tenda, Jaga Malam, dan `CampController`

### `ChestComponent` + `Chest` — penyimpanan 24 slot

`src/components/storage/chest_component.gd`, dipasang sebagai anak Peti.
Aturan stacking sama dengan tas (isi stack sama dulu, lalu slot kosong paling
kiri, urutan tidak diacak).

```gdscript
var chest := $ChestComponent as ChestComponent
chest.add_item(ItemCatalog.WOOD, 10)    # 0 = masuk semua; > 0 = sisa
chest.count_of(&"wood")
chest.move_to_bag(0, inventory)         # seluruh stack; sisa tetap di peti
chest.move_from_bag(inventory, 0)       # seluruh stack tas; sisa tetap di tas
```

API: `get_capacity()` (24), `get_slot(index)`, `get_slot_item()`, `get_slot_count()`,
`is_full()`, `is_empty()`, `count_of()`, `remove_item()` (atomik), `clear()`,
`get_slots()`; sinyal `slot_changed(index)`, `contents_changed()`.

`Chest` (`src/entities/camp/chest/chest.tscn`, extends `CampStructure`) punya
anak `Interact` dengan prompt **"Peti (24 slot)"**; panel UI belum ada (stretch).
Saat HP 0, setiap stack dijatuhkan sebagai `ItemPickup` di posisi peti.

### `Tent` + `TentConfig` — tidur siang

`src/entities/camp/tent/tent.tscn`. Hold **E** 1.5 s (`TentConfig.hold_time`,
nilai misi) saat siang. Syarat: `clock.is_day()`,
`get_remaining_seconds() > 60`, dan `>= 60` detik game sejak tidur terakhir
(`get_total_elapsed_seconds()`). Alasan blokir: `"Hanya bisa tidur di siang hari"`,
`"Waktu siang kurang dari 60 detik"`, `"Tenda masih perlu istirahat"`.

Saat berhasil Tenda hanya memanggil `clock.skip_time(45.0)` **sekali**;
drain Hunger/Thirst (minimal 1.0) dan plafon Fatigue +25 ditangani
`NeedsComponent` lewat `time_skipped` — jangan diduplikasi di Tenda.

### `NightWatchController` — Jaga Malam

`src/levels/camp/night_watch_controller.gd`, anak dari `CampController`
(di `camp_controller.tscn`). Malam + E di Tenda = nyalakan/matikan Jaga Malam.
Syarat mulai: malam (`"Hanya saat malam"`) dan ada Campfire menyala
(`"Butuh Api Unggun menyala"`). ON/OFF memanggil `clock.set_night_watch(true/false)`.

Berhenti otomatis saat: input `move_*` ditekan (`"Bergerak"`), Campfire
`fuel_depleted` atau hancur (`"Api padam"`), ada `camp_structure` yang menerima
damage (`"Struktur diserang"`), atau fajar/`night_ended` (`"Fajar"`); toggle
manual (`"Dimatikan"`). Sinyal: `watch_started`, `watch_stopped(reason)`.
Controller juga mengisi `Tent.night_watch` saat Tenda dibangun, sehingga prompt
Tenda berubah: `"Tahan E: Tidur"` (siang), `"Tahan E: Jaga Malam"` / `"Tahan E: Berhenti Jaga Malam"` (malam).

### `CampController` — registry struktur camp

`src/levels/camp/camp_controller.tscn`: Node2D + 4 `BlueprintSlot`
(campfire 0,0 · workbench -96,-32 · chest 96,-32 · tent 0,-110) +
`NightWatchController`.

```gdscript
camp.has_built(&"campfire")
camp.get_structure(&"workbench")          # CampStructure atau null
camp.get_structures()                     # Array[CampStructure]
camp.get_structures_by_priority()         # aggro 0 -> 1 -> 2 (untuk AI musuh)
```

Sinyal: `structure_built(id)`, `structure_destroyed(id)`. Registry otomatis
mengisi dan mengosongkan diri lewat slot blueprint dan sinyal `destroyed`.

**Jangan:** menyimpan HP/isi struktur di controller, atau menaruh state gameplay
di panel UI.

---

## 28. Combat, fauna, dan malam — `CombatComponent`, `FaunaBase`, `FaunaQuota`, `NightSpawner`

**Gunanya:** loop ancaman P1b. Terpasang di `island.tscn`: `PlayerDamageReceiver`
+ `CombatComponent` di bawah Player, `Fauna`, `FaunaQuota`, `NightSpawner`.

**CombatComponent** (anak Player; `tick(delta)` publik):

```gdscript
combat.get_attack_damage()      # senjata terpasang, atau 8 (tangan kosong)
combat.get_attack_range()       # 45 / 75 / 85
combat.swing_manual(aim_dir)    # ayunan manual; memprovokasi target
# sinyal: hit_dealt(target, damage), swing(aim_dir, hit_count), enemy_killed(target)
```

Aturan: auto-attack hanya menyentuh target `can_be_auto_targeted()` (HOSTILE atau
sudah diprovokasi); manual memakai kerucut 90° dan memprovokasi; cooldown dipakai
bersama, manual didahulukan; klik diabaikan saat kursor berada di Control atau
`BagPanel.is_open()`. Damage lewat `StatsComponent.get_attack_damage(weapon_damage)`,
range dari item WEAPON, Fatigue -1.2 per hit, Bone Spear menambah bleed.

**PlayerDamageReceiver** (anak Player): `receive_hit(raw, source, dir, distance)`
-> dodge roll (`dodged` + "DODGE!") atau damage `calc_incoming_damage()` +
knockback `Player.apply_knockback()`. HP 0 diabaikan musuh (kematian belum ada).

**FaunaBase** (`src/entities/fauna/fauna_base.gd`): grup `fauna`, layer 0 /
mask 1 (pemain bisa menembus hewan; hanya dinding yang menahan).

```gdscript
fauna.provoke(source)
fauna.can_be_auto_targeted()
fauna.apply_night_scaling(1.3, 1.3)   # rasio HP dijaga
fauna.set_speed_modifier(&"dazzle", 0.7)
fauna.begin_flee(player.global_position, 8.0)
```

**WildBoar** (`wild_boar.tscn`): gigit 12 dmg / 50 px / 1.2 s; dash 110-240 px,
0.8 s telegraf, 330 px/s, 20 ke pemain + knockback 60 px, 40 ke struktur;
cooldown dash 6 s siang / 4 s malam; siang NEUTRAL + leash 380 px, malam HOSTILE
deteksi 300 px; `raid_camp` aktif bila mendeteksi pemain di dekat camp atau
mengejar pemain masuk camp, batal > 650 px atau tanpa struktur.

**IslandDeer** (`island_deer.tscn`): 40 HP, selalu PASSIVE, kabur 175 px/s 5 s
saat pemain <= 130 px atau setelah dipukul; drop 2 raw meat + 1 hide.

**FaunaQuota**: 2 Boar + 3 Deer, tanpa respawn siang. `day_started(2..7)`:
lebih dari 2 Boar kabur, survivor NEUTRAL x1.0, top-up 2 Boar + 3 Deer.
`rescue_started`: sisanya kabur, jamin 2 Boar NEUTRAL, respawn 45 detik NYATA,
maksimal 4 (`guarantee_deer_at_rescue` sengaja OFF).

**NightSpawner**: `night_started` -> semua Boar HOSTILE + scaling malam itu, satu
spawn langsung, lalu tiap interval selama Boar HOSTILE < batas tabel. Timer =
delta x `get_time_scale()`.

**Ember Snuff**: `Campfire.remove_fuel(seconds)`; serangan sumber grup `fauna`
ke Campfire saat malam hari >= 5 juga memakan 8 detik bahan bakar.

**Jangan:** menulis HP fauna langsung, memakai physics query untuk menyerang,
atau menaruh state gameplay di HUD.

---

## 29. Proficiency, kematian, dan endgame — P1c + P2

**ProficiencyComponent** (anak Player, `tick(delta)` publik):

```gdscript
prof.add_xp(ProficiencyComponent.Prof.STRENGTH, 10.0, true)  # true = XP tempur (x1.5 malam)
prof.get_level(ProficiencyComponent.Prof.SPEED)
prof.get_xp_to_next_level(ProficiencyComponent.Prof.AGILITY)
prof.has_passive(ProficiencyComponent.Prof.STRENGTH, 3)
prof.apply_death_debuff()   # dipanggil DeathController
```

Level tetap ditulis ke `StatsComponent.strength_level` dkk. XP Speed memakai
perpindahan nyata per tick dan hanya di luar radius 180 px; teleport > 200 px
per tick diabaikan. Passive Heavy Strike/Swift Counter lewat
`CombatComponent.register_hit_modifier`; Second Wind lewat
`NeedsComponent.set_idle_regen_multiplier`; Quick Reflex menambah modifier
`&"prof_quick_reflex"` saat HP < 40%. Master Chef belum diterapkan
(`get_campfire_restore_bonus()` hanya menyediakan angkanya).

**DeathController** (`island.tscn`): `stats.hp_changed` -> HP 0:
`respawns_remaining -= 1`, seluruh tas jadi `LootBag` di posisi mati,
pemain disembunyikan + `PROCESS_MODE_DISABLED`. `respawn()` mengembalikan ke
(0, 64), 70% HP, 60/60/80 needs, lalu debuff. Kematian ke-4 -> `game_over`.
Clock TIDAK dipause. Sinyal: `died(respawns_remaining)`, `respawned`, `game_over`.

**DeathScreen** (CanvasLayer, `PROCESS_MODE_ALWAYS`): hanya UI, memancarkan
`respawn_requested` / `main_menu_requested`; `island.gd` yang menghubungkannya.

**EndgameController + SignalBeacon + EndgameHUD**: banner saat
`day_started(max_days)`, banner rescue saat `rescue_started`, panah arah/jarak ke
Beacon, dan Victory saat Beacon dipakai. Beacon (`Interactable`, hold 1.5 s) hanya
bisa dipakai saat `clock.rescue_triggered` dan `InventoryComponent` punya
`signal_flare` (tidak dikonsumsi).

**RunController / MainMenu**: `request_main_menu()` membekukan clock
(`set_time_scale(0.0)`), `request_restart()` memanggil `DayNightManager.restart()`.
Perubahan scene lewat `_change_scene()` yang bisa ditimpa tes.

**Debug island:** F11 = HP 0 (uji death screen), F12 = lompat ke rescue Hari 7.

**Jangan:** menghitung ulang efek per level di `ProficiencyComponent`, menulis
`current_hp` langsung, atau mem-pause SceneTree saat layar mati.

---

Status kesiapan MVP: `docs/editable/MVP_CHECKLIST.md` · Keputusan arsitektur: `docs/editable/architecture.md`

## 22. Tabel Input Map lengkap (satu-satunya)

> Arti tiap tombol ("Tab untuk apa, F2 untuk apa") ada di
> [`PANDUAN_INPUT.md`](PANDUAN_INPUT.md), yang dibuat dari Input Map hidup oleh
> `tools/generate_input_guide.gd`. Tabel di bawah hanya daftar tombol.

Semua action didaftarkan lewat `InputSetup.ensure_actions()`; tabel ini dibuat
dari InputMap yang hidup, jadi tidak boleh berbeda dengan kode.

| Action | Tombol |
| --- | --- |
| `attack_click` | Mouse 1 |
| `attack_space` | Space |
| `base_place` | B |
| `debug_agi_down` | 4 |
| `debug_agi_up` | 4 |
| `debug_asset_boxes` | Home |
| `debug_cycle_fatigue` | V |
| `debug_cycle_hunger` | X |
| `debug_cycle_thirst` | C |
| `debug_eat` | M |
| `debug_fauna_labels` | Insert |
| `debug_heal` | H |
| `debug_island_boar` | F6 |
| `debug_island_deer` | F7 |
| `debug_island_heal` | F9 |
| `debug_island_kill` | F11 |
| `debug_island_kit` | F5 |
| `debug_island_morning` | F4 |
| `debug_island_night` | F8 |
| `debug_island_rescue` | F12 |
| `debug_island_toggle` | F2 |
| `debug_island_weapon` | F10 |
| `debug_island_zone` | F3 |
| `debug_mas_down` | 3 |
| `debug_mas_up` | 3 |
| `debug_needs_toggle` | F1 |
| `debug_raid` | J |
| `debug_refill_needs` | B |
| `debug_reload_assets` | Backtick (`) |
| `debug_reset` | R |
| `debug_set_hp` | J |
| `debug_spd_down` | 2 |
| `debug_spd_up` | 2 |
| `debug_str_down` | 1 |
| `debug_str_up` | 1 |
| `debug_toggle_sprint` | T |
| `debug_toggle_zirah` | Z |
| `help_toggle` | H |
| `hotbar_1` | 1 |
| `hotbar_2` | 2 |
| `hotbar_3` | 3 |
| `hotbar_4` | 4 |
| `hotbar_5` | 5 |
| `hotbar_next` | Scroll bawah |
| `hotbar_prev` | Scroll atas |
| `use_held` | Klik kanan, F |
| `interact` | E |
| `inventory_toggle` | Tab, I |
| `move_down` | S, Down |
| `move_left` | A, Left |
| `move_right` | D, Right |
| `move_up` | W, Up |
| `pause_toggle` | P |
| `repair` | R |
| `sneak` | Ctrl (tahan) |
| `sprint` | Shift |

## 23. Sistem aset — `Assets`, `VisualSlot`, `UiSkin`, `AssetRegistry`

- **Pasang visual baru di kode** (satu baris di `_ready` entity):

```gdscript
VisualSlot.attach(self, &"campfire", [get_node_or_null("Visual"), get_node_or_null("Flame")], null, CampfireVisual.new())
```

  Placeholder tetap ada (hanya disembunyikan saat art ada), jadi tes lama dan
  kode feedback (`modulate`, `position`) tidak berubah. VisualSlot meniru
  transform placeholder pertama ke node art.

- **Tambah slot**: edit tabel di `tools/generate_asset_registry.gd`, lalu
  `GODOT --headless --path . -s tools/generate_asset_registry.gd`.
  Jangan mengedit `src/data/assets/asset_registry.tres` dengan tangan.
- **Cek file seni**: `GODOT --headless --path . -s tools/check_assets.gd`.
- **Tes**: `tests/unit/test_assets_core.gd`, `test_visual_slot.gd`,
  `test_visual_state_map.gd`, `test_visual_entities.gd`, `test_ui_skin.gd`.
- **Panduan seni**: `docs/editable/ASSET_GUIDE.md`; angka resource:
  `docs/editable/CONFIG_GUIDE.md`.

## 24. `StatusEffectsComponent` — efek berdurasi (regen HP)

`src/components/status/status_effects_component.gd`, child `Player` di
`island.tscn`. Mendengarkan `InventoryComponent.item_used`; item dengan
`consume_effect.regen_hp_per_second > 0` memulai efek ber-id item selama
`regen_duration`. Durasi memakai waktu game (`delta x clock.get_time_scale()`),
pemakaian ulang menyegarkan durasi (tidak menumpuk), dan efek berhenti saat
pemain mati (`DeathController.died`). `StatusEffectHUD` menampilkan
"Kaldu +1 HP/s 12s" (read-only).

## 25. Tabel tombol debug (satu-satunya)

| Tombol | Action | Fungsi |
| --- | --- | --- |
| Backtick (`) | `debug_reload_assets` | Muat ulang semua art tanpa restart (pindah dari F1: F1 dipakai `debug_needs_toggle` di practice) |
| J | `debug_raid` | Picu raid sekarang (island) |
| Home | `debug_asset_boxes` | Tampilkan kotak slot aset + toast cakupan |
| F2 | `debug_island_toggle` | Aktifkan/matikan GatherDebug |
| F3 | `debug_island_zone` | Zona berikutnya |
| F4 | `debug_island_morning` | Pagi berikutnya |
| F5 | `debug_island_kit` | Kit bahan crafting |
| F6/F7 | `debug_island_boar` / `debug_island_deer` | Spawn fauna |
| F8 | `debug_island_night` | Lompat ke malam |
| F9 | `debug_island_heal` | Heal pemain |
| F10 | `debug_island_weapon` | Siklus senjata |
| F11 | `debug_island_kill` | Matikan pemain |
| F12 | `debug_island_rescue` | Lompat ke fajar Hari 7 |
| Insert | `debug_fauna_labels` | Label temperament/state fauna |

## 25b. Balance pass 2 (Mission 9, fase 1-3) — aturan yang berubah

Enam perubahan perilaku. Semua angka hidup di `.tres` yang punya generator, jadi
tuning tidak perlu menyentuh kode.

| # | Perubahan | File angka | Tes |
| --- | --- | --- | --- |
| 1 | **Raid adalah event.** `RaidDirector` (node di `island.tscn`, bukan autoload) menjadwalkan raid per malam, memperingatkan `warning_seconds` lebih dulu (`RaidWarningHUD`: "Babi hutan mendekati base!"), menandai boar terdekat sebagai raider (`WildBoar.is_raider`), lalu melepas tanda itu saat raid selesai/fajar. Mode `EVENT_ONLY` = hostile malam hanya datang lewat raid; `ALWAYS`/`OFF` tetap tersedia untuk tes. | `src/data/configs/fauna/raid_config.tres` (`RaidConfig`) | `test_raid_director.gd` |
| 2 | **Cap populasi.** `NightSpawner.get_hostile_cap()` memakai `night_active_hostile_cap` (kosong = tabel spec lama). `FaunaQuota.get_day_boar_cap()/get_day_deer_cap()` membatasi boar/rusa siang. Cap hanya menahan **spawn baru**; boar yang sudah hostile tidak pernah dibunuh paksa. | sama (`RaidConfig`) | `test_night_spawner.gd`, `test_fauna_quota.gd` |
| 3 | **Babi punya massa.** Fauna dengan `blocks_player = true` masuk `PhysicsLayers.FAUNA_BODY`; pemain (`collision_mask` termasuk `FAUNA_BODY`) tidak bisa menembusnya. Dorongan saat dipukul memakai `move_and_collide()` (bukan `global_position +=`) dan diskalakan `knockback_resistance`. Rusa (`blocks_player = false`) tetap bisa ditembus. | `boar_config.gd`/`deer_config.gd` + `.tres` fauna | `test_boar_mass.gd`, `test_fauna_base.gd` |
| 4 | **Api unggun lahir COLD.** `CampfireConfig.start_lit = false`, `initial_fuel_seconds = 240`, `unlit_light_radius = 0`: bahan bakar tidak mengalir, cahaya mati sampai pernah dinyalakan (QTE `FireStarterController`). Hint `campfire_cold` muncul begitu ada unggun dingin. | `src/data/configs/campfire_config.tres` | `test_campfire_cold.gd` |
| 5 | **Kematian membekukan game.** `FreezeController` (grup `game_freeze`) membeku berbasis alasan (`&"pause"`, `&"death"`); `PauseMenu` memakainya bila ada. Skala waktu lama dipulihkan persis (termasuk x2 Jaga Malam dan 0 saat final dawn). | — | `test_freeze_controller.gd`, `test_island_death.gd` |
| 6 | **Perlindungan respawn + balans needs.** Setelah respawn pemain kebal 5 dtk nyata (kedip, tanpa damage/knockback, fauna berhenti mengejar), berakhir lebih awal bila pemain menyerang. Hunger/Thirst memakai multiplier 0.6/0.57 di atas drain spec; Hunger <= 30 mengunci sprint (`Player.add_sprint_block(&"hunger")`, hint `hunger_sprint_lock`); HP pulih lambat (`HealthRegenComponent`, jeda 6 dtk, skala min(Hunger, Thirst)). | `run_config.tres`, `needs_config.tres`, `health_regen_config.tres` | `test_needs_balance.gd`, `test_sprint_blocks.gd`, `test_health_regen.gd`, `test_respawn_protection.gd` |

Catatan wiring:

- Node baru di `island.tscn`: `RaidDirector`, `RaidWarningHUD`, `FreezeController`,
  `ProtectionHUD`, dan `HealthRegenComponent` (anak `Player`). Semuanya mencari
  dependensi lewat grup/`get_node_or_null`, jadi urutan `_ready` tidak penting.
- `WildBoar.set_raider(true)` itu satu-satunya cara menjadi raider; `get_raid_mode()`
  mengembalikan mode dari `RaidConfig`.
- Debug (island): `J` = picu raid sekarang, `` ` `` = muat ulang aset (F1 lama
  dipakai `debug_needs_toggle`).
- Fase 4 (sneak, waspada rusa, mengarungi sungai) ada di §25c. Fase 5-6
  (sweep matahari, tab Profil, SpriteFrames-first, data audio) **belum**
  dikerjakan.

## 25c. Fase 4 — jongkok, waspada rusa, air sungai

| Fitur | Cara kerja | Angka | Tes |
| --- | --- | --- | --- |
| **Jongkok (sneak)** | Tahan `Ctrl` (gamepad: klik stik kiri). Kecepatan x `speed_multiplier`, sprint diblokir lewat sumber `&"sneak"`, dan fauna mendeteksi pemain dari radius x `detection_multiplier`. `Player.set_sneaking()`, `is_sneaking()`, `get_stealth_multiplier()`, `get_move_speed_multiplier()` | `sneak_config.tres`: 0.55 kecepatan, 0.6 deteksi | `test_sneak.gd` |
| **Waspada rusa** | Rusa berhenti (`IslandDeer.State.ALERT`, sinyal `alerted`, art `idle`) saat pemain masuk radius waspada = radius kabur x `alert_radius_factor`, baru kabur bila masuk radius kabur. Radius kabur ikut mengecil saat pemain jongkok | `deer_config.gd`: `alert_radius_factor` 1.25, `alert_time` 0.45 dtk | `test_deer_alert.gd` |
| **Air sungai (wading)** | `WadingComponent` (anak `Player`) membaca `IslandZones.zone_at()`; di zona `RIVER` pemain diperlambat dan sprint diblokir (`&"wading"`). Berlaku juga untuk babi: `detect_radius` ikut dikali stealth | `wading_config.tres`: 0.55 kecepatan | `test_wading.gd` |
| **Tell visual** | `MotionTell` (anak `Player`) menulis label "JONGKOK" / "AIR" / "JONGKOK + AIR" di atas kepala pemain; rusa waspada memasang label "!" (`AlertMark`) yang hilang begitu rusa kabur atau pemain pergi. Label dibuat runtime (tanpa aset biner, tanpa state art baru), hanya membaca state | — | `test_sneak.gd`, `test_wading.gd`, `test_deer_alert.gd` |

Catatan:

- Satu sumber angka: `Player.sneak_config` dan `Player.wading_config` (default
  `preload` `.tres`). `WadingComponent` hanya melaporkan `set_wading()`, tidak
  menyimpan pengali.
- Radius deteksi fauna dibaca lewat `FaunaBase.get_detection_multiplier(target)`,
  jadi rusa dan babi memakai jalur yang sama.
- `sneak` + air bisa aktif bersama: 0.55 x 0.55 = 0.3025 kecepatan, dua sumber
  blokir sprint.
- Tidak ada state art baru (registry aset tidak berubah): waspada memakai `idle`,
  tell memakai `Label` runtime.
- Bukti lambat: `test_sneak.gd` mengukur velocity **dan** jarak tempuh nyata di
  frame fisika dengan input sungguhan (rasio 0.55), bukan hanya angka config.

## 26. Polish pass (Mission 9) — rasa, bukan aturan

Semua komponen di bawah **hanya membaca** state gameplay. Tidak ada hitbox,
angka balance, atau urutan tick yang berubah. Di headless (tes GUT) efek visual
otomatis no-op supaya deterministik.

| Komponen | File | Fungsi |
| --- | --- | --- |
| `ScreenFade` (const `preload`) | `src/ui/fx/screen_fade.gd` | Fade keluar sebelum ganti scene, fade masuk di `island`/`main_menu`, kilat putih saat Victory. Memakai callback (bukan `await`) agar `RunController._change_scene()` tetap sinkron dan bisa ditimpa tes. |
| `UiMotion` (const `preload`) | `src/ui/fx/ui_motion.gd` | `tween_bar()` untuk NeedsHUD, `pop_in()` untuk BagPanel/ChestPanel, `pop()` untuk slot hotbar. |
| `LowHpVignette` | `src/ui/fx/low_hp_vignette.gd` | Vignette merah berdenyut bila HP < `threshold_percent` (25%). Shader dibuat runtime; art `ui_vignette_low_hp` opsional. |
| `AmbientLife` | `src/levels/components/environment/ambient_life.gd` | Debu siang + kunang-kunang malam; mengikuti pemain, toggle lewat sinyal `day_started`/`night_started`. Tekstur titik dibuat runtime (tanpa biner). |
| `CameraFeel` | `src/components/camera/camera_feel.gd` | Look-ahead 11 px ke arah gerak (`follow_offset`) + zoom 3.0 siang / 2.75 malam. |
| `DeathFX` | `src/ui/fx/death_fx.gd` | Saat `DeathController.died`: slow-mo 0.25× selama 0.18 s + zoom 3.55, pulih otomatis saat HP > 0. **Dilewati bila setelan "Guncangan layar" dimatikan** (`is_slow_mo_enabled()`). |
| `VictoryFX` | `src/ui/fx/victory_fx.gd` | Saat `EndgameController.victory`: kilat putih + zoom 2.6. |
| `OpeningSequence` | `src/ui/hud/hints/opening_sequence.gd` | 3 prompt pembuka (gerak, gather, tas) yang **memakai saluran HintManager yang sama**; masuk **antrean prioritas** (`show_text(..., priority: true)`) sehingga hint gather/low-need tidak bisa memotong urutan intro; sekali per sesi. |
| `CampArrow` | `src/ui/hud/compass/camp_arrow.gd` | Penunjuk arah + jarak ke `CampAnchor` bila > 340 px; label di-anchor ke pojok kanan-atas viewport (bukan piksel tetap). |

Catatan integrasi:

- `HintManager` menambah `show_text(id, text, duration, priority)` dan `skip_current()`;
  teks bebas ikut antrean yang sama, satu hint pada satu waktu.
- Semua node sudah terpasang di `island.tscn` (`AmbientLife`, `CameraFeel`,
  `LowHpVignette`, `OpeningSequence`, `CampArrow`, `DeathFX`, `VictoryFX`);
  urutan `_ready` tidak penting karena tiap node mencari dependensinya sendiri.
- `SettingsService` menambah kunci `fullscreen` (disimpan di `user://settings.cfg`).
  Mode jendela diubah lewat `DisplayServer` saat runtime — `project.godot` tidak
  disentuh. Panel Pengaturan punya baris "Layar penuh".
- Gamepad (didaftarkan `InputSetup.ensure_actions()`, idempotent):

| Aksi | Gamepad |
| --- | --- |
| Gerak 8 arah | Stik kiri (`JOY_AXIS_LEFT_X/Y`) |
| Sprint | RB (`RIGHT_SHOULDER`) |
| Interaksi (tahan) | A |
| Serang | X |
| Tas | Y |
| Jeda | START |
| Hotbar 1–4 | D-pad atas/bawah/kiri/kanan |

- Pixel-snap 2D **tidak** diaktifkan: belum ada art pixel dan `project.godot`
  tidak boleh diubah di repo ini. Saat art masuk, aktifkan di project settings.

## 27. Feedback channel (Mission 10) — toast, angka damage, arah serangan

Tiga node baru di `island.tscn`, semuanya read-only dan disambungkan oleh
`island.gd::_wire_feedback_hud()`:

| Node | File | Sumber sinyal | Tampilan |
| --- | --- | --- | --- |
| `ToastHUD` (CanvasLayer 17) | `src/ui/hud/toast/toast_hud.gd` | `InventoryComponent.add_blocked`, `CraftingComponent.craft_cancelled`, `Campfire.fuel_depleted`/`fuel_changed` | Maks 3 baris di kiri-bawah, 2.8 s, fade 0.3 s; pesan identik beruntun di-dedupe 0.4 s |
| `DamageNumbers` (CanvasLayer 11) | `src/ui/hud/fx/damage_numbers.gd` | `CombatComponent.hit_dealt`, `enemy_killed` | Angka melayang 26 px selama 0.6 s; warna beda untuk damage >= 8; kill memakai penanda `KO` merah (bukan angka 0) |
| `HitDirection` (CanvasLayer 18) | `src/ui/hud/fx/hit_direction.gd` | `PlayerDamageReceiver.damaged` | Busur merah di tepi layar ke arah sumber, span ±0.5 rad, 0.65 s |

Pesan toast (bahasa Indonesia, di kode):

- `Tas penuh: <nama item> (sisa N)` — dari sinyal baru
  `InventoryComponent.add_blocked(item, remaining)`.
- `Crafting batal: <alasan>` — alasan datang dari `craft_cancelled`.
- `Api unggun padam — isi bahan bakar` — `fuel_depleted`.
- `Bahan bakar api hampir habis` — `fuel_changed <= 60` s, sekali per siklus
  (flag `toast_low_fuel` di meta campfire; reset saat fuel > 120).

Catatan:

- Campfire bisa lahir setelah blueprint dibangun, jadi `ToastHUD` menyambung
  lewat `SceneTree.node_added` (filter `has_signal("fuel_depleted")`) plus
  pemindaian awal.
- Angka damage diproyeksikan ke layar dengan
  `get_viewport().get_canvas_transform() * world_position`, jadi tetap benar
  saat kamera zoom 2.6–3.55.
- Tidak ada perubahan damage, hitbox, atau urutan tick; `test_feedback_hud.gd`
  menutup toast (cap/dedupe/expire), sinyal inventory penuh, angka damage, dan
  busur arah.

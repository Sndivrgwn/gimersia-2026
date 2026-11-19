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

`ItemCatalog` punya 22 konstanta (`WOOD`…`LEATHER_VEST`), array `ALL`, dan `get_by_id(id)`. Field `ItemDefinition`: `id`, `display_name`, `description`, `category` {RESOURCE, CONSUMABLE, WEAPON, TOOL, ARMOR, SPECIAL}, `max_stack`, `icon`, `consume_effect`, `equipment_slot` {NONE, WEAPON, TOOL, ARMOR}, `weapon_damage`, `weapon_range`, `armor_damage_reduction`, `armor_max_hp_bonus`. `ItemEffect`: `hunger`, `thirst`, `fatigue`, `hp`, `regen_hp_per_second`, `regen_duration`.

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

Tab **Tas**: grid 12 slot (`bag_slot.tscn`, minimal 64×64, slot 0-4 diberi nomor hotbar 1-5) plus kolom Peralatan read-only (Senjata, Alat = Kapak Batu/Beliung Batu yang dimiliki, Armor). Tab **Crafting** masih placeholder "Segera hadir"; crafting masuk Step 4.

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

## 15. Input Map — `project.godot`

**Sumber kebenaran:** sebagian besar action ada di `project.godot` bagian `[input]`,
jadi terlihat dan bisa diubah di **Project Settings → Input Map**. Action yang
ditambahkan setelah itu (`interact`, `debug_island_*`) didaftarkan
`InputSetup.ensure_actions()` saat runtime supaya `project.godot` tidak berubah;
idempotent, jadi tidak menimpa Project Settings. Kode gameplay tidak memakai
`_unhandled_input` dan tidak mencocokkan `physical_keycode` sendiri; cukup
polling `Input.is_action_just_pressed()` / `Input.get_vector()`.

| Action | Tombol | Dipakai |
|---|---|---|
| `move_left` / `move_right` / `move_up` / `move_down` | A/D/W/S + panah | `Player` |
| `sprint` | Shift | `Player` |
| `hotbar_1` … `hotbar_5` | 1–5 | `InventoryComponent` |
| `inventory_toggle` | Tab / I | `BagPanel` (`_unhandled_input`) |
| `interact` | E (tahan) | `InteractorComponent` — didaftarkan `InputSetup` |
| `debug_island_toggle` / `debug_island_zone` / `debug_island_morning` | F2 / F3 / F4 | `GatherDebug` (island only) — didaftarkan `InputSetup` |
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

**Jalankan unit test:**

```bash
D:\Programming\Gamedev\Godot_v4.7.2-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

Tes ada di `tests/unit/`: clock, stats, needs, inventory/item, bag panel, interaction, resource node, island. Saat ini **156/156 tes lulus** (1160 assert). Tambah tes baru di folder yang sama dengan `extends GutTest`.

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
├── Beacon (Node2D placeholder di (0,2100), tanpa logika)
├── RiverEdges (9 RiverEdge, x=-950, y -1400..1400 tiap 350)
├── Player (group "player", (0,64))
│   ├── InventoryComponent
│   └── InteractorComponent
├── Camera2D + PhantomCameraHost + PhantomCamera2D (follow Player, zoom 3)
├── IslandBuilder (layout = island_layout.tres)
├── DayNightVisual
├── TimeHUD / NeedsHUD / StatsHUD / HotbarHUD / InteractionHUD / BagPanel
└── GatherDebug (F2 tools, F3 zona berikutnya, F4 pagi berikutnya)
```

`island.tscn` **bukan** main scene; `run/main_scene` tetap `practice1.tscn`.
Clock tidak diurus scene ini — `DayNightManager` autoload sudah `auto_start`,
sama seperti `practice1.tscn`.

---

Status kesiapan MVP: `docs/editable/MVP_CHECKLIST.md` · Keputusan arsitektur: `docs/editable/architecture.md`

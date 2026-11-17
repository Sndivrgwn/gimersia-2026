# Panduan Menggunakan Modul — Gimersia 2026

Dokumen ini menjelaskan **cara memakai modul yang sudah ada di repo**, bukan merancang modul baru. Semua path, nama sinyal, dan nama fungsi mengikuti kode saat ini.

## Status modul

| Modul | File utama | Status | Dipakai oleh |
|---|---|---|---|
| `DayNightManager` (GameClock) | `src/core/managers/day_night_manager.gd/.tscn` | Ada; belum dijalankan | Autoload, `DayNightVisual`, `TimeHUD`, tes clock |
| `DayNightConfig` / `DayNightPeriod` | `src/data/resources/environment/` | Ada | `DayNightManager` |
| `DayNightVisual` / `DayNightVisualConfig` | `src/levels/components/environment/`, `src/data/resources/environment/` | Ada; belum dijalankan | `practice1.tscn` |
| `TimeHUD` | `src/ui/hud/time/` | Ada; belum dijalankan | `practice1.tscn` |
| `StatsComponent` / `StatModifier` | `src/components/stats/` | Ada; tes ditulis | `Player`, `SafeZone`, tes stats |
| `PlayerBaseStats` | `src/data/stats/player_base_stats.gd` | Ada | `StatsComponent` |
| `Player` | `src/entities/player/` | Ada; belum dijalankan | `practice1.tscn`, sandbox |
| `InputSetup` | `src/utils/input_setup.gd` | Ada | `Player`, sandbox |
| `SafeZone` | `scenes/practice/safe_zone.gd` | Ada; practice-only | `practice1.tscn` |
| Tes GUT | `tests/unit/` | Ditulis; GUT belum terpasang | — |
| Sandbox stats | `tests/sandbox/` | Ada; manual | — |

Modul yang **belum ada** dan tidak punya panduan karena belum ada kodenya: Hunger/Thirst/Fatigue, inventory/item, resource gathering, crafting, camp, combat, enemy AI, death/respawn, menu, audio, victory/FLARE. Jangan menganggap API-nya sudah tersedia.

---

## 1. `DayNightManager` — GameClock

### 1.1 Peran

`DayNightManager` adalah **satu-satunya sumber waktu game**. Ia menyimpan hari, fase, durasi fase, sisa waktu, status Night Watch, dan final dawn. Modul lain membaca getter atau mendengarkan sinyal; **jangan membuat timer waktu game sendiri**.

### 1.2 Pemasangan

Autoload sudah terdaftar di `project.godot`:

```ini
[autoload]
DayNightManager="*res://src/core/managers/day_night_manager.tscn"
```

Scene `day_night_manager.tscn` memakai `process_mode = 1` (PAUSABLE) dan memasang `debug_config`. Jangan menambahkan autoload kedua dengan nama berbeda.

Ambil referensi dari node biasa:

```gdscript
@onready var clock = get_node_or_null("/root/DayNightManager")

func _ready() -> void:
    if clock == null:
        push_warning("DayNightManager tidak ditemukan.")
        return
    clock.day_started.connect(_on_day_started)
    clock.dusk_started.connect(_on_dusk_started)
```

Di unit test, jangan bergantung pada autoload. Preload script-nya dan buat instance sendiri (lihat §9).

### 1.3 Konfigurasi

`DayNightManager` mengekspos:

```gdscript
@export var config: DayNightConfig
@export var debug_config: DayNightConfig
@export var use_debug_config: bool = false
@export var auto_start: bool = true
```

- `config` default: `src/data/configs/environment/day_night_default.tres`.
- `debug_config` default di scene: `day_night_debug_fast.tres` (60 detik), tetapi **`use_debug_config = false`**, jadi config default yang dipakai.
- **Penting:** `day_night_default.tres` saat ini `cycle_duration = 55.0`, bukan 600.0. Artinya game live berjalan 385 detik total, bukan 4200. Lihat `docs/MVP_CHECKLIST.md` bagian blocker.

### 1.4 Kontrol

| Fungsi | Kegunaan | Catatan |
|---|---|---|
| `start()` | Reset ke Hari 1 pagi dan mulai | Memancarkan `started`; mematikan Night Watch |
| `advance(delta)` | Tick manual memakai pengali waktu | Untuk tes/debug; bukan timer kedua |
| `skip_time(seconds)` | Maju waktu game mentah tanpa pengali | Untuk tidur Tenda; memancarkan `time_skipped` |
| `set_night_watch(active)` | Nyalakan/matikan Night Watch | Hanya berhasil saat malam |
| `set_time_scale(value)` | Override skala runtime | **Nilai negatif saat ini menjadi 0, bukan reset** (bug lama) |

Contoh Night Watch:

```gdscript
if clock.is_night() and not clock.rescue_triggered:
    clock.set_night_watch(true)
```

Contoh tidur Tenda 45 detik:

```gdscript
func try_sleep_in_tent() -> void:
    if clock == null or clock.is_night():
        return
    if clock.get_remaining_seconds() <= 60.0:
        return
    # skip_time memakai detik game mentah, tidak dikali Night Watch.
    clock.skip_time(45.0)
```

Modul kebutuhan (Hunger/Thirst/fuel) harus mendengarkan `time_skipped(seconds)` dan mengalikan drain-nya dengan nilai aktual tersebut, bukan mengulang timer sendiri.

### 1.5 Getter

| Getter | Hasil |
|---|---|
| `get_current_day()` / `current_day` | Hari saat ini (1..max) |
| `get_max_days()` | Total hari config (7 untuk MVP) |
| `get_phase()` / `current_phase` | `Phase.DAY` atau `Phase.NIGHT` |
| `is_day()` / `is_night()` | Cek fase |
| `get_phase_name()` | `"DAY"` / `"NIGHT"` |
| `get_phase_duration()` | Durasi fase saat ini (detik) |
| `get_phase_elapsed()` | Waktu berjalan di fase saat ini |
| `get_remaining_seconds()` | Sisa waktu fase (detik) |
| `get_remaining_text()` | Sisa waktu `"MM:SS"` |
| `get_phase_progress()` | Progres fase 0.0..1.0 |
| `get_total_elapsed_seconds()` | Total detik game sejak Hari 1 pagi |
| `get_day_duration(day = -1)` | Durasi siang hari tertentu (default: hari ini) |
| `get_night_duration(day = -1)` | Durasi malam hari tertentu |
| `get_day_ratio(day = -1)` | Rasio siang 0.0..1.0 |
| `get_time_scale()` | Pengali waktu efektif (0 saat final dawn, 2× saat Night Watch) |
| `is_night_watch_active()` | Status Night Watch |
| `get_config()` | `DayNightConfig` aktif |

Contoh HUD sederhana:

```gdscript
label.text = "Hari %d/%d — %s — %s" % [
    clock.get_current_day(),
    clock.get_max_days(),
    clock.get_phase_name(),
    clock.get_remaining_text(),
]
```

### 1.6 Sinyal

| Sinyal | Payload | Kapan |
|---|---|---|
| `started` | — | Setelah `start()` menyiapkan Hari 1 |
| `day_started` | `day: int` | Awal fase siang |
| `night_started` | `day: int` | Awal fase malam |
| `day_changed` | `day: int` | Saat hari berganti (bukan saat `start()` pertama) |
| `phase_changed` | `phase: int` | Setiap pergantian fase; **hanya satu argumen** |
| `time_updated` | `day, phase, remaining_seconds` | Saat detik tampilan berubah / final |
| `dusk_started` | `day: int` | Sisa siang <= 15 detik, sekali per hari |
| `night_ended` | `day: int` | Malam berakhir karena fajar atau final dawn |
| `time_scale_changed` | `scale: float` | Skala efektif berubah |
| `night_watch_changed` | `active: bool` | Night Watch nyala/mati |
| `time_skipped` | `seconds: float` | Setelah `skip_time()`; nilai aktual yang maju |
| `rescue_started` | — | Final dawn Hari 7; padanan `final_dawn_reached` |

Urutan penting:

```text
night_ended -> (day_changed) -> day_started -> phase_changed -> time_updated
dusk_started -> night_started -> phase_changed -> time_updated
night_ended -> time_updated(force) -> time_scale_changed(0) -> rescue_started
```

### 1.7 Jebakan yang harus diketahui

- `phase_changed` **tidak** membawa `day`. Jangan menghubungkan callback dua argumen ke sinyal ini; `DayNightVisual` memakai satu argumen.
- `_process` lama masih kehilangan overflow jika satu frame melewati lebih dari satu fase. `advance()`/`skip_time()` sudah benar; jangan menganggap `_process` setara untuk delta besar.
- `set_time_scale(-1)` tidak mereset ke config; saat ini menjadi 0.
- `get_time_scale()` mengembalikan 0 saat final dawn. Modul Hunger/Thirst harus memakai getter ini agar ikut berhenti.
- `start()` dari fase malam juga memancarkan `night_ended` untuk malam yang ditinggalkan. Jika listener tidak menginginkan event saat reset, perlu penanganan khusus.

---

## 2. `DayNightConfig` dan `DayNightPeriod`

### 2.1 Peran

- `DayNightConfig` menyimpan `max_days`, `cycle_duration`, `time_scale`, dan daftar `periods`.
- `DayNightPeriod` menyimpan rentang hari (`first_day`, `last_day`) dan `day_ratio` (porsi siang).

### 2.2 Membuat config baru

1. Klik kanan di `src/data/configs/environment/` → **New Resource** → `DayNightConfig`.
2. Isi `cycle_duration = 600.0`, `max_days = 7`, `time_scale = 1.0`.
3. Tambahkan tiga `DayNightPeriod` ke array `periods`:

| first_day | last_day | day_ratio | Hasil pada 600 dtk |
|---:|---:|---:|---|
| 1 | 3 | 0.5 | siang 300 / malam 300 |
| 4 | 5 | 0.4 | siang 240 / malam 360 |
| 6 | 7 | 0.3 | siang 180 / malam 420 |

4. Pasang resource ke `DayNightManager.config` (atau `debug_config` + `use_debug_config = true` untuk uji cepat).

### 2.3 API

```gdscript
config.get_period_for_day(day)   # DayNightPeriod atau null
config.get_day_ratio(day)        # 0.0..1.0; fallback 0.5 + warning
config.get_day_duration(day)     # cycle_duration * ratio
config.get_night_duration(day)   # cycle_duration - day_duration
```

Jangan menulis durasi 300/240/180 di script gameplay. Ubah resource.

---

## 3. `DayNightVisual` dan `DayNightVisualConfig`

### 3.1 Peran

`DayNightVisual` adalah bagian visual dari siklus. Fase gameplay tetap hanya `DAY`/`NIGHT`; visual menambahkan `MORNING`, `DAY`, `EVENING`, `NIGHT` untuk tint dan partikel. Ia tidak punya clock sendiri: transisi dipicu `phase_changed` dari manager.

### 3.2 Pemasangan

1. Instance `src/levels/components/environment/day_night_visual.tscn` sebagai child dunia (di `practice1.tscn` sudah ada).
2. Pastikan child `CanvasModulate` ada. Node ini adalah **satu-satunya penulis warna dunia**.
3. Pasang `DayNightVisualConfig` ke export `visual_config` (default `.tres` sudah terpasang).
4. Autoload `DayNightManager` harus ada; tanpa itu, visual menampilkan tint siang statis dan memberi warning.

### 3.3 Konfigurasi

`DayNightVisualConfig`:

- `transition_duration` (default 30 detik)
- `morning_color`, `day_color`, `evening_color`, `night_color`
- `morning_light_intensity`, `day_light_intensity`, `evening_light_intensity`, `night_light_intensity`
- `enable_environment_effects`, `enable_fireflies`, `firefly_amount`, `firefly_color`
- `enable_day_motes`, `day_mote_amount`, `day_mote_color`

Warna efektif = warna atmosfer × intensitas cahaya, dengan alpha 1.0.

### 3.4 API dan sinyal

```gdscript
visual.get_atmosphere()        # DayNightVisualConfig.Atmosphere.*
visual.get_atmosphere_name()   # "MORNING" / "DAY" / "EVENING" / "NIGHT"
visual.atmosphere_changed      # signal(atmosphere: int)
```

Contoh audio/ambience:

```gdscript
func _ready() -> void:
    $DayNightVisual.atmosphere_changed.connect(_on_atmosphere_changed)

func _on_atmosphere_changed(atmosphere: int) -> void:
    if atmosphere == DayNightVisualConfig.Atmosphere.NIGHT:
        start_night_ambience()
```

### 3.5 Catatan

- Jangan menambahkan `CanvasModulate` kedua untuk cahaya dunia; akan berebut properti yang sama.
- HUD berada di `CanvasLayer` terpisah agar tidak ikut digelapkan.
- Efek partikel mengikuti kamera jika `effects_follow_camera = true`.
- Visual ini reaktif; jangan memanggil `start()` atau `skip_time()` dari visual.

---

## 4. `TimeHUD`

### 4.1 Peran

HUD read-only untuk hari, fase, sisa waktu, progress bar, dan label Survival malam. Ia tidak menghitung waktu sendiri.

### 4.2 Pemasangan

1. Instance `src/ui/hud/time/time_hud.tscn` di scene (di `practice1.tscn` sudah ada).
2. Tidak perlu wiring manual: `_ready()` mencari `/root/DayNightManager`, menghubungkan `time_updated` dan `rescue_started`, lalu membaca `get_phase_progress()`.
3. Jika autoload tidak ada, HUD menampilkan placeholder `--` dan warning.

### 4.3 Kustomisasi

Node yang dipakai:

```text
TimeHUD (CanvasLayer, layer = 10)
└── Root/Panel/Margin/VBox/
    ├── DayLabel
    ├── PhaseLabel
    ├── RemainingLabel
    ├── PhaseProgress
    └── SurvivalLabel
```

- `SurvivalLabel` hanya terlihat saat malam dan menampilkan sisa waktu malam.
- `_on_rescue_started()` mengubah label menjadi `RESCUE`, `00:00`, dan progress 1.0.
- Jika mengganti struktur node, sesuaikan `@onready` path di `time_hud.gd`.

### 4.4 Catatan

- Jangan membuat timer terpisah untuk Survival Timer; label ini sudah mencerminkan sisa malam dari manager.
- Untuk HUD Hunger/Thirst/Fatigue, buat modul HUD terpisah dan jangan menaruh logika survival di HUD waktu.

---

## 5. `StatsComponent`, `StatModifier`, dan `PlayerBaseStats`

### 5.1 Peran

- `PlayerBaseStats` menyimpan angka dasar (HP, speed, attack, survival).
- `StatsComponent` menghitung nilai akhir dari base + proficiency + modifier, menyimpan HP, dan memancarkan sinyal.
- `StatModifier` adalah value object untuk satu baris modifier.

### 5.2 Pemasangan pada entity

Scene player sudah punya child:

```text
Player (CharacterBody2D)
├── CollisionShape2D
├── Visual (Polygon2D placeholder)
└── StatsComponent (Node, script stats_component.gd)
```

Akses:

```gdscript
@onready var stats: StatsComponent = $StatsComponent
```

`StatsComponent.base_stats` boleh dikosongkan; jika null, ia memakai `PlayerBaseStats.new()` dengan nilai default. Untuk tuning, buat `.tres` `PlayerBaseStats` dan pasang ke export tersebut.

### 5.3 Modifier

```gdscript
# +15 max HP dan +20% damage reduction, sebagai satu paket.
stats.add_modifier(&"zirah_kulit", &"max_hp", StatModifier.Kind.FLAT, 15.0)
stats.add_modifier(&"zirah_kulit", &"damage_reduction", StatModifier.Kind.PERCENT, 0.20)

# Hapus semua modifier dengan source_id tersebut.
stats.remove_modifier(&"zirah_kulit")
```

Aturan:

- `source_id` harus stabil dan unik per efek (contoh: `&"safe_zone"`, `&"lapar"`, `&"kelelahan_ekstrem"`).
- `FLAT` menambah nilai langsung; `PERCENT` menambah faktor pecahan (`-0.15` = -15%).
- Modifier dengan `source_id` sama dianggap satu paket dan dihapus bersama.
- Stat yang didukung: `max_hp`, `damage_reduction`, `move_speed`, `sprint_speed`, `attack_damage`, `attack_speed`, `dodge`, `craft_time`, `gather_time`, `sprint_fatigue_drain`.
- Stat tidak dikenal atau `kind` tidak valid akan menghasilkan warning dan diabaikan.

### 5.4 Getter penting

| Getter | Catatan |
|---|---|
| `get_max_hp()` | Base + Strength + FLAT max_hp |
| `get_move_speed()` | Base × (1 + Speed + PERCENT), floor `percent_modifier_floor` |
| `get_sprint_speed()` | Move speed × sprint multiplier; Light Footed di Speed >= 3 |
| `get_attack_damage(weapon_base = -1.0)` | Tanpa argumen memakai base; dengan senjata memakai faktor yang sama |
| `get_attack_speed()` / `get_attack_cooldown()` | Cooldown = 1 / speed |
| `get_dodge_chance()` | Additive, dibatasi `dodge_hard_cap` |
| `get_damage_reduction()` | Dibatasi `max_damage_reduction` |
| `get_craft_time_factor()` / `get_gather_time_factor()` | Faktor pengali waktu, bukan durasi absolut |
| `get_sprint_fatigue_drain_factor()` | Faktor pengurasan Fatigue saat sprint |
| `calc_incoming_damage(raw)` | `raw × (1 - damage_reduction)` |

### 5.5 HP

```gdscript
stats.set_hp(50.0)
stats.heal(20.0)
```

Gunakan `set_hp()`/`heal()`, jangan menulis `current_hp` langsung, agar clamp dan `hp_changed` tetap benar. Saat `max_hp` turun, HP otomatis di-clamp.

### 5.6 Sinyal

- `hp_changed(current: float, max_value: float)`
- `stats_changed()` — dipancarkan setiap level/modifier berubah.

Contoh HUD stats:

```gdscript
func _ready() -> void:
    stats.hp_changed.connect(_on_hp_changed)
    stats.stats_changed.connect(_refresh_all)

func _on_hp_changed(current: float, max_value: float) -> void:
    hp_bar.max_value = max_value
    hp_bar.value = current
```

### 5.7 Catatan

- Jangan menulis angka base di `Player` atau HUD; ubah `PlayerBaseStats`/modifier.
- `StatsComponent` belum punya XP/level-up; level proficiency di-set manual oleh sistem progression nanti.
- `PlayerBaseStats` sudah menyediakan `max_respawn_tokens`, `percent_modifier_floor`, `fatigue_sprint_threshold`, tetapi belum ada modul yang memakainya.

---

## 6. `Player`

### 6.1 Peran

Controller top-down berbasis `CharacterBody2D`. Player tidak menyimpan angka stat; semua kecepatan dibaca dari `StatsComponent`.

### 6.2 Node dan scene

`src/entities/player/player.tscn`:

```text
Player (CharacterBody2D)
├── CollisionShape2D
├── Visual (Polygon2D placeholder)
└── StatsComponent
```

Saat ditempatkan di map, tambahkan ke grup `player` (di `practice1.tscn` sudah):

```gdscript
# Pada instance Player di scene, set Groups = ["player"].
```

Grup ini diperlukan `SafeZone` dan kemungkinan modul lain nanti.

### 6.3 Kontrol

`InputSetup.ensure_actions()` dipanggil di `_ready()`. Action yang tersedia:

| Action | Keyboard |
|---|---|
| `move_up` | W / ↑ |
| `move_down` | S / ↓ |
| `move_left` | A / ← |
| `move_right` | D / → |
| `sprint` | Shift |

Movement memakai `Input.get_vector()`, `motion_mode = MOTION_MODE_FLOATING` (tanpa gravitasi), dan `move_and_slide()`.

### 6.4 Sprint

```gdscript
player.can_sprint = false   # kunci dari modul Fatigue saat nilai <= 25
player.can_sprint = true
```

`Player` memancarkan:

```gdscript
signal sprint_state_changed(is_sprinting: bool)
```

Contoh modul Fatigue:

```gdscript
func _on_fatigue_changed(value: float) -> void:
    player.can_sprint = value > 25.0
```

Jangan mengubah `velocity` langsung dari modul luar; gunakan modifier `move_speed` di `StatsComponent`.

### 6.5 Arah hadap

`facing_direction` menyimpan arah input terakhir yang tidak nol. Saat ini hanya dipakai untuk data; animasi/serangan belum ada.

### 6.6 Catatan

- Player belum punya attack, dodge, interaction, atau inventory.
- Jangan menambahkan `StatsComponent` kedua di scene yang sama.
- Kamera bukan bagian dari `player.tscn`; `practice1.tscn` menambahkan `Camera2D` + Phantom Camera.

---

## 7. `InputSetup`

### 7.1 Peran

Mendaftarkan action Input Map secara idempotent, sehingga scene bisa berjalan tanpa mengedit `project.godot` setiap kali.

### 7.2 Pemakaian

```gdscript
func _ready() -> void:
    InputSetup.ensure_actions()
```

Aman dipanggil dari banyak scene; action/event yang sudah ada tidak diduplikasi. Memakai `physical_keycode` agar layout keyboard berbeda tetap konsisten.

### 7.3 Menambah action

Tambahkan konstanta dan pemanggilan `_ensure_action`/`_ensure_key` di `input_setup.gd`. Jangan menulis `InputMap.add_action()` langsung di banyak tempat.

---

## 8. `SafeZone` (practice-only)

### 8.1 Peran

Contoh efek zona aman di `practice1.tscn`: memperlambat pemain dan mengubah zoom kamera saat masuk area.

### 8.2 Pemasangan

```text
SafeZone (Area2D, script safe_zone.gd)
├── CollisionShape2D
└── export phantom_camera -> PhantomCamera2D
```

Export:

- `phantom_camera: PhantomCamera2D`
- `normal_zoom: float = 1.0`
- `safe_zone_zoom: float = 2.5`
- `zoom_duration: float = 0.6`
- `slow_multiplier: float = 0.5`

Area memakai `body_entered`/`body_exited`; player harus berada di grup `player`.

### 8.3 Efek speed

Saat masuk:

```gdscript
player.stats.remove_modifier(&"safe_zone")
player.stats.add_modifier(
    &"safe_zone",
    &"move_speed",
    StatModifier.Kind.PERCENT,
    slow_multiplier - 1.0
)
```

Saat keluar, modifier `safe_zone` dihapus. Ini adalah pola yang benar untuk efek sementara: **jangan menimpa `move_speed` langsung**.

### 8.4 Catatan

- Ini bukan camp produksi; hanya practice.
- `print()` masih ada; hapus/ganti dengan logging yang sesuai saat dipakai di build.
- Kamera memakai Phantom Camera; jika addon tidak ada, `change_zoom()` kembali tanpa efek.

---

## 9. Tes dan Sandbox

### 9.1 GUT

Tes memakai **GUT 9.x**, `extends GutTest`.

| File | Isi |
|---|---|
| `tests/unit/test_stats_component.gd` | Base stats, proficiency, modifier, HP clamp, dodge cap |
| `tests/unit/test_game_clock.gd` | Durasi, carry-over, dusk, Night Watch, skip, final dawn, sinyal, teks waktu |

GUT **belum terpasang** di `addons/`. Setelah dipasang:

```bash
"C:\Path\To\Godot_v4.7.2-stable_win64.exe" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit
```

Atau jalankan lewat panel GUT di editor. Tes clock membuat config 600 sendiri, mematikan `auto_start`, memanggil `set_process(false)`, lalu `start()`.

### 9.2 Sandbox stats

`tests/sandbox/stats_sandbox.tscn` adalah scene manual:

| Tombol | Efek |
|---|---|
| `1`/`2`/`3`/`4` | +1 STR/SPD/MAS/AGI |
| `Ctrl + 1..4` | -1 level |
| `Z` | Toggle Zirah Kulit |
| `X` | Toggle Lapar |
| `C` | Toggle Kelelahan Ekstrem |
| `H` | Heal +20 |
| `J` | Set HP 50 |
| `T` | Toggle `can_sprint` |
| `R` | Reset |

Sandbox tidak bergantung pada autoload; ia membuat Player sendiri.

---

## 10. Referensi Wiring: `practice1.tscn`

```text
world (Node2D)
├── ground (TileMapLayer)
├── Player (instance player.tscn, group "player")
├── TileMapLayer
├── Camera2D
│   └── PhantomCameraHost
│       └── PhantomCamera2D (follow Player)
├── SafeZone (Area2D + safe_zone.gd)
├── DayNightVisual (instance day_night_visual.tscn)
└── TimeHUD (instance time_hud.tscn, CanvasLayer)
```

Urutan yang perlu dijaga:

1. Autoload `DayNightManager` aktif sebelum scene.
2. Player berada di grup `player` agar SafeZone bisa menemukannya.
3. `DayNightVisual` dan `TimeHUD` menemukan `/root/DayNightManager`.
4. Jangan menambahkan timer waktu game lain di scene.

---

## 11. Aturan Integrasi untuk Modul Berikutnya

Saat menambahkan Hunger/Thirst/Fatigue, inventory, combat, atau camp:

1. **Jangan menghitung waktu sendiri.** Dengarkan `time_updated` atau `time_skipped`, dan kalikan dengan `get_time_scale()` bila perlu.
2. **Jangan mengubah base stats langsung.** Gunakan `StatsComponent.add_modifier()` dengan `source_id` yang jelas.
3. **Jangan mengubah `Player` untuk setiap efek.** Modul efek memanggil API publik Player/Stats.
4. **Jangan menambah sinyal dengan mengubah sinyal lama.** Tambahkan sinyal baru; `phase_changed` satu argumen sudah dipakai.
5. **Jangan mengandalkan autoload di unit test.** Preload script dan buat instance.
6. **Letakkan angka tuning di `.tres`/Resource**, bukan di konstanta tersebar.
7. **Dokumentasikan modul baru di file ini** dan perbarui `docs/architecture.md` bila dependency berubah.

---

## 12. Verifikasi yang Belum Dilakukan

- Godot/GUT tidak tersedia di workspace ini; semua modul dan tes baru ditinjau statis, belum dijalankan.
- `practice1.tscn` belum diuji runtime setelah perubahan modul clock.
- Tes GUT belum dieksekusi karena addon belum terpasang.
- Config default masih 55 detik; gameplay live belum memakai 600 detik.
- `_process` overflow dan `set_time_scale(-1)` adalah bug yang diketahui dan belum diperbaiki.

Lihat `docs/MVP_CHECKLIST.md` untuk status kesiapan MVP dan `docs/architecture.md` untuk keputusan arsitektur.

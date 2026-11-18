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
| **Node / scene** | `Player`, `StatsComponent`, `NeedsComponent`, `DayNightVisual` | Instance scene-nya, atau tambahkan sebagai child node. |
| **HUD** | `TimeHUD`, `NeedsHUD` | Instance scene `.tscn`-nya di scene permainan. Selesai. |

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
```

**Dengar perubahannya:**

```gdscript
needs.value_changed.connect(func(need, value): print(need, " -> ", value))
needs.tier_changed.connect(func(need, tier): print(need, " tier ", tier))
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
- **Fatigue turun paling cepat saat sprint.** Hunger/Thirst turun pasif; Fatigue berkurang saat **sprint** (Shift + gerak, −2.5/s × faktor stat) dan **sedikit saat jalan biasa** (−0.08/s). Diam di tempat = Fatigue tidak turun. Semua angka ada di `needs_config.gd`; set `fatigue_walk_drain = 0.0` kalau mau sprint-only lagi.
- `time_skipped` (tidur) menguras Hunger/Thirst tapi tidak pernah di bawah 1.0.
- Sprint dikunci dengan menulis `player.can_sprint`; `velocity` dan base stats tidak disentuh.

---

## 7. `NeedsHUD` — bar Hunger/Thirst/Fatigue

**Cara pakai:** instance `src/ui/hud/needs/needs_hud.tscn` di scene. HUD mencari komponen lewat grup `player` → `NeedsComponent`, atau isi `@export needs_component` kalau mau eksplisit.

Warna normal di atas 25, warna peringatan saat LOW/ZERO. Read-only: tidak menulis nilai need.

---

## 8. `StatsComponent` + `PlayerBaseStats` — angka stat

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

## 9. `Player` — karakter

**Gunanya:** gerak top-down + sprint, semuanya membaca StatsComponent.

- `can_sprint` — boleh dikunci dari luar (Needs memakainya).
- `sprint_state_changed(is_sprinting)` — sinyal untuk modul yang peduli sprint.
- `facing_direction` — arah hadap terakhir.
- `stats` — referensi ke `StatsComponent`.

**Penting:** grup `player` dipasang di **scene pemakai**, bukan di `player.tscn`. Scene baru harus menambahkan `player.add_to_group(&"player")`.

---

## 10. `InputSetup` — Input Map

**Cara pakai:** `InputSetup.ensure_actions()` sekali di `_ready()`. Aman dipanggil berkali-kali. Mendaftarkan `move_up/down/left/right` dan `sprint`.

---

## 11. `SafeZone` — contoh area efek (practice only)

Area2D yang mengubah zoom kamera dan kecepatan pemain saat dimasuki. Contoh paling gampang untuk melihat cara kerja modifier.

Export: `phantom_camera`, `normal_zoom`, `safe_zone_zoom`, `zoom_duration`, `slow_multiplier`. Ini bukan sistem camp produksi.

---

## 12. Tes dan sandbox

**Jalankan unit test:**

```bash
D:\Programming\Gamedev\Godot_v4.7.2-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

Tes ada di `tests/unit/`: clock, stats, needs. Tambah tes baru di folder yang sama dengan `extends GutTest`.

**Sandbox manual** (`tests/sandbox/stats_sandbox.tscn`) untuk mencoba stat dan needs tanpa main game:

```bash
D:\Programming\Gamedev\Godot_v4.7.2-stable_win64.exe --path D:\Programming\Gamedev\gimersia-2026 res://tests/sandbox/stats_sandbox.tscn
```

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

**Debug cepat di practice:** tekan **F1** untuk mengaktifkan debug needs, lalu
`X` / `C` / `V` memutar Hunger / Thirst / Fatigue `100 → 25 (LOW) → 0 (ZERO) → 100`
dan `B` mengisi semua ke 100. Efeknya langsung terlihat di `StatsHUD` (attack, move
speed, gather time, HP). Default mati supaya gameplay normal tidak berubah; nodenya
`NeedsDebug` di `practice1.tscn` (practice-only).

---

## 13. Wiring `practice1.tscn`

```text
world (Node2D)
├── ground (TileMapLayer)
├── Player (instance player.tscn, group "player")
│   ├── StatsComponent
│   └── NeedsComponent
├── TileMapLayer
├── Camera2D
│   └── PhantomCameraHost
│       └── PhantomCamera2D (follow Player)
├── SafeZone (Area2D)
├── DayNightVisual (instance day_night_visual.tscn)
├── TimeHUD (CanvasLayer)
├── NeedsHUD (CanvasLayer)
├── StatsHUD (CanvasLayer)
└── NeedsDebug (Node, practice-only: F1 + X/C/V/B)
```

---

## 14. Kalau menambah modul baru

1. Jangan membuat jam sendiri — baca `DayNightManager`.
2. Jangan menulis base stats — pakai `add_modifier()` dengan `source_id` yang jelas.
3. Jangan mengubah `Player` untuk tiap efek — panggil API publiknya.
4. Jangan mengubah sinyal lama — tambahkan sinyal baru.
5. Angka tuning masuk Resource/`.tres`, bukan konstanta tersebar.
6. Tes baru masuk `tests/unit/`, lalu jalankan GUT.

---

## 15. Kalau ada yang aneh

| Gejala | Penyebab biasanya |
|---|---|
| HUD Needs tidak muncul / bar diam | Player belum masuk grup `player`, atau node komponennya bukan bernama `NeedsComponent`. |
| Needs tidak turun | `DayNightManager` tidak ada di `/root`, atau `time_scale` sedang 0 (final dawn). |
| Sprint tidak bisa | Fatigue ≤ 25 (memang dikunci Needs). |
| Fatigue turunnya lambat | Normal: jalan −0.08/s, sprint −2.5/s. Diam di tempat tidak menurunkan Fatigue. Naikkan `fatigue_walk_drain` / `fatigue_sprint_drain` di `needs_config.gd` kalau kurang cepat. |
| `Could not find type "..."` setelah menambah script baru | Cache kelas belum diperbarui — jalankan `Godot_v4.7.2-stable_win64_console.exe --headless --import` sekali. |
| Tes gagal karena autoload | Jangan andalkan autoload di unit test: `preload` script dan buat instance sendiri. |

---

Status kesiapan MVP: `docs/editable/MVP_CHECKLIST.md` · Keputusan arsitektur: `docs/editable/architecture.md`

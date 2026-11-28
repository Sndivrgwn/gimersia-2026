# Daftar Aset Audio yang Belum Ada

Dokumen ini mencatat cue dari [AUDIO_GUIDE.md](AUDIO_GUIDE.md) yang **belum memiliki aset asli** di folder `assets/audio/`.
Untuk daftar lengkap sistem audio dan **52 cue (+2 layer pantai) yang sudah terpasang dan aktif di game**, lihat [AUDIO_STATUS.md](AUDIO_STATUS.md).

> Spesifikasi teknis lengkap (format `.ogg` 44.1 kHz, mono/stereo, loudness, loop point) mengikuti [AUDIO_GUIDE.md](AUDIO_GUIDE.md).
> Begitu file `.ogg` ditaruh sesuai pola `AUDIO_GUIDE.md`, `AudioManager` akan langsung memuatnya otomatis tanpa perlu ubah kode untuk cue yang hook-nya sudah terhubung.

## Ringkasan

| Kategori | Total di Panduan | Sudah Terpasang | Belum Ada Aset Asli | Catatan |
| --- | :---: | :---: | :---: | --- |
| Musik (`music/`) | 7 | **3** *(sting)* | **4** *(loop)* + 2 upgrade | `music_death_sting`, `music_game_over`, `music_victory` sudah aktif pakai sting pendek |
| Ambience (`ambience/`) | 5 (+2 layer) | **3** (+2 layer) | **2** | Hutan, Pantai (`ocean+wind`), Malam, Sungai sudah aktif dengan crossfade |
| SFX (`sfx/`) | 80 | **35** | **45** | 12 cue fauna (`boar_*`, `deer_*`) sengaja dikosongkan dulu sampai ada aset asli |
| UI (`ui/`) | 12 | **11** | **1** | Semua UI sudah `.ogg`; hanya `ui_splash_sting` yang belum ada |
| **Total** | **104** | **52** *(+2 layer)* | **52** *(kosong)* | **12/12 Prioritas 1 sudah aktif** (3 di antaranya pakai pilihan sementara dari pack) |

---

## 1. Prioritas 1 (Sudah Aktif dengan Aset Pack — Opsional Upgrade ke Aset Asli)

Seluruh 12 cue Prioritas 1 sudah terpasang di [AUDIO_STATUS.md](AUDIO_STATUS.md). Tiga cue di bawah memakai pilihan dari asset pack yang saat ini sudah aktif di game dan dapat di-upgrade ke rekaman asli bila diinginkan:

| Status | Cue | Pola File | Durasi | Varian | Deskripsi | Terpasang Saat Ini |
| :---: | --- | --- | --- | :---: | --- | --- |
| [~] | `gathering_tree_fall` | `res://assets/audio/sfx/gathering_tree_fall[_1.._2].ogg` | 0.8-1.4 s | 2 | Pohon tumbang (spatial). Sinkron animasi jatuh 0.6 s. | `heavy-thud.ogg` (aktif) |
| [~] | `player_hurt` | `res://assets/audio/sfx/player_hurt[_1.._3].ogg` | 0.20-0.35 s | 3 | Pemain menerima damage (vokal/erangan pendek). | `punch.ogg` (aktif) |
| [~] | `player_death` | `res://assets/audio/sfx/player_death[_1.._2].ogg` | 0.8-1.2 s | 2 | Pemain kehabisan HP (dipisah dari sting musik kematian). | `body-fall.ogg` (aktif) |

---

## 2. Musik (4 Loop Belum Ada, 3 Sting Sudah Aktif)

Semua cue musik berformat stereo `.ogg` sekitar -18 LUFS.

| Status | Cue | Pola File | Prioritas | Loop | Durasi | Deskripsi & Catatan | Status Saat Ini |
| :---: | --- | --- | :---: | :---: | --- | --- | --- |
| [ ] | `music_menu` | `res://assets/audio/music/music_menu.ogg` | 2 (Penting) | ya | loop (60-120 s) | Musik menu utama; duck saat panel pengaturan. | Belum ada |
| [ ] | `music_day` | `res://assets/audio/music/music_day.ogg` | 2 (Penting) | ya | loop | Musik eksplorasi siang; tenang, dinamika rendah. | Belum ada |
| [ ] | `music_night_tension` | `res://assets/audio/music/music_night_tension.ogg` | 2 (Penting) | ya | loop | Musik ketegangan malam; naik intensitas saat raid aktif. | Belum ada |
| [ ] | `music_rescue` | `res://assets/audio/music/music_rescue.ogg` | 3 (Opsional) | ya | loop | Musik fase rescue (Hari 7). | Belum ada |
| [~] | `music_victory` | `res://assets/audio/music/music_victory.ogg` | 2 (Penting) | tidak | 8-12 s | Musik kemenangan saat rescue tercapai. | Aktif (`victory.ogg` sting) |
| [~] | `music_game_over` | `res://assets/audio/music/music_game_over.ogg` | 2 (Penting) | ya | loop | Musik game over saat token respawn habis. | Aktif (`game-over.ogg` sting) |
| [x] | `music_death_sting` | `res://assets/audio/music/music_death_sting.ogg` | 3 (Opsional) | tidak | 2-4 s | Sting menu respawn saat pemain tewas. | Aktif (`game-over.ogg`) |

---

## 3. Ambience (2/5 Belum Ada)

| Status | Cue | Pola File | Prioritas | Loop | Durasi | Deskripsi & Catatan |
| :---: | --- | --- | :---: | :---: | --- | --- |
| [ ] | `dawn_transition` | `res://assets/audio/ambience/dawn_transition.ogg` | 2 (Penting) | tidak | 3-5 s | Transisi menjelang fajar; menutup transisi visual fajar. |
| [ ] | `dusk_transition` | `res://assets/audio/ambience/dusk_transition.ogg` | 2 (Penting) | tidak | 3-5 s | Transisi menjelang malam; peringatan 15 s sebelum malam. |

---

## 4. SFX yang Belum Ada Aset Asli

### 4.1 Loop Proses & Status Pemain

| Status | Cue | Pola File | Prioritas | Spatial | Varian | Deskripsi & Catatan | Proxy Sementara |
| :---: | --- | --- | :---: | :---: | :---: | --- | --- |
| [ ] | `craft_loop` | `res://assets/audio/sfx/craft_loop.ogg` | 2 (Penting) | tidak | 1 | Suara proses crafting (seamless loop). | — |
| [ ] | `build_loop` | `res://assets/audio/sfx/build_loop.ogg` | 2 (Penting) | tidak | 1 | Proses membangun struktur saat menahan E. | — |
| [ ] | `repair_loop` | `res://assets/audio/sfx/repair_loop.ogg` | 2 (Penting) | tidak | 1 | Proses memperbaiki saat menahan R (boleh variasi dari `build_loop`). | — |
| [ ] | `campfire_ember_loop` | `res://assets/audio/sfx/campfire_ember_loop[_1.._2].ogg` | 2 (Penting) | ya | 2 | Loop bara api saat bahan bakar api unggun rendah (Bus: Ambience). | — |
| [ ] | `player_low_hp_loop` | `res://assets/audio/sfx/player_low_hp_loop.ogg` | 2 (Penting) | tidak | 1 | Detak jantung saat HP pemain di bawah ambang bahaya. | — |
| [ ] | `player_sprint_breath` | `res://assets/audio/sfx/player_sprint_breath[_1.._2].ogg` | 2 (Penting) | tidak | 2 | Napas pemain saat sprint; loop pendek, fade cepat. | — |
| [ ] | `player_protection_loop` | `res://assets/audio/sfx/player_protection_loop.ogg` | 3 (Opsional) | tidak | 1 | Dengung halus selama perlindungan respawn aktif. | `sfx/magic/magic-shield.ogg` |

### 4.2 Api Unggun, QTE Api & Memasak

| Status | Cue | Pola File | Prioritas | Spatial | Durasi | Varian | Deskripsi & Catatan | Proxy Sementara |
| :---: | --- | --- | :---: | :---: | --- | :---: | --- | --- |
| [ ] | `campfire_ignite` | `res://assets/audio/sfx/campfire_ignite[_1.._2].ogg` | 2 (Penting) | ya | 0.6-1.0 s | 2 | Percobaan menyalakan api unggun berhasil. | `sfx/magic/fireball.ogg` |
| [ ] | `campfire_out` | `res://assets/audio/sfx/campfire_out[_1.._2].ogg` | 2 (Penting) | ya | 0.5-0.8 s | 2 | Api unggun padam (desis padam). | — |
| [ ] | `campfire_refuel` | `res://assets/audio/sfx/campfire_refuel[_1.._2].ogg` | 2 (Penting) | ya | 0.3-0.5 s | 2 | Bunyi kayu masuk ke api unggun. | — |
| [ ] | `cook_sizzle` | `res://assets/audio/sfx/cook_sizzle[_1.._2].ogg` | 2 (Penting) | ya | 0.4-0.6 s | 2 | Mendesis saat memasak selesai di stasiun CAMPFIRE. | — |
| [ ] | `fire_flint_strike` | `res://assets/audio/sfx/fire_flint_strike[_1.._3].ogg` | 2 (Penting) | tidak | 0.10-0.20 s | 3 | Gesekan batu api pada QTE api. | `sfx/combat/sword-clash.ogg` |
| [ ] | `fire_qte_good` | `res://assets/audio/sfx/fire_qte_good[_1.._2].ogg` | 2 (Penting) | tidak | 0.15-0.25 s | 2 | Strike QTE masuk zona GOOD. | `sfx/interface/select.ogg` |
| [ ] | `fire_qte_perfect` | `res://assets/audio/sfx/fire_qte_perfect.ogg` | 2 (Penting) | tidak | 0.25-0.35 s | 1 | Strike QTE masuk zona PERFECT (lebih terang dari GOOD). | `sfx/interface/confirm.ogg` |
| [ ] | `fire_qte_miss` | `res://assets/audio/sfx/fire_qte_miss[_1.._2].ogg` | 2 (Penting) | tidak | 0.15-0.25 s | 2 | Strike QTE meleset (Bus: UI). | `sfx/interface/error.ogg` |

### 4.3 Gathering Spesifik

| Status | Cue | Pola File | Prioritas | Spatial | Durasi | Varian | Deskripsi & Catatan |
| :---: | --- | --- | :---: | :---: | --- | :---: | --- |
| [ ] | `gathering_pick_berry` | `res://assets/audio/sfx/gathering_pick_berry[_1.._2].ogg` | 2 (Penting) | ya | 0.2-0.3 s | 2 | Memetik buah beri (boleh satu keluarga bunyi dengan serat). |
| [ ] | `gathering_pick_fiber` | `res://assets/audio/sfx/gathering_pick_fiber[_1.._2].ogg` | 2 (Penting) | ya | 0.2-0.3 s | 2 | Memetik serat dari semak. |
| [ ] | `gathering_pick_coconut` | `res://assets/audio/sfx/gathering_pick_coconut[_1.._2].ogg` | 3 (Opsional) | ya | 0.3-0.5 s | 2 | Menurunkan kelapa (bunyi jatuh ke pasir). |
| [ ] | `gathering_cut_bambu` | `res://assets/audio/sfx/gathering_cut_bambu[_1.._2].ogg` | 3 (Opsional) | ya | 0.3-0.5 s | 2 | Memotong rumpun bambu (lebih berongga dari kayu). |

### 4.4 Fauna — Babi Hutan & Rusa (12 Cue)

Belum ada rekaman suara babi hutan maupun rusa asli. Folder `sfx/creatures/` hanya berisi suara monster/creature generik (`monster-growl.ogg`, `boss-roar.ogg`, `creature-squeak.ogg`, `zombie-groan.ogg`).

| Status | Cue | Pola File | Prioritas | Spatial | Durasi | Varian | Deskripsi & Catatan | Proxy Sementara |
| :---: | --- | --- | :---: | :---: | --- | :---: | --- | --- |
| [ ] | `boar_alert` | `res://assets/audio/sfx/boar_alert[_1.._2].ogg` | 2 (Penting) | ya | 0.3-0.5 s | 2 | Babi menyadari pemain dan mulai mengejar. | `sfx/creatures/monster-growl.ogg` |
| [ ] | `boar_telegraph` | `res://assets/audio/sfx/boar_telegraph[_1.._2].ogg` | 2 (Penting) | ya | 0.4-0.6 s | 2 | Awal `DASH_TELEGRAPH` (dengusan/kerukan sebelum seruduk). | `sfx/creatures/monster-growl.ogg` |
| [ ] | `boar_charge` | `res://assets/audio/sfx/boar_charge[_1.._2].ogg` | 2 (Penting) | ya | 0.4-0.7 s | 2 | Awal `DASH` menyeruduk. | `sfx/creatures/boss-roar.ogg` |
| [ ] | `boar_bite` | `res://assets/audio/sfx/boar_bite[_1.._3].ogg` | 2 (Penting) | ya | 0.20-0.30 s | 3 | Babi menggigit pemain atau struktur. | — |
| [ ] | `boar_hurt` | `res://assets/audio/sfx/boar_hurt[_1.._3].ogg` | 2 (Penting) | ya | 0.20-0.30 s | 3 | Babi menerima damage. | `sfx/creatures/creature-squeak.ogg` |
| [ ] | `boar_death` | `res://assets/audio/sfx/boar_death[_1.._2].ogg` | 2 (Penting) | ya | 0.6-1.0 s | 2 | HP babi habis. | `sfx/creatures/zombie-groan.ogg` |
| [ ] | `boar_idle` | `res://assets/audio/sfx/boar_idle[_1.._4].ogg` | 3 (Opsional) | ya | 0.3-0.5 s | 4 | Babi mendengus pelan saat mengembara. | — |
| [ ] | `deer_alert_snort` | `res://assets/audio/sfx/deer_alert_snort[_1.._2].ogg` | 2 (Penting) | ya | 0.25-0.40 s | 2 | Rusa mendengus waspada saat masuk state `ALERT`. | — |
| [ ] | `deer_hurt` | `res://assets/audio/sfx/deer_hurt[_1.._3].ogg` | 2 (Penting) | ya | 0.20-0.30 s | 3 | Rusa menerima damage. | `sfx/creatures/creature-squeak.ogg` |
| [ ] | `deer_death` | `res://assets/audio/sfx/deer_death[_1.._2].ogg` | 2 (Penting) | ya | 0.6-1.0 s | 2 | HP rusa habis. | — |
| [ ] | `deer_startle` | `res://assets/audio/sfx/deer_startle[_1.._2].ogg` | 3 (Opsional) | ya | 0.3-0.5 s | 2 | Rusa terpaku kaget (`STARTLE`). | — |
| [ ] | `deer_flee_steps` | `res://assets/audio/sfx/deer_flee_steps[_1.._3].ogg` | 3 (Opsional) | ya | 0.15-0.25 s | 3 | Langkah rusa kabur (`FLEE`). | `sfx/movement/steps-grass.ogg` |

### 4.5 Momen Siklus Hari, Raid & Endgame

| Status | Cue | Pola File | Prioritas | Spatial | Durasi | Varian | Deskripsi & Catatan | Proxy Sementara |
| :---: | --- | --- | :---: | :---: | --- | :---: | --- | --- |
| [ ] | `raid_warning_horn` | `res://assets/audio/sfx/raid_warning_horn[_1.._2].ogg` | 2 (Penting) | tidak | 1.0-1.6 s | 2 | Tanduk peringatan raid; harus terdengar di atas ambience malam. | `sfx/moments/alarm.ogg` |
| [ ] | `ship_horn` | `res://assets/audio/sfx/ship_horn.ogg` | 2 (Penting) | tidak | 2-3 s | 1 | Klakson kapal penyelamat saat victory. | — |
| [ ] | `dawn_sting` | `res://assets/audio/sfx/dawn_sting.ogg` | 2 (Penting) | tidak | 1.5-2.5 s | 1 | Sting pagi resmi dimulai. | — |
| [ ] | `night_start_sting` | `res://assets/audio/sfx/night_start_sting.ogg` | 2 (Penting) | tidak | 1.5-2.5 s | 1 | Sting malam resmi dimulai. | — |
| [ ] | `night_watch_start` | `res://assets/audio/sfx/night_watch_start[_1.._2].ogg` | 2 (Penting) | tidak | 0.4-0.6 s | 2 | Jaga Malam dinyalakan. | — |
| [ ] | `night_watch_stop` | `res://assets/audio/sfx/night_watch_stop[_1.._2].ogg` | 2 (Penting) | tidak | 0.3-0.5 s | 2 | Jaga Malam berhenti. | — |
| [ ] | `tent_sleep` | `res://assets/audio/sfx/tent_sleep[_1.._2].ogg` | 2 (Penting) | tidak | 0.8-1.2 s | 2 | Tidur di tenda (sebelum waktu di-skip). | — |

### 4.6 Player & Interaksi Lainnya

| Status | Cue | Pola File | Prioritas | Spatial | Durasi | Varian | Deskripsi & Catatan | Proxy Sementara |
| :---: | --- | --- | :---: | :---: | --- | :---: | --- | --- |
| [ ] | `player_sneak_step` | `res://assets/audio/sfx/player_sneak_step[_1.._3].ogg` | 2 (Penting) | ya | 0.10-0.20 s | 3 | Langkah sangat pelan saat jongkok. | `steps-grass.ogg` (volume rendah) |
| [ ] | `player_respawn` | `res://assets/audio/sfx/player_respawn[_1.._2].ogg` | 2 (Penting) | tidak | 0.5-0.8 s | 2 | Pemain hidup kembali setelah layar kematian ditutup. | `sfx/magic/heal.ogg` |
| [ ] | `player_kill_confirm` | `res://assets/audio/sfx/player_kill_confirm.ogg` | 2 (Penting) | tidak | 0.25-0.40 s | 1 | Konfirmasi hewan mati oleh serangan pemain. | `sfx/pickups/bonus.ogg` |
| [ ] | `player_hunger_warning` | `res://assets/audio/sfx/player_hunger_warning[_1.._2].ogg` | 2 (Penting) | tidak | 0.25-0.40 s | 2 | Peringatan lapar (Bus: UI). | `sfx/interface/warning.ogg` |
| [ ] | `player_thirst_warning` | `res://assets/audio/sfx/player_thirst_warning[_1.._2].ogg` | 2 (Penting) | tidak | 0.25-0.40 s | 2 | Peringatan haus (Bus: UI; nada beda dari lapar). | `sfx/interface/notification.ogg` |
| [ ] | `chest_close` | `res://assets/audio/sfx/chest_close[_1.._2].ogg` | 3 (Opsional) | tidak | 0.2-0.3 s | 2 | Panel peti ditutup (kebalikan `chest_open`). | `sfx/interface/menu-close.ogg` |

---

## 5. UI (1/12 Belum Ada)

| Status | Cue | Pola File | Prioritas | Durasi | Varian | Deskripsi & Catatan |
| :---: | --- | --- | :---: | --- | :---: | --- |
| [ ] | `ui_splash_sting` | `res://assets/audio/ui/ui_splash_sting.ogg` | 3 (Opsional) | 2 s | 1 | Sting singkat saat setiap logo muncul di layar pembuka. |

---

## 6. Catatan Tambahan: Varian `_1.._N`

Sebagian besar cue SFX yang **sudah ada** dari asset pack saat ini baru memiliki **1 file** (misalnya `steps-sand.ogg`, `steps-grass.ogg`, `axe-hit.ogg`, `sword-swing.ogg`), padahal [AUDIO_GUIDE.md](AUDIO_GUIDE.md) menyarankan 2–4 varian agar tidak terasa repetitif.

- **Solusi sementara:** `AudioManager` dapat menambahkan *pitch randomization* (misalnya `0.92`–`1.08`).
- **Solusi final:** Tambahkan varian `_2.._N` terutama untuk cue yang sangat sering terdengar (`player_footstep_sand`, `player_footstep_grass`, `gathering_chop_hit`, `player_attack_swing`, `player_hit_flesh`, `item_pickup`).

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

> **Status saat ini:** fondasi teknis (waktu, stats, movement, HUD siang-malam) sudah ada, tetapi loop survival inti belum. Game **belum dapat dimainkan dari awal sampai akhir**.

---

## 0. Ringkasan Kesiapan

| Area | Status | Catatan |
|---|---|---|
| Fondasi project & struktur | Sebagian besar ada | Godot 4.7.2, folder, scene practice, autoload |
| Kontrol & movement | Ada | Top-down, sprint, collision dasar |
| Stats & proficiency | Ada | Komponen + tes tertulis; belum ada XP/level-up |
| Siklus waktu | Ada | Manager, config, HUD, visual; config default 600 dtk |
| Survival needs | Sebagian | Komponen + HUD + 19 tes; konsumsi item, Campfire, dan Tenda belum |
| Inventory & gathering | Belum | Belum ada item, pickup, atau resource node |
| Crafting & camp | Belum | Belum ada resep, workbench, campfire, tenda |
| Combat & enemy | Belum | Belum ada attack, AI, spawn, scaling malam |
| Night survival loop | Belum | Timer malam ada di HUD, tetapi belum ada gelombang ancaman |
| Death & respawn | Belum | Belum ada death screen, drop item, debuff |
| Win condition | Belum | `rescue_started` ada, tetapi flare/victory belum |
| UI & audio final | Sebagian | HUD waktu ada; HUD needs, menu, audio belum |
| Build & playtest | Belum | Belum ada build/export yang diverifikasi |

---

## 1. Fondasi Teknis

- [x] Project Godot 4.7.2 dengan `project.godot` dan renderer GL Compatibility.
- [x] Struktur folder `src/core`, `src/components`, `src/data`, `src/entities`, `src/levels`, `src/ui`, `src/utils`, `tests`, `docs`.
- [x] Scene utama sementara: `scenes/practice/practice1.tscn`.
- [x] Autoload `DayNightManager` terdaftar di `project.godot`.
- [x] Input Map untuk `move_up`, `move_down`, `move_left`, `move_right`, `sprint`; didaftarkan idempotent oleh `InputSetup`.
- [x] Player top-down dengan `CharacterBody2D`, collision, dan `move_and_slide()`.
- [x] Sprint dengan kecepatan dari `StatsComponent`.
- [x] `StatsComponent`, `StatModifier`, dan `PlayerBaseStats` sebagai fondasi stat.
- [x] `DayNightManager` dengan config, sinyal, getter, Night Watch, `skip_time`, dan final dawn.
- [x] `DayNightVisual` dengan `CanvasModulate`, transisi warna, dan partikel.
- [x] `TimeHUD` read-only untuk hari, fase, sisa waktu, progress, dan label Survival.
- [x] `SafeZone` practice sebagai contoh modifier dan zoom kamera.
- [x] Tes GUT ditulis: `tests/unit/test_stats_component.gd`, `tests/unit/test_game_clock.gd`.
- [x] Sandbox manual stats: `tests/sandbox/stats_sandbox.tscn`.
- [x] GUT 9.7.1 terpasang di `addons/gut` dan tes benar-benar dijalankan.
- [x] Smoke test runtime `practice1.tscn` setelah semua perubahan clock.
  - Headless `--quit-after 120` selesai tanpa error (exit 0).
- [ ] Build/export Windows yang bisa dijalankan tanpa error penghambat.

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
- [ ] Audio peringatan senja.
- [ ] Integrasi waktu dengan Hunger/Thirst/fuel (Hunger/Thirst selesai; fuel menunggu Campfire).
- [ ] Survival Timer malam yang terhubung ke gelombang musuh (HUD saja belum cukup).

---

## 3. Player dan Kontrol

- [x] Movement 8 arah dengan keyboard dan collision.
- [x] Kamera top-down mengikuti pemain (Phantom Camera).
- [x] Sprint (Shift) dengan speed dari stats.
- [x] `can_sprint` dapat dikunci modul luar.
- [x] `facing_direction` menyimpan arah hadap terakhir.
- [ ] Animasi sprite/arah hadap.
- [ ] Attack otomatis dan cooldown.
- [ ] Dodge dengan i-frame.
- [ ] Interaksi dengan resource/objek (E).
- [ ] Inventory dan item yang dibawa.
- [ ] Respawn di camp.
- [ ] Efek debuff setelah respawn.

---

## 4. Stats dan Progression

- [x] Base stats: HP, move speed, sprint, attack damage/speed, dodge, damage reduction.
- [x] Proficiency STR/SPD/MAS/AGI dengan clamp 1..10.
- [x] Modifier FLAT/PERCENT additive dengan `source_id`.
- [x] HP clamp saat `max_hp` berubah; `hp_changed`.
- [x] Dodge hard cap dan damage reduction cap.
- [x] Faktor craft/gather/sprint fatigue.
- [ ] XP gain dari aktivitas (gather, craft, combat).
- [ ] Level-up otomatis dan batas XP.
- [ ] Passive ability yang terhubung ke level.
- [ ] Death debuff permanen dengan batas maksimal.
- [ ] Integrasi `max_respawn_tokens` dan `fatigue_sprint_threshold` ke gameplay.

---

## 5. Hunger, Thirst, dan Fatigue

- [x] Data hunger/thirst/fatigue dan nilai awal.
- [x] Laju pengurangan sesuai spesifikasi 3.A–3.C.
- [ ] HUD bar/ikon untuk ketiganya.
  - Bar, angka, dan warna peringatan ada di `src/ui/hud/needs/`, tetapi belum diverifikasi visual; ikon menyusul.
- [x] Efek status saat nilai rendah.
- [x] Sprint terkunci saat Fatigue <= 25.
- [ ] Rest di dekat Campfire menyala.
- [ ] Tidur di Tenda Daun: pulihkan Fatigue, `skip_time(45)`, cooldown, syarat sisa siang > 60 detik.
  - `time_skipped` dan clamp 1.0 sudah siap dan teruji; scene Tenda belum ada.
- [ ] Konsumsi makanan/minuman memulihkan nilai.
- [x] Integrasi `get_time_scale()` agar drain ikut 2× saat Night Watch dan 0 saat final dawn.
- [x] Clamp agar tidur tidak membunuh pemain (minimal 1.0).

---

## 6. Inventory dan Item

- [ ] Definisi item/data item.
- [ ] Inventory pemain dan kapasitas.
- [ ] Pickup resource ke inventory.
- [ ] UI inventory sederhana.
- [ ] Item drop di lokasi kematian.
- [ ] Pengambilan kembali item drop.
- [ ] Item Suar Darurat.
- [ ] Item makanan/minuman dan efeknya.
- [ ] Senjata/tools dasar (jika diperlukan MVP).

---

## 7. Resource Gathering

- [ ] Node resource yang bisa diinteraksi.
- [ ] Waktu gathering dan animasi/feedback.
- [ ] Respawn resource.
- [ ] Tool requirement (jika ada).
- [ ] Integrasi `get_gather_time_factor()`.
- [ ] Integrasi fatigue per aksi gathering.
- [ ] Resource masuk inventory.

---

## 8. Crafting dan Camp

- [ ] Resep hand-crafting MVP.
- [ ] Resep Workbench MVP.
- [ ] Resep Campfire MVP.
- [ ] UI crafting.
- [ ] Workbench sebagai struktur camp.
- [ ] Campfire dengan fuel dan radius cahaya.
- [ ] Tenda Daun dengan interaksi tidur.
- [ ] Peti camp.
- [ ] Tiang Suar di Pantai Selatan.
- [ ] Daya tahan struktur camp (destructible).
- [ ] Light debuff `Dazzled` untuk musuh di radius campfire.
- [ ] Ember Snuff malam 5–7.

---

## 9. Combat dan Enemy

- [ ] Auto-attack pemain.
- [ ] Damage, knockback, dan feedback hit.
- [ ] Dodge/i-frame.
- [ ] Satu jenis hewan liar MVP.
- [ ] AI berkeliaran, mendeteksi, mengejar, menyerang.
- [ ] Spawn musuh siang/malam.
- [ ] Scaling jumlah/stat malam berdasarkan hari.
- [ ] Target prioritas pemain vs struktur camp.
- [ ] Serangan ke Campfire/Workbench/Peti/Tenda.
- [ ] Dash Charge Babi Hutan dan damage 2× ke struktur.
- [ ] Bonus XP +50% untuk combat malam.
- [ ] Anti-softlock spawn 2 Babi Hutan setelah fajar Hari 7.

---

## 10. Night Survival Loop

- [ ] Survival Timer malam terhubung ke gameplay, bukan hanya label.
- [ ] Gelombang musuh malam.
- [ ] Peningkatan ancaman per hari.
- [ ] Pemain bisa bertahan sampai timer 00:00 tanpa wajib membunuh semua musuh.
- [ ] Fajar berikutnya reset ke hari baru.
- [ ] Kondisi gagal saat pemain mati di malam hari.
- [ ] Feedback audio/visual saat malam dimulai dan berakhir.

---

## 11. Death dan Respawn

- [ ] Deteksi kematian pemain.
- [ ] Layar kematian dengan pilihan **Respawn** dan **Main Menu**.
- [ ] Respawn mengembalikan pemain ke camp.
- [ ] Semua item yang dibawa jatuh di lokasi kematian.
- [ ] Item drop bisa diambil kembali.
- [ ] Debuff skill permanen setelah respawn.
- [ ] Batas maksimal debuff.
- [ ] Sisa kesempatan respawn (`max_respawn_tokens`).
- [ ] Edge case: mati saat timer Hari 7 00:00, respawn tetap mempertahankan kondisi fajar.

---

## 12. UI, Menu, dan Audio

- [x] HUD hari/fase/sisa waktu/progress.
- [x] Label Survival malam (mencerminkan sisa malam).
- [ ] HUD Hunger/Thirst/Fatigue.
  - Scene dan skrip ada; tampilan belum dicek secara visual.
- [ ] HUD inventory.
- [ ] HUD debuff setelah respawn.
- [ ] Indikator status siang/malam yang lebih lengkap.
- [ ] Menu utama dan navigasi.
- [ ] Pause menu.
- [ ] Layar kematian.
- [ ] Layar Victory.
- [ ] Audio ambience siang/malam.
- [ ] SFX langkah, gather, combat, hit, kematian, respawn.
- [ ] Audio peringatan senja.
- [ ] Mixing/volume balance.

---

## 13. Kondisi Menang dan Hari ke-7

- [ ] Banner pagi Hari 7.
- [ ] Gelombang maksimal malam Hari 7.
- [x] Final dawn membekukan waktu dan menghentikan Hunger/Thirst.
- [ ] Musuh malam ekstra kabur/despawn.
- [ ] Arrow pointer ke Tiang Suar.
- [ ] Item Suar Darurat di inventory.
- [ ] Interaksi tahan E 1.5 detik di Tiang Suar.
- [ ] Layar Victory setelah suar dinyalakan.
- [ ] Anti-softlock Babi Hutan (minimal 2 ekor, respawn terbatas).
- [ ] Tidak ada softlock jika pemain mati tepat saat 00:00.

---

## 14. Fitur Post-MVP (Jangan Dikerjakan Sebelum Inti Stabil)

- [ ] NPC penyintas.
- [ ] Spesialisasi NPC.
- [ ] NPC otomatis di camp.
- [ ] Variasi hewan liar.
- [ ] Area tambahan.
- [ ] Crafting/building di luar kebutuhan inti.

---

## 15. Gerbang Akhir MVP

Checklist ini mengikuti kriteria selesai di dokumen MVP. Semua harus tercentang sebelum build dianggap MVP.

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

## 16. Backlog per Divisi (Ringkas)

### Rafli — PM & Game Designer

- [ ] Finalisasi backlog MVP dan target mingguan.
- [ ] Kunci angka final: durasi siklus, laju needs, besaran efek.
- [ ] Finalisasi flow: start → siang → persiapan → malam → hari berikutnya → Hari 7 → rescue.
- [ ] Playtest dan catat bug/balance.
- [ ] Siapkan build final dan materi presentasi.

### Sandi — Main Programmer & Game Designer

- [x] Project, struktur folder, scene utama.
- [x] Kontrol karakter, movement, collision, kamera top-down.
- [x] Proficiency/stat dasar.
- [x] Siklus siang-malam dan HUD waktu.
- [ ] Interaksi resource dan inventory.
- [ ] Combat sederhana dan AI hewan.
- [ ] Item drop, death, respawn, debuff.
- [ ] Hunger, thirst, fatigue.
- [ ] Integrasi sistem inti dengan UI/audio/aset.

### Nun — Programmer & UI/UX

- [x] HUD waktu/hari dan indikator siang/malam.
- [ ] HUD hunger/thirst/fatigue.
- [ ] Menu utama dan navigasi.
- [ ] UI kematian (Respawn/Main Menu).
- [ ] UI inventory.
- [ ] UI feedback debuff.
- [ ] Survival Timer malam yang lengkap.
- [ ] Penyesuaian UI hasil playtest.

### Riyan — Programmer & Sound Engineer

- [ ] Daftar kebutuhan audio inti.
- [ ] Ambience siang/malam.
- [ ] SFX langkah, gather, interaksi, combat, serangan hewan.
- [ ] Audio feedback hunger/thirst/fatigue/kematian/respawn.
- [ ] Audio menu dan suasana pulau.
- [ ] Mixing dan volume balance.

### Wandi — Game Artist / 2D Artist

- [ ] Style visual konsisten.
- [ ] Sprite dan animasi dasar pemain.
- [ ] Tileset/aset pulau dan camp.
- [ ] Aset resource.
- [ ] Aset hewan liar MVP.
- [ ] Aset item drop dan objek interaksi.
- [ ] Ikon needs dan elemen HUD.
- [ ] Ekspor aset dengan ukuran/pivot/format konsisten.

---

## 17. Playtest Script Minimum

Jalankan setelah modul inti tersedia. Centang hanya jika seluruh langkah berhasil dalam satu sesi.

- [ ] Mulai game → Hari 1 siang, HUD menampilkan 05:00 (setelah config 600).
- [ ] Gerak 8 arah, sprint, dan collision berjalan.
- [ ] Stats berubah saat level/modifier diuji; HP clamp benar.
- [ ] Senja muncul di 15 detik terakhir; Night Watch 2×; `skip_time(45)` sesuai.
- [ ] Kumpulkan resource → masuk inventory → kembali ke camp.
- [ ] Craft item inti → gunakan → efeknya terlihat.
- [ ] Malam: Survival Timer berjalan, musuh menyerang, pemain bisa bertahan.
- [ ] Mati → item jatuh → pilih Respawn → kembali ke camp → ambil item → debuff terlihat.
- [ ] Hari 7: final dawn, flare, Victory.
- [ ] Tidak ada crash/softlock yang menghambat.

---

## 18. Blocker dan Keputusan yang Harus Diselesaikan

1. **[Selesai] Config default 600 detik.** `cycle_duration` bawaan script = 600 detik dan `day_night_default.tres` tidak lagi menimpanya; acceptance “rasio 5:5/4:6/3:7 dengan durasi 300/300” kini terpenuhi di game live.
2. **[Selesai] `_process` mempertahankan overflow multi-fase.** `_process` memakai carry-over loop; jalur `advance()`/`skip_time()` tetap memakai `_advance_game_seconds()`.
3. **[Selesai] `set_time_scale(-1)` reset ke config.** Nilai negatif mengembalikan `DayNightConfig.time_scale`; `0.0` tetap override nyata untuk freeze final dawn.
4. **`phase_changed` tidak membawa `day`.** Jangan ubah sinyal lama; tambahkan sinyal baru bila perlu.
5. **[Selesai] GUT 9.7.1 terpasang.** Tes clock/stats sudah dijalankan lewat GUT command line.
6. **[Sebagian] Modul inti belum lengkap.** Needs sudah ada (komponen + HUD + 19 tes); inventory, gather, craft, combat, enemy, death, menu, audio, victory belum.
7. **`get_time_scale()` berubah saat final dawn.** Modul survival harus memakai getter ini agar ikut berhenti.
8. **`SafeZone` masih practice-only.** Jangan anggap ini sistem camp produksi.

---

## 19. Urutan Prioritas yang Disarankan

1. **[Selesai] P0 — Fondasi yang menghambat verifikasi:** GUT 9.7.1 terpasang, tes dijalankan, config 600, `_process` carry-over, smoke test `practice1` headless bersih.
2. **[Sebagian] P1 — Loop survival minimum:** needs + HUD selesai; inventory + gathering, crafting/camp dasar, combat + satu hewan, night survival belum.
3. **P2 — Kematian dan akhir permainan:** death/respawn, item drop, debuff, Hari 7, flare, Victory.
4. **P3 — Polish:** menu, audio, animasi, balancing, playtest, build final.

---

## 20. Cara Merawat Checklist Ini

- Centang item hanya setelah kode **dan** verifikasi runtime/tes yang relevan selesai.
- Jika sebuah item hanya sebagian, biarkan `[ ]` dan tulis catatan “sebagian” di bawahnya.
- Setiap perubahan arsitektur/modul baru: perbarui `docs/editable/architecture.md` dan `docs/editable/PANDUAN_MODUL.md`.
- Setiap keputusan angka final: perbarui `.tres` dan checklist ini, jangan hanya mengubah kode.

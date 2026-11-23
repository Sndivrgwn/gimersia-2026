# Panduan Input (Input Map)

Dokumen ini menjawab satu pertanyaan: **tombol ini fungsinya apa?**

- Tabel di bawah DIBUAT dari Input Map yang hidup (`InputSetup.ensure_actions()`),
  jadi tombolnya tidak bisa berbeda dengan kode. Jangan edit bagian di antara
  penanda GENERATED: ubah `src/utils/input_setup.gd` (tombol) atau
  `PURPOSES` di `tools/generate_input_guide.gd` (fungsi), lalu jalankan
  `GODOT --headless --path . -s tools/generate_input_guide.gd`.
- Tombol memakai `physical_keycode`, jadi posisi tombol sama di keyboard
  QWERTY/AZERTY.
- Panel tas dibuka dengan Tab atau I. Di dalamnya ada tiga tab: **Tas**
  (12 slot + alat/weapon/armor), **Crafting** (resep tersedia dan terkunci), dan
  **Profisiensi** (level, XP, dan passive Kekuatan/Kecepatan/Penguasaan/Kelincahan).
- Menu Jeda dibuka dengan P (Esc juga menutupnya). Isinya Lanjutkan,
  Pengaturan, Bantuan, dan Menu Utama.
- Aksi `ui_cancel` adalah Esc bawaan Godot; dipakai untuk menutup panel.

<!-- BEGIN GENERATED: PANDUAN_INPUT -->

## Aksi permainan

Tombol yang dipakai pemain sehari-hari. Action ini didaftarkan `InputSetup.ensure_actions()` dan berlaku di semua scene.

| Action | Tombol | Fungsi |
| --- | --- | --- |
| `attack_click` | Mouse 1 | Serang ke arah kursor mouse. |
| `attack_space` | Space, Gamepad X | Serang ke arah hadap (gamepad: X). |
| `base_place` | B | Tentukan lokasi base saat fase penentuan base (sekali). |
| `help_toggle` | H | Buka/tutup panel bantuan (daftar kontrol dan alur main). |
| `hotbar_1` | 1, Gamepad D-pad atas | Pakai slot hotbar 1. |
| `hotbar_2` | 2, Gamepad D-pad bawah | Pakai slot hotbar 2. |
| `hotbar_3` | 3, Gamepad D-pad kiri | Pakai slot hotbar 3. |
| `hotbar_4` | 4, Gamepad D-pad kanan | Pakai slot hotbar 4. |
| `hotbar_5` | 5 | Pakai slot hotbar 5. |
| `interact` | E, Gamepad A | Tahan untuk memanen, membangun, membuka koper, minum di sungai, menyalakan api (QTE), dan interaksi lain. |
| `inventory_toggle` | Tab, I, Gamepad Y | Buka/tutup panel tas: Tab 1 (Tas + alat + tas), Tab 2 (Crafting), Tab 3 (Profisiensi). |
| `move_down` | S, Down, Stik kiri (atas/bawah) | Jalan ke bawah (S / panah bawah). |
| `move_left` | A, Left, Stik kiri (kiri/kanan) | Jalan ke kiri (A / panah kiri). |
| `move_right` | D, Right, Stik kiri (kiri/kanan) | Jalan ke kanan (D / panah kanan). |
| `move_up` | W, Up, Stik kiri (atas/bawah) | Jalan ke atas (W / panah atas). |
| `pause_toggle` | P, Gamepad Start | Buka/tutup menu Jeda (Lanjutkan, Pengaturan, Bantuan, Menu Utama). |
| `repair` | R | Tahan untuk memperbaiki struktur camp yang rusak. |
| `sneak` | Ctrl, Gamepad klik stik kiri | Tahan untuk jongkok: gerak 0.55x, deteksi fauna 0.6x, sprint terkunci. Label JONGKOK muncul di atas pemain. |
| `sprint` | Shift, Gamepad RB | Lari selama fatigue masih ada; dikunci saat Fatigue rendah, Hunger <= 30, jongkok, atau di air. |
| `ui_cancel` | — (belum ada tombol) | Tutup panel yang sedang terbuka (tas, peti, bantuan, jeda). |

## Debug pulau (`island.tscn`)

Hanya berguna di `island.tscn`; dipasang `GatherDebug` dan diabaikan di scene lain.

| Action | Tombol | Fungsi |
| --- | --- | --- |
| `debug_asset_boxes` | Home | Tampilkan kotak/garis bantu untuk setiap slot aset. |
| `debug_fauna_labels` | Insert | Tampilkan label temperament/state di atas setiap fauna. |
| `debug_island_boar` | F6 | Spawn babi hutan di dekat pemain. |
| `debug_island_deer` | F7 | Spawn rusa di dekat pemain. |
| `debug_island_heal` | F9 | Pulihkan HP pemain penuh. |
| `debug_island_kill` | F11 | Matikan pemain untuk menguji layar kematian dan perlindungan respawn. |
| `debug_island_kit` | F5 | Beri kit bahan crafting (kayu, batu, fiber, bambu, tulang, kulit, daging, beri). |
| `debug_island_morning` | F4 | Lompat ke pagi hari berikutnya. |
| `debug_island_night` | F8 | Lompat ke malam (uji raid dan Jaga Malam). |
| `debug_island_rescue` | F12 | Lompat ke fajar Hari 7 (urutan rescue/endgame). |
| `debug_island_toggle` | F2 | Aktifkan/matikan mode debug pulau (menampilkan status debug). |
| `debug_island_weapon` | F10 | Siklus senjata di tangan (tangan kosong, tombak, kapak, ...). |
| `debug_island_zone` | F3 | Teleport ke zona berikutnya (pantai, hutan, sungai, tebing). |
| `debug_raid` | J | Picu satu raid sekarang tanpa menunggu jadwal malam. |
| `debug_reload_assets` | QuoteLeft | Muat ulang semua art aset tanpa restart game. |

## Debug sandbox (`practice1.tscn`)

Hanya untuk sandbox `practice1.tscn` (didaftarkan `project.godot`), tidak ada di build pemain.

| Action | Tombol | Fungsi |
| --- | --- | --- |
| `debug_agi_down` | 4 | Turunkan Agility 1 level (sandbox). |
| `debug_agi_up` | 4 | Naikkan Agility 1 level (sandbox). |
| `debug_cycle_fatigue` | V | Putar nilai Fatigue (uji kunci sprint). |
| `debug_cycle_hunger` | X | Putar nilai Hunger (uji tier NORMAL/LOW/ZERO). |
| `debug_cycle_thirst` | C | Putar nilai Thirst (uji tier NORMAL/LOW/ZERO). |
| `debug_eat` | M | Makan item uji untuk memulihkan Hunger. |
| `debug_heal` | H | Pulihkan HP penuh (sandbox). |
| `debug_mas_down` | 3 | Turunkan Mastery 1 level (sandbox). |
| `debug_mas_up` | 3 | Naikkan Mastery 1 level (sandbox). |
| `debug_needs_toggle` | F1 | Tampilkan/sembunyikan HUD debug kebutuhan. |
| `debug_refill_needs` | B | Isi ulang Hunger/Thirst/Fatigue penuh. |
| `debug_reset` | R | Reset sandbox ke kondisi awal. |
| `debug_set_hp` | J | Set HP ke nilai uji berikutnya. |
| `debug_spd_down` | 2 | Turunkan Speed 1 level (sandbox). |
| `debug_spd_up` | 2 | Naikkan Speed 1 level (sandbox). |
| `debug_str_down` | 1 | Turunkan Strength 1 level (sandbox). |
| `debug_str_up` | 1 | Naikkan Strength 1 level (sandbox). |
| `debug_toggle_sprint` | T | Paksa mode sprint untuk uji drain fatigue. |
| `debug_toggle_zirah` | Z | Pasang/lepas zirah uji (damage reduction). |

<!-- END GENERATED -->

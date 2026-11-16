**MVP & DAFTAR PEKERJAAN**

RTRw Studio • Gimersia 2026

*Target pengembangan efektif: 2 minggu*

# **1\. Target MVP**

* Game dapat dimainkan dari awal hingga akhir dengan tujuan bertahan hidup selama 7 hari sampai tim penyelamat tiba.  
* Sudut pandang top-down; pemain mengendalikan karakter secara langsung pada siang dan malam.  
* Pemain dapat bergerak, menjelajah area pulau, mengumpulkan sumber daya, dan kembali ke camp.  
* Siklus siang-malam berjalan otomatis dengan perubahan rasio sesuai hari.  
* Malam menggunakan Survival Timer. Pemain harus bertahan sampai timer selesai; tidak wajib mengalahkan seluruh musuh.  
* Terdapat ancaman hewan liar yang lebih aktif dan berbahaya pada malam hari serta meningkat seiring hari.  
* Kebutuhan survival mencakup hunger, thirst, dan fatigue dengan indikator serta efek sederhana.  
* Camp menjadi hub aman untuk persiapan dan pengelolaan kebutuhan dasar, bukan objek tower defense.  
* Pemain dapat mati, memilih Respawn atau Main Menu, lalu respawn di camp.  
* Saat mati, seluruh item yang dibawa jatuh di lokasi kematian dan dapat diambil kembali.  
* Respawn memberikan pengurangan permanen pada skill tertentu; debuff memiliki batas maksimal.  
* Progression karakter berjalan melalui pengulangan aktivitas, tanpa menu upgrade statistik konvensional.  
* NPC menjadi target tambahan jika waktu cukup, bukan syarat MVP.

# **2\. Aturan Mekanisme**

## **Siklus Siang dan Malam**

* Hari 1–3: rasio siang : malam \= 5 : 5\.  
* Hari 4–5: rasio siang : malam \= 4 : 6\.  
* Hari 6–7: rasio siang : malam \= 3 : 7\.  
* Durasi total siklus belum ditetapkan; rasio diterapkan pada durasi total yang dipilih saat implementasi.

## **Death & Respawn**

* Menu setelah pemain mati: Respawn atau Main Menu.  
* Respawn mengembalikan pemain ke camp.  
* Semua item yang dibawa pemain jatuh di lokasi kematian dan dapat diambil kembali.  
* Skill tertentu mengalami pengurangan permanen dengan batas maksimal debuff.

## **Hunger, Thirst, dan Fatigue**

* Hunger dan thirst menjadi kebutuhan yang perlu dipantau pemain.  
* Fatigue merepresentasikan kelelahan akibat aktivitas.  
* Untuk MVP, gunakan indikator sederhana dan efek gameplay terbatas; hindari simulasi metabolisme atau penyakit kompleks.

## **Batasan Scope**

* Prioritaskan satu area pulau kecil, satu camp, dan jumlah jenis sumber daya terbatas.  
* Prioritaskan satu jenis hewan liar sebagai ancaman utama; variasi tambahan hanya jika waktu cukup.  
* Crafting dan pembangunan dibatasi pada kebutuhan inti loop survival.  
* NPC, variasi hewan, dan konten tambahan dikerjakan setelah fitur inti stabil.

# **3\. Daftar Pekerjaan per Divisi**

## **A. Rafli — Project Manager & Game Designer**

* Menyusun backlog tugas MVP dan membaginya menjadi target mingguan.  
* Menjaga scope agar fitur inti selesai sebelum fitur tambahan.  
* Mendokumentasikan aturan yang masih perlu angka final: durasi total siklus, laju hunger/thirst/fatigue, dan besaran efek status.  
* Membuat flow gameplay: mulai permainan → siang → persiapan → malam → hari berikutnya → hari ke-7 → penyelamatan.  
* Menentukan kebutuhan minimum tiap fitur bersama programmer dan artist.  
* Memantau progres harian, dependensi, kendala, dan integrasi antaranggota.  
* Melakukan playtest, mencatat bug/masalah balance, dan menentukan prioritas perbaikan.  
* Menyiapkan build final serta materi penjelasan/presentasi game.

**TARGET AKHIR:** Backlog dan aturan MVP terdokumentasi; seluruh fitur inti terintegrasi; build dapat dimainkan dari awal sampai akhir.

## **B. Sandi — Main Programmer & Game Designer**

* Menyiapkan project game, struktur folder, dan scene utama. (github & godot)  
* Mengimplementasikan kontrol karakter, pergerakan, collision, dan kamera top-down.  
* Membangun interaksi dasar untuk mengambil sumber daya.  
* Mengimplementasikan proficiency character (kekuatan, kecepatan, kemahiran, ketangkasan)  
* Mengimplementasikan combat sederhana untuk menghadapi hewan liar. (attack otomatis, karakter kita gerakin)  
* Mengimplementasikan perilaku dasar hewan: berkeliaran, mendeteksi pemain, mengejar/menyerang, dan lebih aktif pada malam hari.  
* Mengimplementasikan sistem item yang dibawa pemain serta item drop di lokasi kematian.  
* Mengimplementasikan alur kematian dan respawn ke camp, termasuk pemanggilan efek debuff skill.  
* Mengimplementasikan sistem hunger, thirst dan fatigue  
* Mengintegrasikan sistem inti dengan UI, audio, dan aset anggota lain.

**TARGET AKHIR:** Prototype gameplay utama berjalan: karakter, eksplorasi, pengumpulan, combat, musuh, death/respawn, dan integrasi sistem.

## **C. Nun — Programmer & UI/UX Designer**

* Membuat HUD hunger, thirst, fatigue, waktu/hari, dan Survival Timer.  
* Membuat UI menu utama dan navigasi dasar.  
* Membuat indikator status siang/malam dan hari ke-1 sampai hari ke-7.  
* Membuat UI kematian dengan pilihan Respawn dan Main Menu.  
* Membuat inventori sederhana untuk item yang dibawa pemain.  
* Mengimplementasikan sistem waktu dan perubahan rasio siang-malam berdasarkan hari.  
* Mengimplementasikan hunger, thirst, dan fatigue beserta perubahan nilai dan efek sederhana.  
* Membuat UI/feedback untuk skill yang terkena debuff setelah respawn.  
* Menyesuaikan UI berdasarkan hasil playtest.

**TARGET AKHIR:** UI penting tersedia; sistem waktu dan kebutuhan survival dapat digunakan serta dipantau pemain.

## **D. Riyan — Programmer & Sound Engineer**

* Membuat daftar kebutuhan audio gameplay inti.  
* Menyiapkan dan mengintegrasikan ambience siang dan malam.  
* Menyiapkan SFX langkah, pengumpulan sumber daya, interaksi, combat, serangan hewan, dan kondisi pemain.  
* Menyiapkan audio feedback untuk hunger, thirst, fatigue, kematian, dan respawn.  
* Membuat atau mengintegrasikan audio menu dan suasana pulau.  
* Membantu implementasi atau perbaikan fitur gameplay tambahan yang disepakati bersama programmer utama.  
* Memastikan volume audio seimbang dan tidak mengganggu informasi gameplay.

**TARGET AKHIR:** Audio inti terpasang dan berfungsi; kontribusi pemrograman tambahan selesai sesuai prioritas integrasi.

## **E. Wandi — Game Artist / 2D Artist**

* Menetapkan style visual yang konsisten dan realistis-semi stylized sesuai konsep. (castaway)  
* Membuat/menyiapkan sprite karakter utama dan animasi dasar yang diperlukan.  
* Membuat tileset atau aset lingkungan untuk area pulau dan camp.  
* Membuat aset sumber daya yang dapat dikumpulkan.  
* Membuat aset hewan liar untuk musuh MVP.  
* Membuat aset visual item drop dan objek interaksi.  
* Membuat ikon kebutuhan survival serta elemen visual pendukung HUD jika dibutuhkan.  
* Mengekspor aset dengan ukuran, pivot, format, dan penamaan yang konsisten.

**TARGET AKHIR:** Paket aset visual minimum tersedia dan seluruh aset utama sudah masuk ke dalam build.

# **4\. Target Pengerjaan 2 Minggu**

## **Minggu 1 — Prototype dan Fitur Dasar**

* Project game, struktur scene/folder, dan alur kerja tim siap digunakan.  
* Karakter dapat bergerak dengan kamera top-down.  
* Area pulau sederhana dan camp awal tersedia.  
* Pemain dapat mengumpulkan sumber daya dan melihat item di inventori.  
* HUD dasar dan menu utama tersedia.  
* Sistem siang-malam dasar mulai berjalan.  
* Aset karakter, lingkungan, sumber daya, dan audio dasar mulai terintegrasi.

## **Minggu 2 — Survival Loop dan Integrasi**

* Rasio siang-malam hari 1–7 diterapkan.  
* Hunger, thirst, dan fatigue berjalan dengan efek sederhana.  
* Hewan liar dan combat dasar berfungsi.  
* Survival Timer malam dan peningkatan ancaman berdasarkan hari berfungsi.  
* Death, item drop, pengambilan kembali item, respawn, dan debuff skill berfungsi.  
* Kondisi kemenangan saat bertahan sampai hari ke-7 tersedia.  
* Playtest, perbaikan bug, penyesuaian balance, dan build final dilakukan.  
* NPC hanya dikerjakan jika seluruh fitur inti sudah stabil dan masih ada waktu.

# **5\. Kriteria Selesai MVP**

* Pemain dapat memulai permainan dan mengendalikan karakter di area pulau.  
* Pemain dapat mengumpulkan sumber daya dan kembali ke camp.  
* Sistem waktu menampilkan hari serta pergantian siang dan malam sesuai rasio.  
* Pemain dapat memantau hunger, thirst, dan fatigue.  
* Hewan liar menjadi ancaman dan dapat dihadapi dengan combat sederhana.  
* Pemain dapat bertahan melewati Survival Timer malam.  
* Kematian menampilkan pilihan Respawn atau Main Menu.  
* Respawn mengembalikan pemain ke camp, menjatuhkan item di lokasi kematian, dan menerapkan debuff skill yang dibatasi.  
* Pemain dapat mencapai hari ke-7 dan memicu kondisi berhasil diselamatkan.  
* Build dapat dimainkan dan diuji tanpa bug penghambat utama.

# **6\. Fitur Tambahan Jika Waktu Cukup**

* Menemukan satu atau lebih penyintas/NPC di area tertentu.  
* Satu spesialisasi NPC sederhana dengan kontribusi yang mudah diuji.  
* NPC yang ditinggalkan di camp menjalankan satu pekerjaan otomatis.  
* Variasi hewan liar atau tambahan aset/area.  
* Detail crafting atau pembangunan camp di luar kebutuhan inti.
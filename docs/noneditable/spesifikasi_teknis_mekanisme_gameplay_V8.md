# **Spesifikasi Teknis Mekanisme Gameplay** 

**Project:** RTRw Studio • Gimersia 2026 **Target Implementasi:** Godot Engine 4.x (GDScript) **Latar Naratif:** Pemain adalah penyintas kecelakaan pesawat ( _plane crash_ ) yang terdampar di pulau terpencil dan harus membangun perkemahan dari nol di sekitar puing pesawat sambil bertahan hidup selama 7 hari hingga kapal penyelamat tiba. 

Dokumen ini merupakan acuan angka final, konstanta sistem, tata letak puing awal, mekanika pertahanan markas ( _destructible camp_ ), aturan _anti-exploit_ , dan penanganan _edge-case_ untuk implementasi _core loop_ dan fitur lanjutan. Fitur diberi label **[MVP]** (prioritas utama 2 minggu) dan **[POST-MVP]** (dikerjakan setelah seluruh fitur inti stabil dan bebas bug). 

## **0. Konstanta Dasar Karakter, Kontrol, & Rumus Modifier [MVP]** 

### **A. Parameter Dasar Pemain (** **_Base Stats_ )** 

Seluruh stat pemain di awal permainan (Hari ke-1 Pagi, Level 1 tanpa debuff) mengacu pada konstanta berikut: 

- **Base Max HP:** 100.0 (HP awal = 100.0; regenerasi pasif HP = 0.0 / detik; pemulihan HP hanya berasal dari konsumsi item, efek NPC Sari, atau _Respawn_ ). 

- **Batas Nyawa (** **_Life Tokens_ / Kesempatan Respawn):** Pemain memulai permainan dengan **3 Token Nyawa** (respawns_remaining = 3). 

   - **Tampilan UI:** Menampilkan label **"Sisa Kesempatan Respawn: X / 3"** . Saat mati ke-1 hingga ke-3, UI menampilkan angka 2/3, 1/3, dan 0/3 _(dengan teks keterangan: "Kesempatan Respawn Terakhir Telah Digunakan — Kematian Berikutnya Game Over")_ . 

   - Kematian ke-4 (respawns_remaining < 0) memicu **Game Over Permanen (Run Gagal)** . 

- **Base Damage Reduction:** 0.0% (dapat ditingkatkan melalui _Equipment_ seperti _Zirah Kulit_ ). 

- **Base Move Speed:** 160.0 px/s (Jalan normal) | 240.0 px/s ( _Sprint_ , pengali 1.5×). 

- **Base Auto-Attack:** Damage 8.0 | Jangkauan 45 px | Attack Speed 1.2 serangan/detik (Cooldown dasar 0.83 detik). 

- **Base Dodge Chance:** 0.0% (Batas maksimal / _Hard Cap_ = 50.0%). 

- **Base Knockback Resistance:** 0.0 (terdorong 60 px selama 0.2 detik saat terkena serangan _Dash Charge_ ). 

- **Kapasitas & Aturan Inventori (Terpisah dari Slot Equipment):** 

   - **12 Slot Tas Utama:** Slot 1–5 berfungsi sebagai _Quick-Access Hotbar_ di bagian bawah layar. Item yang baru diambil otomatis mengisi slot kosong pertama dari kiri ke kanan (Slot 1 → Slot 12) atau menumpuk ke slot item sejenis yang sudah ada; urutan slot **tidak pernah diacak atau berubah sendiri** . 

   - **3 Slot Equipment Permanen (Terpisah dari 12 Slot Tas):** 

      1. Slot Senjata: Otomatis menyimpan senjata terbaik yang sudah di-craft ( _Tombak Kayu / Batu / Tulang_ ). 

      2. Slot Alat (Tools): Otomatis menyimpan alat _gathering_ yang sudah di-craft ( _Kapak Batu_ dan _Beliung Batu_ sebagai status kepemilikan alat permanen). 

   3. Slot Zirah: Otomatis terisi saat men-craft _Zirah Kulit_ . 

   4. Seluruh item di 3 Slot Equipment ini bersifat **permanen** , tidak memakan kapasitas 12 slot tas, dan **tidak jatuh saat pemain mati** . 

- **Aturan Stack Tas:** Item material dan konsumsi dapat ditumpuk ( _stack_ ) hingga maksimal **20 per slot** . _Kantung Air Kulit_ dan _Suar Darurat_ memiliki max_stack = 1. Jika 12 slot tas penuh saat _gathering_ atau _loot_ , item hasil drop terjatuh di tanah (Area2D pickup) di dekat kaki pemain. 

### **B. Skema Kontrol & Mekanika Aksi** 

- **Pergerakan:** W, A, S, D atau tombol arah (Input.get_vector()). 

- **Sprint:** Tahan Shift (aktif selama _Fatigue_ > 25). 

- **Combat (Auto-Attack & Sistem Provokasi):** 

   - **Target HOSTILE (Musuh Malam / Entitas yang Sudah Diprovokasi):** Sistem menyerang **secara otomatis** ke arah target HOSTILE terdekat yang berada di dalam radius jangkauan senjata (attack_range) setiap kali cooldown serangan selesai (berlaku baik di luar maupun di dalam area Camp). 

   - **Target PASSIVE (Rusa) & NEUTRAL (Babi Hutan / Serigala Siang):** Diabaikan oleh _auto-attack_ sampai pemain melakukan **1 kali serangan pemicu manual** menggunakan **Klik Kiri** (menyerang ke arah posisi kursor mouse) atau tombol **Space** (menyerang target terdekat di dalam kerucut sudut 90° di depan arah hadap karakter dalam radius attack_range). Begitu terkena serangan pemicu tersebut, entitas masuk ke daftar target aktif pemain sehingga _auto-attack_ otomatis mengunci dan terus menyerang selama target masih berada di dalam jangkauan senjata. 

- **Dodge (Hindaran Pasif):** Mekanisme menghindar otomatis berbasis peluang ( _RNG_ ) saat serangan musuh mengenai _hitbox_ pemain. Jika berhasil, muncul _floating text "DODGE!"_ dan damage menjadi 0. 

- **Interaksi, Gathering, & Membangun Camp:** Tahan tombol E di dekat objek sumber daya, sungai, Koper Darurat, **Slot Blueprint Camp** , NPC, Tiang Suar, atau fasilitas Camp hingga _progress bar_ radial terisi penuh (100%). Jika tombol E dilepas sebelum penuh atau pemain bergerak keluar dari area interaksi, progres direset ke 0%. 

- **Perbaikan Struktur Camp (** **_Repair_ ):** Tahan tombol **R** selama **1.0 detik** di dekat bangunan Camp yang rusak (current_hp < max_hp) untuk memulihkan HP struktur tersebut (otomatis mengonsumsi bahan perbaikan dari tas). 

- **Menu Inventori & Hand-Crafting:** Tekan Tab atau I untuk membuka tas sekaligus tab **Hand-Crafting** (merakit item dasar tanpa membutuhkan _Workbench_ ). 

- **Penggunaan Item (Makan, Minum, Obor, Perban, Perangkap):** 

   - **Via Hotbar:** Tekan tombol angka 1 sampai 5 untuk langsung memakai item konsumsi/utilitas yang berada di slot tersebut. 

   - **Via UI Inventori: Klik Kanan** pada item di dalam tas untuk memakainya (atau **Klik Kiri** untuk _drag & drop_ memindahkan posisi slot). 

### **C. Aturan Penumpukan Modifier (** **_Stat Stacking_ )** 

Seluruh bonus stat per level dimulai sejak **Level 2** (menggunakan faktor pengali Level_Saat_Ini - 1, sehingga pada **Level 1** seluruh bonus bernilai 0): 

1. **Bonus Flat (Contoh: +5 Max HP per level Kekuatan, +15 Max HP dari** **_Zirah Kulit_ ):** Ditambahkan langsung ke nilai dasar: Total Max HP = 100.0 + (5.0 × (Level Kekuatan - 1)) + Bonus Zirah 

2. **Modifier Persentase (Speed, Damage, Attack Speed, Crafting):** Dihitung secara **Additive** di dalam kategorinya masing-masing dengan batas bawah ( _clamp_ ) 0.25: Final Stat = Base Stat × max(0.25, 1.0 + Σ Bonus% - Σ Penalti%) _(Khusus_ **_Dodge Chance_** _dihitung secara additive murni dan di-clamp pada [0.0%, 50.0%]: Final Dodge = min(50.0%, 2.0% × (Level Ketangkasan - 1) + Bonus Pasif))._ 

3. **Multiplier Spesifik Serangan (** **_Heavy Strike_ &** **_Swift Counter_ ):** Dihitung **Multiplicative** di tahap akhir perhitungan damage serangan tersebut (misal: Final Attack Damage × 1.30 pada serangan ke-4 _Heavy Strike_ ). 

4. **Perhitungan Damage Masuk (Mitigasi Zirah):** Damage Diterima = Damage Musuh × (1.0 - Damage Reduction) 

## **1. Layout Dunia, Puing Pesawat, Siklus Waktu, & Hari Terakhir [MVP]** 

### **A. Layout Makro Peta, Prioritas Zona, & Sebaran Resource** 

- **Ukuran & Skala Pulau:** Pulau berbentuk oval/persegi membulat berukuran **4800 × 4800 px** (koordinat X dan Y dari -2400 hingga +2400, waktu tempuh jalan kaki dari pusat pulau ke ujung pesisir ≈ 15 detik) yang dikelilingi lautan (batas jalan berupa _StaticBody2D_ garis pantai). 

- **Hierarki Prioritas Pengecekan Zona (CrashSiteOrigin = Vector2(0, 0)):** Untuk menghindari tumpang tindih koordinat, pembagian zona dievaluasi secara berurutan menggunakan struktur if / elif dari kondisi paling spesifik ke paling umum: 

   1. **Zona 1 — Crash Site / Camp:** Jarak Euclidean dari (0, 0) ≤ 800 px. Area dataran terbuka bekas benturan pesawat tempat **Puing Pesawat** dan **Camp** didirikan. 

   2. **Zona 2 — Pantai Selatan (Titik Suar):** Y > +1400 (dan di luar Zona 1). Berisi **Pohon Kelapa** (12 node) dan objek **Tiang Suar (Signal Beacon)** di (0, +2100). 

   3. **Zona 3 — Pantai Timur:** X > +1400 dan -1400 ≤ Y ≤ +1400. Pesisir timur tempat kemunculan NPC Bima _(Post-MVP)_ . 

   4. **Zona 4 — Tebing Barat:** X < -1400 dan Y ≤ +1400. Area berbatu di sisi barat berisi **Bongkahan Batu Kecil/Besar** (22 node) dan tempat kemunculan NPC Raka _(Post-MVP)_ . 

   5. **Zona 5 — Aliran Sungai:** -1050 ≤ X ≤ -850 dan -1400 ≤ Y ≤ +1400. Sumber **Air Sungai** dan **Rumpun Bambu** (14 node). 

   6. **Zona 6 — Hutan Lebat (Utara, Timur, & Barat Tengah):** Seluruh area tersisa di dalam pulau (-2400 s.d. +2400) yang tidak masuk ke dalam Zona 1 hingga Zona 5. Berisi **Pohon Kecil/Besar** (30 node), **Semak Serat** (24 node), **Semak Beri** (18 node), habitat fauna, serta titik spawn musuh malam. 

- **Node Awal & Aturan Penipisan di Zona 1 (radius <= 800 px dari (0, 0)):** 

   1. Di dalam radius 800 px sekitar titik jatuhnya pesawat, terdapat node awal tetap agar pemain dapat membangun _Campfire_ dan _Workbench_ pada Hari ke-1: **6 Ranting (Kayu)** , **4 Bongkahan Batu Kecil (Batu)** , **5 Semak Serat** , dan **4 Semak Beri** . 

   2. Seluruh node di dalam Zona 1 (radius <= 800 px) hanya melakukan _respawn_ **maksimal 3 kali** sepanjang permainan (terakhir _respawn_ pada Pagi Hari ke-4). Mulai Hari ke-5, node di dalam Zona 1 yang sudah diambil akan hilang permanen sehingga pemain wajib menjelajah ke Zona 2– 6. 

### **B. Puing Pesawat, Pembangunan Camp, & Daya Tahan Struktur (** **_Destructible Camp_ )** 

Saat permainan dimulai (00:00 Hari ke-1), belum ada satu pun fasilitas Camp yang berdiri. Pemain memulai permainan di samping **Puing Pesawat** dan membangun fasilitas perkemahan secara mandiri pada **4 Titik Blueprint Tetap** di area Camp. 

Seluruh struktur yang telah dibangun memiliki **HP (** **_Structural Durability_ )** dan **dapat diserang serta dihancurkan oleh musuh** (bar HP struktur hanya muncul di atas objek saat current_hp < max_hp): 

|**Nama Objek /**<br>**Struktur**|**Posisi dari (0, 0)**|**Max HP**|**Biaya Perbaikan**<br>**(Tahan R, 1.0 dtk)**|**Kondisi Awal &**<br>**Konsekuensi Jika HP**<br>**= 0 (Hancur)**|
|---|---|---|---|---|
|**0. Puing Badan**<br>**Pesawat** _(Plane_<br>_Wreckage)_|(0, -185)|Kebal (_Indestructible_)|—|**Objek Lingkungan**<br>**Permanen**<br>_(StaticBody2D)_. Ekor<br>pesawat berasap tipis<br>sebagai penanda<br>pusat Camp.|
|**1. Koper Darurat**<br>_(Emergency Suitcase)_|(-48, +40)|Kebal (_Indestructible_)|—|**Tertutup** _(Hanya_<br>_dapat di-loot 1x)_.<br>Tahan E (1.0 dtk)<br>untuk mengambil**1**<br>**Perban Herbal**,**1 Air**<br>**Matang**, dan**Catatan**<br>**Kokpit**.|
|||||**Belum Terbangun**.<br>Tahan E (2.5 dtk)<br>dengan 4 Kayu + 3<br>Batu + 2 Serat untuk|
|**2. Campfire** _(Api_<br>_Unggun)_|(0, 0)_(Pusat Camp)_|**250 HP**|1 Kayu + 1 Batu (+80<br>HP)|membangun<br>(langsung menyala<br>**240 dtk**).**Jika hancur:**<br>Api padam, efek<br>_Light Debuff_hilang,<br>dan kembali menjadi<br>_Blueprint Slot_kosong.|
|**3. Workbench** _(Meja_<br>_Kerja)_|(-96, -32)|**180 HP**|1 Kayu + 1 Serat (+70<br>HP)|**Belum Terbangun**.<br>Tahan E (3.0 dtk)<br>dengan 5 Kayu + 2<br>Batu + 3 Serat.**Jika**<br>**hancur:**Kembali<br>menjadi_Blueprint_<br>_Slot_kosong (akses<br>_Workbench Crafting_<br>tertutup sampai<br>dibangun ulang).|



|**Nama Objek /**<br>**Struktur**|**Posisi dari (0, 0)**|**Max HP**|**Biaya Perbaikan**<br>**(Tahan R, 1.0 dtk)**|**Kondisi Awal &**<br>**Konsekuensi Jika HP**<br>**= 0 (Hancur)**|
|---|---|---|---|---|
|**4. Peti Camp** _(Camp_<br>_Storage)_|(+96, -32)|**200 HP**|2 Kayu (+80 HP)|**Belum Terbangun**.<br>Tahan E (2.5 dtk)<br>dengan 6 Kayu + 2<br>Serat (24 Slot).**Jika**<br>**hancur:**Kembali<br>menjadi_Blueprint_<br>_Slot_, dan**seluruh isi**<br>**peti jatuh ke tanah**<br>dalam bentuk_Loot_<br>_Bag_(barang tidak<br>hilang).|
|**5. Tenda Daun** _(Leaf_<br>_Shelter)_|(0, -110)|**120 HP**|1 Kayu + 2 Serat (+60<br>HP)|**Belum Terbangun**.<br>Tahan E (4.0 dtk)<br>dengan 6 Kayu + 6<br>Serat + 2 Bambu.**Jika**<br>**hancur:**Kembali<br>menjadi_Blueprint_<br>_Slot_kosong (fitur<br>_Tidur_&_Night Watch_<br>terkunci sampai<br>dibangun ulang).|



   - **Definisi "Radius Camp":** Area lingkaran beradius **180 px** dari titik pusat **Campfire** (0, 0). 

   - **Titik Spawn Awal Pemain:** Koordinat (0, +64) menghadap ke utara (ke arah puing pesawat dan Koper Darurat). 

- **C. Laju Konsumsi Bahan Bakar Campfire & Fitur Night Watch** 

   - **Fase Malam:** Berkurang **1.0 detik per detik** _real-time_ . 

   - **Fase Siang:** Api menyala dalam mode bara hemat ( _smoldering_ ), berkurang **0.25 detik per detik** _realtime_ . 

   - **Aturan Isi Ulang (+180 detik per 2 Kayu):** Hanya dapat dilakukan setelah **Campfire** selesai dibangun. Jika total bahan bakar setelah diisi melebihi 600 detik, nilainya di- _clamp_ menjadi 600 detik (tombol isi ulang di UI dinonaktifkan jika bahan bakar sudah ≥ 580 detik). 

   - **Fitur Berjaga / Percepat Malam (** **_Night Watch_ — Khusus Malam Hari):** 

      - Dapat diaktifkan melalui **Tenda Daun** (atau **Campfire** jika Tenda belum dibangun) selama Campfire dalam kondisi menyala (fuel > 0). 

      - Saat mode _Night Watch_ aktif, karakter duduk berjaga di dekat api unggun dan **laju waktu malam berjalan 2× lebih cepat** (2.0 detik waktu game per 1.0 detik _real-time_ ). 

      - Selama mode ini aktif, laju pengurangan _Hunger_ , _Thirst_ , dan bahan bakar _Campfire_ juga berjalan **2× lipat** secara proporsional. Mode ini otomatis berhenti seketika jika pemain menekan tombol gerak (WASD), api unggun padam (fuel == 0), **ada struktur Camp yang terkena serangan musuh** , atau fajar tiba. 

### **D. Durasi Total & Rasio Siklus** 

Total durasi **1 siklus penuh (1 hari) = 10 menit (600 detik)** _real-time_ (pada kecepatan normal 1.0×). 

|**Hari**|**Rasio Siang : Malam**|**Durasi Siang**|**Durasi Malam (Survival**<br>**Timer)**|
|---|---|---|---|
|**Hari 1 – 3**|5 : 5|5 menit (300 detik)|5 menit (300 detik)|
|**Hari 4 – 5**|4 : 6|4 menit (240 detik)|6 menit (360 detik)|
|**Hari 6 – 7**|3 : 7|3 menit (180 detik)|7 menit (420 detik)|



- **Transisi Senja:** Pada **15 detik terakhir** fase siang, layar menampilkan tint jingga tipis dan memutar audio peringatan agar pemain segera kembali ke Camp. 

### **E. Pencahayaan, Light Debuff, & Logika Serangan Musuh ke Camp** 

- **Visibilitas & Pencahayaan:** Malam hari mengubah CanvasModulate ke #1a2238. Pemain memiliki PointLight2D radius **110 px** (atau **190 px** dengan _Obor_ ). Campfire yang menyala memancarkan cahaya **240 px** ; jika sudah dibangun tetapi padam (fuel == 0), menyusut menjadi bara redup **80 px** . _(Jika Campfire belum dibangun atau hancur, tidak ada sumber cahaya di Camp)._ 

- **Mekanika Cahaya Api Unggun (** **_Light Debuff_ — Bukan Barrier Absolut):** 

   - Cahaya Campfire **tidak memblokir fisik musuh** . Musuh bebas masuk ke dalam area Camp (<= 180 px) untuk menyerang pemain maupun menghancurkan struktur Camp. 

   - Selama **Campfire menyala (fuel > 0)** , setiap musuh yang berada di dalam radius **180 px** dari Campfire otomatis terkena status **_Dazzled (Silau Cahaya)_** : **Move Speed -30%** dan **Attack Speed -25%** . Jika api padam atau Campfire hancur, status _Dazzled_ langsung hilang dan musuh bertarung dengan kecepatan penuh. 

- **Aturan Aktivasi & Prioritas Target AI Musuh Terhadap Camp:** 

 **Syarat Aktivasi Serangan Markas:** Musuh malam hanya menargetkan struktur Camp apabila musuh tersebut **telah mendeteksi pemain** di area Camp (radius 500 px dari pusat (0, 0)) atau mengejar pemain masuk ke Camp. Musuh yang _spawn_ di hutan jauh tidak akan berjalan menghancurkan Camp kosong saat pemain sedang eksplorasi di luar Camp. 

- **Pembagian Target (** **_Aggro Split_ ):** 

   - Jika pemain berada dalam jarak <= 140 px dari musuh, musuh memprioritaskan mengejar dan menyerang **Pemain** . 

   - Jika pemain berada di luar 140 px (misalnya pemain menjauh, menghindar, atau berada di balik bangunan), musuh mengalihkan serangan ke struktur Camp terbangun terdekat dengan urutan prioritas: **Campfire (Prioritas 1)** → **Workbench / Peti Camp (Prioritas 2)** → **Tenda Daun (Prioritas 3)** . 

- **Kerusakan Khusus ke Bangunan:** Serangan _Dash Charge_ Babi Hutan memberikan **2× Damage (40 Base Damage)** saat menghantam struktur Camp. 

- **Efek Tambahan Malam 5–7 (** **_Ember Snuff_ ):** Pada Malam ke-5 hingga ke-7, setiap serangan fisik musuh yang mengenai **Campfire** selain mengurangi HP bangunan juga menyemburkan percikan bara yang mengurangi sisa bahan bakar api unggun sebesar **-8 detik per hit** (bonus pasif NPC Bima -25% mengurangi efek ini menjadi -6 detik per hit). 

- **Insentif Bertarung di Malam Hari:** 

   - Seluruh aktivitas pertempuran ( _hit_ , _dodge_ , _kill_ ) pada malam hari memberikan **Bonus +50% XP Proficiency** . 

   - Mempertahankan Camp di malam hari menjadi sumber utama **Daging Mentah** , **Tulang** (untuk _Tombak Tulang_ , _Kaldu Tulang_ , dan **Suar Darurat** ), serta **Serat Jaring** _(Post-MVP)_ . 

### **F. Konsep Penjemputan & Syarat Tamat di Hari Terakhir (Hari ke-7)** 

1. **Pagi Hari ke-7:** Banner HUD: _"Kapal penyelamat terlihat di cakrawala! Siapkan Suar Darurat dan bertahanlah melewati malam terakhir untuk menyalakan suar penjemputan."_ 

2. **Malam Hari ke-7:** Gelombang maksimal aktif hingga Survival Timer mencapai 00:00. 

3. **Trigger Penyelamatan (Timer == 00:00):** 

   - Langit berubah fajar cerah, timer siklus waktu di- _freeze_ , laju _Hunger/Thirst_ dihentikan (0 / detik), dan seluruh musuh malam ekstra kabur (FLEE) lalu _despawn_ . 

   - **Anti-Softlock Suar Darurat (Sinkron):** Tepat saat fajar Hari ke-7 tiba (Timer == 00:00), jika jumlah **Babi Hutan** aktif di map kurang dari **2 ekor** , sistem langsung melakukan _spawn_ hingga berjumlah **2 ekor Babi Hutan** (berstatus NEUTRAL) di Zona 6 (Hutan Lebat). Jika dibunuh setelah fajar Hari ke-7, Babi Hutan tersebut memiliki _respawn timer_ **45 detik** (dibatasi maksimal **4 kali respawn tambahan** setelah fajar) sehingga bahan _Tulang_ untuk **Suar Darurat** dijamin tidak pernah terkunci ( _soft-lock_ ) tanpa membuka celah _farming_ tak terbatas. 

   - _(Edge-Case Kematian)_ : Jika pemain sedang berada di layar **Kamu Tewas** (dan masih memiliki sisa kesempatan respawn) tepat saat Timer == 00:00, begitu pemain menekan **Respawn** , kondisi fajar dan indikator suar tetap aktif. 

   - Muncul _arrow pointer_ di HUD menunjuk ke **Tiang Suar** di Pantai Selatan (0, +2100). 

   - **Syarat Aktivasi Suar:** Pemain wajib memiliki item **Suar Darurat (** **_Signal Flare_ )** di inventori. Saat berada di dekat Tiang Suar dengan item tersebut, pemain menahan E selama 1.5 detik untuk menembakkan suar merah, memicu kapal merapat, dan menampilkan layar **Victory** . 

## **2. Daftar Musuh, Fauna, dan Scaling Malam** 

- **A. Aturan Agresivitas Siang vs Malam (** **_Neutral Daytime Rule_ )** 

   - **Fase Siang Hari (Seluruh Entitas):** Semua fauna dan musuh (termasuk **Babi Hutan** dan **Serigala Pulau** ) berstatus **NEUTRAL (Pasif/Tidak Menyerang Duluan)** . Mereka hanya berjalan santai (WANDER) di habitatnya dan **tidak akan mengejar pemain maupun menyerang struktur Camp** meskipun berada di dekatnya, **KECUALI jika pemain menyerang mereka terlebih dahulu** ( _provoked_ ). Begitu terkena serangan pertama dari pemain, entitas tersebut berubah menjadi AGGRESSIVE dan mengejar hingga jarak _leash_ terlewati. 

   - **Fase Malam Hari:** Seluruh musuh (Babi Hutan, Serigala Pulau, Laba-Laba Hutan) otomatis memasuki status **HOSTILE (Agresif penuh)** terhadap pemain dan struktur Camp. _(Rusa Pulau tetap PASSIVE siang maupun malam)._ 

### **B. Spesifikasi Entitas Fauna & Musuh** 

Seluruh _drop item_ di bawah ini memiliki peluang jatuh **100% pasti** ( _guaranteed drop_ ) saat entitas mati: 

|**Nama Entitas**|**Kategori**|**HP**|**Base Damage**|**Move Speed**|**Ability &**<br>**Perilaku AI**|**Drop Item**<br>**(100%)**|
|---|---|---|---|---|---|---|
|**Rusa Pulau**<br>_(Island Deer)_|Buruan Pasif<br>**[MVP]**|40|0|175 px/s|**Flee:**Selalu<br>PASSIVE (siang<br>& malam). Jika<br>pemain masuk<br>radius**130 px**<br>atau terkena<br>serangan,<br>berlari<br>menjauh<br>berlawanan<br>arah selama 5<br>detik.|2 Daging<br>Mentah,**1**<br>**Kulit**|



|**Nama Entitas**|**Kategori**|**HP**|**Base Damage**|**Move Speed**|**Ability &**<br>**Perilaku AI**|**Drop Item**<br>**(100%)**|
|---|---|---|---|---|---|---|
|**Babi Hutan**<br>_(Wild Boar)_|Ancaman<br>Utama**[MVP]**|80|12|115 px/s<br>(Siang)150<br>px/s (Malam)|**1. Serangan**<br>**Dasar**<br>**(Bite/Gore):**<br>Jarak ≤ 50 px,<br>cooldown**1.2**<br>**detik**(12<br>Damage ke<br>pemain/strukt<br>ur).**2. Dash**<br>**Charge**<br>**(Seruduk):**<br>Jika target<br>berada di<br>jarak**110–240**<br>**px**, berhenti<br>0.8 detik<br>(garis<br>_telegraph_<br>merah), lalu<br>menerjang<br>lurus**330 px/s**<br>(20 Damage<br>ke pemain +<br>Knockback,<br>atau**40**<br>**Damage ke**<br>**struktur**<br>**Camp**).<br>Cooldown: 6<br>detik.**3.**<br>**Perilaku Siang**<br>**vs Malam:**<br>Siang hari<br>**NEUTRAL**<br>(_leash_ **380 px**).<br>Malam hari<br>**NOCTURNAL**<br>**HOSTILE**<br>(radius<br>deteksi**300**<br>**px**, cooldown<br>_Dash_menjadi<br>**4 detik**).|2 Daging<br>Mentah,**1**<br>**Tulang**|



|**Nama Entitas**|**Kategori**|**HP**|**Base Damage**|**Move Speed**|**Ability &**<br>**Perilaku AI**|**Drop Item**<br>**(100%)**|
|---|---|---|---|---|---|---|
|**Serigala Pulau**<br>_(Island Wolf)_|Variasi**[POST-**<br>**MVP]**|65|10|170 px/s|**Pack Howl:**<br>Jarak serang<br>dasar 45 px<br>(CD 1.0 dtk).<br>Siang hari<br>**NEUTRAL**<br>(_leash_420 px).<br>Malam hari<br>**HOSTILE**<br>(deteksi 300<br>px): saat<br>melihat<br>pemain,<br>mengaum 1<br>detik untuk<br>memanggil 1<br>Serigala<br>terdekat<br>(radius 400<br>px) dan<br>mendapat<br>buff +25%<br>Attack Speed<br>selama 5<br>detik.|1 Daging<br>Mentah,**1**<br>**Kulit**|
|**Laba-Laba**<br>**Hutan**<br>_(Shadow_<br>_Stalker)_|Variasi Malam<br>**[POST-MVP]**|45|8|155 px/s|**Venom Bite:**<br>Hanya muncul<br>pada malam<br>hari dan selalu<br>**HOSTILE**<br>(deteksi 280<br>px, jarak<br>serang 45 px,<br>CD 1.1 dtk).<br>Memberi efek<br>_Poison_(-2<br>HP/detik<br>selama 4<br>detik) dan<br>slow -15%<br>selama 3 detik<br>(efek_Poison_<br>tidak<br>memengaruhi<br>struktur<br>bangunan).|**2 Serat Jaring**|



**C. Rasio, Komposisi, & Aturan Spawn Tiap Malam** 

|**Malam ke-**|**Musuh Aktif**<br>**Maksimal**|**Interval Spawn**|**Multiplier HP &**<br>**Damage**|**Komposisi Penuh**<br>**(Post-MVP)**|**Komposisi**<br>**Fallback (MVP)**|
|---|---|---|---|---|---|
|**Malam 1**|3 ekor|Setiap 45 detik|1.0×|100% Babi Hutan|100% Babi Hutan|
|**Malam 2**|4 ekor|Setiap 40 detik|1.0×|100% Babi Hutan|100% Babi Hutan|
|**Malam 3**|5 ekor|Setiap 35 detik|1.1×|100% Babi Hutan|100% Babi Hutan|
|**Malam 4**|6 ekor|Setiap 30 detik|1.2×|70% Babi Hutan,<br>30% Serigala|100% Babi Hutan|
|**Malam 5**|7 ekor|Setiap 25 detik|1.3×|60% Babi Hutan,<br>40% Serigala|100% Babi Hutan|
|**Malam 6**|9 ekor|Setiap 20 detik|1.4×|50% Babi Hutan,<br>30% Serigala,<br>20% Laba-Laba|100% Babi Hutan|
|**Malam 7**|12 ekor|Setiap 15 detik|1.5×|40% Babi Hutan,<br>35% Serigala,<br>25% Laba-Laba|100% Babi Hutan|



- **Mekanisme Slot & Titik Spawn Malam:** 

   - Angka _Musuh Aktif Maksimal_ adalah jumlah musuh hidup secara bersamaan di map. Jika musuh mati dibunuh pemain, slot langsung terbuka kembali dan spawner memunculkan penggantinya pada siklus _Interval Spawn_ berikutnya. 

   - Sistem menyediakan **16 titik Marker2D** di Zona 6 (Hutan Lebat, radius ≥ 1100 px dari Camp). Jika semua titik kebetulan berada < 600 px dari pemain, sistem memilih titik spawn dengan **jarak terjauh dari posisi pemain** di luar batas layar kamera. 

- **Kuota Populasi & Aturan Respawn Fauna Siang Hari (Anti-Farming):** 

   - Sejak awal permainan (00:00 Hari ke-1), map memiliki kuota populasi siang hari sebanyak **2 ekor Babi Hutan** (berstatus NEUTRAL) dan **3 ekor Rusa Pulau** (PASSIVE). 

   - **Tidak ada** **_timer_ respawn di tengah siang hari.** Jika Babi Hutan atau Rusa mati dibunuh pada fase siang, entitas tersebut **tidak akan muncul lagi hingga fajar hari berikutnya** . 

   - Setiap pergantian malam ke pagi (fajar Hari ke-2 hingga ke-6), musuh malam ekstra kabur (FLEE) hingga tersisa maksimal **2 ekor Babi Hutan** (yang langsung kembali ke status NEUTRAL), dan populasi Rusa dipulihkan kembali ke kuota **3 ekor** di titik hutan acak di luar layar kamera. _(Untuk fajar Hari ke-7, berlaku aturan khusus Anti-Softlock pada Bagian 1F)._ 

## **3. Indikator Hunger, Thirst, Fatigue & Cara Mengatasinya [MVP]** 

Ketiga kebutuhan memakai rentang nilai **0.0 sampai 100.0** (nilai awal permainan = 100.0). 

### **A. Hunger (Lapar)** 

- **Indikator HUD:** Ikon daging + bar oranye. Ikon dan bar berkedip merah saat nilai **≤ 25.0** . 

- **Laju Pengurangan: -0.16 / detik** (Siang) | **-0.20 / detik** (Malam, +25%). _(Total konsumsi 1 hari penuh berkisar_ **_108–114 poin_** _)_ . 

- **Efek Status:** 

   - **Nilai 25.0 – 0.1 (Lapar):** Move Speed **-15%** , Damage serangan **-15%** . 

   - **Nilai 0.0 (Kelaparan):** HP berkurang **-1.5 HP / detik** . 

- **Cara Mengatasi:** 

   - Makan **Buah Beri** (+12 Hunger) atau **Kelapa** (+10 Hunger). 

   - Makan **Daging Mentah** (+15 Hunger, penalti **-10 Thirst** ). 

   - Makan **Daging Matang** (+45 Hunger, **+15 HP** ). 

   - Makan **Kaldu Tulang** (+35 Hunger, **+40 Thirst** , regenerasi **+1 HP/detik** selama 20 detik). 

### **B. Thirst (Haus)** 

- **Indikator HUD:** Ikon tetesan air + bar biru. Ikon dan bar berkedip merah saat nilai **≤ 25.0** . 

- **Laju Pengurangan: -0.24 / detik** (Siang) | **-0.18 / detik** (Malam, -25%). _(Total konsumsi 1 hari penuh berkisar_ **_119–126 poin_** _)_ . 

- **Efek Status:** 

   - **Nilai 25.0 – 0.1 (Haus):** Konsumsi _Fatigue_ meningkat **+30%** , kecepatan auto-attack melambat **-20%** . 

   - **Nilai 0.0 (Dehidrasi):** HP berkurang **-2.0 HP / detik** . 

- **Cara Mengatasi:** 

   - **Minum Langsung di Sungai:** Tahan E di tepi sungai selama 1.5 detik. Memulihkan **+25 Thirst** (cooldown 15 detik), penalti **-8 Hunger** . 

   - **Minum dari Kantung Air Kulit (** **_Waterskin_ ):** Memulihkan **+25 Thirst** per tegukan (kapasitas 3/3 tegukan, penalti -5 Hunger karena air mentah; dapat diisi penuh kembali 3/3 di sungai dengan menahan E selama 1.5 detik). 

   - **Minum Kelapa:** Memulihkan **+30 Thirst** dan **+10 Hunger** . 

   - **Air Matang (Boiled Water):** Diolah di Campfire menggunakan 1 Bambu → menghasilkan botol bambu sekali pakai yang memulihkan **+60 Thirst** tanpa penalti Hunger. 

### **C. Fatigue (Kelelahan)** 

- **Indikator HUD:** Ikon petir + bar kuning. Ikon dan bar berkedip merah saat nilai **≤ 25.0** . 

- **Laju Pengurangan (Berbasis Aktivitas):** 

   - Diam / Jalan normal: 0.0 / detik. 

   - Berlari ( _Sprint_ ): **-2.5 / detik** . 

   - Mengayunkan senjata (auto-attack): **-1.2 per serangan** . 

   - Menebang pohon / menambang batu: **-2.0 per aksi** (dihitung 1 kali saat proses _gathering_ selesai). 

- **Efek Status:** 

   - **Nilai 25.0 – 0.1 (Lelah):** Fitur _Sprint_ terkunci, Move Speed **-20%** , durasi _gathering_ bertambah **+30%** . 

   - **Nilai 0.0 (Kelelahan Ekstrem):** Move Speed **-45%** , kecepatan auto-attack melambat **-50%** . 

- **Cara Mengatasi:** 

   - **Istirahat Diam di Dekat Campfire:** Berdiri **diam (velocity == Vector2.ZERO)** dalam radius 120 px dari Campfire menyala memulihkan **+5.0 Fatigue / detik** _(tidak aktif saat berjalan atau berlari agar tidak dieksploitasi untuk Sprint-farming)_ . 

   - **Tidur di Tenda Daun (Khusus Siang Hari):** Interaksi dengan Tenda (setelah dibangun) memulihkan **100% Fatigue** secara instan dan memajukan waktu siang sebanyak **45 detik** . Selama lompatan 45 detik ini, simulasi lingkungan tetap berjalan secara proporsional: _Hunger_ berkurang -7.2, _Thirst_ berkurang -10.8, dan bahan bakar _Campfire_ berkurang -11.25 detik _(tidur tidak dapat membunuh pemain; nilai Hunger/Thirst di-clamp minimal pada 1.0)_ . Hanya dapat dipakai jika sisa waktu siang > 60 detik; cooldown **60 detik** . 

   - **Konsumsi Buah Beri / Kelapa:** Memulihkan **+10 Fatigue** secara instan. 

## **4. Eksplorasi Siang Hari & Arsitektur Sistem Crafting** 

### **A. Konsep & Alur Teknis Sistem Crafting (GDScript)** 

Sistem _crafting_ menggunakan pendekatan **Recipe-List One-Click Crafting** (daftar resep tanpa _grid_ 3×3) yang dibagi ke dalam **3 Stasiun Crafting** : 

1. **Hand-Crafting (Tab Crafting di Menu Inventori — Tab / I):** Dapat diakses kapan saja tanpa meja kerja untuk merakit peralatan paling awal dan fasilitas dasar. 

2. **Workbench Crafting (Interaksi E di Workbench):** Terbuka setelah _Workbench_ dibangun di slot Camp; memuat seluruh resep peralatan _gathering_ , senjata Tier 2, zirah, utilitas lanjutan, dan _Suar Darurat_ . 

3. **Campfire Cooking (Interaksi E di Campfire Menyala):** Terbuka setelah _Campfire_ dibangun dan memiliki fuel > 0; memuat resep pengolahan makanan dan minuman. 

- **Alur UX & Eksekusi:** 

   - Saat menu stasiun dibuka, panel kiri menampilkan daftar resep (resep dengan bahan mencukupi menyala terang; yang kurang redup). Panel kanan menampilkan ikon hasil, efek stat, rincian bahan (misal 3/3 Kulit), dan waktu pembuatan. 

   - Menekan tombol **Craft** memunculkan _progress bar_ radial di atas kepala karakter sesuai _Waktu Craft_ (1.5 – 4.0 detik). Jika pemain bergerak (velocity != Vector2.ZERO) atau terkena serangan musuh sebelum selesai, proses batal secara bersih tanpa mengurangi bahan. 

- **Aturan Pengecekan Bahan dari** **_Slot Equipment_ (Upgrade Senjata):** 

   - Untuk resep _upgrade_ seperti **Tombak Batu** dan **Tombak Tulang** yang membutuhkan 1 Tombak Kayu, fungsi has_ingredients() memindai **12 Slot Tas** terlebih dahulu, lalu memeriksa **Slot Senjata** jika tidak ditemukan di dalam tas. 

   - Saat _craft_ selesai, _Tombak Kayu_ yang terpasang di Slot Senjata otomatis dikonsumsi dan senjata baru langsung terpasang menggantikannya. Pemain tetap bebas membuat _Tombak Kayu_ baru lewat _Hand-Crafting_ kapan saja jika ingin memiliki kedua tombak Tier 2 secara bergantian. 

**B. Sumber Daya Alam yang Dapat Dicari Waktu Siang [MVP]** 

|**Sumber Daya**|**Objek di Map**|**Alat yang**<br>**Dibutuhkan**|**Durasi Ambil**|**Hasil Drop**|**Waktu Respawn**|
|---|---|---|---|---|---|
|**Kayu (Wood)**|Ranting di<br>tanahPohon<br>kecil/besar|Tangan<br>kosongKapak<br>Batu|1.0 dtk2.5 dtk|1 Kayu3 Kayu|Setiap pagi<br>_(Maks. 3x untuk_<br>_6 node awal di_<br>_Zona 1)_|
|**Batu (Stone)**|Bongkahan batu<br>kecilBatu besar|Tangan<br>kosongBeliung<br>Batu|1.5 dtk3.0 dtk|1 Batu3 Batu|Setiap pagi<br>_(Maks. 3x untuk_<br>_4 node awal di_<br>_Zona 1)_|
|**Serat (Fiber)**|Semak belukar<br>hijau|Tangan kosong|1.0 dtk|2 Serat|Setiap pagi<br>_(Maks. 3x untuk_<br>_5 node awal di_<br>_Zona 1)_|
|**Buah Beri (Berry)**|Semak beri<br>merah|Tangan kosong|0.8 dtk|2 Buah Beri|Setiap pagi<br>_(Maks. 3x untuk_<br>_4 node awal di_<br>_Zona 1)_|
|**Kelapa (Coconut)**|Pohon kelapa di<br>pesisir|Tangan kosong /<br>Kapak|1.2 dtk|1–2 Kelapa|Setiap 2 hari<br>(Pagi hari ganjil)|
|**Bambu**<br>**(Bamboo)**|Rumpun bambu<br>dekat sungai|Tangan kosong /<br>Kapak|1.5 dtk|2 Bambu|Setiap pagi (Hari<br>baru)|
|**Air Sungai**|Tepi aliran sungai|Tidak perlu alat|1.5 dtk|Minum<br>langsung / Isi<br>_Kantung Air Kulit_|Tidak terbatas|



### **C. Daftar Resep Hand-Crafting (Tanpa Meja Kerja) [MVP]** 

Dapat dibuat langsung melalui tab **Hand-Crafting** di menu inventori (Tab/I) atau dengan menahan E pada **Blueprint Slot** di Camp. Seluruh bahan habis terpakai: 

|**Item / Struktur Hasil**<br>**Craft**|**Lokasi / Cara Craft**|**Bahan yang**<br>**Dibutuhkan**|**Waktu Craft**|**Fungsi & Statistik**|
|---|---|---|---|---|
|**Campfire** _(Api_<br>_Unggun)_|Blueprint Camp (0, 0)|4 Kayu + 3 Batu + 2<br>Serat|2.5 dtk|Mendirikan Campfire<br>(250 HP) & langsung<br>menyala dengan<br>bahan bakar awal<br>**240 detik**. Memberi<br>efek_Light Debuff_<br>(180 px) & menu<br>memasak.|



|**Item / Struktur Hasil**<br>**Craft**|**Lokasi / Cara Craft**|**Bahan yang**<br>**Dibutuhkan**|**Waktu Craft**|**Fungsi & Statistik**|
|---|---|---|---|---|
|**Workbench** _(Meja_<br>_Kerja)_|Blueprint Camp (-96,<br>-32)|5 Kayu + 2 Batu + 3<br>Serat|3.0 dtk|Mendirikan<br>Workbench (180 HP)<br>di Camp; membuka<br>seluruh resep<br>peralatan & senjata<br>lanjutan.|
|**Peti Camp** _(Camp_<br>_Storage)_|Blueprint Camp (+96,<br>-32)|6 Kayu + 2 Serat|2.5 dtk|Mendirikan peti<br>penyimpanan<br>bersama (200 HP)<br>berkapasitas**24 Slot**<br>(max_stack = 20).|
|**Tenda Daun** _(Leaf_<br>_Shelter)_|Blueprint Camp (0,<br>-110)|6 Kayu + 6 Serat + 2<br>Bambu|4.0 dtk|Mendirikan tenda<br>(120 HP) di Camp;<br>membuka fitur**Tidur**<br>(siang) &**Night**<br>**Watch**(malam).|
|**Tombak Kayu**<br>_(Wooden Spear)_|Hand-Crafting<br>(Inventori)|3 Kayu + 2 Serat|2.0 dtk|Masuk ke Slot<br>Senjata: Base auto-<br>attack damage<br>menjadi**18**,<br>jangkauan**75 px**.|
|**Obor** _(Torch)_|Hand-Crafting<br>(Inventori)|2 Kayu + 1 Serat|1.5 dtk|Item_consumable_.<br>Pakai via hotbar/klik<br>kanan untuk<br>memperluas radius<br>cahaya pemain<br>menjadi**190 px**<br>selama**300 detik**.|
|**Perban Herbal**|Hand-Crafting<br>(Inventori)|3 Serat + 2 Buah Beri|1.5 dtk|Memulihkan**+35 HP**<br>secara instan.|



### **D. Daftar Resep Workbench & Campfire [MVP]** 

Baru dapat diakses setelah pemain membangun **Workbench** dan **Campfire** di area Camp: 

|**Item Hasil Craft**|**Lokasi Craft**|**Bahan yang**<br>**Dibutuhkan**|**Waktu Craft**|**Fungsi & Statistik**|
|---|---|---|---|---|
|**Kapak Batu** _(Stone_<br>_Axe)_|Workbench|2 Kayu + 2 Batu + 1<br>Serat|2.5 dtk|Masuk ke Slot Alat:<br>Membuka tebang<br>pohon (+3 Kayu).|
|**Beliung Batu** _(Stone_<br>_Pickaxe)_|Workbench|2 Kayu + 3 Batu + 1<br>Serat|2.5 dtk|Masuk ke Slot Alat:<br>Membuka tambang<br>batu besar (+3 Batu).|



|**Item Hasil Craft**|**Lokasi Craft**|**Bahan yang**<br>**Dibutuhkan**|**Waktu Craft**|**Fungsi & Statistik**|
|---|---|---|---|---|
|**Tombak Batu** _(Stone_<br>_Spear)_|Workbench|1 Tombak Kayu + 2<br>Batu + 2 Serat|3.0 dtk|Meng-upgrade Slot<br>Senjata (Jalur<br>Tambang): Base<br>damage**28**,<br>jangkauan**85 px**.|
|**Tombak Tulang**<br>_(Bone Spear)_|Workbench|1 Tombak Kayu +**2**<br>**Tulang**+ 2 Serat|3.0 dtk|Meng-upgrade Slot<br>Senjata (Jalur<br>Berburu): Base<br>damage**30**,<br>jangkauan**85 px**, dan<br>memberi efek_Bleed_<br>(-2 HP/detik selama 3<br>detik).|
|**Zirah Kulit** _(Leather_<br>_Vest)_|Workbench|**3 Kulit**+ 3 Serat|3.0 dtk|Masuk ke Slot Zirah:<br>mengurangi seluruh<br>damage masuk<br>sebesar**20%**dan<br>menambah**+15 Max**<br>**HP**.|
|**Kantung Air Kulit**<br>_(Waterskin)_|Workbench|**2 Kulit**+ 1 Serat|2.5 dtk|Wadah air isi ulang<br>(3/3 penggunaan).<br>Pakai via hotbar/klik<br>kanan untuk<br>memulihkan**+25**<br>**Thirst**(-5 Hunger)<br>kapan saja saat<br>eksplorasi.|
|**Isi Ulang Api Unggun**|Campfire|2 Kayu_(Campfire_<br>_sudah dibangun)_|Instan|Menambah durasi<br>nyala Campfire<br>sebesar**+180 detik**<br>(maksimal 600 detik).|
|**Daging Matang**|Campfire|1 Daging Mentah<br>_(Api menyala)_|2.0 dtk|Memulihkan**+45**<br>**Hunger**dan**+15 HP**.|
|**Air Matang**|Campfire|1 Bambu_(Api_<br>_menyala)_|2.0 dtk|Membuat air rebusan<br>bambu yang<br>memulihkan**+60**<br>**Thirst**tanpa penalti<br>Hunger.|
|**Kaldu Tulang** _(Bone_<br>_Broth)_|Campfire|**2 Tulang**+ 1 Daging<br>Mentah_(Api_<br>_menyala)_|2.5 dtk|Memulihkan**+35**<br>**Hunger**,**+40 Thirst**,<br>dan memberi<br>regenerasi**+1**<br>**HP/detik**selama 20<br>detik.|



|**Item Hasil Craft**|**Lokasi Craft**|**Bahan yang**<br>**Dibutuhkan**|**Waktu Craft**|**Fungsi & Statistik**|
|---|---|---|---|---|
|**Suar Darurat** _(Signal_<br>_Flare)_|Workbench|5 Kayu +**3 Tulang**+**2**<br>**Kulit**+ 2 Serat|4.0 dtk|**Item Kunci Tamat**<br>**(max_stack = 1):**<br>Wajib dibawa ke<br>**Tiang Suar**di Pantai<br>Selatan setelah<br>malam Hari ke-7<br>berakhir untuk<br>memanggil kapal<br>penyelamat.|



### **E. Daftar Resep Crafting Tambahan [POST-MVP]** 

Resep berikut baru diaktifkan bersamaan dengan kemunculan musuh **Laba-Laba Hutan** ( _Shadow Stalker_ ): 

|**Item Hasil Craft**|**Lokasi Craft**|**Bahan yang**<br>**Dibutuhkan**|**Waktu Craft**|**Fungsi & Statistik**|
|---|---|---|---|---|
|**Jaring Perangkap**<br>_(Snare Trap)_|Workbench|**2 Serat Jaring**+ 2<br>Kayu|2.0 dtk|Item_consumable_.<br>Pakai via hotbar/klik<br>kanan untuk<br>meletakkan<br>perangkap di tanah<br>(sangat efektif<br>dipasang di sekitar<br>perimeter<br>Campfire/Workbench<br>untuk menahan_Dash_<br>_Charge_musuh).<br>Musuh pertama yang<br>menginjak terkena<br>_Root_(tidak bisa<br>bergerak/dash)<br>selama**3.5 detik**.|
|**Perban Jaring Steril**<br>_(Silk Bandage)_|Workbench|**2 Serat Jaring**+ 2<br>Buah Beri|1.5 dtk|Memulihkan**+65 HP**<br>secara instan dan<br>langsung menghapus<br>efek status_Poison_.|



## **5. Sistem Proficiency, Passive Ability, & Death Debuff [MVP]** 

Terdapat **4 Proficiency** dengan rentang **Level 1 (awal) hingga Level 10 (maksimal)** . 

### **A. Aturan Kenaikan Level & Batas Maksimal XP** 

- **Rumus XP Naik Level:** XP Dibutuhkan = 100 × Level Saat Ini. 

- **Carry-Over XP:** Saat current_xp >= xp_needed, level naik +1 dan sisa kelebihan XP tetap dibawa ke level 

berikutnya (current_xp -= xp_needed). 

- **Batas Level 10:** Saat mencapai **Level 10** , current_xp dikunci di 0 dan perolehan XP untuk proficiency tersebut dihentikan. 

- **Pelacakan max_reached_level:** Setiap proficiency menyimpan variabel max_reached_level miliknya sendiri (nilai awal = 1). Variabel ini diperbarui secara otomatis (max_reached_level = max(max_reached_level, current_level)) setiap kali proficiency tersebut naik level. 

### **B. Daftar Proficiency, Efek Stat, dan Cara Meningkatkan** 

|**Proficiency**|**Efek Stat per Level****_(Mulai_**<br>**_Lv. 2)_**|**Passive Ability (Otomatis**<br>**Aktif)**|**Aktivitas untuk**<br>**Meningkatkan (+XP)**|
|---|---|---|---|
|**1. Kekuatan** _(Strength)_|**+10% Melee Damage**per<br>level**+5 Max HP**per level|**Lv. 3 — Heavy Strike:**<br>Setiap serangan ke-4<br>memberi × 1.30 damage.**Lv.**<br>**6 — Sturdy:**Mengurangi<br>jarak knockback musuh<br>sebesar 50%.|• Menyerang<br>musuh/hewan (+10 XP per<br>hit)• Menebang pohon<br>(+15 XP per pohon)•<br>Menambang batu (+15 XP<br>per batu)|
|**2. Kecepatan** _(Speed)_|**+4% Move Speed**per<br>level**-3% Drain Fatigue**saat<br>berlari|**Lv. 3 — Light Footed:**<br>Kecepatan_Sprint_<br>meningkat ekstra +10%.**Lv.**<br>**6 — Second Wind:**<br>Regenerasi Fatigue saat di<br>Camp lebih cepat +25%.|• Berjalan / eksplorasi di<br>luar Radius Camp (> 180 px)<br>(+1 XP per 100 px jarak<br>tempuh)• Berlari /_Sprint_di<br>luar Radius Camp (> 180 px)<br>(+3 XP per detik)<br>_(Pergerakan di dalam_<br>_Radius Camp <= 180 px_<br>_memberikan 0 XP untuk_<br>_mencegah Sprint-farming)_|
|**3. Kemahiran** _(Crafting /_<br>_Mastery)_|**-6% Waktu Crafting &**<br>**Gathering**per level|**Lv. 3 — Resourceful:**<br>Peluang**20%**mendapat +1<br>bonus resource saat<br>_gathering_.**Lv. 6 — Master**<br>**Chef:**Makanan/minuman<br>hasil olahan Campfire<br>memberi ekstra**+10 poin**<br>**pemulihan**.|• Melakukan crafting item<br>(+25 XP per item)•<br>Memasak di Campfire (+20<br>XP per item)•<br>Mengumpulkan resource<br>(+8 XP per aksi)|
|**4. Ketangkasan** _(Agility)_|**+5% Auto-Attack Speed**per<br>level**+2% Dodge Chance**<br>per level|**Lv. 3 — Quick Reflex:**<br>Peluang dodge bertambah<br>ekstra +8% saat HP di<br>bawah 40%.**Lv. 6 — Swift**<br>**Counter:**Setelah berhasil<br>_dodge_, serangan berikutnya<br>memberi × 1.25 damage.|• Berhasil_dodge_serangan<br>musuh (+20 XP, cooldown<br>perolehan XP**3.0 detik**per<br>musuh)• Selamat keluar<br>dari garis merah_Dash_<br>_Charge_Babi Hutan (+25 XP,<br>maksimal**2x per Babi**<br>**Hutan**agar tidak di-_farm_)•<br>Mengalahkan musuh (+30<br>XP per kill)|



**C. Aturan Death, Respawn, & Batas Debuff** 

1. **Pengecekan Token Nyawa:** 

   - Saat HP mencapai 0, sistem mengurangi respawns_remaining -= 1. 

   - Jika respawns_remaining >= 0 (kematian ke-1, ke-2, atau ke-3), muncul UI **Kamu Tewas** yang menampilkan **"Sisa Kesempatan Respawn: X / 3"** beserta tombol **Respawn** atau **Main Menu** . 

   - Jika respawns_remaining < 0 (kematian ke-4), permainan langsung masuk ke layar **GAME OVER PERMANEN** (seluruh progres hari direset dan pemain hanya dapat memilih **Mulai Baru** atau **Main Menu** ). 

2. **Death Loot:** Seluruh item di **12 Slot Tas Utama** jatuh di titik kematian dalam bentuk objek **Tas Jatuh** yang dapat diambil kembali kapan saja (tas tidak saling menghapus jika mati berkali-kali). Seluruh item yang sudah terpasang di **3 Slot Equipment Permanen** (Slot Senjata, Slot Alat, dan Slot Zirah) **tetap melekat pada pemain** saat respawn. 

3. **Status saat Respawn:** Pemain hidup kembali di titik spawn awal Camp (0, +64) dengan **70% Max HP** , **60% Hunger** , **60% Thirst** , dan **80% Fatigue** . 

4. **Algoritma Pengurangan Proficiency (Debuff):** 

   - Sistem menyaring seluruh proficiency yang memenuhi syarat: current_level > 1 **DAN** current_level > (max_reached_level - 2). 

   - Proficiency yang lolos filter diurutkan dari current_level tertinggi ke terendah (jika seri, urutan prioritas: _Kekuatan > Kecepatan > Kemahiran > Ketangkasan_ ). 

   - Sistem memilih maksimal **2 proficiency teratas** , mengurangi levelnya sebesar **-1 Level** , dan mereset current_xp = 0 **hanya pada proficiency yang terkena pengurangan** . 

## **6. Konsep Penemuan & Daftar NPC [POST-MVP / OPSIONAL]** 

### **A. Konsep Menemukan NPC** 

- Terdapat total **3 NPC penyintas** (penumpang/kru pesawat yang selamat di lokasi lain) yang muncul di titik koordinat tetap di luar area Camp secara bertahap mulai **Siang Hari ke-2** , **Hari ke-4** , dan **Hari ke-5** . 

- Saat pemain mendekat dalam radius **100 px** , muncul ikon ! di atas kepala NPC. Tekan E untuk menyerahkan item syarat rekrutmen; status NPC berubah menjadi RECRUITED dan menetap permanen di Camp _(NPC tidak dapat ditarget atau dibunuh oleh musuh)_ . 

**B. Daftar NPC & Ability Otomatis di Camp** 

|**Nama NPC**|**Lokasi & Waktu**<br>**Muncul**|**Syarat Rekrut**|**Pekerjaan Otomatis**<br>**di Camp (Jadwal**<br>**Harian)**|**Ability Pasif untuk**<br>**Pemain**|
|---|---|---|---|---|
|**Bima** _(Pencari Kayu)_|Pantai Timur (2100,<br>0) (Mulai Siang Hari<br>ke-2)|1 Buah Beri / Kelapa|Setiap pagi (awal fase<br>siang), otomatis<br>menaruh**+3 Kayu**<br>**dan +2 Serat**ke<br>dalam**Peti Camp**.<br>_(Jika Peti Camp_<br>_belum_<br>_dibangun/hancur_<br>_atau penuh, sisa item_<br>_otomatis diletakkan_<br>_di tanah tepat di_<br>_samping koordinat_<br>_Peti Camp)._|Mengurangi<br>konsumsi bahan<br>bakar Api Unggun<br>sebesar**25%**<br>(termasuk<br>mengurangi efek<br>_Ember Snuff_di<br>Malam 5–7).|
|**Sari** _(Juru Masak)_|Hutan Utara (0,<br>-1500) (Mulai Siang<br>Hari ke-4)|1 Air Matang /<br>Daging Matang|Setiap sore (30 detik<br>sebelum malam),<br>otomatis<br>mengonversi hingga<br>**2 Daging Mentah**di<br>dalam Peti Camp<br>menjadi**Daging**<br>**Matang** _(hanya_<br>_berjalan jika Peti_<br>_Camp dalam_<br>_keadaan terbangun)_.|Seluruh makanan<br>yang dikonsumsi<br>pemain di dalam<br>**Radius Camp (180**<br>**px)**memulihkan<br>ekstra**+15 HP**.|
|**Raka** _(Pengrajin)_|Tebing Barat (-1600,<br>0) (Mulai Siang Hari<br>ke-5)|2 Kayu|Setiap pagi (awal fase<br>siang), otomatis<br>menaruh**+2 Batu**ke<br>dalam**Peti Camp**<br>_(atau di samping titik_<br>_Peti jika belum_<br>_dibangun/hancur/pe_<br>_nuh)_.|Mempercepat durasi<br>crafting pemain di<br>Workbench sebesar<br>**30%**.|




extends SceneTree

## Mission 10 fase 6: menulis src/data/audio/audio_registry.tres dari tabel cue.
## Jalankan: GODOT --headless --path . -s tools/generate_audio_registry.gd
## Data dan dokumentasi saja: tidak ada playback, AudioManager, atau file audio.

const CueScript = preload("res://src/data/resources/audio/audio_cue_definition.gd")
const RegistryScript = preload("res://src/data/resources/audio/audio_registry.gd")
const OUTPUT_PATH := "res://src/data/audio/audio_registry.tres"
const NO_HOOK := "HOOK BELUM ADA"

## Kolom: key, kategori, deskripsi_id, trigger, hook, loop, spatial, varian,
## durasi, bus, prioritas, opsional, catatan.
const CUES: Array = [
	# --- Pemain -------------------------------------------------------------
	["player_footstep_sand", "sfx", "Langkah pemain di pasir pantai.", "Setiap langkah saat pemain berjalan di zona pantai.", NO_HOOK, false, true, 4, "0.15-0.30 s", "sfx", 1, false, "Butuh footstep emitter; jarak antar langkah mengikuti kecepatan."],
	["player_footstep_grass", "sfx", "Langkah pemain di rumput atau hutan.", "Setiap langkah saat pemain berjalan di zona hutan atau camp.", NO_HOOK, false, true, 4, "0.15-0.30 s", "sfx", 2, false, "Pasangan pasir; beda tekstur, bukan beda volume."],
	["player_footstep_water", "sfx", "Langkah pemain di air dangkal.", "Setiap langkah saat pemain berada di zona sungai.", NO_HOOK, false, true, 3, "0.15-0.30 s", "sfx", 3, true, "Zona sungai sudah terbaca lewat IslandZones.zone_at."],
	["player_footstep_wade", "sfx", "Langkah berat saat mengarungi air.", "Setiap langkah saat pemain wading.", NO_HOOK, false, true, 3, "0.25-0.40 s", "sfx", 3, true, "Lebih pelan dan lebih basah dari langkah air dangkal."],
	["player_sneak_step", "sfx", "Langkah sangat pelan saat jongkok.", "Setiap langkah saat pemain jongkok.", NO_HOOK, false, true, 3, "0.10-0.20 s", "sfx", 2, false, "Hampir tidak terdengar; jangan lebih keras dari langkah biasa."],
	["player_sprint_breath", "sfx", "Napas pemain saat sprint.", "Selama pemain sprint.", "Player.sprint_state_changed(is_sprinting)", true, false, 2, "loop", "sfx", 2, false, "Loop pendek, fade cepat saat sprint berhenti."],
	["player_hurt", "sfx", "Pemain terluka.", "Pemain menerima damage.", "CombatFeedback.feedback_event kind `player_hurt`", false, false, 3, "0.20-0.35 s", "sfx", 1, false, "Satu-satunya jalur damage pemain yang sudah punya kind."],
	["player_death", "sfx", "Pemain mati.", "Pemain kehabisan HP.", "DeathController.died(respawns_remaining)", false, false, 2, "0.8-1.2 s", "sfx", 1, false, "Dipisah dari sting musik kematian."],
	["player_respawn", "sfx", "Pemain hidup kembali.", "Pemain memilih respawn.", "DeathController.respawned", false, false, 2, "0.5-0.8 s", "sfx", 2, false, "Terdengar setelah layar kematian ditutup."],
	["player_protection_loop", "sfx", "Dengung perlindungan respawn.", "Selama perlindungan respawn aktif.", "PlayerDamageReceiver.protection_started / protection_ended", true, false, 1, "loop", "sfx", 3, true, "Sengaja halus; hanya penanda status."],
	["player_dodge", "sfx", "Pemain mengelak.", "Dodge berhasil.", "CombatFeedback.feedback_event kind `dodge`", false, false, 2, "0.15-0.25 s", "sfx", 2, false, "Sama dengan teks melayang DODGE."],
	["player_attack_swing", "sfx", "Ayunan serangan pemain.", "Pemain menyerang (klik atau Space).", "CombatComponent.swing(aim_direction, hit_count)", false, true, 3, "0.15-0.25 s", "sfx", 1, false, "Berbunyi walau tidak mengenai apa pun."],
	["player_hit_flesh", "sfx", "Pukulan mengenai tubuh hewan.", "Serangan pemain mengenai target.", "CombatComponent.hit_dealt(target, damage)", false, true, 3, "0.15-0.30 s", "sfx", 1, false, "Menumpuk dengan ayunan; jaga headroom."],
	["player_kill_confirm", "sfx", "Konfirmasi target mati.", "Hewan mati oleh serangan pemain.", "CombatFeedback.feedback_event kind `kill`", false, false, 1, "0.25-0.40 s", "sfx", 2, false, "Melengkapi teks KO di damage numbers."],
	["proficiency_level_up", "sfx", "Naik level profisiensi.", "Level profisiensi bertambah.", "ProficiencyComponent.level_changed(prof, level)", false, false, 1, "0.6-0.9 s", "sfx", 2, false, "Tidak diputar untuk XP yang hanya naik sebagian."],
	["proficiency_passive_unlocked", "sfx", "Passive baru terbuka.", "Passive profisiensi terbuka.", "ProficiencyComponent.passive_unlocked(prof, level)", false, false, 1, "0.8-1.2 s", "sfx", 3, true, "Boleh menumpuk dengan level up; beri jeda 0.2 s."],
	["player_low_hp_loop", "sfx", "Detak jantung saat HP rendah.", "HP pemain di bawah ambang bahaya.", "StatsComponent.hp_changed(current, max_value)", true, false, 1, "loop", "sfx", 2, false, "Volume naik saat HP makin rendah; hentikan saat di atas ambang."],
	["player_hunger_warning", "sfx", "Peringatan lapar.", "Tier Hunger turun ke LOW atau ZERO.", "NeedsComponent.tier_changed(need, tier)", false, false, 2, "0.25-0.40 s", "ui", 2, false, "Ditumpuk ke peringatan thirst? Beri jeda 0.3 s."],
	["player_thirst_warning", "sfx", "Peringatan haus.", "Tier Thirst turun ke LOW atau ZERO.", "NeedsComponent.tier_changed(need, tier)", false, false, 2, "0.25-0.40 s", "ui", 2, false, "Nada berbeda dari lapar supaya bisa dibedakan."],
	["player_eat", "sfx", "Pemain makan.", "Item makanan dipakai.", "InventoryComponent.item_used(item, slot_index)", false, false, 2, "0.3-0.5 s", "sfx", 2, false, "Bedakan lewat kategori item, bukan sinyal baru."],
	["player_drink", "sfx", "Pemain minum.", "Item minuman dipakai.", "InventoryComponent.item_used(item, slot_index)", false, false, 2, "0.3-0.5 s", "sfx", 2, false, "Termasuk air matang dan air kelapa."],
	["player_bandage", "sfx", "Pemain membalut luka.", "Item perban dipakai.", "InventoryComponent.item_used(item, slot_index)", false, false, 2, "0.4-0.6 s", "sfx", 3, true, "Hanya item dengan efek regen HP."],
	["player_swap_held", "sfx", "Menukar item di tangan.", "Slot hotbar berganti.", "HotbarSelectionComponent.selected_changed(index, stack)", false, false, 3, "0.05-0.10 s", "sfx", 2, false, "Sangat pendek; jangan menutupi ayunan."],
	["player_use_item", "sfx", "Item dipakai (umum).", "Item apa pun dipakai dari hotbar.", "InventoryComponent.item_used(item, slot_index)", false, false, 2, "0.2-0.3 s", "sfx", 3, true, "Dipakai hanya untuk item yang tidak punya cue khusus."],

	# --- Gathering ----------------------------------------------------------
	["gathering_chop_hit", "sfx", "Kapak mengenai pohon.", "Progres menebang berjalan.", "CombatFeedback.feedback_event kind `chop_hit`", false, true, 3, "0.10-0.20 s", "sfx", 1, false, "Berirama 0.22 s mengikuti ChopFeedback.CHOP_INTERVAL."],
	["gathering_tree_fall", "sfx", "Pohon tumbang.", "Pohon selesai ditebang.", "CombatFeedback.feedback_event kind `tree_fall`", false, true, 2, "0.8-1.4 s", "sfx", 1, false, "Sinkron dengan animasi jatuh 0.6 s."],
	["gathering_mine_hit", "sfx", "Beliung mengenai batu.", "Progres menambang berjalan.", NO_HOOK, false, true, 3, "0.10-0.20 s", "sfx", 2, false, "ResourceNode belum punya sinyal progres per pukulan."],
	["gathering_rock_break", "sfx", "Batu pecah.", "Node batu selesai ditambang.", "ResourceNode.gathered(definition, amount, interactor)", false, true, 2, "0.5-0.9 s", "sfx", 2, false, "Bedakan batu kecil dan besar lewat ukuran, bukan key baru."],
	["gathering_pick_fiber", "sfx", "Memetik serat.", "Semak serat selesai dipanen.", "ResourceNode.gathered(definition, amount, interactor)", false, true, 2, "0.2-0.3 s", "sfx", 2, false, "Tidak ada bunyi per tarikan; hanya saat selesai."],
	["gathering_pick_berry", "sfx", "Memetik buah beri.", "Semak beri selesai dipanen.", "ResourceNode.gathered(definition, amount, interactor)", false, true, 2, "0.2-0.3 s", "sfx", 2, false, "Boleh memakai keluarga yang sama dengan serat."],
	["gathering_pick_coconut", "sfx", "Menurunkan kelapa.", "Pohon kelapa selesai dipanen.", "ResourceNode.gathered(definition, amount, interactor)", false, true, 2, "0.3-0.5 s", "sfx", 3, true, "Bunyi jatuh ke pasir."],
	["gathering_cut_bambu", "sfx", "Memotong bambu.", "Rumpun bambu selesai dipanen.", "ResourceNode.gathered(definition, amount, interactor)", false, true, 2, "0.3-0.5 s", "sfx", 3, true, "Lebih berongga dari kayu."],
	["item_pickup", "sfx", "Item masuk ke tas.", "Item terambil dari tanah.", "InventoryComponent.inventory_changed()", false, false, 3, "0.10-0.20 s", "sfx", 1, false, "Termasuk pickup otomatis dan sisa stack yang gagal masuk."],
	["loot_bag", "sfx", "Membuka kantung jarahan.", "Kantung jarahan diambil.", "LootBag.looted", false, false, 2, "0.3-0.5 s", "sfx", 2, false, "Juga dipakai untuk koper darurat (EmergencySuitcase.looted)."],

	# --- Crafting dan camp --------------------------------------------------
	["station_open", "sfx", "Membuka stasiun kerja.", "Panel Meja Kerja atau Api Unggun dibuka.", "StationPanel.opened(station)", false, false, 2, "0.2-0.3 s", "ui", 2, false, "Sama untuk kedua stasiun; panel tetap membedakan isi."],
	["station_close", "sfx", "Menutup stasiun kerja.", "Panel Meja Kerja atau Api Unggun ditutup.", "StationPanel.closed(station)", false, false, 2, "0.15-0.25 s", "ui", 2, false, "Termasuk penutupan karena pemain menjauh."],
	["craft_loop", "sfx", "Suara proses crafting.", "Selama crafting berjalan.", "CraftingComponent.craft_progress(ratio)", true, false, 1, "loop", "sfx", 2, false, "Boleh satu loop untuk semua resep."],
	["craft_done", "sfx", "Crafting selesai.", "Resep selesai dibuat.", "CraftingComponent.craft_completed(recipe)", false, false, 2, "0.4-0.6 s", "sfx", 1, false, "Jangan berbunyi saat craft dibatalkan."],
	["build_loop", "sfx", "Proses membangun struktur.", "Menahan E pada BlueprintSlot.", "InteractorComponent.progress_changed(ratio)", true, false, 1, "loop", "sfx", 2, false, "BlueprintSlot memakai InteractorComponent untuk progres."],
	["build_done", "sfx", "Struktur selesai dibangun.", "BlueprintSlot selesai dibangun.", "BlueprintSlot.built(structure)", false, true, 2, "0.5-0.8 s", "sfx", 2, false, "Termasuk segmen pagar."],
	["repair_loop", "sfx", "Proses memperbaiki.", "Menahan R pada struktur rusak.", "RepairComponent.progress_changed(ratio)", true, false, 1, "loop", "sfx", 2, false, "Sama seperti build loop, boleh variasi pitch."],
	["repair_done", "sfx", "Perbaikan selesai.", "RepairComponent menyelesaikan perbaikan.", "RepairComponent.repair_completed(structure)", false, true, 2, "0.4-0.6 s", "sfx", 2, false, "Tidak berbunyi saat bahan kurang."],
	["base_place_confirm", "sfx", "Base berhasil didirikan.", "Titik base valid dan dikonfirmasi.", "BasePlacementController.base_placed(center)", false, false, 1, "0.8-1.2 s", "sfx", 2, false, "Momen besar; satu kali per run."],
	["base_place_invalid", "sfx", "Titik base tidak valid.", "Preview base berubah menjadi tidak valid.", "BasePlacementController.preview_changed(valid, reason)", false, false, 2, "0.15-0.25 s", "ui", 2, false, "Throttle: maksimal 4 kali per detik."],
	["fence_hit", "sfx", "Pagar terkena serangan.", "Segmen pagar menerima damage.", "CampStructure.damaged(amount, source) pada FenceSegment", false, true, 2, "0.15-0.25 s", "sfx", 2, false, "Sama untuk gigitan boar dan serangan lain."],
	["fence_break", "sfx", "Segmen pagar hancur.", "HP segmen pagar habis.", "CampStructure.destroyed pada FenceSegment", false, true, 2, "0.5-0.8 s", "sfx", 2, false, "Berbeda dari struktur camp yang hancur."],
	["structure_destroyed", "sfx", "Struktur camp hancur.", "CampStructure apa pun hancur.", "CampStructure.destroyed", false, true, 1, "0.8-1.2 s", "sfx", 2, false, "Termasuk peti yang menjatuhkan isinya."],
	["fire_flint_strike", "sfx", "Gesekan batu api.", "Pemain menekan strike pada QTE api.", "FireStarterController.strike_result(quality, success)", false, false, 3, "0.10-0.20 s", "sfx", 2, false, "Bunyi dasar sebelum kualitas dinilai."],
	["fire_qte_good", "sfx", "Hasil QTE bagus.", "Strike masuk zona GOOD.", "FireStarterController.strike_result(quality, success)", false, false, 2, "0.15-0.25 s", "sfx", 2, false, "Nada pendek yang menandakan kemajuan."],
	["fire_qte_perfect", "sfx", "Hasil QTE sempurna.", "Strike masuk zona PERFECT.", "FireStarterController.strike_result(quality, success)", false, false, 1, "0.25-0.35 s", "sfx", 2, false, "Lebih terang dari GOOD."],
	["fire_qte_miss", "sfx", "QTE meleset.", "Strike gagal atau di luar zona.", "FireStarterController.strike_result(quality, success)", false, false, 2, "0.15-0.25 s", "ui", 2, false, "Batu dihabiskan pada percobaan gagal."],
	["campfire_ignite", "sfx", "Api unggun menyala.", "Percobaan ignition berhasil.", "FireStarterController.finished(success) + Campfire.lit_changed(is_lit)", false, true, 2, "0.6-1.0 s", "sfx", 2, false, "Awal loop api; jangan tumpang tindih dengan loop."],
	["campfire_loop", "sfx", "Loop api unggun menyala.", "Selama api unggun menyala.", "Campfire.lit_changed(is_lit)", true, true, 2, "loop", "ambience", 1, false, "Seamless; volume turun saat pemain menjauh (spatial)."],
	["campfire_ember_loop", "sfx", "Loop bara api.", "Api unggun menyala dengan bahan bakar rendah.", "Campfire.fuel_changed(seconds)", true, true, 2, "loop", "ambience", 2, false, "Pengganti loop utama saat bahan bakar menipis."],
	["campfire_out", "sfx", "Api unggun padam.", "Bahan bakar habis.", "Campfire.fuel_depleted", false, true, 2, "0.5-0.8 s", "sfx", 2, false, "Juga berhenti saat struktur hancur."],
	["cook_sizzle", "sfx", "Mendesis saat memasak.", "Resep stasiun CAMPFIRE selesai.", "CraftingComponent.craft_completed(recipe) dengan stasiun CAMPFIRE", false, true, 2, "0.4-0.6 s", "sfx", 2, false, "Hanya resep bertipe CAMPFIRE."],
	["campfire_refuel", "sfx", "Menambah bahan bakar.", "Pemain menambahkan kayu ke api unggun.", "Campfire.fuel_changed(seconds)", false, true, 2, "0.3-0.5 s", "sfx", 2, false, "Bunyi kayu masuk ke api."],
	["tent_sleep", "sfx", "Tidur di tenda.", "Tidur siang berhasil.", "Tent.sleep_completed", false, false, 2, "0.8-1.2 s", "sfx", 2, false, "Waktu di-skip setelah bunyi ini."],
	["night_watch_start", "sfx", "Mulai jaga malam.", "Jaga Malam dinyalakan.", "NightWatchController.watch_started", false, false, 2, "0.4-0.6 s", "sfx", 2, false, "Boleh jadi bagian awal musik malam."],
	["night_watch_stop", "sfx", "Berhenti jaga malam.", "Jaga Malam berhenti karena alasan apa pun.", "NightWatchController.watch_stopped(reason)", false, false, 2, "0.3-0.5 s", "sfx", 2, false, "Alasan tidak perlu dibedakan oleh suara."],
	["chest_open", "sfx", "Membuka peti.", "Pemain berinteraksi dengan peti.", "Chest.interaction_requested(interactor)", false, true, 2, "0.3-0.5 s", "sfx", 2, false, "Panel peti dibuka setelah sinyal ini."],
	["chest_close", "sfx", "Menutup peti.", "Panel peti ditutup.", "ChestPanel.closed", false, false, 2, "0.2-0.3 s", "sfx", 3, true, "Termasuk penutupan karena jarak."],
	["raid_warning_horn", "sfx", "Tanduk peringatan raid.", "Raid dijadwalkan malam ini.", "RaidDirector.raid_warning(day, count, seconds) + feedback_event kind `raid_warning`", false, false, 2, "1.0-1.6 s", "sfx", 2, false, "Harus terdengar di atas ambience malam."],

	# --- Fauna --------------------------------------------------------------
	["boar_idle", "sfx", "Babi mendengus pelan.", "Babi mengembara tanpa ancaman.", NO_HOOK, false, true, 4, "0.3-0.5 s", "sfx", 3, true, "Diputar acak saat WANDER."],
	["boar_alert", "sfx", "Babi menyadari pemain.", "Babi mulai mengejar.", NO_HOOK, false, true, 2, "0.3-0.5 s", "sfx", 2, false, "Penanda sebelum dash ditelegraf."],
	["boar_telegraph", "sfx", "Babi bersiap menyeruduk.", "Awal DASH_TELEGRAPH.", NO_HOOK, false, true, 2, "0.4-0.6 s", "sfx", 2, false, "Sinkron dengan garis telegraph di CombatFeedback."],
	["boar_charge", "sfx", "Babi menyeruduk.", "Awal DASH.", NO_HOOK, false, true, 2, "0.4-0.7 s", "sfx", 2, false, "WildBoar.dash_ended hanya menandai akhir dash."],
	["boar_bite", "sfx", "Gigitan babi.", "Babi menggigit pemain atau struktur.", NO_HOOK, false, true, 3, "0.20-0.30 s", "sfx", 2, false, "Belum ada sinyal gigitan di FaunaBase."],
	["boar_hurt", "sfx", "Babi terluka.", "Babi menerima damage.", "HealthComponent.damaged(amount, source)", false, true, 3, "0.20-0.30 s", "sfx", 2, false, "Bersama dengan flash_hit."],
	["boar_death", "sfx", "Babi mati.", "HP babi habis.", "FaunaBase.died(node)", false, true, 2, "0.6-1.0 s", "sfx", 2, false, "Jasad visual animasi tetap diputar CombatFeedback."],
	["deer_alert_snort", "sfx", "Rusa mendengus waspada.", "Rusa masuk state ALERT.", "IslandDeer.alerted", false, true, 2, "0.25-0.40 s", "sfx", 2, false, "Satu-satunya tanda bunyi sebelum STARTLE."],
	["deer_startle", "sfx", "Rusa terpaku kaget.", "Rusa masuk state STARTLE.", NO_HOOK, false, true, 2, "0.3-0.5 s", "sfx", 3, true, "Tidak ada sinyal STARTLE; state hanya bisa dibaca lewat get_state."],
	["deer_flee_steps", "sfx", "Langkah rusa kabur.", "Selama rusa FLEE.", NO_HOOK, false, true, 3, "0.15-0.25 s", "sfx", 3, true, "Langkah per frame belum punya sinyal."],
	["deer_hurt", "sfx", "Rusa terluka.", "Rusa menerima damage.", "HealthComponent.damaged(amount, source)", false, true, 3, "0.20-0.30 s", "sfx", 2, false, "Hit pertama langsung memicu FLEE."],
	["deer_death", "sfx", "Rusa mati.", "HP rusa habis.", "FaunaBase.died(node)", false, true, 2, "0.6-1.0 s", "sfx", 2, false, "Jatuh tanpa suara serangan."],

	# --- Dunia --------------------------------------------------------------
	["ambience_day", "ambience", "Suasana siang pulau.", "Fase siang dimulai.", "DayNightManager.phase_changed(phase)", true, false, 1, "loop", "ambience", 2, false, "Loop panjang 60-90 s; crossfade dengan malam."],
	["ambience_night", "ambience", "Suasana malam pulau.", "Fase malam dimulai.", "DayNightManager.night_started(day)", true, false, 1, "loop", "ambience", 1, false, "Dasar ketegangan malam; jangan menutupi raid horn."],
	["river_loop", "ambience", "Suara sungai mengalir.", "Pemain dekat sungai.", NO_HOOK, true, true, 1, "loop", "ambience", 3, true, "Zona sungai terbaca, tetapi belum ada node sungai bersuara."],
	["dawn_transition", "ambience", "Transisi menjelang fajar.", "Malam berakhir.", "DayNightManager.night_ended(day)", false, false, 1, "3-5 s", "ambience", 2, false, "Menutup transisi visual fajar."],
	["dusk_transition", "ambience", "Transisi menjelang malam.", "Senja dimulai.", "DayNightManager.dusk_started(day)", false, false, 1, "3-5 s", "ambience", 2, false, "Peringatan 15 s sebelum malam."],
	["night_start_sting", "sfx", "Sting malam dimulai.", "Malam resmi dimulai.", "DayNightManager.night_started(day)", false, false, 1, "1.5-2.5 s", "sfx", 2, false, "Satu kali per pergantian fase."],
	["dawn_sting", "sfx", "Sting fajar.", "Pagi resmi dimulai.", "DayNightManager.day_started(day)", false, false, 1, "1.5-2.5 s", "sfx", 2, false, "Berbeda dari sting menang."],

	# --- Musik --------------------------------------------------------------
	["music_menu", "music", "Musik menu utama.", "Menu utama tampil.", "RunController.main_menu_requested", true, false, 1, "loop", "music", 2, false, "Loop 60-120 s; duck saat panel pengaturan."],
	["music_day", "music", "Musik eksplorasi siang.", "Hari dimulai.", "DayNightManager.day_started(day)", true, false, 1, "loop", "music", 2, false, "Tenang, rendah dinamika."],
	["music_night_tension", "music", "Musik ketegangan malam.", "Malam dimulai.", "DayNightManager.night_started(day)", true, false, 1, "loop", "music", 2, false, "Naik intensitas saat raid aktif."],
	["music_rescue", "music", "Musik penyelamatan.", "Fase rescue dimulai.", "DayNightManager.rescue_started", true, false, 1, "loop", "music", 3, true, "Hanya di Hari 7."],
	["music_victory", "music", "Musik kemenangan.", "Victory tercapai.", "EndgameController.victory", false, false, 1, "8-12 s", "music", 2, false, "Hentikan musik hari/malam saat mulai."],
	["music_game_over", "music", "Musik game over.", "Token respawn habis.", "DeathController.game_over", true, false, 1, "loop", "music", 2, false, "Layar game over tidak pause game."],
	["music_death_sting", "music", "Sting kematian.", "Pemain mati.", "DeathController.died(respawns_remaining)", false, false, 1, "2-4 s", "music", 3, true, "Duck musik utama 1.5 s."],

	# --- UI -----------------------------------------------------------------
	["ui_click", "ui", "Klik tombol.", "Tombol UI ditekan.", NO_HOOK, false, false, 2, "0.05-0.10 s", "ui", 1, false, "UiSkin membuat tombol runtime, belum ada sinyal bersama."],
	["ui_hover", "ui", "Hover tombol.", "Kursor masuk tombol UI.", NO_HOOK, false, false, 2, "0.03-0.08 s", "ui", 3, true, "Sangat pelan; hanya umpan balik halus."],
	["ui_panel_open", "ui", "Panel terbuka.", "Panel stasiun dibuka.", "StationPanel.opened(station)", false, false, 2, "0.15-0.25 s", "ui", 2, false, "Sama untuk Meja Kerja dan Api Unggun."],
	["ui_panel_close", "ui", "Panel tertutup.", "Panel stasiun atau peti ditutup.", "StationPanel.closed(station) / ChestPanel.closed", false, false, 2, "0.12-0.20 s", "ui", 2, false, "Nada turun, kebalikan panel_open."],
	["ui_error", "ui", "Aksi ditolak.", "Interaksi diblokir dengan alasan.", "InteractorComponent.interaction_blocked(target, reason)", false, false, 2, "0.15-0.25 s", "ui", 2, false, "Jangan diulang tiap frame; throttle 0.3 s."],
	["ui_toast", "ui", "Toast informasi muncul.", "ToastHUD menampilkan pesan.", NO_HOOK, false, false, 2, "0.12-0.20 s", "ui", 2, false, "ToastHUD belum punya sinyal; hanya Label runtime."],
	["ui_hint", "ui", "Petunjuk muncul.", "HintManager menampilkan hint.", "HintManager.hint_shown(id, text)", false, false, 2, "0.25-0.40 s", "ui", 2, false, "Sekali per hint; hint_hidden tanpa suara."],
	["ui_pause_on", "ui", "Game dijeda.", "Pause menu dibuka.", NO_HOOK, false, false, 2, "0.15-0.25 s", "ui", 2, false, "PauseMenu hanya punya sinyal resumed."],
	["ui_pause_off", "ui", "Game dilanjutkan.", "Pause menu ditutup.", "PauseMenu.resumed", false, false, 2, "0.12-0.20 s", "ui", 2, false, "Termasuk tombol Lanjutkan."],
	["ui_banner", "ui", "Banner besar muncul.", "Banner endgame tampil.", "EndgameController.banner_shown(text)", false, false, 2, "0.4-0.6 s", "ui", 2, false, "Banner Hari 7 dan rescue."],
	["ui_tab_switch", "ui", "Ganti tab panel.", "Tab Tas atau Crafting dipilih.", NO_HOOK, false, false, 2, "0.05-0.10 s", "ui", 3, true, "BagPanel tidak punya sinyal ganti tab."],
	["ui_splash_sting", "ui", "Sting singkat saat logo muncul di layar pembuka.", "Setiap logo muncul di layar pembuka.", "SplashScreen.entry_started", false, false, 1, "2 s", "ui", 3, true, "Opsional; diputar saat setiap entri logo muncul di layar pembuka."],

	# --- Endgame ------------------------------------------------------------
	["beacon_activate", "sfx", "Mengaktifkan beacon.", "SignalBeacon dipakai saat rescue.", "SignalBeacon.victory_triggered", false, true, 1, "1.0-1.5 s", "sfx", 2, false, "Suar darurat dikonsumsi setelah ini."],
	["flare_launch", "sfx", "Suar diluncurkan.", "Rescue siap dan suar dipakai.", "EndgameController.rescue_ready", false, false, 1, "0.8-1.2 s", "sfx", 2, false, "Naik dan memudar; jangan loop."],
	["ship_horn", "sfx", "Klakson kapal penyelamat.", "Victory tercapai.", "EndgameController.victory", false, false, 1, "2-3 s", "sfx", 2, false, "Penutup naratif; biarkan musik menang di bawahnya."],
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_PATH.get_base_dir())
	var registry = RegistryScript.new()
	for row in CUES:
		registry.cues.append(_make_cue(row))
	var error: int = ResourceSaver.save(registry, OUTPUT_PATH)
	if error != OK:
		printerr("generate_audio_registry: gagal menyimpan %s (error %d)" % [OUTPUT_PATH, error])
		quit(1)
		return
	print("generate_audio_registry: %s (%d cue)" % [OUTPUT_PATH, registry.size()])
	quit(0)


func _make_cue(row: Array) -> Resource:
	var cue = CueScript.new()
	cue.key = StringName(row[0])
	cue.category = _category(row[1])
	cue.description_id = row[2]
	cue.trigger = row[3]
	cue.hook = row[4]
	cue.loop = row[5]
	cue.spatial = row[6]
	cue.variants_recommended = row[7]
	cue.duration_hint = row[8]
	cue.bus = _bus(row[9])
	cue.priority = row[10]
	cue.optional = row[11]
	cue.notes = row[12]
	cue.file_pattern = cue.expected_pattern()
	return cue


func _category(value: String) -> int:
	match value:
		"music":
			return CueScript.Category.MUSIC
		"ambience":
			return CueScript.Category.AMBIENCE
		"ui":
			return CueScript.Category.UI
		_:
			return CueScript.Category.SFX


func _bus(value: String) -> int:
	match value:
		"master":
			return CueScript.Bus.MASTER
		"music":
			return CueScript.Bus.MUSIC
		"ambience":
			return CueScript.Bus.AMBIENCE
		"ui":
			return CueScript.Bus.UI
		_:
			return CueScript.Bus.SFX

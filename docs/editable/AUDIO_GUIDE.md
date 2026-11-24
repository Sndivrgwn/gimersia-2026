# Panduan Audio

Dokumen ini untuk tim audio. Isinya kebutuhan bunyi game, bukan file audio:
repo **belum** punya playback, `AudioManager`, atau file `.ogg`. Semua yang ada
di sini adalah kontrak data (`AudioRegistry`) supaya pekerjaan audio bisa
dimulai tanpa menebak-nebak.

## Cara pemasangan nanti

1. Satu cue = satu key stabil (`player_hurt`, `campfire_loop`). Key tidak
   berubah walau nama file berubah.
2. Taruh file di folder kategori: `res://assets/audio/sfx/`,
   `res://assets/audio/music/`, `res://assets/audio/ambience/`,
   `res://assets/audio/ui/`.
3. Nama file = key, tambah `_1`..`_N` untuk varian. Contoh:
   `res://assets/audio/sfx/player_hurt_2.ogg`.
4. Pemasangan kode nanti memakai registry ini: satu cue dipetakan ke satu
   pemutar (2D untuk `spatial`, 1D/non-posisional untuk sisanya).
5. Sampai playback ada, cue tanpa titik sambung ditandai `HOOK BELUM ADA` dan
   tidak boleh dianggap sudah terdengar di game.

## Spesifikasi teknis

- Format: **OGG Vorbis** (`.ogg`), satu file per varian.
- Sample rate: **44.1 kHz**.
- Channel: **mono** untuk SFX dan semua cue `spatial`; **stereo** untuk musik
  dan ambience.
- Peak maksimum: **-3 dBFS**, tanpa clipping.
- Musik: sekitar **-18 LUFS** terintegrasi; SFX pendek boleh lebih keras
  sesaat, tetapi tetap di bawah peak.
- Ekor bunyi pendek dan bersih; hindari reverb panjang pada SFX.
- Cue loop: **loop point seamless** (awal dan akhir sampel menyambung),
  tanpa fade di tengah file.
- Ukuran: SFX < 200 KB per varian, musik < 4 MB per menit, ambience loop
  < 3 MB.
- Beri jeda sunyi minimal 5 ms di awal dan akhir file satu-tembak supaya tidak
  terpotong saat diputar.

## Bus dan ducking (saran)

- `Master` -> `Music`, `SFX`, `Ambience`, `UI`.
- `Music` di-duck **-6 dB** selama sting kematian, banner, dan panel jeda.
- `SFX` di-duck **-3 dB** saat musik menang diputar.
- `UI` tidak di-duck; volumenya paling rendah di antara semua bus.
- `Ambience` di-duck **-6 dB** saat raid horn berbunyi.
- Semua nilai di atas adalah titik awal; tuning akhir setelah playtest.


<!-- BEGIN GENERATED -->
## Minimum audio untuk build pertama (prioritas 1)

Cue berikut yang paling menentukan rasa build pertama. Tanpa file-nya,
game tetap jalan, tetapi terasa bisu.

- `campfire_loop` — Loop api unggun menyala.
- `craft_done` — Crafting selesai.
- `gathering_chop_hit` — Kapak mengenai pohon.
- `gathering_tree_fall` — Pohon tumbang.
- `item_pickup` — Item masuk ke tas.
- `player_attack_swing` — Ayunan serangan pemain.
- `player_death` — Pemain mati.
- `player_footstep_sand` — Langkah pemain di pasir pantai.
- `player_hit_flesh` — Pukulan mengenai tubuh hewan.
- `player_hurt` — Pemain terluka.
- `ambience_night` — Suasana malam pulau.
- `ui_click` — Klik tombol.

## SFX

| Cue | Pola file | Wajib/Opsional | Loop | Spatial | Durasi | Varian | Bus | Dipakai di (trigger + hook) | Prioritas |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `base_place_confirm` | `res://assets/audio/sfx/base_place_confirm.ogg` | Penting | tidak | tidak | 0.8-1.2 s | 1 | SFX | Titik base valid dan dikonfirmasi.<br>Hook: BasePlacementController.base_placed(center) | 2 |
| `base_place_invalid` | `res://assets/audio/sfx/base_place_invalid[_1.._2].ogg` | Penting | tidak | tidak | 0.15-0.25 s | 2 | UI | Preview base berubah menjadi tidak valid.<br>Hook: BasePlacementController.preview_changed(valid, reason) | 2 |
| `beacon_activate` | `res://assets/audio/sfx/beacon_activate.ogg` | Penting | tidak | ya | 1.0-1.5 s | 1 | SFX | SignalBeacon dipakai saat rescue.<br>Hook: SignalBeacon.victory_triggered | 2 |
| `boar_alert` | `res://assets/audio/sfx/boar_alert[_1.._2].ogg` | Penting | tidak | ya | 0.3-0.5 s | 2 | SFX | Babi mulai mengejar.<br>Hook: HOOK BELUM ADA | 2 |
| `boar_bite` | `res://assets/audio/sfx/boar_bite[_1.._3].ogg` | Penting | tidak | ya | 0.20-0.30 s | 3 | SFX | Babi menggigit pemain atau struktur.<br>Hook: HOOK BELUM ADA | 2 |
| `boar_charge` | `res://assets/audio/sfx/boar_charge[_1.._2].ogg` | Penting | tidak | ya | 0.4-0.7 s | 2 | SFX | Awal DASH.<br>Hook: HOOK BELUM ADA | 2 |
| `boar_death` | `res://assets/audio/sfx/boar_death[_1.._2].ogg` | Penting | tidak | ya | 0.6-1.0 s | 2 | SFX | HP babi habis.<br>Hook: FaunaBase.died(node) | 2 |
| `boar_hurt` | `res://assets/audio/sfx/boar_hurt[_1.._3].ogg` | Penting | tidak | ya | 0.20-0.30 s | 3 | SFX | Babi menerima damage.<br>Hook: HealthComponent.damaged(amount, source) | 2 |
| `boar_idle` | `res://assets/audio/sfx/boar_idle[_1.._4].ogg` | Opsional | tidak | ya | 0.3-0.5 s | 4 | SFX | Babi mengembara tanpa ancaman.<br>Hook: HOOK BELUM ADA | 3 |
| `boar_telegraph` | `res://assets/audio/sfx/boar_telegraph[_1.._2].ogg` | Penting | tidak | ya | 0.4-0.6 s | 2 | SFX | Awal DASH_TELEGRAPH.<br>Hook: HOOK BELUM ADA | 2 |
| `build_done` | `res://assets/audio/sfx/build_done[_1.._2].ogg` | Penting | tidak | ya | 0.5-0.8 s | 2 | SFX | BlueprintSlot selesai dibangun.<br>Hook: BlueprintSlot.built(structure) | 2 |
| `build_loop` | `res://assets/audio/sfx/build_loop.ogg` | Penting | ya | tidak | loop | 1 | SFX | Menahan E pada BlueprintSlot.<br>Hook: InteractorComponent.progress_changed(ratio) | 2 |
| `campfire_ember_loop` | `res://assets/audio/sfx/campfire_ember_loop[_1.._2].ogg` | Penting | ya | ya | loop | 2 | Ambience | Api unggun menyala dengan bahan bakar rendah.<br>Hook: Campfire.fuel_changed(seconds) | 2 |
| `campfire_ignite` | `res://assets/audio/sfx/campfire_ignite[_1.._2].ogg` | Penting | tidak | ya | 0.6-1.0 s | 2 | SFX | Percobaan ignition berhasil.<br>Hook: FireStarterController.finished(success) + Campfire.lit_changed(is_lit) | 2 |
| `campfire_loop` | `res://assets/audio/sfx/campfire_loop[_1.._2].ogg` | Wajib | ya | ya | loop | 2 | Ambience | Selama api unggun menyala.<br>Hook: Campfire.lit_changed(is_lit) | 1 |
| `campfire_out` | `res://assets/audio/sfx/campfire_out[_1.._2].ogg` | Penting | tidak | ya | 0.5-0.8 s | 2 | SFX | Bahan bakar habis.<br>Hook: Campfire.fuel_depleted | 2 |
| `campfire_refuel` | `res://assets/audio/sfx/campfire_refuel[_1.._2].ogg` | Penting | tidak | ya | 0.3-0.5 s | 2 | SFX | Pemain menambahkan kayu ke api unggun.<br>Hook: Campfire.fuel_changed(seconds) | 2 |
| `chest_close` | `res://assets/audio/sfx/chest_close[_1.._2].ogg` | Opsional | tidak | tidak | 0.2-0.3 s | 2 | SFX | Panel peti ditutup.<br>Hook: ChestPanel.closed | 3 |
| `chest_open` | `res://assets/audio/sfx/chest_open[_1.._2].ogg` | Penting | tidak | ya | 0.3-0.5 s | 2 | SFX | Pemain berinteraksi dengan peti.<br>Hook: Chest.interaction_requested(interactor) | 2 |
| `cook_sizzle` | `res://assets/audio/sfx/cook_sizzle[_1.._2].ogg` | Penting | tidak | ya | 0.4-0.6 s | 2 | SFX | Resep stasiun CAMPFIRE selesai.<br>Hook: CraftingComponent.craft_completed(recipe) dengan stasiun CAMPFIRE | 2 |
| `craft_done` | `res://assets/audio/sfx/craft_done[_1.._2].ogg` | Wajib | tidak | tidak | 0.4-0.6 s | 2 | SFX | Resep selesai dibuat.<br>Hook: CraftingComponent.craft_completed(recipe) | 1 |
| `craft_loop` | `res://assets/audio/sfx/craft_loop.ogg` | Penting | ya | tidak | loop | 1 | SFX | Selama crafting berjalan.<br>Hook: CraftingComponent.craft_progress(ratio) | 2 |
| `dawn_sting` | `res://assets/audio/sfx/dawn_sting.ogg` | Penting | tidak | tidak | 1.5-2.5 s | 1 | SFX | Pagi resmi dimulai.<br>Hook: DayNightManager.day_started(day) | 2 |
| `deer_alert_snort` | `res://assets/audio/sfx/deer_alert_snort[_1.._2].ogg` | Penting | tidak | ya | 0.25-0.40 s | 2 | SFX | Rusa masuk state ALERT.<br>Hook: IslandDeer.alerted | 2 |
| `deer_death` | `res://assets/audio/sfx/deer_death[_1.._2].ogg` | Penting | tidak | ya | 0.6-1.0 s | 2 | SFX | HP rusa habis.<br>Hook: FaunaBase.died(node) | 2 |
| `deer_flee_steps` | `res://assets/audio/sfx/deer_flee_steps[_1.._3].ogg` | Opsional | tidak | ya | 0.15-0.25 s | 3 | SFX | Selama rusa FLEE.<br>Hook: HOOK BELUM ADA | 3 |
| `deer_hurt` | `res://assets/audio/sfx/deer_hurt[_1.._3].ogg` | Penting | tidak | ya | 0.20-0.30 s | 3 | SFX | Rusa menerima damage.<br>Hook: HealthComponent.damaged(amount, source) | 2 |
| `deer_startle` | `res://assets/audio/sfx/deer_startle[_1.._2].ogg` | Opsional | tidak | ya | 0.3-0.5 s | 2 | SFX | Rusa masuk state STARTLE.<br>Hook: HOOK BELUM ADA | 3 |
| `fence_break` | `res://assets/audio/sfx/fence_break[_1.._2].ogg` | Penting | tidak | ya | 0.5-0.8 s | 2 | SFX | HP segmen pagar habis.<br>Hook: CampStructure.destroyed pada FenceSegment | 2 |
| `fence_hit` | `res://assets/audio/sfx/fence_hit[_1.._2].ogg` | Penting | tidak | ya | 0.15-0.25 s | 2 | SFX | Segmen pagar menerima damage.<br>Hook: CampStructure.damaged(amount, source) pada FenceSegment | 2 |
| `fire_flint_strike` | `res://assets/audio/sfx/fire_flint_strike[_1.._3].ogg` | Penting | tidak | tidak | 0.10-0.20 s | 3 | SFX | Pemain menekan strike pada QTE api.<br>Hook: FireStarterController.strike_result(quality, success) | 2 |
| `fire_qte_good` | `res://assets/audio/sfx/fire_qte_good[_1.._2].ogg` | Penting | tidak | tidak | 0.15-0.25 s | 2 | SFX | Strike masuk zona GOOD.<br>Hook: FireStarterController.strike_result(quality, success) | 2 |
| `fire_qte_miss` | `res://assets/audio/sfx/fire_qte_miss[_1.._2].ogg` | Penting | tidak | tidak | 0.15-0.25 s | 2 | UI | Strike gagal atau di luar zona.<br>Hook: FireStarterController.strike_result(quality, success) | 2 |
| `fire_qte_perfect` | `res://assets/audio/sfx/fire_qte_perfect.ogg` | Penting | tidak | tidak | 0.25-0.35 s | 1 | SFX | Strike masuk zona PERFECT.<br>Hook: FireStarterController.strike_result(quality, success) | 2 |
| `flare_launch` | `res://assets/audio/sfx/flare_launch.ogg` | Penting | tidak | tidak | 0.8-1.2 s | 1 | SFX | Rescue siap dan suar dipakai.<br>Hook: EndgameController.rescue_ready | 2 |
| `gathering_chop_hit` | `res://assets/audio/sfx/gathering_chop_hit[_1.._3].ogg` | Wajib | tidak | ya | 0.10-0.20 s | 3 | SFX | Progres menebang berjalan.<br>Hook: CombatFeedback.feedback_event kind `chop_hit` | 1 |
| `gathering_cut_bambu` | `res://assets/audio/sfx/gathering_cut_bambu[_1.._2].ogg` | Opsional | tidak | ya | 0.3-0.5 s | 2 | SFX | Rumpun bambu selesai dipanen.<br>Hook: ResourceNode.gathered(definition, amount, interactor) | 3 |
| `gathering_mine_hit` | `res://assets/audio/sfx/gathering_mine_hit[_1.._3].ogg` | Penting | tidak | ya | 0.10-0.20 s | 3 | SFX | Progres menambang berjalan.<br>Hook: HOOK BELUM ADA | 2 |
| `gathering_pick_berry` | `res://assets/audio/sfx/gathering_pick_berry[_1.._2].ogg` | Penting | tidak | ya | 0.2-0.3 s | 2 | SFX | Semak beri selesai dipanen.<br>Hook: ResourceNode.gathered(definition, amount, interactor) | 2 |
| `gathering_pick_coconut` | `res://assets/audio/sfx/gathering_pick_coconut[_1.._2].ogg` | Opsional | tidak | ya | 0.3-0.5 s | 2 | SFX | Pohon kelapa selesai dipanen.<br>Hook: ResourceNode.gathered(definition, amount, interactor) | 3 |
| `gathering_pick_fiber` | `res://assets/audio/sfx/gathering_pick_fiber[_1.._2].ogg` | Penting | tidak | ya | 0.2-0.3 s | 2 | SFX | Semak serat selesai dipanen.<br>Hook: ResourceNode.gathered(definition, amount, interactor) | 2 |
| `gathering_rock_break` | `res://assets/audio/sfx/gathering_rock_break[_1.._2].ogg` | Penting | tidak | ya | 0.5-0.9 s | 2 | SFX | Node batu selesai ditambang.<br>Hook: ResourceNode.gathered(definition, amount, interactor) | 2 |
| `gathering_tree_fall` | `res://assets/audio/sfx/gathering_tree_fall[_1.._2].ogg` | Wajib | tidak | ya | 0.8-1.4 s | 2 | SFX | Pohon selesai ditebang.<br>Hook: CombatFeedback.feedback_event kind `tree_fall` | 1 |
| `item_pickup` | `res://assets/audio/sfx/item_pickup[_1.._3].ogg` | Wajib | tidak | tidak | 0.10-0.20 s | 3 | SFX | Item terambil dari tanah.<br>Hook: InventoryComponent.inventory_changed() | 1 |
| `loot_bag` | `res://assets/audio/sfx/loot_bag[_1.._2].ogg` | Penting | tidak | tidak | 0.3-0.5 s | 2 | SFX | Kantung jarahan diambil.<br>Hook: LootBag.looted | 2 |
| `night_start_sting` | `res://assets/audio/sfx/night_start_sting.ogg` | Penting | tidak | tidak | 1.5-2.5 s | 1 | SFX | Malam resmi dimulai.<br>Hook: DayNightManager.night_started(day) | 2 |
| `night_watch_start` | `res://assets/audio/sfx/night_watch_start[_1.._2].ogg` | Penting | tidak | tidak | 0.4-0.6 s | 2 | SFX | Jaga Malam dinyalakan.<br>Hook: NightWatchController.watch_started | 2 |
| `night_watch_stop` | `res://assets/audio/sfx/night_watch_stop[_1.._2].ogg` | Penting | tidak | tidak | 0.3-0.5 s | 2 | SFX | Jaga Malam berhenti karena alasan apa pun.<br>Hook: NightWatchController.watch_stopped(reason) | 2 |
| `player_attack_swing` | `res://assets/audio/sfx/player_attack_swing[_1.._3].ogg` | Wajib | tidak | ya | 0.15-0.25 s | 3 | SFX | Pemain menyerang (klik atau Space).<br>Hook: CombatComponent.swing(aim_direction, hit_count) | 1 |
| `player_bandage` | `res://assets/audio/sfx/player_bandage[_1.._2].ogg` | Opsional | tidak | tidak | 0.4-0.6 s | 2 | SFX | Item perban dipakai.<br>Hook: InventoryComponent.item_used(item, slot_index) | 3 |
| `player_death` | `res://assets/audio/sfx/player_death[_1.._2].ogg` | Wajib | tidak | tidak | 0.8-1.2 s | 2 | SFX | Pemain kehabisan HP.<br>Hook: DeathController.died(respawns_remaining) | 1 |
| `player_dodge` | `res://assets/audio/sfx/player_dodge[_1.._2].ogg` | Penting | tidak | tidak | 0.15-0.25 s | 2 | SFX | Dodge berhasil.<br>Hook: CombatFeedback.feedback_event kind `dodge` | 2 |
| `player_drink` | `res://assets/audio/sfx/player_drink[_1.._2].ogg` | Penting | tidak | tidak | 0.3-0.5 s | 2 | SFX | Item minuman dipakai.<br>Hook: InventoryComponent.item_used(item, slot_index) | 2 |
| `player_eat` | `res://assets/audio/sfx/player_eat[_1.._2].ogg` | Penting | tidak | tidak | 0.3-0.5 s | 2 | SFX | Item makanan dipakai.<br>Hook: InventoryComponent.item_used(item, slot_index) | 2 |
| `player_footstep_grass` | `res://assets/audio/sfx/player_footstep_grass[_1.._4].ogg` | Penting | tidak | ya | 0.15-0.30 s | 4 | SFX | Setiap langkah saat pemain berjalan di zona hutan atau camp.<br>Hook: HOOK BELUM ADA | 2 |
| `player_footstep_sand` | `res://assets/audio/sfx/player_footstep_sand[_1.._4].ogg` | Wajib | tidak | ya | 0.15-0.30 s | 4 | SFX | Setiap langkah saat pemain berjalan di zona pantai.<br>Hook: HOOK BELUM ADA | 1 |
| `player_footstep_wade` | `res://assets/audio/sfx/player_footstep_wade[_1.._3].ogg` | Opsional | tidak | ya | 0.25-0.40 s | 3 | SFX | Setiap langkah saat pemain wading.<br>Hook: HOOK BELUM ADA | 3 |
| `player_footstep_water` | `res://assets/audio/sfx/player_footstep_water[_1.._3].ogg` | Opsional | tidak | ya | 0.15-0.30 s | 3 | SFX | Setiap langkah saat pemain berada di zona sungai.<br>Hook: HOOK BELUM ADA | 3 |
| `player_hit_flesh` | `res://assets/audio/sfx/player_hit_flesh[_1.._3].ogg` | Wajib | tidak | ya | 0.15-0.30 s | 3 | SFX | Serangan pemain mengenai target.<br>Hook: CombatComponent.hit_dealt(target, damage) | 1 |
| `player_hunger_warning` | `res://assets/audio/sfx/player_hunger_warning[_1.._2].ogg` | Penting | tidak | tidak | 0.25-0.40 s | 2 | UI | Tier Hunger turun ke LOW atau ZERO.<br>Hook: NeedsComponent.tier_changed(need, tier) | 2 |
| `player_hurt` | `res://assets/audio/sfx/player_hurt[_1.._3].ogg` | Wajib | tidak | tidak | 0.20-0.35 s | 3 | SFX | Pemain menerima damage.<br>Hook: CombatFeedback.feedback_event kind `player_hurt` | 1 |
| `player_kill_confirm` | `res://assets/audio/sfx/player_kill_confirm.ogg` | Penting | tidak | tidak | 0.25-0.40 s | 1 | SFX | Hewan mati oleh serangan pemain.<br>Hook: CombatFeedback.feedback_event kind `kill` | 2 |
| `player_low_hp_loop` | `res://assets/audio/sfx/player_low_hp_loop.ogg` | Penting | ya | tidak | loop | 1 | SFX | HP pemain di bawah ambang bahaya.<br>Hook: StatsComponent.hp_changed(current, max_value) | 2 |
| `player_protection_loop` | `res://assets/audio/sfx/player_protection_loop.ogg` | Opsional | ya | tidak | loop | 1 | SFX | Selama perlindungan respawn aktif.<br>Hook: PlayerDamageReceiver.protection_started / protection_ended | 3 |
| `player_respawn` | `res://assets/audio/sfx/player_respawn[_1.._2].ogg` | Penting | tidak | tidak | 0.5-0.8 s | 2 | SFX | Pemain memilih respawn.<br>Hook: DeathController.respawned | 2 |
| `player_sneak_step` | `res://assets/audio/sfx/player_sneak_step[_1.._3].ogg` | Penting | tidak | ya | 0.10-0.20 s | 3 | SFX | Setiap langkah saat pemain jongkok.<br>Hook: HOOK BELUM ADA | 2 |
| `player_sprint_breath` | `res://assets/audio/sfx/player_sprint_breath[_1.._2].ogg` | Penting | ya | tidak | loop | 2 | SFX | Selama pemain sprint.<br>Hook: Player.sprint_state_changed(is_sprinting) | 2 |
| `player_swap_held` | `res://assets/audio/sfx/player_swap_held[_1.._3].ogg` | Penting | tidak | tidak | 0.05-0.10 s | 3 | SFX | Slot hotbar berganti.<br>Hook: HotbarSelectionComponent.selected_changed(index, stack) | 2 |
| `player_thirst_warning` | `res://assets/audio/sfx/player_thirst_warning[_1.._2].ogg` | Penting | tidak | tidak | 0.25-0.40 s | 2 | UI | Tier Thirst turun ke LOW atau ZERO.<br>Hook: NeedsComponent.tier_changed(need, tier) | 2 |
| `player_use_item` | `res://assets/audio/sfx/player_use_item[_1.._2].ogg` | Opsional | tidak | tidak | 0.2-0.3 s | 2 | SFX | Item apa pun dipakai dari hotbar.<br>Hook: InventoryComponent.item_used(item, slot_index) | 3 |
| `proficiency_level_up` | `res://assets/audio/sfx/proficiency_level_up.ogg` | Penting | tidak | tidak | 0.6-0.9 s | 1 | SFX | Level profisiensi bertambah.<br>Hook: ProficiencyComponent.level_changed(prof, level) | 2 |
| `proficiency_passive_unlocked` | `res://assets/audio/sfx/proficiency_passive_unlocked.ogg` | Opsional | tidak | tidak | 0.8-1.2 s | 1 | SFX | Passive profisiensi terbuka.<br>Hook: ProficiencyComponent.passive_unlocked(prof, level) | 3 |
| `raid_warning_horn` | `res://assets/audio/sfx/raid_warning_horn[_1.._2].ogg` | Penting | tidak | tidak | 1.0-1.6 s | 2 | SFX | Raid dijadwalkan malam ini.<br>Hook: RaidDirector.raid_warning(day, count, seconds) + feedback_event kind `raid_warning` | 2 |
| `repair_done` | `res://assets/audio/sfx/repair_done[_1.._2].ogg` | Penting | tidak | ya | 0.4-0.6 s | 2 | SFX | RepairComponent menyelesaikan perbaikan.<br>Hook: RepairComponent.repair_completed(structure) | 2 |
| `repair_loop` | `res://assets/audio/sfx/repair_loop.ogg` | Penting | ya | tidak | loop | 1 | SFX | Menahan R pada struktur rusak.<br>Hook: RepairComponent.progress_changed(ratio) | 2 |
| `ship_horn` | `res://assets/audio/sfx/ship_horn.ogg` | Penting | tidak | tidak | 2-3 s | 1 | SFX | Victory tercapai.<br>Hook: EndgameController.victory | 2 |
| `station_close` | `res://assets/audio/sfx/station_close[_1.._2].ogg` | Penting | tidak | tidak | 0.15-0.25 s | 2 | UI | Panel Meja Kerja atau Api Unggun ditutup.<br>Hook: StationPanel.closed(station) | 2 |
| `station_open` | `res://assets/audio/sfx/station_open[_1.._2].ogg` | Penting | tidak | tidak | 0.2-0.3 s | 2 | UI | Panel Meja Kerja atau Api Unggun dibuka.<br>Hook: StationPanel.opened(station) | 2 |
| `structure_destroyed` | `res://assets/audio/sfx/structure_destroyed.ogg` | Penting | tidak | ya | 0.8-1.2 s | 1 | SFX | CampStructure apa pun hancur.<br>Hook: CampStructure.destroyed | 2 |
| `tent_sleep` | `res://assets/audio/sfx/tent_sleep[_1.._2].ogg` | Penting | tidak | tidak | 0.8-1.2 s | 2 | SFX | Tidur siang berhasil.<br>Hook: Tent.sleep_completed | 2 |

## Musik

| Cue | Pola file | Wajib/Opsional | Loop | Spatial | Durasi | Varian | Bus | Dipakai di (trigger + hook) | Prioritas |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `music_day` | `res://assets/audio/music/music_day.ogg` | Penting | ya | tidak | loop | 1 | Music | Hari dimulai.<br>Hook: DayNightManager.day_started(day) | 2 |
| `music_death_sting` | `res://assets/audio/music/music_death_sting.ogg` | Opsional | tidak | tidak | 2-4 s | 1 | Music | Pemain mati.<br>Hook: DeathController.died(respawns_remaining) | 3 |
| `music_game_over` | `res://assets/audio/music/music_game_over.ogg` | Penting | ya | tidak | loop | 1 | Music | Token respawn habis.<br>Hook: DeathController.game_over | 2 |
| `music_menu` | `res://assets/audio/music/music_menu.ogg` | Penting | ya | tidak | loop | 1 | Music | Menu utama tampil.<br>Hook: RunController.main_menu_requested | 2 |
| `music_night_tension` | `res://assets/audio/music/music_night_tension.ogg` | Penting | ya | tidak | loop | 1 | Music | Malam dimulai.<br>Hook: DayNightManager.night_started(day) | 2 |
| `music_rescue` | `res://assets/audio/music/music_rescue.ogg` | Opsional | ya | tidak | loop | 1 | Music | Fase rescue dimulai.<br>Hook: DayNightManager.rescue_started | 3 |
| `music_victory` | `res://assets/audio/music/music_victory.ogg` | Penting | tidak | tidak | 8-12 s | 1 | Music | Victory tercapai.<br>Hook: EndgameController.victory | 2 |

## Ambience

| Cue | Pola file | Wajib/Opsional | Loop | Spatial | Durasi | Varian | Bus | Dipakai di (trigger + hook) | Prioritas |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `ambience_day` | `res://assets/audio/ambience/ambience_day.ogg` | Penting | ya | tidak | loop | 1 | Ambience | Fase siang dimulai.<br>Hook: DayNightManager.phase_changed(phase) | 2 |
| `ambience_night` | `res://assets/audio/ambience/ambience_night.ogg` | Wajib | ya | tidak | loop | 1 | Ambience | Fase malam dimulai.<br>Hook: DayNightManager.night_started(day) | 1 |
| `dawn_transition` | `res://assets/audio/ambience/dawn_transition.ogg` | Penting | tidak | tidak | 3-5 s | 1 | Ambience | Malam berakhir.<br>Hook: DayNightManager.night_ended(day) | 2 |
| `dusk_transition` | `res://assets/audio/ambience/dusk_transition.ogg` | Penting | tidak | tidak | 3-5 s | 1 | Ambience | Senja dimulai.<br>Hook: DayNightManager.dusk_started(day) | 2 |
| `river_loop` | `res://assets/audio/ambience/river_loop.ogg` | Opsional | ya | ya | loop | 1 | Ambience | Pemain dekat sungai.<br>Hook: HOOK BELUM ADA | 3 |

## UI

| Cue | Pola file | Wajib/Opsional | Loop | Spatial | Durasi | Varian | Bus | Dipakai di (trigger + hook) | Prioritas |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `ui_banner` | `res://assets/audio/ui/ui_banner[_1.._2].ogg` | Penting | tidak | tidak | 0.4-0.6 s | 2 | UI | Banner endgame tampil.<br>Hook: EndgameController.banner_shown(text) | 2 |
| `ui_click` | `res://assets/audio/ui/ui_click[_1.._2].ogg` | Wajib | tidak | tidak | 0.05-0.10 s | 2 | UI | Tombol UI ditekan.<br>Hook: HOOK BELUM ADA | 1 |
| `ui_error` | `res://assets/audio/ui/ui_error[_1.._2].ogg` | Penting | tidak | tidak | 0.15-0.25 s | 2 | UI | Interaksi diblokir dengan alasan.<br>Hook: InteractorComponent.interaction_blocked(target, reason) | 2 |
| `ui_hint` | `res://assets/audio/ui/ui_hint[_1.._2].ogg` | Penting | tidak | tidak | 0.25-0.40 s | 2 | UI | HintManager menampilkan hint.<br>Hook: HintManager.hint_shown(id, text) | 2 |
| `ui_hover` | `res://assets/audio/ui/ui_hover[_1.._2].ogg` | Opsional | tidak | tidak | 0.03-0.08 s | 2 | UI | Kursor masuk tombol UI.<br>Hook: HOOK BELUM ADA | 3 |
| `ui_panel_close` | `res://assets/audio/ui/ui_panel_close[_1.._2].ogg` | Penting | tidak | tidak | 0.12-0.20 s | 2 | UI | Panel stasiun atau peti ditutup.<br>Hook: StationPanel.closed(station) / ChestPanel.closed | 2 |
| `ui_panel_open` | `res://assets/audio/ui/ui_panel_open[_1.._2].ogg` | Penting | tidak | tidak | 0.15-0.25 s | 2 | UI | Panel stasiun dibuka.<br>Hook: StationPanel.opened(station) | 2 |
| `ui_pause_off` | `res://assets/audio/ui/ui_pause_off[_1.._2].ogg` | Penting | tidak | tidak | 0.12-0.20 s | 2 | UI | Pause menu ditutup.<br>Hook: PauseMenu.resumed | 2 |
| `ui_pause_on` | `res://assets/audio/ui/ui_pause_on[_1.._2].ogg` | Penting | tidak | tidak | 0.15-0.25 s | 2 | UI | Pause menu dibuka.<br>Hook: HOOK BELUM ADA | 2 |
| `ui_tab_switch` | `res://assets/audio/ui/ui_tab_switch[_1.._2].ogg` | Opsional | tidak | tidak | 0.05-0.10 s | 2 | UI | Tab Tas atau Crafting dipilih.<br>Hook: HOOK BELUM ADA | 3 |
| `ui_toast` | `res://assets/audio/ui/ui_toast[_1.._2].ogg` | Penting | tidak | tidak | 0.12-0.20 s | 2 | UI | ToastHUD menampilkan pesan.<br>Hook: HOOK BELUM ADA | 2 |

## Hook yang sudah ada

- `base_place_confirm` -> BasePlacementController.base_placed(center)
- `base_place_invalid` -> BasePlacementController.preview_changed(valid, reason)
- `beacon_activate` -> SignalBeacon.victory_triggered
- `boar_death` -> FaunaBase.died(node)
- `boar_hurt` -> HealthComponent.damaged(amount, source)
- `build_done` -> BlueprintSlot.built(structure)
- `build_loop` -> InteractorComponent.progress_changed(ratio)
- `campfire_ember_loop` -> Campfire.fuel_changed(seconds)
- `campfire_ignite` -> FireStarterController.finished(success) + Campfire.lit_changed(is_lit)
- `campfire_loop` -> Campfire.lit_changed(is_lit)
- `campfire_out` -> Campfire.fuel_depleted
- `campfire_refuel` -> Campfire.fuel_changed(seconds)
- `chest_close` -> ChestPanel.closed
- `chest_open` -> Chest.interaction_requested(interactor)
- `cook_sizzle` -> CraftingComponent.craft_completed(recipe) dengan stasiun CAMPFIRE
- `craft_done` -> CraftingComponent.craft_completed(recipe)
- `craft_loop` -> CraftingComponent.craft_progress(ratio)
- `dawn_sting` -> DayNightManager.day_started(day)
- `deer_alert_snort` -> IslandDeer.alerted
- `deer_death` -> FaunaBase.died(node)
- `deer_hurt` -> HealthComponent.damaged(amount, source)
- `fence_break` -> CampStructure.destroyed pada FenceSegment
- `fence_hit` -> CampStructure.damaged(amount, source) pada FenceSegment
- `fire_flint_strike` -> FireStarterController.strike_result(quality, success)
- `fire_qte_good` -> FireStarterController.strike_result(quality, success)
- `fire_qte_miss` -> FireStarterController.strike_result(quality, success)
- `fire_qte_perfect` -> FireStarterController.strike_result(quality, success)
- `flare_launch` -> EndgameController.rescue_ready
- `gathering_chop_hit` -> CombatFeedback.feedback_event kind `chop_hit`
- `gathering_cut_bambu` -> ResourceNode.gathered(definition, amount, interactor)
- `gathering_pick_berry` -> ResourceNode.gathered(definition, amount, interactor)
- `gathering_pick_coconut` -> ResourceNode.gathered(definition, amount, interactor)
- `gathering_pick_fiber` -> ResourceNode.gathered(definition, amount, interactor)
- `gathering_rock_break` -> ResourceNode.gathered(definition, amount, interactor)
- `gathering_tree_fall` -> CombatFeedback.feedback_event kind `tree_fall`
- `item_pickup` -> InventoryComponent.inventory_changed()
- `loot_bag` -> LootBag.looted
- `night_start_sting` -> DayNightManager.night_started(day)
- `night_watch_start` -> NightWatchController.watch_started
- `night_watch_stop` -> NightWatchController.watch_stopped(reason)
- `player_attack_swing` -> CombatComponent.swing(aim_direction, hit_count)
- `player_bandage` -> InventoryComponent.item_used(item, slot_index)
- `player_death` -> DeathController.died(respawns_remaining)
- `player_dodge` -> CombatFeedback.feedback_event kind `dodge`
- `player_drink` -> InventoryComponent.item_used(item, slot_index)
- `player_eat` -> InventoryComponent.item_used(item, slot_index)
- `player_hit_flesh` -> CombatComponent.hit_dealt(target, damage)
- `player_hunger_warning` -> NeedsComponent.tier_changed(need, tier)
- `player_hurt` -> CombatFeedback.feedback_event kind `player_hurt`
- `player_kill_confirm` -> CombatFeedback.feedback_event kind `kill`
- `player_low_hp_loop` -> StatsComponent.hp_changed(current, max_value)
- `player_protection_loop` -> PlayerDamageReceiver.protection_started / protection_ended
- `player_respawn` -> DeathController.respawned
- `player_sprint_breath` -> Player.sprint_state_changed(is_sprinting)
- `player_swap_held` -> HotbarSelectionComponent.selected_changed(index, stack)
- `player_thirst_warning` -> NeedsComponent.tier_changed(need, tier)
- `player_use_item` -> InventoryComponent.item_used(item, slot_index)
- `proficiency_level_up` -> ProficiencyComponent.level_changed(prof, level)
- `proficiency_passive_unlocked` -> ProficiencyComponent.passive_unlocked(prof, level)
- `raid_warning_horn` -> RaidDirector.raid_warning(day, count, seconds) + feedback_event kind `raid_warning`
- `repair_done` -> RepairComponent.repair_completed(structure)
- `repair_loop` -> RepairComponent.progress_changed(ratio)
- `ship_horn` -> EndgameController.victory
- `station_close` -> StationPanel.closed(station)
- `station_open` -> StationPanel.opened(station)
- `structure_destroyed` -> CampStructure.destroyed
- `tent_sleep` -> Tent.sleep_completed
- `music_day` -> DayNightManager.day_started(day)
- `music_death_sting` -> DeathController.died(respawns_remaining)
- `music_game_over` -> DeathController.game_over
- `music_menu` -> RunController.main_menu_requested
- `music_night_tension` -> DayNightManager.night_started(day)
- `music_rescue` -> DayNightManager.rescue_started
- `music_victory` -> EndgameController.victory
- `ambience_day` -> DayNightManager.phase_changed(phase)
- `ambience_night` -> DayNightManager.night_started(day)
- `dawn_transition` -> DayNightManager.night_ended(day)
- `dusk_transition` -> DayNightManager.dusk_started(day)
- `ui_banner` -> EndgameController.banner_shown(text)
- `ui_error` -> InteractorComponent.interaction_blocked(target, reason)
- `ui_hint` -> HintManager.hint_shown(id, text)
- `ui_panel_close` -> StationPanel.closed(station) / ChestPanel.closed
- `ui_panel_open` -> StationPanel.opened(station)
- `ui_pause_off` -> PauseMenu.resumed

## Hook yang belum ada

- `boar_alert` — Babi menyadari pemain.
- `boar_bite` — Gigitan babi.
- `boar_charge` — Babi menyeruduk.
- `boar_idle` — Babi mendengus pelan.
- `boar_telegraph` — Babi bersiap menyeruduk.
- `deer_flee_steps` — Langkah rusa kabur.
- `deer_startle` — Rusa terpaku kaget.
- `gathering_mine_hit` — Beliung mengenai batu.
- `player_footstep_grass` — Langkah pemain di rumput atau hutan.
- `player_footstep_sand` — Langkah pemain di pasir pantai.
- `player_footstep_wade` — Langkah berat saat mengarungi air.
- `player_footstep_water` — Langkah pemain di air dangkal.
- `player_sneak_step` — Langkah sangat pelan saat jongkok.
- `river_loop` — Suara sungai mengalir.
- `ui_click` — Klik tombol.
- `ui_hover` — Hover tombol.
- `ui_pause_on` — Game dijeda.
- `ui_tab_switch` — Ganti tab panel.
- `ui_toast` — Toast informasi muncul.

<!-- END GENERATED -->

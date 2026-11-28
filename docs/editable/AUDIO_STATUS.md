# Status Integrasi Audio

Dokumen ini merangkum seluruh pekerjaan integrasi audio yang **sudah selesai dikerjakan** beserta daftar file yang sudah dipasang mengikuti pola [AUDIO_GUIDE.md](AUDIO_GUIDE.md). Untuk daftar aset yang masih belum ada atau baru memakai proxy sementara, lihat [AUDIO_MISSING.md](AUDIO_MISSING.md).

---

## Ringkasan Progres

| Kategori | Total di Panduan | Sudah Terintegrasi | Belum Ada / Kosong | Catatan |
| --- | :---: | :---: | :---: | --- |
| Musik & Sting (`music/`) | 7 | **3** *(sting)* | **4** *(loop)* | `music_death_sting`, `music_game_over`, `music_victory` sudah terpasang (pakai sting pendek) |
| Ambience (`ambience/`) | 5 (+2 layer pantai) | **3** (+2 layer) | **2** | Hutan, Pantai (`ocean + wind`), Malam, dan Sungai sudah aktif dengan crossfade |
| SFX (`sfx/`) | 80 | **35** | **45** | Termasuk 12 cue fauna (`boar_*`, `deer_*`) yang sengaja dikosongkan dulu |
| UI (`ui/`) | 12 | **11** | **1** | Semua `.ogg`; hanya `ui_splash_sting` yang belum ada |
| **Total Cue Panduan** | **104** | **52** *(+2 layer pantai)* | **52** | **12/12 cue Prioritas 1 (Wajib) sudah aktif terdengar di game** |

---

## Infrastruktur yang Sudah Dibangun

1. **Audio Bus Layout** — [default_bus_layout.tres](../../default_bus_layout.tres) (didaftarkan di `project.godot`)
   - Bus: `Master` → `Music`, `SFX`, `Ambience`, `UI` (`UI` di-set `-3 dB` agar tidak menutupi gameplay).
2. **Autoload `AudioManager`** — [audio_manager.gd](../../src/core/managers/audio_manager.gd)
   - Membaca kontrak dari [audio_registry.tres](../../src/data/audio/audio_registry.tres) dan memuat otomatis file `.ogg` sesuai pola `res://assets/audio/<kategori>/<key>[_1.._8].ogg`.
   - Pool playback non-spasial (`16` player) & spasial 2D (`16` `AudioStreamPlayer2D`), random pitch halus agar 1 varian tidak terasa monoton, serta throttling untuk mencegah spam.
   - **Global UI Hook:** semua `BaseButton` di seluruh scene otomatis terhubung ke `ui_click` (pressed) dan `ui_hover` (mouse_entered).
   - **Ducking otomatis:** saat `PauseMenu` terbuka, `Music` di-duck `-6 dB` dan `Ambience` `-4 dB`; sting kematian/kemenangan juga men-duck musik utama.
   - **Ambience Zone Crossfade (~1.8 detik):**
     - **Hutan / Camp (Siang):** `ambience_day.ogg` (`forest.ogg`)
     - **Pantai Selatan & Timur (Siang):** layer `ambience_beach_ocean.ogg` + `ambience_beach_wind.ogg`
     - **Sungai (Siang):** `river_loop.ogg` + sedikit `ambience_day.ogg`
     - **Tebing Barat (Siang):** `ambience_beach_wind.ogg` + sedikit `ambience_day.ogg` & `ocean`
     - **Malam:** `ambience_night.ogg` (di pantai tetap ada sisa ombak & angin halus; di sungai tetap ada aliran sungai halus).
3. **Bridge Gameplay Pulau** — [island_audio_bridge.gd](../../src/core/managers/island_audio_bridge.gd) (terpasang di [island.gd](../../src/levels/island/island.gd))
   - Menghubungkan semua sinyal gameplay yang sudah ada tanpa memodifikasi komponen inti.
   - Menambahkan pelacakan langkah kaki pemain per zona (`sand`, `grass`, `water`, `wade`) dan irama menambang batu (`gathering_mine_hit`).
   - Memasang loop spasial `campfire_loop` langsung pada setiap `Campfire` yang menyala.
4. **Sinyal Tambahan** — `signal paused` pada [pause_menu.gd](../../src/ui/menus/pause_menu.gd) agar `ui_pause_on` dan ducking pause aktif tepat saat jeda dibuka.
5. **Tes Otomatis** — [test_audio_manager.gd](../../tests/unit/test_audio_manager.gd) (verifikasi bus, 12 cue Prioritas 1, fauna kosong, crossfade hutan↔pantai, dan sinyal `PauseMenu`).

---

## Daftar Aset yang Sudah Terpasang & Terintegrasi

### 1. Ambience (`assets/audio/ambience/`)

| Cue / Layer | File Terpasang | Sumber Pack | Hook / Perilaku |
| --- | --- | --- | --- |
| `ambience_day` | `ambience_day.ogg` | `ambience/forest.ogg` | Siang di Hutan / Camp (crossfade halus) |
| `ambience_beach_ocean` *(layer)* | `ambience_beach_ocean.ogg` | `ambience/ocean.ogg` | Layer ombak saat di Pantai Selatan/Timur |
| `ambience_beach_wind` *(layer)* | `ambience_beach_wind.ogg` | `ambience/wind.ogg` | Layer angin saat di Pantai & Tebing Barat |
| `ambience_night` | `ambience_night.ogg` | `ambience/night.ogg` | Fase malam (`DayNightManager.is_night()`) |
| `river_loop` | `river_loop.ogg` | `ambience/river.ogg` | Saat pemain berada di zona Sungai |

### 2. Musik & Sting (`assets/audio/music/`)

| Cue | File Terpasang | Sumber Pack | Hook / Perilaku | Status |
| --- | --- | --- | --- | --- |
| `music_death_sting` | `music_death_sting.ogg` | `sfx/moments/game-over.ogg` | `DeathController.died` (menu respawn) | Aktif |
| `music_game_over` | `music_game_over.ogg` | `sfx/moments/game-over.ogg` | `DeathController.game_over` | Sting sementara |
| `music_victory` | `music_victory.ogg` | `sfx/moments/victory.ogg` | `EndgameController.victory` | Sting sementara |

### 3. UI (`assets/audio/ui/` — Semua `.ogg`)

| Cue | File Terpasang | Sumber Pack | Hook / Perilaku |
| --- | --- | --- | --- |
| `ui_click` | `ui_click.ogg` | `sfx/interface/click.ogg` | Global `BaseButton.pressed` |
| `ui_hover` | `ui_hover.ogg` | `sfx/interface/tap.ogg` | Global `BaseButton.mouse_entered` (volume halus) |
| `ui_pause_on` | `ui_pause_on.ogg` | `sfx/interface/menu-open.ogg` | `PauseMenu.paused` |
| `ui_pause_off` | `ui_pause_off.ogg` | `sfx/interface/menu-close.ogg` | `PauseMenu.resumed` |
| `ui_panel_open` | `ui_panel_open.ogg` | `sfx/interface/menu-open.ogg` | Siap pakai untuk panel umum |
| `ui_panel_close` | `ui_panel_close.ogg` | `sfx/interface/menu-close.ogg` | `ChestPanel.closed` |
| `ui_error` | `ui_error.ogg` | `sfx/interface/error.ogg` | `InteractorComponent.interaction_blocked` (throttled 0.3s) |
| `ui_hint` | `ui_hint.ogg` | `sfx/interface/notification.ogg` | `HintManager.hint_shown` |
| `ui_toast` | `ui_toast.ogg` | `sfx/interface/message.ogg` | File siap (menunggu hook sinyal `ToastHUD`) |
| `ui_banner` | `ui_banner.ogg` | `sfx/interface/popup.ogg` | `EndgameController.banner_shown` |
| `ui_tab_switch` | `ui_tab_switch.ogg` | `sfx/interface/toggle.ogg` | File siap (menunggu hook sinyal tab `BagPanel`) |

### 4. SFX (`assets/audio/sfx/`)

| Cue | File Terpasang | Sumber Pack | Hook / Perilaku |
| --- | --- | --- | --- |
| `campfire_loop` | `campfire_loop.ogg` | `ambience/campfire.ogg` | Loop spasial di `Campfire` (`lit_changed`) |
| `player_attack_swing` | `player_attack_swing.ogg` | `sfx/combat/whip-crack.ogg` | `CombatComponent.swing` (spasial) |
| `player_hit_flesh` | `player_hit_flesh.ogg` | `sfx/combat/dagger-stab.ogg` | `CombatComponent.hit_dealt` (spasial) |
| `player_hurt` | `player_hurt.ogg` | `sfx/combat/punch.ogg` | `CombatFeedback.feedback_event` (`player_hurt`) |
| `player_death` | `player_death.ogg` | `sfx/combat/body-fall.ogg` | `DeathController.died` |
| `player_dodge` | `player_dodge.ogg` | `sfx/movement/dash.ogg` | `CombatFeedback.feedback_event` (`dodge`) |
| `player_bandage` | `player_bandage.ogg` | `sfx/pickups/health.ogg` | `InventoryComponent.item_used` (efek heal/regen) |
| `player_eat` | `player_eat.ogg` | `sfx/pickups/food.ogg` | `InventoryComponent.item_used` (efek hunger) |
| `player_drink` | `player_drink.ogg` | `sfx/magic/potion.ogg` | `InventoryComponent.item_used` (efek thirst) |
| `player_footstep_sand` | `player_footstep_sand.ogg` | `sfx/movement/steps-sand.ogg` | Langkah pemain di zona Pantai |
| `player_footstep_grass` | `player_footstep_grass.ogg` | `sfx/movement/steps-grass.ogg` | Langkah pemain di Hutan / Camp / Tebing |
| `player_footstep_water` | `player_footstep_water.ogg` | `sfx/movement/splash.ogg` | Langkah pemain di zona Sungai |
| `player_footstep_wade` | `player_footstep_wade.ogg` | `sfx/movement/swim.ogg` | Langkah pemain saat `is_wading()` |
| `player_swap_held` | `player_swap_held.ogg` | `sfx/interface/tap.ogg` | `HotbarSelectionComponent.selected_changed` |
| `item_pickup` | `item_pickup.ogg` | `sfx/pickups/item-equip.ogg` | `InventoryComponent.inventory_changed` (saat item bertambah) |
| `loot_bag` | `loot_bag.ogg` | `sfx/pickups/coin-bag.ogg` | `LootBag.looted` & `EmergencySuitcase.looted` |
| `chest_open` | `chest_open.ogg` | `sfx/pickups/chest-open.ogg` | `Chest.interaction_requested` (spasial) |
| `gathering_chop_hit` | `gathering_chop_hit.ogg` | `sfx/combat/axe-hit.ogg` | `ChopFeedback.feedback_event` (`chop_hit`, spasial) |
| `gathering_tree_fall` | `gathering_tree_fall.ogg` | `sfx/explosions/heavy-thud.ogg` | `ChopFeedback.feedback_event` (`tree_fall`, spasial) |
| `gathering_mine_hit` | `gathering_mine_hit.ogg` | `sfx/explosions/metal-impact.ogg` | Irama hold-E pada `ResourceNode` batu (spasial) |
| `gathering_rock_break` | `gathering_rock_break.ogg` | `sfx/explosions/rock-smash.ogg` | `ResourceNode.gathered` tipe batu (spasial) |
| `fence_hit` | `fence_hit.ogg` | `sfx/combat/hammer-smash.ogg` | `FenceSegment.damaged` (spasial) |
| `fence_break` | `fence_break.ogg` | `sfx/explosions/crate-break.ogg` | `FenceSegment.destroyed` (spasial) |
| `structure_destroyed` | `structure_destroyed.ogg` | `sfx/explosions/wall-collapse.ogg` | `CampStructure.destroyed` (spasial) |
| `craft_done` | `craft_done.ogg` | `sfx/interface/confirm.ogg` | `CraftingComponent.craft_completed` |
| `build_done` | `build_done.ogg` | `sfx/interface/confirm.ogg` | `BlueprintSlot.built` (spasial) |
| `repair_done` | `repair_done.ogg` | `sfx/interface/confirm.ogg` | `RepairComponent.repair_completed` (spasial) |
| `base_place_confirm` | `base_place_confirm.ogg` | `sfx/interface/confirm.ogg` | `BasePlacementController.base_placed` |
| `base_place_invalid` | `base_place_invalid.ogg` | `sfx/interface/error.ogg` | `BasePlacementController.preview_changed` (throttled) |
| `station_open` | `station_open.ogg` | `sfx/interface/menu-open.ogg` | `StationPanel.opened` |
| `station_close` | `station_close.ogg` | `sfx/interface/menu-close.ogg` | `StationPanel.closed` |
| `proficiency_level_up` | `proficiency_level_up.ogg` | `sfx/interface/level-up.ogg` | `ProficiencyComponent.level_changed` |
| `proficiency_passive_unlocked` | `proficiency_passive_unlocked.ogg` | `sfx/interface/unlock.ogg` | `ProficiencyComponent.passive_unlocked` |
| `flare_launch` | `flare_launch.ogg` | `sfx/explosions/firework.ogg` | `EndgameController.rescue_ready` |
| `beacon_activate` | `beacon_activate.ogg` | `sfx/moments/checkpoint.ogg` | `SignalBeacon.victory_triggered` (spasial) |

---

## Langkah Selanjutnya

Lihat [AUDIO_MISSING.md](AUDIO_MISSING.md) untuk daftar lengkap aset yang masih kosong (musik loop, suara fauna babi/rusa, loop proses crafting/build/repair, efek api unggun/masak, dan varian `_2.._4`). Begitu file `.ogg` baru ditaruh sesuai pola `AUDIO_GUIDE.md`, `AudioManager` akan langsung mendeteksinya secara otomatis.

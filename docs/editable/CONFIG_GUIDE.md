# Panduan Konfigurasi

Dokumen ini untuk desainer: semua angka gameplay disimpan di Resource `.tres`
supaya bisa diubah dari Inspector Godot tanpa menyentuh kode.

## Mengapa Resource

- Satu sumber angka: kode membaca `config.field`, tidak menyalin nilai.
- Bisa di-tune di Inspector, lalu dijalankan ulang — tanpa rebuild.
- Tes memakai nilai yang sama, jadi balance dan tes tidak bisa berbeda.

## Mengedit `.tres` dengan aman

1. Buka file `.tres` di Godot (double click) — Inspector menampilkan field.
2. Ubah nilai, `Ctrl+S`. Jangan edit teks `.tres` dengan editor teks biasa
   kecuali Anda paham formatnya (urutan properti dan id sub-resource bisa rusak).
3. Jalankan tes terkait (kolom "Tes terkait") sebelum commit.

## PERINGATAN: generator menimpa edit tangan

Menjalankan `tools/generate_*.gd` MENULIS ULANG file yang dimilikinya. Jangan
mengedit file tersebut di Inspector tanpa memindahkan angkanya ke generator.


<!-- BEGIN GENERATED -->
## Peta pemilik file

| Generator | Perintah | File `.tres` yang ditulis |
| --- | --- | --- |
| `res://tools/generate_asset_registry.gd` | `GODOT --headless --path . -s tools/generate_asset_registry.gd` | res://src/data/assets/asset_registry.tres |
| `res://tools/generate_audio_registry.gd` | `GODOT --headless --path . -s tools/generate_audio_registry.gd` | res://src/data/audio/audio_registry.tres |
| `res://tools/generate_balance_data.gd` | `GODOT --headless --path . -s tools/generate_balance_data.gd` | res://src/data/configs/health_regen_config.tres, res://src/data/configs/needs_config.tres, res://src/data/configs/run_config.tres, res://src/data/configs/sneak_config.tres, res://src/data/configs/wading_config.tres |
| `res://tools/generate_body_profiles.gd` | `GODOT --headless --path . -s tools/generate_body_profiles.gd` | res://src/data/configs/physics/body_island_deer.tres, res://src/data/configs/physics/body_player.tres, res://src/data/configs/physics/body_wild_boar.tres |
| `res://tools/generate_camera_feel_config.gd` | `GODOT --headless --path . -s tools/generate_camera_feel_config.gd` | res://src/data/configs/camera_feel_config.tres |
| `res://tools/generate_clock_format.gd` | `GODOT --headless --path . -s tools/generate_clock_format.gd` | res://src/data/configs/environment/clock_format.tres |
| `res://tools/generate_combat_data.gd` | `GODOT --headless --path . -s tools/generate_combat_data.gd` | res://src/data/configs/combat_config.tres, res://src/data/configs/fauna/boar_config.tres, res://src/data/configs/fauna/deer_config.tres, res://src/data/configs/fauna/ember_snuff_config.tres, res://src/data/configs/fauna/night_scaling_config.tres, res://src/data/configs/fauna/raid_config.tres |
| `res://tools/generate_compass_config.gd` | `GODOT --headless --path . -s tools/generate_compass_config.gd` | res://src/data/configs/compass_config.tres |
| `res://tools/generate_daily_goals.gd` | `GODOT --headless --path . -s tools/generate_daily_goals.gd` | res://src/data/configs/daily_goals.tres, res://src/data/configs/dawn_recap_config.tres |
| `res://tools/generate_fauna_configs.gd` | `GODOT --headless --path . -s tools/generate_fauna_configs.gd` | res://src/data/configs/fauna/boar_config.tres, res://src/data/configs/fauna/deer_config.tres |
| `res://tools/generate_guides.gd` | `GODOT --headless --path . -s tools/generate_guides.gd` | — (tidak menulis .tres) |
| `res://tools/generate_held_item_data.gd` | `GODOT --headless --path . -s tools/generate_held_item_data.gd` | res://src/data/configs/held_item_config.tres |
| `res://tools/generate_hints.gd` | `GODOT --headless --path . -s tools/generate_hints.gd` | res://src/data/hints/base_place.tres, res://src/data/hints/campfire_cold.tres, res://src/data/hints/crafting.tres, res://src/data/hints/dusk.tres, res://src/data/hints/fence.tres, res://src/data/hints/gather.tres, res://src/data/hints/hunger_sprint_lock.tres, res://src/data/hints/need_low.tres, res://src/data/hints/neutral_hit.tres, res://src/data/hints/repair.tres |
| `res://tools/generate_input_guide.gd` | `GODOT --headless --path . -s tools/generate_input_guide.gd` | — (tidak menulis .tres) |
| `res://tools/generate_player_light.gd` | `GODOT --headless --path . -s tools/generate_player_light.gd` | res://src/data/configs/player_light_config.tres |
| `res://tools/generate_proficiency_data.gd` | `GODOT --headless --path . -s tools/generate_proficiency_data.gd` | res://src/data/configs/proficiency_config.tres |
| `res://tools/generate_recipes.gd` | `GODOT --headless --path . -s tools/generate_recipes.gd` | res://src/data/recipes/boiled_water.tres, res://src/data/recipes/bone_broth.tres, res://src/data/recipes/bone_spear.tres, res://src/data/recipes/cooked_meat.tres, res://src/data/recipes/herbal_bandage.tres, res://src/data/recipes/leather_vest.tres, res://src/data/recipes/signal_flare.tres, res://src/data/recipes/stone_axe.tres, res://src/data/recipes/stone_pickaxe.tres, res://src/data/recipes/stone_spear.tres, res://src/data/recipes/torch.tres, res://src/data/recipes/waterskin.tres, res://src/data/recipes/wooden_spear.tres |
| `res://tools/generate_sample_world.gd` | `GODOT --headless --path . -s tools/generate_sample_world.gd` | res://src/data/gathering/bamboo_clump.tres, res://src/data/gathering/berry_bush.tres, res://src/data/gathering/big_rock.tres, res://src/data/gathering/coconut_palm.tres, res://src/data/gathering/fiber_bush.tres, res://src/data/gathering/small_rock.tres, res://src/data/gathering/small_tree.tres, res://src/data/gathering/tree.tres, res://src/data/gathering/twig.tres |
| `res://tools/generate_station_data.gd` | `GODOT --headless --path . -s tools/generate_station_data.gd` | res://src/data/configs/station_config.tres |
| `res://tools/generate_structures.gd` | `GODOT --headless --path . -s tools/generate_structures.gd` | res://src/data/camp/campfire.tres, res://src/data/camp/chest.tres, res://src/data/camp/fence_segment.tres, res://src/data/camp/tent.tres, res://src/data/camp/workbench.tres, res://src/data/configs/campfire_config.tres, res://src/data/configs/fence_config.tres |
| `res://tools/generate_sun_config.gd` | `GODOT --headless --path . -s tools/generate_sun_config.gd` | res://src/data/configs/environment/day_night_visual_default.tres, res://src/data/configs/environment/sun_config.tres |
| `res://tools/generate_world_config.gd` | `GODOT --headless --path . -s tools/generate_world_config.gd` | res://src/data/configs/world/world_config.tres |

## src/data/assets

### `res://src/data/assets/asset_registry.tres`

- Kelas: `asset_registry.gd` (`res://src/data/resources/assets/asset_registry.gd`)
- Tujuan: Daftar semua slot aset (digenerate).
- Dipakai oleh: Assets, VisualSlot, UiSkin, check_assets
- Pemilik: generator
- Efek tuning: Menambah slot membuat visual baru bisa diganti art.
- Tes terkait: test_assets_core.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `slots` | Array | [67 item] |


## src/data/audio

### `res://src/data/audio/audio_registry.tres`

- Kelas: `audio_registry.gd` (`res://src/data/resources/audio/audio_registry.gd`)
- Tujuan: Daftar semua cue audio (key, kategori, hook, bus, prioritas). Data dan dokumentasi saja.
- Dipakai oleh: AUDIO_GUIDE (generator), test_audio_guide_sync; belum ada playback
- Pemilik: generator
- Efek tuning: Menambah cue berarti satu key baru di panduan audio; tidak mengubah gameplay.
- Tes terkait: test_audio_guide_sync.gd, test_docs_in_sync.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `cues` | Array | [103 item] |


## src/data/camp

### `res://src/data/camp/campfire.tres`

- Kelas: `structure_definition.gd` (`res://src/data/resources/camp/structure_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | campfire |
| `display_name` | String | Api Unggun |
| `scene` | Resource | (res://src/entities/camp/campfire/campfire.ts... |
| `max_hp` | float | 250.00 |
| `build_cost` | Array | [3 item] |
| `build_time` | float | 2.50 |
| `aggro_priority` | int | 0 |
| `repair_cost` | Array | [2 item] |
| `repair_hp` | float | 80.00 |
| `slot_position` | Vector2 | 0.0 × 0.0 |

### `res://src/data/camp/chest.tres`

- Kelas: `structure_definition.gd` (`res://src/data/resources/camp/structure_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | chest |
| `display_name` | String | Peti |
| `scene` | Resource | (res://src/entities/camp/chest/chest.tscn):<P... |
| `max_hp` | float | 200.00 |
| `build_cost` | Array | [2 item] |
| `build_time` | float | 2.50 |
| `aggro_priority` | int | 1 |
| `repair_cost` | Array | [1 item] |
| `repair_hp` | float | 80.00 |
| `slot_position` | Vector2 | 96.0 × -32.0 |

### `res://src/data/camp/fence_segment.tres`

- Kelas: `structure_definition.gd` (`res://src/data/resources/camp/structure_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | fence_segment |
| `display_name` | String | Pagar |
| `scene` | Resource | (res://src/entities/camp/fence/fence_segment.... |
| `max_hp` | float | 60.00 |
| `build_cost` | Array | [2 item] |
| `build_time` | float | 1.50 |
| `aggro_priority` | int | 3 |
| `repair_cost` | Array | [1 item] |
| `repair_hp` | float | 30.00 |
| `slot_position` | Vector2 | 0.0 × 0.0 |

### `res://src/data/camp/tent.tres`

- Kelas: `structure_definition.gd` (`res://src/data/resources/camp/structure_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | tent |
| `display_name` | String | Tenda Daun |
| `scene` | Resource | (res://src/entities/camp/tent/tent.tscn):<Pac... |
| `max_hp` | float | 120.00 |
| `build_cost` | Array | [3 item] |
| `build_time` | float | 4.00 |
| `aggro_priority` | int | 2 |
| `repair_cost` | Array | [2 item] |
| `repair_hp` | float | 60.00 |
| `slot_position` | Vector2 | 0.0 × -110.0 |

### `res://src/data/camp/workbench.tres`

- Kelas: `structure_definition.gd` (`res://src/data/resources/camp/structure_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | workbench |
| `display_name` | String | Meja Kerja |
| `scene` | Resource | (res://src/entities/camp/workbench/workbench.... |
| `max_hp` | float | 180.00 |
| `build_cost` | Array | [3 item] |
| `build_time` | float | 3.00 |
| `aggro_priority` | int | 1 |
| `repair_cost` | Array | [2 item] |
| `repair_hp` | float | 70.00 |
| `slot_position` | Vector2 | -96.0 × -32.0 |


## src/data/configs

### `res://src/data/configs/asset_config.tres`

- Kelas: `asset_config.gd` (`res://src/data/resources/assets/asset_config.gd`)
- Tujuan: Filter pixel-art, fallback mirror, fps default animasi.
- Dipakai oleh: Assets, VisualSlot
- Pemilik: edit tangan
- Efek tuning: Mematikan mirror membuat arah tanpa art jatuh ke placeholder.
- Tes terkait: test_assets_core.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `pixel_art` | bool | true |
| `mirror_fallback` | bool | true |
| `default_fps` | Dictionary | {8 entri} |

### `res://src/data/configs/camera_feel_config.tres`

- Kelas: `camera_feel_config.gd` (`res://src/data/resources/camera/camera_feel_config.gd`)
- Tujuan: Look-ahead/zoom kamera dan margin batas tepi pulau.
- Dipakai oleh: CameraFeel, CameraFeelConfig
- Pemilik: generator
- Efek tuning: Mengubah rasa kamera dan seberapa dalam batas tepi pulau ditarik.
- Tes terkait: test_fase3_camera_telegraph.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `look_ahead_px` | float | 11.00 |
| `follow_speed` | float | 3.20 |
| `day_zoom` | float | 3.00 |
| `night_zoom` | float | 2.75 |
| `zoom_time` | float | 1.40 |
| `camera_limit_margin` | float | 0.00 |

### `res://src/data/configs/campfire_config.tres`

- Kelas: `campfire_config.gd` (`res://src/data/resources/camp/campfire_config.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `start_lit` | bool | false |
| `initial_fuel_seconds` | float | 240.00 |
| `unlit_light_radius` | float | 0.00 |
| `start_fuel` | float | 240.00 |
| `max_fuel` | float | 600.00 |
| `day_drain` | float | 0.25 |
| `night_drain` | float | 1.00 |
| `full_threshold` | float | 580.00 |
| `refuel_wood_cost` | int | 2 |
| `refuel_seconds` | float | 180.00 |
| `refuel_hold_time` | float | 0.50 |
| `manual_ignition_enabled` | bool | true |
| `lit_light_radius` | float | 240.00 |
| `ember_light_radius` | float | 80.00 |
| `dazzle_radius` | float | 180.00 |
| `rest_radius` | float | 120.00 |
| `rest_regen` | float | 5.00 |
| `rest_check_interval` | float | 0.25 |

### `res://src/data/configs/combat_config.tres`

- Kelas: `combat_config.gd` (`res://src/data/resources/combat/combat_config.gd`)
- Tujuan: Damage, jangkauan, cooldown, knockback.
- Dipakai oleh: CombatComponent, PlayerDamageReceiver
- Pemilik: generator
- Efek tuning: Rasa tempur: seberapa cepat dan keras serangan.
- Tes terkait: test_combat_component.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `bare_range` | float | 45.00 |
| `cone_angle_degrees` | float | 90.00 |
| `fatigue_cost_per_hit` | float | 1.20 |
| `knockback_distance` | float | 60.00 |
| `knockback_duration` | float | 0.20 |
| `bleed_dps` | float | 2.00 |
| `bleed_duration` | float | 3.00 |
| `bleed_weapon_ids` | Array | [1 item] |
| `floating_text_lifetime` | float | 0.80 |

### `res://src/data/configs/compass_config.tres`

- Kelas: `compass_config.gd` (`res://src/data/resources/hud/compass_config.gd`)
- Tujuan: Ambang jarak panah base dan penanda tas jatuh.
- Dipakai oleh: CampArrow, LootBagArrow, CompassConfig
- Pemilik: generator
- Efek tuning: Menentukan kapan penunjuk arah muncul/hilang; tidak mengubah gameplay.
- Tes terkait: test_fase2_navigation.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `camp_arrow_distance` | float | 600.00 |
| `loot_arrow_distance` | float | 40.00 |

### `res://src/data/configs/daily_goals.tres`

- Kelas: `daily_goal_config.gd` (`res://src/data/resources/goals/daily_goal_config.gd`)
- Tujuan: Daftar tujuan harian (HUD kiri bawah) untuk Hari 1-7.
- Dipakai oleh: DailyGoalHUD, DailyGoalConfig, DailyGoal
- Pemilik: generator
- Efek tuning: Mengubah teks/urutan tujuan; kondisi dibaca dari tas, struktur, dan base.
- Tes terkait: test_daily_goals_and_light.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `goals` | Array | [17 item] |

### `res://src/data/configs/dawn_recap_config.tres`

- Kelas: `dawn_recap_config.gd` (`res://src/data/resources/recap/dawn_recap_config.gd`)
- Tujuan: Durasi panel rekap fajar.
- Dipakai oleh: DawnRecapHUD, DawnRecapConfig
- Pemilik: generator
- Efek tuning: Berapa lama panel rekap tampil sebelum menutup sendiri.
- Tes terkait: test_daily_goals_and_light.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `panel_seconds` | float | 6.00 |
| `fade_seconds` | float | 0.35 |

### `res://src/data/configs/fence_config.tres`

- Kelas: `fence_config.gd` (`res://src/data/resources/camp/fence_config.gd`)
- Tujuan: Jumlah segmen, radius ring, dan daya tahan pagar.
- Dipakai oleh: FenceRing, FenceSegment
- Pemilik: generator
- Efek tuning: Bentuk dan kekuatan pagar base.
- Tes terkait: test_fence.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `ring_radius` | float | 200.00 |
| `segment_count` | int | 20 |
| `segment_length` | float | 66.00 |
| `thickness` | float | 10.00 |
| `hp` | float | 60.00 |
| `build_time` | float | 1.50 |
| `build_wood` | int | 1 |
| `build_fiber` | int | 1 |
| `repair_wood` | int | 1 |
| `repair_hp` | float | 30.00 |
| `aggro_priority` | int | 3 |
| `blocks_player` | bool | false |

### `res://src/data/configs/fire_starter_config.tres`

- Kelas: `fire_starter_config.gd` (`res://src/data/resources/combat/fire_starter_config.gd`)
- Tujuan: Minigame gesek batu untuk menyalakan api.
- Dipakai oleh: FireStarterController
- Pemilik: edit tangan
- Efek tuning: Seberapa sulit menyalakan api COLD.
- Tes terkait: test_fire_starter.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `strikes_per_attempt` | int | 3 |
| `sweep_period` | float | 1.10 |
| `perfect_zone` | float | 0.12 |
| `good_zone` | float | 0.30 |
| `miss_chance` | float | 0.10 |
| `good_chance` | float | 0.45 |
| `perfect_chance` | float | 0.80 |
| `hold_time` | float | 0.30 |
| `stone_cost` | int | 1 |
| `consume_stone_on_fail_only` | bool | true |
| `fail_cooldown` | float | 0.80 |
| `cancel_distance` | float | 96.00 |

### `res://src/data/configs/health_regen_config.tres`

- Kelas: `health_regen_config.gd` (`res://src/data/resources/needs/health_regen_config.gd`)
- Tujuan: Regen HP pasif: laju, jeda keluar combat, dan kurva Hunger/Thirst.
- Dipakai oleh: HealthRegenComponent
- Pemilik: generator
- Efek tuning: Seberapa cepat HP pulih dan seberapa besar penalti need rendah.
- Tes terkait: test_health_regen.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `base_regen_per_second` | float | 0.50 |
| `out_of_combat_delay` | float | 6.00 |
| `regen_hunger_curve` | lain | [(0.0, 0.0), (30.0, 0.3), (60.0, 0.75), (100.... |
| `regen_thirst_curve` | lain | [(0.0, 0.0), (30.0, 0.3), (60.0, 0.75), (100.... |

### `res://src/data/configs/held_item_config.tres`

- Kelas: `held_item_config.gd` (`res://src/data/resources/items/held_item_config.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `hand_offset_down` | Vector2 | 10.0 × -2.0 |
| `hand_offset_up` | Vector2 | -10.0 × -8.0 |
| `hand_offset_left` | Vector2 | -10.0 × -2.0 |
| `hand_offset_right` | Vector2 | 10.0 × -2.0 |
| `hand_size` | Vector2 | 14.0 × 14.0 |
| `walk_bob` | float | 1.00 |
| `swing_arc_degrees` | float | 70.00 |
| `swing_seconds` | float | 0.12 |
| `use_bob_seconds` | float | 0.25 |
| `show_tool_while_gathering` | bool | true |

### `res://src/data/configs/interaction_config.tres`

- Kelas: `interaction_config.gd` (`res://src/data/resources/interaction/interaction_config.gd`)
- Tujuan: Jarak interaksi dan waktu tahan E.
- Dipakai oleh: InteractorComponent, Interactable
- Pemilik: edit tangan
- Efek tuning: Seberapa dekat pemain harus berdiri dan berapa lama menahan E.
- Tes terkait: test_interactor_component.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `interaction_range` | float | 64.00 |
| `scan_interval` | float | 0.10 |

### `res://src/data/configs/inventory_config.tres`

- Kelas: `inventory_config.gd` (`res://src/data/resources/items/inventory_config.gd`)
- Tujuan: Ukuran tas, radius pickup, jeda pickup.
- Dipakai oleh: InventoryComponent, ItemPickup
- Pemilik: edit tangan
- Efek tuning: Jumlah slot dan seberapa mudah item terambil.
- Tes terkait: test_inventory_component.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `bag_size` | int | 12 |
| `hotbar_size` | int | 5 |
| `pickup_delay` | float | 0.50 |
| `pickup_radius` | float | 24.00 |
| `hotbar_select_mode` | bool | true |

### `res://src/data/configs/island_layout.tres`

- Kelas: `island_layout_config.gd` (`res://src/data/resources/island/island_layout_config.gd`)
- Tujuan: Titik spawn resource, fauna, dan zona pulau FORMULA.
- Dipakai oleh: IslandBuilder, NightSpawner, FormulaWorld, WorldValidator
- Pemilik: edit tangan
- Efek tuning: Isi dan kepadatan pulau FORMULA (AUTHORED memakai scene sendiri).
- Tes terkait: test_island.gd, test_world_golden.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `layout_seed` | int | 20260101 |
| `half_size` | float | 2400.00 |
| `coast_margin` | float | 150.00 |
| `min_spacing` | float | 70.00 |
| `keep_out_radius` | float | 140.00 |
| `beacon_keep_out` | float | 150.00 |
| `camp_ring_min` | float | 220.00 |
| `camp_ring_max` | float | 700.00 |
| `max_attempts` | int | 2000 |
| `markers_min_distance` | float | 1100.00 |
| `camp_starters_last_respawn_day` | int | 4 |
| `camp_twig` | int | 10 |
| `camp_small_rock` | int | 8 |
| `camp_fiber_bush` | int | 5 |
| `camp_berry_bush` | int | 4 |
| `camp_small_tree` | int | 6 |
| `south_coconut_palm` | int | 12 |
| `west_small_rock` | int | 14 |
| `west_big_rock` | int | 8 |
| `river_bamboo` | int | 14 |
| `forest_tree` | int | 30 |
| `forest_fiber_bush` | int | 24 |
| `forest_berry_bush` | int | 18 |
| `night_spawn_markers` | int | 16 |

### `res://src/data/configs/juice_config.tres`

- Kelas: `juice_config.gd` (`res://src/data/resources/combat/juice_config.gd`)
- Tujuan: Hit-stop, shake, flash, squash, intensitas efek.
- Dipakai oleh: CombatFeedback
- Pemilik: edit tangan
- Efek tuning: Seberapa berat pukulan terasa (tanpa mengubah damage).
- Tes terkait: test_combat_feedback.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `intensity` | float | 1.00 |
| `screenshake_enabled` | bool | true |
| `hit_stop_light` | float | 0.05 |
| `hit_stop_heavy` | float | 0.09 |
| `shake_light` | float | 3.00 |
| `shake_light_time` | float | 0.12 |
| `shake_heavy` | float | 6.00 |
| `shake_heavy_time` | float | 0.18 |
| `shake_kill` | float | 5.00 |
| `shake_kill_time` | float | 0.15 |
| `shake_player_hurt` | float | 7.00 |
| `shake_player_hurt_time` | float | 0.22 |
| `knockback_light` | float | 28.00 |
| `knockback_heavy` | float | 45.00 |
| `knockback_time` | float | 0.12 |
| `squash_scale` | Vector2 | 1.25 × 0.8 |
| `squash_time` | float | 0.12 |
| `flash_color` | lain | (3.0, 3.0, 3.0, 1.0) |
| `flash_time` | float | 0.06 |
| `hit_spark_count` | int | 8 |
| `kill_burst_count` | int | 18 |
| `player_lunge` | float | 6.00 |
| `player_lunge_time` | float | 0.06 |
| `manual_swing_buffer` | float | 0.15 |
| `low_hp_vignette_threshold` | float | 25.00 |
| `death_sequence_time` | float | 0.25 |

### `res://src/data/configs/needs_config.tres`

- Kelas: `needs_config.gd` (`res://src/data/resources/needs/needs_config.gd`)
- Tujuan: Laju Hunger/Thirst/Fatigue dan ambang tier.
- Dipakai oleh: NeedsComponent, NeedsHUD
- Pemilik: generator
- Efek tuning: Mengubah seberapa cepat kebutuhan turun dan kapan tier LOW/ZERO.
- Tes terkait: test_needs_component.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `max_value` | float | 100.00 |
| `start_value` | float | 100.00 |
| `low_threshold` | float | 25.00 |
| `zero_threshold` | float | 0.00 |
| `sleep_min_value` | float | 1.00 |
| `hunger_day_drain` | float | 0.16 |
| `hunger_night_drain` | float | 0.20 |
| `thirst_day_drain` | float | 0.24 |
| `thirst_night_drain` | float | 0.18 |
| `fatigue_sprint_drain` | float | 2.50 |
| `fatigue_walk_drain` | float | 0.08 |
| `fatigue_idle_regen` | float | 1.00 |
| `fatigue_sprint_cap_drain` | float | 0.40 |
| `fatigue_meal_cap_restore` | float | 10.00 |
| `sleep_fatigue_cap_restore` | float | 25.00 |
| `global_drain_multiplier` | float | 1.00 |
| `hunger_drain_multiplier` | float | 0.60 |
| `thirst_drain_multiplier` | float | 0.57 |
| `drain_multiplier_by_day` | Array | [7 item] |
| `hunger_sprint_lock_threshold` | float | 30.00 |
| `hunger_zero_hp_loss` | float | 1.50 |
| `thirst_zero_hp_loss` | float | 2.00 |
| `hunger_low_move_speed` | float | -0.15 |
| `hunger_low_attack_damage` | float | -0.15 |
| `thirst_low_sprint_fatigue_drain` | float | 0.30 |
| `thirst_low_attack_speed` | float | -0.20 |
| `fatigue_low_move_speed` | float | -0.20 |
| `fatigue_gather_time` | float | 0.30 |
| `fatigue_zero_move_speed` | float | -0.45 |
| `fatigue_zero_attack_speed` | float | -0.50 |

### `res://src/data/configs/player_light_config.tres`

- Kelas: `player_light_config.gd` (`res://src/data/resources/environment/player_light_config.gd`)
- Tujuan: Radius dan energi cahaya pemain malam (110 px, obor 190 px).
- Dipakai oleh: PlayerLight, PlayerLightConfig
- Pemilik: generator
- Efek tuning: Mengubah terang/radius cahaya pemain; tidak mengubah tint dunia.
- Tes terkait: test_daily_goals_and_light.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `player_radius` | float | 110.00 |
| `torch_radius` | float | 190.00 |
| `day_energy` | float | 0.00 |
| `night_energy` | float | 1.00 |
| `torch_energy_bonus` | float | 0.00 |
| `color` | lain | (1.0, 0.86, 0.62, 1.0) |
| `torch_item` | Resource | (res://src/data/items/torch.tres):<Resource#-... |

### `res://src/data/configs/proficiency_config.tres`

- Kelas: `proficiency_config.gd` (`res://src/data/resources/proficiency/proficiency_config.gd`)
- Tujuan: Ambang level proficiency dan debuff kematian.
- Dipakai oleh: ProficiencyComponent, ProficiencyHUD
- Pemilik: generator
- Efek tuning: Kecepatan naik level dan besar penalti saat mati.
- Tes terkait: test_proficiency_component.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `max_level` | int | 10 |
| `xp_per_level_base` | float | 100.00 |
| `night_xp_multiplier` | float | 1.50 |
| `strength_hit_xp` | float | 10.00 |
| `strength_tree_xp` | float | 15.00 |
| `strength_rock_xp` | float | 15.00 |
| `heavy_strike_level` | int | 3 |
| `heavy_strike_every` | int | 4 |
| `heavy_strike_multiplier` | float | 1.30 |
| `sturdy_level` | int | 6 |
| `sturdy_knockback_multiplier` | float | 0.50 |
| `speed_camp_radius` | float | 180.00 |
| `speed_walk_distance` | float | 100.00 |
| `speed_walk_xp` | float | 1.00 |
| `speed_sprint_xp_per_second` | float | 3.00 |
| `light_footed_level` | int | 3 |
| `light_footed_sprint_percent` | float | 0.10 |
| `second_wind_level` | int | 6 |
| `second_wind_regen_multiplier` | float | 1.25 |
| `mastery_gather_xp` | float | 8.00 |
| `mastery_craft_xp` | float | 25.00 |
| `mastery_cook_xp` | float | 20.00 |
| `resourceful_level` | int | 3 |
| `resourceful_chance` | float | 0.20 |
| `resourceful_bonus` | int | 1 |
| `master_chef_level` | int | 6 |
| `master_chef_bonus` | float | 10.00 |
| `master_chef_hunger_items` | Array | [1 item] |
| `master_chef_thirst_items` | Array | [2 item] |
| `agility_dodge_xp` | float | 20.00 |
| `agility_dodge_cooldown` | float | 3.00 |
| `agility_dash_miss_xp` | float | 25.00 |
| `agility_dash_miss_max_per_boar` | int | 2 |
| `agility_kill_xp` | float | 30.00 |
| `quick_reflex_level` | int | 3 |
| `quick_reflex_dodge_percent` | float | 0.08 |
| `quick_reflex_hp_threshold` | float | 0.40 |
| `swift_counter_level` | int | 6 |
| `swift_counter_multiplier` | float | 1.25 |
| `death_debuff_levels` | int | 2 |
| `first_passive_level` | int | 3 |

### `res://src/data/configs/run_config.tres`

- Kelas: `run_config.gd` (`res://src/data/resources/run/run_config.gd`)
- Tujuan: Perlindungan setelah respawn: durasi, kedip, aturan batal.
- Dipakai oleh: DeathController, PlayerDamageReceiver
- Pemilik: generator
- Efek tuning: Menentukan lama pemain aman setelah respawn; tidak mengubah token respawn.
- Tes terkait: test_respawn_protection.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `respawn_protection_seconds` | float | 5.00 |
| `protection_ignored_by_enemies` | bool | true |
| `protection_ends_on_attack` | bool | false |
| `protection_blink_hz` | float | 6.00 |

### `res://src/data/configs/sneak_config.tres`

- Kelas: `sneak_config.gd` (`res://src/data/resources/movement/sneak_config.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `speed_multiplier` | float | 0.55 |
| `detection_multiplier` | float | 0.60 |
| `blocks_sprint` | bool | true |

### `res://src/data/configs/station_config.tres`

- Kelas: `station_config.gd` (`res://src/data/resources/camp/station_config.gd`)
- Tujuan: Panel stasiun: hold E, jarak pakai/tutup, mode tab tas, batas craft xN.
- Dipakai oleh: CraftingComponent, StationPanel, CraftingRow
- Pemilik: generator
- Efek tuning: Seberapa mudah membuka panel dan berapa banyak craft sekali tekan.
- Tes terkait: test_station_panel_craft.gd, test_crafting_panel.gd, test_fase4_crafting.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `open_hold_time` | float | 0.10 |
| `use_range` | float | 140.00 |
| `panel_close_distance` | float | 160.00 |
| `bag_tab_hand_only` | bool | true |
| `campfire_opens_panel` | bool | true |
| `craft_batch_max` | int | 5 |

### `res://src/data/configs/wading_config.tres`

- Kelas: `wading_config.gd` (`res://src/data/resources/movement/wading_config.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `speed_multiplier` | float | 0.55 |
| `blocks_sprint` | bool | true |


## src/data/configs/environment

### `res://src/data/configs/environment/clock_format.tres`

- Kelas: `clock_format_config.gd` (`res://src/data/resources/environment/clock_format_config.gd`)
- Tujuan: Jam dunia nyata: jam terbit/terbenam, format 12/24 jam, label periode, flag HUD.
- Dipakai oleh: DayNightManager, GameClockFormat, TimeHUD, NightSurvivalHUD
- Pemilik: generator
- Efek tuning: Menggeser jam terbit/terbenam atau format jam; durasi fase dan siklus tidak berubah.
- Tes terkait: test_game_clock_format.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `day_start_hour` | float | 6.00 |
| `night_start_hour` | float | 18.00 |
| `use_24h` | bool | true |
| `minute_step` | int | 1 |
| `period_names` | lain | [Pagi, Siang, Sore, Malam] |
| `period_start_hours` | lain | [5.0, 10.0, 15.0, 18.0] |
| `show_period_label` | bool | true |
| `show_remaining_at_night` | bool | true |
| `show_remaining_by_day` | bool | false |
| `sleep_toast` | bool | true |

### `res://src/data/configs/environment/day_night_debug_fast.tres`

- Kelas: `day_night_config.gd` (`res://src/data/resources/environment/day_night_config.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `max_days` | int | 7 |
| `cycle_duration` | float | 60.00 |
| `time_scale` | float | 1.00 |
| `periods` | Array | [3 item] |

### `res://src/data/configs/environment/day_night_default.tres`

- Kelas: `day_night_config.gd` (`res://src/data/resources/environment/day_night_config.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `max_days` | int | 7 |
| `cycle_duration` | float | 600.00 |
| `time_scale` | float | 1.00 |
| `periods` | Array | [3 item] |

### `res://src/data/configs/environment/day_night_visual_default.tres`

- Kelas: `day_night_visual_config.gd` (`res://src/data/resources/environment/day_night_visual_config.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `transition_duration` | float | 60.00 |
| `morning_color` | lain | (0.95, 0.8, 0.68, 1.0) |
| `day_color` | lain | (1.0, 0.96, 0.88, 1.0) |
| `evening_color` | lain | (1.0, 0.68, 0.45, 1.0) |
| `night_color` | lain | (0.34, 0.42, 0.66, 1.0) |
| `morning_light_intensity` | float | 0.82 |
| `day_light_intensity` | float | 1.00 |
| `evening_light_intensity` | float | 0.75 |
| `night_light_intensity` | float | 0.62 |
| `enable_environment_effects` | bool | true |
| `enable_fireflies` | bool | true |
| `firefly_amount` | int | 24 |
| `firefly_color` | lain | (0.85, 1.0, 0.6, 1.0) |
| `enable_day_motes` | bool | true |
| `day_mote_amount` | int | 12 |
| `day_mote_color` | lain | (1.0, 0.95, 0.82, 0.55) |

### `res://src/data/configs/environment/sun_config.tres`

- Kelas: `sun_config.gd` (`res://src/data/resources/environment/sun_config.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `sweep_enabled` | bool | true |
| `dawn_side` | int | 0 |
| `dawn_sweep_seconds` | float | 60.00 |
| `dusk_sweep_seconds` | float | 60.00 |
| `softness` | float | 0.35 |
| `warm_rim_strength` | float | 0.25 |
| `sun_arc_enabled` | bool | true |


## src/data/configs/fauna

### `res://src/data/configs/fauna/boar_config.tres`

- Kelas: `boar_config.gd` (`res://src/data/resources/fauna/boar_config.gd`)
- Tujuan: Angka babi hutan: gigit, dash, persepsi, dan timing state.
- Dipakai oleh: WildBoar, FaunaBase
- Pemilik: generator
- Efek tuning: Rasa tempur babi; timing BITE/RECOVER dan knockback dash ada di sini (Fase 5).
- Tes terkait: test_wild_boar.gd, test_fase5_summary.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `bite_hold_time` | float | 0.22 |
| `dash_recover_time` | float | 0.30 |
| `dash_knockback_distance` | float | 60.00 |
| `bite_damage` | float | 12.00 |
| `bite_range` | float | 50.00 |
| `bite_cooldown` | float | 1.20 |
| `dash_min_distance` | float | 110.00 |
| `dash_max_distance` | float | 240.00 |
| `dash_telegraph` | float | 0.80 |
| `dash_speed` | float | 330.00 |
| `dash_cooldown_day` | float | 6.00 |
| `dash_cooldown_night` | float | 4.00 |
| `dash_player_damage` | float | 20.00 |
| `dash_structure_damage` | float | 40.00 |
| `dash_hit_radius` | float | 40.00 |
| `detect_radius` | float | 300.00 |
| `leash_radius` | float | 380.00 |
| `provoke_calm_seconds` | float | 10.00 |
| `camp_player_radius` | float | 140.00 |
| `raid_camp_radius` | float | 500.00 |
| `raid_clear_radius` | float | 650.00 |
| `max_hp` | float | 80.00 |
| `move_speed_day` | float | 115.00 |
| `move_speed_night` | float | 150.00 |
| `wander_speed_factor` | float | 0.50 |
| `wander_radius` | float | 200.00 |
| `wander_pause_min` | float | 2.00 |
| `wander_pause_max` | float | 5.00 |
| `flee_despawn_distance` | float | 600.00 |
| `flee_despawn_timeout` | float | 8.00 |
| `hp_bar_hide_seconds` | float | 3.00 |
| `loot_ids` | Array | [] |
| `loot_counts` | Array | [] |
| `blocks_player` | bool | true |
| `knockback_resistance` | float | 0.35 |
| `contact_stop_extra` | float | 2.00 |

### `res://src/data/configs/fauna/deer_config.tres`

- Kelas: `deer_config.gd` (`res://src/data/resources/fauna/deer_config.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `flee_speed` | float | 175.00 |
| `flee_trigger_radius` | float | 130.00 |
| `flee_duration` | float | 5.00 |
| `alert_radius_factor` | float | 1.25 |
| `alert_time` | float | 0.45 |
| `startle_seconds` | float | 0.90 |
| `flee_accel_seconds` | float | 0.50 |
| `sneak_notice_floor_px` | float | 24.00 |
| `hit_stun` | float | 0.35 |
| `max_hp` | float | 40.00 |
| `move_speed_day` | float | 60.00 |
| `move_speed_night` | float | 60.00 |
| `wander_speed_factor` | float | 1.00 |
| `wander_radius` | float | 200.00 |
| `wander_pause_min` | float | 2.00 |
| `wander_pause_max` | float | 5.00 |
| `flee_despawn_distance` | float | 600.00 |
| `flee_despawn_timeout` | float | 8.00 |
| `hp_bar_hide_seconds` | float | 3.00 |
| `loot_ids` | Array | [] |
| `loot_counts` | Array | [] |
| `blocks_player` | bool | true |
| `knockback_resistance` | float | 0.60 |
| `contact_stop_extra` | float | 2.00 |

### `res://src/data/configs/fauna/ember_snuff_config.tres`

- Kelas: `ember_snuff_config.gd` (`res://src/data/resources/fauna/ember_snuff_config.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `first_day` | int | 5 |
| `fuel_loss` | float | 8.00 |

### `res://src/data/configs/fauna/night_scaling_config.tres`

- Kelas: `night_scaling_config.gd` (`res://src/data/resources/fauna/night_scaling_config.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `max_enemies` | Array | [7 item] |
| `spawn_interval` | Array | [7 item] |
| `hp_damage_multiplier` | Array | [7 item] |

### `res://src/data/configs/fauna/raid_config.tres`

- Kelas: `raid_config.gd` (`res://src/data/resources/fauna/raid_config.gd`)
- Tujuan: Jadwal raid malam, jumlah raider, cap populasi, dan mode raid.
- Dipakai oleh: RaidDirector, WildBoar, NightSpawner, FaunaQuota
- Pemilik: generator
- Efek tuning: Menentukan kapan dan seberapa besar raid; 1.0 = tabel spesifikasi.
- Tes terkait: test_raid_director.gd, test_night_spawner.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `mode` | int | 0 |
| `raids_per_night` | Array | [7 item] |
| `raiders_per_raid` | Array | [7 item] |
| `first_raid_delay_min` | float | 45.00 |
| `first_raid_delay_max` | float | 120.00 |
| `raid_duration` | float | 40.00 |
| `raid_gap_min` | float | 70.00 |
| `warning_seconds` | float | 8.00 |
| `day_raids_enabled` | bool | false |
| `day_raids_per_day` | Array | [7 item] |
| `day_raiders_per_raid` | Array | [7 item] |
| `global_pressure_multiplier` | float | 1.00 |
| `day_boar_cap` | int | 2 |
| `day_deer_cap` | int | 3 |
| `night_active_hostile_cap` | Array | [7 item] |
| `spawn_interval_multiplier` | float | 1.00 |


## src/data/configs/physics

### `res://src/data/configs/physics/body_island_deer.tres`

- Kelas: `body_profile.gd` (`res://src/data/resources/physics/body_profile.gd`)
- Tujuan: Profil massa/kolisi rusa pulau (MEDIUM, knockback 0.6).
- Dipakai oleh: BodyProfileApplier (FaunaBase._ready), BodySeparation
- Pemilik: generator
- Efek tuning: Rusa kini padat dan menerima 60% knockback; jarak kontak dijaga pemisah badan.
- Tes terkait: test_mission10_physics_matrix.gd, test_mission10_body_separation.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | island_deer |
| `mass_class` | int | 1 |
| `radius` | float | 10.00 |
| `collision_layer` | int | 2 |
| `collision_mask` | int | 15 |
| `blocks_player` | bool | true |
| `pushable_by_others` | bool | false |
| `knockback_taken_multiplier` | float | 0.60 |
| `contact_stop_extra` | float | 2.00 |
| `separation_speed` | float | 60.00 |
| `max_overlap_px` | float | 2.00 |

### `res://src/data/configs/physics/body_player.tres`

- Kelas: `body_profile.gd` (`res://src/data/resources/physics/body_profile.gd`)
- Tujuan: Profil massa/kolisi badan pemain (LIGHT, radius 12).
- Dipakai oleh: BodyProfileApplier (Player._ready), BodySeparation
- Pemilik: generator
- Efek tuning: Menentukan siapa yang bisa ditembus, jarak kontak, dan pengali knockback yang diterima.
- Tes terkait: test_mission10_physics_matrix.gd, test_mission10_mass_deer.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | player |
| `mass_class` | int | 0 |
| `radius` | float | 12.00 |
| `collision_layer` | int | 5 |
| `collision_mask` | int | 3 |
| `blocks_player` | bool | true |
| `pushable_by_others` | bool | false |
| `knockback_taken_multiplier` | float | 1.00 |
| `contact_stop_extra` | float | 2.00 |
| `separation_speed` | float | 60.00 |
| `max_overlap_px` | float | 2.00 |

### `res://src/data/configs/physics/body_wild_boar.tres`

- Kelas: `body_profile.gd` (`res://src/data/resources/physics/body_profile.gd`)
- Tujuan: Profil massa/kolisi babi hutan (HEAVY, knockback 0.35).
- Dipakai oleh: BodyProfileApplier (FaunaBase._ready), BodySeparation
- Pemilik: generator
- Efek tuning: Babi memblokir pemain, tetap bisa dipisah saat bertumpuk, dan hanya menerima 35% knockback.
- Tes terkait: test_mission10_physics_matrix.gd, test_boar_mass.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | wild_boar |
| `mass_class` | int | 2 |
| `radius` | float | 12.00 |
| `collision_layer` | int | 2 |
| `collision_mask` | int | 15 |
| `blocks_player` | bool | true |
| `pushable_by_others` | bool | false |
| `knockback_taken_multiplier` | float | 0.35 |
| `contact_stop_extra` | float | 2.00 |
| `separation_speed` | float | 60.00 |
| `max_overlap_px` | float | 2.00 |


## src/data/configs/world

### `res://src/data/configs/world/world_config.tres`

- Kelas: `world_config.gd` (`res://src/data/resources/world/world_config.gd`)
- Tujuan: Mode dunia (FORMULA/AUTHORED), path scene AUTHORED, dan angka validasi dunia.
- Dipakai oleh: WorldController, AuthoredWorld, WorldValidator, WorldDebugOverlay
- Pemilik: generator
- Efek tuning: Menentukan pulau mana yang dimuat dan seberapa ketat validator.
- Tes terkait: test_world_controller_authored.gd, test_world_validator.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `mode` | int | 0 |
| `authored_scene_path` | String | res://src/levels/worlds/sample_island/world.tscn |
| `fallback_to_formula` | bool | true |
| `cell_size` | float | 32.00 |
| `min_spawn_points` | int | 8 |
| `min_spawn_distance` | float | 1100.00 |
| `min_corridor_width` | float | 96.00 |
| `base_clearance_extra` | float | 50.00 |
| `reachability_required_ratio` | float | 0.98 |
| `warn_node_ratio` | float | 0.50 |
| `polygon_vertex_limit` | int | 2000 |
| `min_forest_area` | float | 1000000.00 |
| `overlay_cell_px` | int | 64 |


## src/data/gathering

### `res://src/data/gathering/bamboo_clump.tres`

- Kelas: `resource_node_definition.gd` (`res://src/data/resources/gathering/resource_node_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | bamboo_clump |
| `display_name` | String | Rumpun Bambu |
| `item` | Resource | (res://src/data/items/bamboo.tres):<Resource#... |
| `yield_min` | int | 2 |
| `yield_max` | int | 2 |
| `required_tool` | int | 0 |
| `speed_tool` | int | 0 |
| `speed_factor` | float | 1.00 |
| `chop_feedback_enabled` | bool | false |
| `gather_time` | float | 1.50 |
| `fatigue_cost` | float | 2.00 |
| `respawn_rule` | int | 0 |

### `res://src/data/gathering/berry_bush.tres`

- Kelas: `resource_node_definition.gd` (`res://src/data/resources/gathering/resource_node_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | berry_bush |
| `display_name` | String | Semak Beri |
| `item` | Resource | (res://src/data/items/berry.tres):<Resource#-... |
| `yield_min` | int | 2 |
| `yield_max` | int | 2 |
| `required_tool` | int | 0 |
| `speed_tool` | int | 0 |
| `speed_factor` | float | 1.00 |
| `chop_feedback_enabled` | bool | false |
| `gather_time` | float | 0.80 |
| `fatigue_cost` | float | 2.00 |
| `respawn_rule` | int | 0 |

### `res://src/data/gathering/big_rock.tres`

- Kelas: `resource_node_definition.gd` (`res://src/data/resources/gathering/resource_node_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | big_rock |
| `display_name` | String | Batu Besar |
| `item` | Resource | (res://src/data/items/stone.tres):<Resource#-... |
| `yield_min` | int | 3 |
| `yield_max` | int | 3 |
| `required_tool` | int | 2 |
| `speed_tool` | int | 0 |
| `speed_factor` | float | 1.00 |
| `chop_feedback_enabled` | bool | false |
| `gather_time` | float | 3.00 |
| `fatigue_cost` | float | 2.00 |
| `respawn_rule` | int | 0 |

### `res://src/data/gathering/coconut_palm.tres`

- Kelas: `resource_node_definition.gd` (`res://src/data/resources/gathering/resource_node_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | coconut_palm |
| `display_name` | String | Pohon Kelapa |
| `item` | Resource | (res://src/data/items/coconut.tres):<Resource... |
| `yield_min` | int | 1 |
| `yield_max` | int | 2 |
| `required_tool` | int | 0 |
| `speed_tool` | int | 0 |
| `speed_factor` | float | 1.00 |
| `chop_feedback_enabled` | bool | false |
| `gather_time` | float | 1.20 |
| `fatigue_cost` | float | 2.00 |
| `respawn_rule` | int | 1 |

### `res://src/data/gathering/fiber_bush.tres`

- Kelas: `resource_node_definition.gd` (`res://src/data/resources/gathering/resource_node_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | fiber_bush |
| `display_name` | String | Semak Serat |
| `item` | Resource | (res://src/data/items/fiber.tres):<Resource#-... |
| `yield_min` | int | 2 |
| `yield_max` | int | 2 |
| `required_tool` | int | 0 |
| `speed_tool` | int | 0 |
| `speed_factor` | float | 1.00 |
| `chop_feedback_enabled` | bool | false |
| `gather_time` | float | 1.00 |
| `fatigue_cost` | float | 2.00 |
| `respawn_rule` | int | 0 |

### `res://src/data/gathering/small_rock.tres`

- Kelas: `resource_node_definition.gd` (`res://src/data/resources/gathering/resource_node_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | small_rock |
| `display_name` | String | Batu Kecil |
| `item` | Resource | (res://src/data/items/stone.tres):<Resource#-... |
| `yield_min` | int | 1 |
| `yield_max` | int | 1 |
| `required_tool` | int | 0 |
| `speed_tool` | int | 0 |
| `speed_factor` | float | 1.00 |
| `chop_feedback_enabled` | bool | false |
| `gather_time` | float | 1.50 |
| `fatigue_cost` | float | 2.00 |
| `respawn_rule` | int | 0 |

### `res://src/data/gathering/small_tree.tres`

- Kelas: `resource_node_definition.gd` (`res://src/data/resources/gathering/resource_node_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | small_tree |
| `display_name` | String | Pohon Kecil |
| `item` | Resource | (res://src/data/items/wood.tres):<Resource#-9... |
| `yield_min` | int | 2 |
| `yield_max` | int | 2 |
| `required_tool` | int | 0 |
| `speed_tool` | int | 1 |
| `speed_factor` | float | 0.50 |
| `chop_feedback_enabled` | bool | true |
| `gather_time` | float | 4.00 |
| `fatigue_cost` | float | 3.00 |
| `respawn_rule` | int | 0 |

### `res://src/data/gathering/tree.tres`

- Kelas: `resource_node_definition.gd` (`res://src/data/resources/gathering/resource_node_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | tree |
| `display_name` | String | Pohon |
| `item` | Resource | (res://src/data/items/wood.tres):<Resource#-9... |
| `yield_min` | int | 3 |
| `yield_max` | int | 3 |
| `required_tool` | int | 1 |
| `speed_tool` | int | 0 |
| `speed_factor` | float | 1.00 |
| `chop_feedback_enabled` | bool | true |
| `gather_time` | float | 2.50 |
| `fatigue_cost` | float | 2.00 |
| `respawn_rule` | int | 0 |

### `res://src/data/gathering/twig.tres`

- Kelas: `resource_node_definition.gd` (`res://src/data/resources/gathering/resource_node_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | twig |
| `display_name` | String | Ranting |
| `item` | Resource | (res://src/data/items/wood.tres):<Resource#-9... |
| `yield_min` | int | 1 |
| `yield_max` | int | 1 |
| `required_tool` | int | 0 |
| `speed_tool` | int | 0 |
| `speed_factor` | float | 1.00 |
| `chop_feedback_enabled` | bool | false |
| `gather_time` | float | 1.00 |
| `fatigue_cost` | float | 2.00 |
| `respawn_rule` | int | 0 |


## src/data/hints

### `res://src/data/hints/base_place.tres`

- Kelas: `hint_definition.gd` (`res://src/data/resources/hints/hint_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | base_place |
| `text` | String | Tekan B untuk menentukan lokasi base. |

### `res://src/data/hints/campfire_cold.tres`

- Kelas: `hint_definition.gd` (`res://src/data/resources/hints/hint_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | campfire_cold |
| `text` | String | Api unggun belum menyala. Tahan E, lalu tekan... |

### `res://src/data/hints/crafting.tres`

- Kelas: `hint_definition.gd` (`res://src/data/resources/hints/hint_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | crafting |
| `text` | String | Buka Tab atau I, lalu tab Crafting untuk memb... |

### `res://src/data/hints/dusk.tres`

- Kelas: `hint_definition.gd` (`res://src/data/resources/hints/hint_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | dusk |
| `text` | String | Malam hampir tiba. Nyalakan api unggun dan si... |

### `res://src/data/hints/fence.tres`

- Kelas: `hint_definition.gd` (`res://src/data/resources/hints/hint_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | fence |
| `text` | String | Bangun pagar di sekitar base. |

### `res://src/data/hints/gather.tres`

- Kelas: `hint_definition.gd` (`res://src/data/resources/hints/hint_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | gather |
| `text` | String | Tahan E untuk mengumpulkan. |

### `res://src/data/hints/hunger_sprint_lock.tres`

- Kelas: `hint_definition.gd` (`res://src/data/resources/hints/hint_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | hunger_sprint_lock |
| `text` | String | Lapar: kamu tidak bisa sprint dan HP pulih le... |

### `res://src/data/hints/need_low.tres`

- Kelas: `hint_definition.gd` (`res://src/data/resources/hints/hint_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | need_low |
| `text` | String | Makan atau minum sebelum terlalu lemah. |

### `res://src/data/hints/neutral_hit.tres`

- Kelas: `hint_definition.gd` (`res://src/data/resources/hints/hint_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | neutral_hit |
| `text` | String | Menyerang hewan netral membuatnya menyerang b... |

### `res://src/data/hints/repair.tres`

- Kelas: `hint_definition.gd` (`res://src/data/resources/hints/hint_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | repair |
| `text` | String | Tahan R untuk memperbaiki struktur. |


## src/data/items

### `res://src/data/items/bamboo.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | bamboo |
| `display_name` | String | Bambu |
| `description` | String | Bambu ringan dari tepi sungai. |
| `category` | int | 0 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/berry.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | berry |
| `display_name` | String | Beri |
| `description` | String | Buah beri hutan. +12 Hunger, +10 Fatigue. |
| `category` | int | 1 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | (res://src/data/items/berry.tres::Resource_ef... |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/boiled_water.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | boiled_water |
| `display_name` | String | Air Matang |
| `description` | String | Air rebusan. +60 Thirst tanpa penalti Hunger. |
| `category` | int | 1 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | (res://src/data/items/boiled_water.tres::Reso... |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/bone.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | bone |
| `display_name` | String | Tulang |
| `description` | String | Tulang hewan; bahan senjata dan kaldu. |
| `category` | int | 0 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/bone_broth.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | bone_broth |
| `display_name` | String | Kaldu Tulang |
| `description` | String | Kaldu hangat. +35 Hunger, +40 Thirst, +1 HP/d... |
| `category` | int | 1 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | (res://src/data/items/bone_broth.tres::Resour... |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/bone_spear.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | bone_spear |
| `display_name` | String | Tombak Tulang |
| `description` | String | Tombak bermata tulang. Menyebabkan Bleed (bel... |
| `category` | int | 2 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 1 |
| `weapon_damage` | float | 30.00 |
| `weapon_range` | float | 85.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/cockpit_notes.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | cockpit_notes |
| `display_name` | String | Catatan Kokpit |
| `description` | String | Catatan pilot tentang penerbangan yang gagal ... |
| `category` | int | 5 |
| `max_stack` | int | 1 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/coconut.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | coconut |
| `display_name` | String | Kelapa |
| `description` | String | Kelapa segar. +10 Hunger, +30 Thirst, +10 Fat... |
| `category` | int | 1 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | (res://src/data/items/coconut.tres::Resource_... |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/cooked_meat.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | cooked_meat |
| `display_name` | String | Daging Matang |
| `description` | String | Daging panggang. +45 Hunger, +15 HP. |
| `category` | int | 1 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | (res://src/data/items/cooked_meat.tres::Resou... |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/fiber.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | fiber |
| `display_name` | String | Serat |
| `description` | String | Serat tumbuhan untuk ikatan dan kain. |
| `category` | int | 0 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/herbal_bandage.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | herbal_bandage |
| `display_name` | String | Perban Herbal |
| `description` | String | Perban dari serat dan beri. +35 HP. |
| `category` | int | 1 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | (res://src/data/items/herbal_bandage.tres::Re... |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/hide.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | hide |
| `display_name` | String | Kulit |
| `description` | String | Kulit hewan; bahan armor dan wadah air. |
| `category` | int | 0 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/leather_vest.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | leather_vest |
| `display_name` | String | Rompi Kulit |
| `description` | String | Rompi kulit: -20% damage diterima, +15 max HP. |
| `category` | int | 4 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 3 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.20 |
| `armor_max_hp_bonus` | float | 15.00 |

### `res://src/data/items/raw_meat.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | raw_meat |
| `display_name` | String | Daging Mentah |
| `description` | String | Daging mentah. +15 Hunger, -10 Thirst. Masak ... |
| `category` | int | 1 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | (res://src/data/items/raw_meat.tres::Resource... |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/signal_flare.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | signal_flare |
| `display_name` | String | Suar Darurat |
| `description` | String | Suar untuk memanggil kapal penyelamat di Hari... |
| `category` | int | 5 |
| `max_stack` | int | 1 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/stone.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | stone |
| `display_name` | String | Batu |
| `description` | String | Batu keras untuk alat dan struktur. |
| `category` | int | 0 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/stone_axe.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | stone_axe |
| `display_name` | String | Kapak Batu |
| `description` | String | Alat untuk menebang pohon. Hanya kepemilikan;... |
| `category` | int | 3 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 2 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/stone_pickaxe.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | stone_pickaxe |
| `display_name` | String | Beliung Batu |
| `description` | String | Alat untuk menambang batu. Hanya kepemilikan;... |
| `category` | int | 3 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 2 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/stone_spear.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | stone_spear |
| `display_name` | String | Tombak Batu |
| `description` | String | Tombak bermata batu. |
| `category` | int | 2 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 1 |
| `weapon_damage` | float | 28.00 |
| `weapon_range` | float | 85.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/torch.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | torch |
| `display_name` | String | Obor |
| `description` | String | Pilih di hotbar saat malam: cahaya pemain mel... |
| `category` | int | 5 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/waterskin.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: Kantung air penuh: satu tegukan, +25 Thirst dan -5 Hunger, lalu jadi kantung kosong.
- Dipakai oleh: InventoryComponent.use_slot, RiverEdge/RiverDrinkZone
- Pemilik: edit tangan
- Efek tuning: Nilai efek minum dan varian hasil pemakaian (`use_result`).
- Tes terkait: test_item_definitions.gd, test_fase3_waterskin.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | waterskin |
| `display_name` | String | Kantung Air Kulit |
| `description` | String | Wadah air kulit berisi satu tegukan. Pakai un... |
| `category` | int | 1 |
| `max_stack` | int | 1 |
| `icon` | Resource | — |
| `consume_effect` | Resource | (res://src/data/items/waterskin.tres::Resourc... |
| `use_result` | Resource | (res://src/data/items/waterskin_empty.tres):<... |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/waterskin_empty.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: Varian kantung kosong; diisi ulang di sungai (tahan E).
- Dipakai oleh: RiverEdge.refill_waterskin, RiverDrinkZone
- Pemilik: edit tangan
- Efek tuning: Tidak punya efek konsumsi; hanya penanda bahwa kantung perlu diisi.
- Tes terkait: test_fase3_waterskin.gd

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | waterskin_empty |
| `display_name` | String | Kantung Air Kosong |
| `description` | String | Kantung air kulit yang sudah kosong. Isi ulan... |
| `category` | int | 5 |
| `max_stack` | int | 1 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/wood.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | wood |
| `display_name` | String | Kayu |
| `description` | String | Batang kayu untuk membangun dan membuat alat. |
| `category` | int | 0 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 0 |
| `weapon_damage` | float | 0.00 |
| `weapon_range` | float | 0.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |

### `res://src/data/items/wooden_spear.tres`

- Kelas: `item_definition.gd` (`res://src/data/resources/items/item_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | wooden_spear |
| `display_name` | String | Tombak Kayu |
| `description` | String | Tombak kayu sederhana. |
| `category` | int | 2 |
| `max_stack` | int | 20 |
| `icon` | Resource | — |
| `consume_effect` | Resource | — |
| `use_result` | Resource | — |
| `equipment_slot` | int | 1 |
| `weapon_damage` | float | 18.00 |
| `weapon_range` | float | 75.00 |
| `armor_damage_reduction` | float | 0.00 |
| `armor_max_hp_bonus` | float | 0.00 |


## src/data/recipes

### `res://src/data/recipes/boiled_water.tres`

- Kelas: `recipe_definition.gd` (`res://src/data/resources/crafting/recipe_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | boiled_water |
| `display_name` | String | Air Matang |
| `result` | Resource | (res://src/data/items/boiled_water.tres):<Res... |
| `result_count` | int | 1 |
| `ingredients` | Array | [1 item] |
| `station` | int | 2 |
| `craft_time` | float | 2.00 |

### `res://src/data/recipes/bone_broth.tres`

- Kelas: `recipe_definition.gd` (`res://src/data/resources/crafting/recipe_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | bone_broth |
| `display_name` | String | Kaldu Tulang |
| `result` | Resource | (res://src/data/items/bone_broth.tres):<Resou... |
| `result_count` | int | 1 |
| `ingredients` | Array | [2 item] |
| `station` | int | 2 |
| `craft_time` | float | 2.50 |

### `res://src/data/recipes/bone_spear.tres`

- Kelas: `recipe_definition.gd` (`res://src/data/resources/crafting/recipe_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | bone_spear |
| `display_name` | String | Tombak Tulang |
| `result` | Resource | (res://src/data/items/bone_spear.tres):<Resou... |
| `result_count` | int | 1 |
| `ingredients` | Array | [3 item] |
| `station` | int | 1 |
| `craft_time` | float | 3.00 |

### `res://src/data/recipes/cooked_meat.tres`

- Kelas: `recipe_definition.gd` (`res://src/data/resources/crafting/recipe_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | cooked_meat |
| `display_name` | String | Daging Matang |
| `result` | Resource | (res://src/data/items/cooked_meat.tres):<Reso... |
| `result_count` | int | 1 |
| `ingredients` | Array | [1 item] |
| `station` | int | 2 |
| `craft_time` | float | 2.00 |

### `res://src/data/recipes/herbal_bandage.tres`

- Kelas: `recipe_definition.gd` (`res://src/data/resources/crafting/recipe_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | herbal_bandage |
| `display_name` | String | Perban Herbal |
| `result` | Resource | (res://src/data/items/herbal_bandage.tres):<R... |
| `result_count` | int | 1 |
| `ingredients` | Array | [2 item] |
| `station` | int | 0 |
| `craft_time` | float | 1.50 |

### `res://src/data/recipes/leather_vest.tres`

- Kelas: `recipe_definition.gd` (`res://src/data/resources/crafting/recipe_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | leather_vest |
| `display_name` | String | Rompi Kulit |
| `result` | Resource | (res://src/data/items/leather_vest.tres):<Res... |
| `result_count` | int | 1 |
| `ingredients` | Array | [2 item] |
| `station` | int | 1 |
| `craft_time` | float | 3.00 |

### `res://src/data/recipes/signal_flare.tres`

- Kelas: `recipe_definition.gd` (`res://src/data/resources/crafting/recipe_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | signal_flare |
| `display_name` | String | Suar Darurat |
| `result` | Resource | (res://src/data/items/signal_flare.tres):<Res... |
| `result_count` | int | 1 |
| `ingredients` | Array | [4 item] |
| `station` | int | 1 |
| `craft_time` | float | 4.00 |

### `res://src/data/recipes/stone_axe.tres`

- Kelas: `recipe_definition.gd` (`res://src/data/resources/crafting/recipe_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | stone_axe |
| `display_name` | String | Kapak Batu |
| `result` | Resource | (res://src/data/items/stone_axe.tres):<Resour... |
| `result_count` | int | 1 |
| `ingredients` | Array | [3 item] |
| `station` | int | 1 |
| `craft_time` | float | 2.50 |

### `res://src/data/recipes/stone_pickaxe.tres`

- Kelas: `recipe_definition.gd` (`res://src/data/resources/crafting/recipe_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | stone_pickaxe |
| `display_name` | String | Beliung Batu |
| `result` | Resource | (res://src/data/items/stone_pickaxe.tres):<Re... |
| `result_count` | int | 1 |
| `ingredients` | Array | [3 item] |
| `station` | int | 1 |
| `craft_time` | float | 2.50 |

### `res://src/data/recipes/stone_spear.tres`

- Kelas: `recipe_definition.gd` (`res://src/data/resources/crafting/recipe_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | stone_spear |
| `display_name` | String | Tombak Batu |
| `result` | Resource | (res://src/data/items/stone_spear.tres):<Reso... |
| `result_count` | int | 1 |
| `ingredients` | Array | [3 item] |
| `station` | int | 1 |
| `craft_time` | float | 3.00 |

### `res://src/data/recipes/torch.tres`

- Kelas: `recipe_definition.gd` (`res://src/data/resources/crafting/recipe_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | torch |
| `display_name` | String | Obor |
| `result` | Resource | (res://src/data/items/torch.tres):<Resource#-... |
| `result_count` | int | 1 |
| `ingredients` | Array | [2 item] |
| `station` | int | 0 |
| `craft_time` | float | 1.50 |

### `res://src/data/recipes/waterskin.tres`

- Kelas: `recipe_definition.gd` (`res://src/data/resources/crafting/recipe_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | waterskin |
| `display_name` | String | Kantung Air Kulit |
| `result` | Resource | (res://src/data/items/waterskin.tres):<Resour... |
| `result_count` | int | 1 |
| `ingredients` | Array | [2 item] |
| `station` | int | 1 |
| `craft_time` | float | 2.50 |

### `res://src/data/recipes/wooden_spear.tres`

- Kelas: `recipe_definition.gd` (`res://src/data/resources/crafting/recipe_definition.gd`)
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: generator
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `id` | StringName | wooden_spear |
| `display_name` | String | Tombak Kayu |
| `result` | Resource | (res://src/data/items/wooden_spear.tres):<Res... |
| `result_count` | int | 1 |
| `ingredients` | Array | [2 item] |
| `station` | int | 0 |
| `craft_time` | float | 2.00 |


## src/ui/theme

### `res://src/ui/theme/stitch_frame_material.tres`

- Kelas: `Resource`
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `shader` | Resource | (res://src/ui/theme/stitch_frame.gdshader):<S... |
| `shader_parameter/frame_size` | Vector2 | 520.0 × 300.0 |
| `shader_parameter/inset` | float | 2.00 |
| `shader_parameter/corner_radius` | float | 24.00 |
| `shader_parameter/thickness` | float | 1.60 |
| `shader_parameter/dash_length` | float | 4.00 |
| `shader_parameter/gap_length` | float | 3.00 |
| `shader_parameter/stitch_color` | lain | (0.7412, 0.698, 0.6471, 1.0) |

### `res://src/ui/theme/ui_theme.tres`

- Kelas: `Resource`
- Tujuan: belum didokumentasikan
- Dipakai oleh: —
- Pemilik: edit tangan
- Efek tuning: —
- Tes terkait: —

| Field | Tipe | Nilai |
| --- | --- | --- |
| `resource_local_to_scene` | bool | false |
| `default_base_scale` | float | 0.00 |
| `default_font` | Resource | (res://assets/fonts/nunito/nunito_variable.tt... |
| `default_font_size` | int | 20 |
| `BackButton/base_type` | StringName | Button |
| `BackButton/colors/font_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `BackButton/colors/font_disabled_color` | lain | (0.2431, 0.1529, 0.102, 0.45) |
| `BackButton/colors/font_focus_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `BackButton/colors/font_hover_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `BackButton/colors/font_hover_pressed_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `BackButton/colors/font_pressed_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `BackButton/font_sizes/font_size` | int | 20 |
| `BackButton/fonts/font` | Resource | (res://src/ui/theme/ui_theme.tres::FontVariat... |
| `BackButton/styles/disabled` | Resource | (res://src/ui/theme/ui_theme.tres::sb_back_di... |
| `BackButton/styles/focus` | Resource | (res://src/ui/theme/ui_theme.tres::sb_back_ho... |
| `BackButton/styles/hover` | Resource | (res://src/ui/theme/ui_theme.tres::sb_back_ho... |
| `BackButton/styles/normal` | Resource | (res://src/ui/theme/ui_theme.tres::sb_back_no... |
| `BackButton/styles/pressed` | Resource | (res://src/ui/theme/ui_theme.tres::sb_back_pr... |
| `BodyLabel/base_type` | StringName | Label |
| `BodyLabel/colors/font_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `BodyLabel/constants/line_spacing` | int | 7 |
| `BodyLabel/font_sizes/font_size` | int | 18 |
| `BodyLabel/fonts/font` | Resource | (res://src/ui/theme/ui_theme.tres::FontVariat... |
| `Button/colors/font_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `Button/colors/font_disabled_color` | lain | (0.2431, 0.1529, 0.102, 0.45) |
| `Button/colors/font_focus_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `Button/colors/font_hover_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `Button/colors/font_hover_pressed_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `Button/colors/font_pressed_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `Button/font_sizes/font_size` | int | 26 |
| `Button/fonts/font` | Resource | (res://src/ui/theme/ui_theme.tres::FontVariat... |
| `Button/styles/disabled` | Resource | (res://src/ui/theme/ui_theme.tres::sb_seconda... |
| `Button/styles/focus` | Resource | (res://src/ui/theme/ui_theme.tres::sb_seconda... |
| `Button/styles/hover` | Resource | (res://src/ui/theme/ui_theme.tres::sb_seconda... |
| `Button/styles/normal` | Resource | (res://src/ui/theme/ui_theme.tres::sb_seconda... |
| `Button/styles/pressed` | Resource | (res://src/ui/theme/ui_theme.tres::sb_seconda... |
| `CardTitleLabel/base_type` | StringName | Label |
| `CardTitleLabel/colors/font_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `CardTitleLabel/font_sizes/font_size` | int | 28 |
| `CardTitleLabel/fonts/font` | Resource | (res://src/ui/theme/ui_theme.tres::FontVariat... |
| `EyebrowLabel/base_type` | StringName | Label |
| `EyebrowLabel/colors/font_color` | lain | (0.9686, 0.9451, 0.898, 0.82) |
| `EyebrowLabel/font_sizes/font_size` | int | 14 |
| `EyebrowLabel/fonts/font` | Resource | (res://src/ui/theme/ui_theme.tres::FontVariat... |
| `HeroTitle/base_type` | StringName | Label |
| `HeroTitle/colors/font_color` | lain | (0.9765, 0.9569, 0.9137, 1.0) |
| `HeroTitle/colors/font_outline_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `HeroTitle/colors/font_shadow_color` | lain | (0.1176, 0.0745, 0.0471, 0.35) |
| `HeroTitle/constants/outline_size` | int | 9 |
| `HeroTitle/constants/shadow_offset_x` | int | 0 |
| `HeroTitle/constants/shadow_offset_y` | int | 7 |
| `HeroTitle/constants/shadow_outline_size` | int | 9 |
| `HeroTitle/font_sizes/font_size` | int | 88 |
| `HeroTitle/fonts/font` | Resource | (res://src/ui/theme/ui_theme.tres::FontVariat... |
| `Label/colors/font_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `Label/font_sizes/font_size` | int | 20 |
| `Label/fonts/font` | Resource | (res://src/ui/theme/ui_theme.tres::FontVariat... |
| `PanelCard/base_type` | StringName | PanelContainer |
| `PanelCard/styles/panel` | Resource | (res://src/ui/theme/ui_theme.tres::sb_panel):... |
| `PrimaryButton/base_type` | StringName | Button |
| `PrimaryButton/colors/font_color` | lain | (0.9686, 0.9451, 0.898, 1.0) |
| `PrimaryButton/colors/font_disabled_color` | lain | (0.9686, 0.9451, 0.898, 0.5) |
| `PrimaryButton/colors/font_focus_color` | lain | (0.9686, 0.9451, 0.898, 1.0) |
| `PrimaryButton/colors/font_hover_color` | lain | (0.9686, 0.9451, 0.898, 1.0) |
| `PrimaryButton/colors/font_hover_pressed_color` | lain | (0.9686, 0.9451, 0.898, 1.0) |
| `PrimaryButton/colors/font_pressed_color` | lain | (0.9686, 0.9451, 0.898, 1.0) |
| `PrimaryButton/font_sizes/font_size` | int | 26 |
| `PrimaryButton/fonts/font` | Resource | (res://src/ui/theme/ui_theme.tres::FontVariat... |
| `PrimaryButton/styles/disabled` | Resource | (res://src/ui/theme/ui_theme.tres::sb_primary... |
| `PrimaryButton/styles/focus` | Resource | (res://src/ui/theme/ui_theme.tres::sb_primary... |
| `PrimaryButton/styles/hover` | Resource | (res://src/ui/theme/ui_theme.tres::sb_primary... |
| `PrimaryButton/styles/normal` | Resource | (res://src/ui/theme/ui_theme.tres::sb_primary... |
| `PrimaryButton/styles/pressed` | Resource | (res://src/ui/theme/ui_theme.tres::sb_primary... |
| `SecondaryButton/base_type` | StringName | Button |
| `SecondaryButton/colors/font_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `SecondaryButton/colors/font_disabled_color` | lain | (0.2431, 0.1529, 0.102, 0.45) |
| `SecondaryButton/colors/font_focus_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `SecondaryButton/colors/font_hover_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `SecondaryButton/colors/font_hover_pressed_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `SecondaryButton/colors/font_pressed_color` | lain | (0.2431, 0.1529, 0.102, 1.0) |
| `SecondaryButton/font_sizes/font_size` | int | 26 |
| `SecondaryButton/fonts/font` | Resource | (res://src/ui/theme/ui_theme.tres::FontVariat... |
| `SecondaryButton/styles/disabled` | Resource | (res://src/ui/theme/ui_theme.tres::sb_seconda... |
| `SecondaryButton/styles/focus` | Resource | (res://src/ui/theme/ui_theme.tres::sb_seconda... |
| `SecondaryButton/styles/hover` | Resource | (res://src/ui/theme/ui_theme.tres::sb_seconda... |
| `SecondaryButton/styles/normal` | Resource | (res://src/ui/theme/ui_theme.tres::sb_seconda... |
| `SecondaryButton/styles/pressed` | Resource | (res://src/ui/theme/ui_theme.tres::sb_seconda... |
| `VersionLabel/base_type` | StringName | Label |
| `VersionLabel/colors/font_color` | lain | (0.9686, 0.9451, 0.898, 0.5) |
| `VersionLabel/font_sizes/font_size` | int | 13 |
| `VersionLabel/fonts/font` | Resource | (res://src/ui/theme/ui_theme.tres::FontVariat... |


## Resource tanpa `.tres` (nilai default di script)

Kelas berikut hanya punya default di kode; ubah lewat kode atau dengan membuat `.tres` baru.

| Kelas | Default | Catatan |
| --- | --- | --- |
| `PlayerBaseStats` | `src/data/stats/player_base_stats.gd` | Stat dasar pemain; dipakai `StatsComponent.base_stats` bila tidak diisi. |
| `AssetConfig` | `src/data/configs/asset_config.tres` | Ada `.tres`; nilai default script jadi cadangan. |

## Generator di `tools/`

| Generator | Perintah |
| --- | --- |
| `res://tools/generate_asset_registry.gd` | `GODOT --headless --path . -s tools/generate_asset_registry.gd` |
| `res://tools/generate_audio_registry.gd` | `GODOT --headless --path . -s tools/generate_audio_registry.gd` |
| `res://tools/generate_balance_data.gd` | `GODOT --headless --path . -s tools/generate_balance_data.gd` |
| `res://tools/generate_body_profiles.gd` | `GODOT --headless --path . -s tools/generate_body_profiles.gd` |
| `res://tools/generate_camera_feel_config.gd` | `GODOT --headless --path . -s tools/generate_camera_feel_config.gd` |
| `res://tools/generate_clock_format.gd` | `GODOT --headless --path . -s tools/generate_clock_format.gd` |
| `res://tools/generate_combat_data.gd` | `GODOT --headless --path . -s tools/generate_combat_data.gd` |
| `res://tools/generate_compass_config.gd` | `GODOT --headless --path . -s tools/generate_compass_config.gd` |
| `res://tools/generate_daily_goals.gd` | `GODOT --headless --path . -s tools/generate_daily_goals.gd` |
| `res://tools/generate_fauna_configs.gd` | `GODOT --headless --path . -s tools/generate_fauna_configs.gd` |
| `res://tools/generate_guides.gd` | `GODOT --headless --path . -s tools/generate_guides.gd` |
| `res://tools/generate_held_item_data.gd` | `GODOT --headless --path . -s tools/generate_held_item_data.gd` |
| `res://tools/generate_hints.gd` | `GODOT --headless --path . -s tools/generate_hints.gd` |
| `res://tools/generate_input_guide.gd` | `GODOT --headless --path . -s tools/generate_input_guide.gd` |
| `res://tools/generate_player_light.gd` | `GODOT --headless --path . -s tools/generate_player_light.gd` |
| `res://tools/generate_proficiency_data.gd` | `GODOT --headless --path . -s tools/generate_proficiency_data.gd` |
| `res://tools/generate_recipes.gd` | `GODOT --headless --path . -s tools/generate_recipes.gd` |
| `res://tools/generate_sample_world.gd` | `GODOT --headless --path . -s tools/generate_sample_world.gd` |
| `res://tools/generate_station_data.gd` | `GODOT --headless --path . -s tools/generate_station_data.gd` |
| `res://tools/generate_structures.gd` | `GODOT --headless --path . -s tools/generate_structures.gd` |
| `res://tools/generate_sun_config.gd` | `GODOT --headless --path . -s tools/generate_sun_config.gd` |
| `res://tools/generate_world_config.gd` | `GODOT --headless --path . -s tools/generate_world_config.gd` |

<!-- END GENERATED -->

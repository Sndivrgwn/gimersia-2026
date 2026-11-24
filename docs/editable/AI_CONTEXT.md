# AI Context — Continue the Gimersia 2026 MVP

> Purpose: handoff document for an AI agent (or a new developer) picking up this
> repository. Read this file first, then the linked docs. **Code is the source of
> truth** when a doc disagrees with it.

Last verified: 2026-11-24, Godot 4.7.2, GUT 9.7.1 — 836/836 tests (821 unit + 15 integration), 4432 asserts, 103 scripts; boots island + main_menu bersih (practice1 tidak dipakai lagi).
Spec cross-check: 2026-11-18 against spec V8. Gaps found are listed in §4
(missing systems), §7.1-7.8 (spec details), §8 (revised build order) and §13
(open design questions).


## 1. What this project is

- Godot **4.7.2**, GDScript, **top-down 2D survival**.
- Premise: plane-crash survivor builds a camp on an island and survives 7 days
  until a rescue ship arrives.
- MVP target: playable loop **start → day → prepare → night → next day → day 7
  → rescue (flare + Victory)**.
- Renderer: GL Compatibility. Input: WASD/arrows + Shift sprint.
- Main scene: `res://scenes/practice/practice1.tscn` (a practice map used as the
  current integration scene, not a production level).
- Team roles and full scope: `docs/noneditable/MVP_dan_Daftar_Pekerjaan_RTRw_Studio.docx.md`.
- Final gameplay numbers: `docs/noneditable/spesifikasi_teknis_mekanisme_gameplay_V8.md`
  (referred to below as **the spec**).

---

## 2. Read order

Baca juga `docs/editable/ASSET_GUIDE.md` (pipeline seni) dan
`docs/editable/CONFIG_GUIDE.md` (semua Resource `.tres`); keduanya digenerate
oleh `tools/generate_guides.gd`.

1. This file.
2. `docs/editable/architecture.md` — structure, dependency rules, contracts.
3. `docs/editable/PANDUAN_MODUL.md` — how to use every implemented module.
4. `docs/editable/MVP_CHECKLIST.md` — actionable status and priority order.
5. The spec, sections you are implementing (numbers live there).

The spec and the MVP/work-list document are **non-editable inputs**. Everything
in `docs/editable/` is maintained by the project.

---

## 3. Verified state (trust this over older prose)

| Check | Command | Result |
|---|---|---|
| Engine | — | `D:\Programming\Gamedev\Godot_v4.7.2-stable_win64.exe` (console variant exists) |
| GUT | — | **9.7.1 installed** in `addons/gut` (docs saying otherwise are stale) |
| Unit tests | `... -Dir res://tests/unit` | **799/799 passing** (93 file di `tests/unit`) |
| Default suite | `powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1` | **836/836 passing**, 4432 asserts, **103 skrip**. Waktu GUT **> 300 s**, jadi perintah runner 120 s **masih timeout** (exit 124); angka di atas dari invokasi GUT yang sama (`-gdir` unit + integration) tanpa kill runner |
| One test file | `... -Test res://tests/unit/<file>.gd` | dipakai saat memperbaiki satu kegagalan |
| Integration tests | `... -Dir res://tests/integration` | **15/15 passing** (10 file: S1-S5 + 7-day soak + perf) |
| Slow-only tests | `... -Slow` (sets `GIMERSIA_SLOW=1`) | helper `tests/helpers/slow_guard.gd` tersedia; saat ini belum ada file tes yang memakainya |
| Lapisan dunia (Mission 13) | `... -Test res://tests/unit/<file>.gd` per berkas | **132/132** di 12 berkas: `test_world_validator` 25, `test_world_guide_sync` 6, `test_docs_in_sync` 16, `test_authored_world` 12, `test_world_zone_grid` 8, `test_world_controller_authored` 8, `test_island_authored` 3, `test_world_golden` 5, `test_world_rules` 14, `test_island` 17, `test_camp_anchor` 13, `test_fase4_base_build` 5. Full suite tidak bisa dijalankan penuh (timeout 120 s per perintah) |
| Verified on | — | 24 Nov 2026 (Mission 11-13) |
| Main scene boot | `--quit-after 120 res://src/levels/island/island.tscn` | exit 0, **no ERROR/WARNING** (island = `run/main_scene`) |
| Legacy practice boot | — | `scenes/practice/practice1.tscn` tidak dipakai lagi sejak Mission 11 (tidak dijalankan) |
| Main menu boot | `--quit-after 120 res://src/ui/menus/main_menu.tscn` | exit 0, **no ERROR/WARNING** |
| Default clock config | — | `cycle_duration` **600 s** (script default; `.tres` no longer overrides it) |
| Dusk warning | — | 15 s before night |

Known bugs still present:

- `phase_changed` carries **only** `phase: int`. Do not connect a two-arg callback.

---

## 4. Implemented modules (code that exists today)

| Module | Path | Contract |
|---|---|---|
| `DayNightManager` (autoload GameClock) | `src/core/managers/day_night_manager.gd/.tscn` | Only source of game time. `start()`, `advance()`, `skip_time()`, `set_night_watch()`, `set_time_scale()`, getters and signals in §6 |
| `DayNightConfig` / `DayNightPeriod` | `src/data/resources/environment/` | `cycle_duration`, `max_days`, `time_scale`, `periods`, day/night duration getters |
| `DayNightVisual` / `DayNightVisualConfig` / `DayLightCurve` / `SunOverlay` | `src/levels/components/environment/`, `src/data/resources/environment/` | World tint via one `CanvasModulate`. Dusk starts when the day phase has `transition_duration` left (60 s = the last game minute of a 300 s day: minute 4 -> evening, minute 5 -> night) and dawn ends exactly at day start; progress comes from `get_remaining_seconds()`, so a scene loaded mid-transition continues correctly. `SunOverlay` (CanvasLayer 1) draws an additive gradient from the sun's screen direction (`DayLightCurve.sun_direction`: sunrise left -> noon top -> sunset right). Particles: fireflies only in `NIGHT`, day motes in every other atmosphere. `get_world_darkness()` (0 day, 1 night) also drives campfire light energy | Implemented; `test_day_light_curve.gd`, `test_environment_light.gd` |
| `TimeHUD` | `src/ui/hud/time/` | Read-only day/phase/remaining/progress/night-survival label |
| `StatsComponent` / `StatModifier` | `src/components/stats/` | Derived stats, proficiency, modifier stacking, HP, `hp_changed`, `stats_changed` |
| `NeedsComponent` / `NeedsConfig` | `src/components/needs/`, `src/data/resources/needs/` | Owns Hunger/Thirst/Fatigue (0..100) plus a Fatigue cap that sprint lowers and food/sleep restores. `get_value()`, `set_value()`, `add()`, `spend_fatigue()`, `get_tier()`, `get_fatigue_cap()`, `restore_fatigue_capacity()`, `set_idle_regen_override(source_id, per_second)`, `clear_idle_regen_override(source_id)`, `get_idle_regen()` (max of base and overrides), `tick(delta)`; signals `value_changed(need, value)`, `tier_changed(need, tier)`, `fatigue_cap_changed(cap)`. Tiers NORMAL/LOW/ZERO apply stats via `&"lapar"`/`&"haus"`/`&"lelah"`. Drains via `get_time_scale()`; no own clock. Mission 9: drain dikali `global_drain_multiplier` x `hunger/thirst_drain_multiplier` x `drain_multiplier_by_day`; Hunger <= 30 menambah sprint block `&"hunger"` |
| `HealthRegenComponent` / `HealthRegenConfig` | `src/components/needs/`, `src/data/resources/needs/` | Mission 9. Regen HP pasif `tick(delta)` waktu game; jeda `out_of_combat_delay` sejak HP turun; multiplier = min kurva Hunger/Thirst (`sample_curve()` murni); nol saat tier ZERO. `.tres`: `src/data/configs/health_regen_config.tres` |
| `RaidDirector` / `RaidConfig` | `src/core/managers/raid_director.gd`, `src/data/resources/fauna/raid_config.gd` | Mission 9. Raid sebagai event: jadwal per malam dari `raids_per_night` x `global_pressure_multiplier`, peringatan `warning_seconds`, raider terdekat ke pusat base, tanda `is_raider` dilepas saat raid selesai/fajar. Sinyal `raid_warning`, `raid_started`, `raid_ended`. Node di `island.tscn`, bukan autoload |
| `NightSpawner` (cap) / `FaunaQuota` (cap siang) | `src/core/managers/` | Mission 9: `NightSpawner.get_hostile_cap()` = `RaidConfig.night_active_hostile_cap` (kosong = tabel spec), `spawn_raid_boar()` additive; `FaunaQuota.get_day_boar_cap()/get_day_deer_cap()` = `day_boar_cap`/`day_deer_cap`. Cap hanya membatasi spawn baru, tidak pernah membunuh boar |
| `FreezeController` | `src/core/managers/freeze_controller.gd` | Mission 9. Beku berbasis alasan (`&"pause"`, `&"death"`), grup `&"game_freeze"`, `request()`/`release()`, skala waktu dipulihkan persis (x2 Jaga Malam, 0 final dawn). `PauseMenu` memakainya bila ada |
| `PlayerDamageReceiver` (protection) | `src/components/combat/player_damage_receiver.gd` | Mission 9. `start_protection()/stop_protection()/is_protected()/tick()` detik nyata, sinyal `protection_started/ended`, kedip visual, tidak ada damage/knockback. `FaunaBase._find_player()` mengabaikan pemain terlindungi bila `protection_ignored_by_enemies` |
| `RunConfig` | `src/data/resources/run/run_config.gd` | Mission 9. `respawn_protection_seconds`, `protection_ignored_by_enemies`, `protection_ends_on_attack`, `protection_blink_hz`. `.tres`: `src/data/configs/run_config.tres` (generator `tools/generate_balance_data.gd`) |
| `RaidWarningHUD` / `ProtectionHUD` | `src/ui/hud/night/`, `src/ui/hud/protection/` | Mission 9, read-only. Banner "Babi hutan mendekati base!" dan label "Perlindungan N dtk" |
| `SneakConfig` / `WadingConfig` | `src/data/resources/movement/`, `src/data/configs/*.tres` | Mission 9 fase 4. `SneakConfig`: `speed_multiplier` 0.55, `detection_multiplier` 0.6, `blocks_sprint`. `WadingConfig`: `speed_multiplier` 0.55, `blocks_sprint`. Digenerate `tools/generate_balance_data.gd` |
| `WadingComponent` | `src/components/movement/wading_component.gd` | Mission 9 fase 4. Anak `Player` di `player.tscn`; `tick()` membaca `IslandZones.zone_at()` dan memanggil `Player.set_wading()`. Tidak menyimpan pengali |
| `MotionTell` | `src/components/movement/motion_tell.gd` | Tell visual fase 4: label runtime "JONGKOK"/"AIR"/"JONGKOK + AIR" di atas pemain. `tick()`, `get_text()`, `is_showing()`; hanya membaca state |
| `Player` (mode gerak) | `src/entities/player/player.gd` | `set_sneaking()/is_sneaking()/get_stealth_multiplier()`, `set_wading()/is_wading()`, `get_move_speed_multiplier()` (jongkok x air), sinyal `movement_mode_changed`; blokir sprint lewat `add_sprint_block(&"sneak"/&"wading")` |
| `IslandDeer` (waspada) | `src/entities/fauna/island_deer/island_deer.gd` | Mission 9 fase 4. `State.ALERT` + sinyal `alerted` sebelum kabur, `get_effective_detect_radius()` = radius kabur x stealth pemain. Art waspada memakai `idle` (tanpa state registry baru) |
| `FaunaBase.get_detection_multiplier()` | `src/entities/fauna/fauna_base.gd` | Jalur bersama rusa + babi: pemain jongkok = radius deteksi x 0.6 |
| `PauseMenu` (UI) | `src/ui/menus/pause_menu.gd` | Menu Jeda sekarang punya isi: panel + 4 tombol (Lanjutkan, Pengaturan, Bantuan, Menu Utama). Dibangun runtime, Esc/P menutup. Sebelumnya CanvasLayer kosong |
| `BagPanel` (tab Profisiensi) | `src/ui/panels/inventory/bag_panel.gd` | Tab ketiga di panel Tab/I: level + XP + passive Kekuatan/Kecepatan/Penguasaan/Kelincahan. `get_proficiency_tab()`, `refresh_proficiency()` |
| `PlaceholderLabels` | `src/ui/hud/placeholder/placeholder_labels.gd` | Overlay HUD: nama slot untuk art yang masih kosong, dekat pemain, kolam `MAX_LABELS` 12, pindai 0.25 s, `ground_*` dilewati. Dipasang di `island.tscn`. Sengaja memakai kolam label bersama, bukan satu `Label` per slot, supaya jumlah Control tidak tumbuh bersama jumlah resource |
| `ChopFeedback` (fix) | `src/entities/props/resource_node/chop_feedback.gd` | Getaran hanya saat progres menebang berjalan (bukan sekadar dekat) dan interactor benar-benar menargetkan pohon ini (`get_target() == _target`, target `null` tidak lagi dianggap cocok), berirama: `CHOP_INTERVAL` 0.22 s, `SHAKE_BURST` 0.12 s |
| `InputGuideGenerator` | `src/core/docs/input_guide_generator.gd`, `tools/generate_input_guide.gd` | Menulis `docs/editable/PANDUAN_INPUT.md` dari InputMap hidup + `PURPOSES`; action tanpa tujuan menggagalkan tes |
| `NeedsHUD` | `src/ui/hud/needs/` | Read-only Hunger/Thirst/Fatigue bars, warning color at tier <= LOW |
| `StatsHUD` | `src/ui/hud/stats/` | Read-only readout of HP, speeds, attack, gather time, sprint drain, Fatigue value/cap and the three need tiers; makes ZERO-tier effects visible |
| `InventoryComponent` | `src/components/inventory/` | Owns 12 bag slots (0-4 = hotbar) of `ItemStack`, plus WEAPON/ARMOR equipment and TOOL ownership. `add_item() -> int` (leftover), atomic `remove_item() -> bool`, `has_item()`, `count_of()`, `get_slot()`/`get_slot_item()`/`get_slot_count()`, `is_full()`, `move_slot()`, `use_slot()`, `add_or_drop()`, `equip()`/`unequip()`/`has_tool()`, `get_capacity()`, `get_hotbar_size()`, `clear()`; `slot_changed(index)`, `equipment_changed(slot)`, `inventory_changed()`. Keys 1-5 use slots; effects via `NeedsComponent.add()` / `StatsComponent` / `restore_fatigue_capacity()`; armor modifiers use `&"equip_armor"` |
| `ItemDefinition` / `ItemEffect` / `ItemStack` / `ItemCatalog` / `InventoryConfig` | `src/data/resources/items/`, `.tres` in `src/data/items/` + `src/data/configs/inventory_config.tres` | Item content: `id`, `display_name`, `description`, `category` {RESOURCE, CONSUMABLE, WEAPON, TOOL, ARMOR, SPECIAL}, `max_stack`, `icon`, `consume_effect`, `equipment_slot`, `weapon_damage/range`, `armor_damage_reduction/max_hp_bonus`; effect `hunger`, `thirst`, `fatigue`, `hp`, `regen_hp_per_second`, `regen_duration`. **`ItemEffect.fatigue` is not a plain Fatigue delta:** `InventoryComponent` applies it through `NeedsComponent.restore_fatigue_capacity()`, so it raises the Fatigue **cap** and fills the current value by the same amount (bounded by the new cap). The field keeps its historical name | `ItemCatalog.ALL` + 23 constants + `get_by_id()` |
| `ItemPickup` | `src/entities/props/item_pickup.gd/.tscn` | Area2D pickup: a body in the `player` group adds `item` x `count` through `InventoryComponent.add_item()`; leftover stays in the world, frees itself at 0. Ignores overlaps during `InventoryConfig.pickup_delay` and sizes its shape from `pickup_radius` |
| `HotbarHUD` | `src/ui/hud/inventory/` | Read-only 5-slot hotbar (key number, display_name or icon, count); binds to `slot_changed(index)` and finds `InventoryComponent` via the `player` group or `@export inventory` |
| `BagPanel` / `BagSlot` | `src/ui/panels/inventory/` | Interactive bag UI on its own `CanvasLayer` (layer 20): 12-slot grid with hotbar markers 1-5, a read-only equipment column (Weapon / Tool ownership / Armor) and a `Crafting` placeholder tab. Toggled by the `inventory_toggle` action (Tab or I) in `_unhandled_input`; Esc (`ui_cancel`) closes it but never opens it; it never pauses the game. Slots use `_get_drag_data`/`_can_drop_data`/`_drop_data` → `move_slot()`, right-click → `use_slot()`, hover tooltip from `ItemDefinition`/`ItemEffect`. Refreshes only from `slot_changed`, `equipment_changed`, `inventory_changed` |
| `Interactable` / `InteractorComponent` / `InteractionHUD` | `src/components/interaction/`, `src/ui/hud/interaction/`, `src/data/configs/interaction_config.tres` | Hold-E framework reused by gather/loot/build/beacon: `Interactable` (group `interactable`, virtual `get_prompt(interactor)`, `get_hold_time(interactor)`, `can_interact()`, `get_block_reason()`, `interact()`), `InteractorComponent` (scan 0.1 s, range 64 from config, progress uses real delta, release/lost target/out of range resets, must re-press after completion; signals `target_changed`, `progress_changed`, `interaction_completed`, `interaction_blocked`, `interaction_cancelled`; `cancel()`, `get_stats()/get_inventory()/get_needs()`), read-only prompt + progress bar + blocked-reason HUD | Implemented; 13 tests |
| `ResourceNodeDefinition` / `ResourceNode` | `src/data/resources/gathering/`, `src/data/gathering/*.tres`, `src/entities/props/resource_node/` | Eight definitions (twig, tree, small/big rock, fiber/berry bush, coconut palm, bamboo clump) with tool gates (`stone_axe`/`stone_pickaxe`), hold time = `gather_time` x `StatsComponent.get_gather_time_factor()`, seeded yield, `spend_fatigue()` once, DAILY / EVERY_OTHER_DAY / NEVER respawn through `DayNightManager.day_started(day)`, permanent removal after `last_respawn_day`; signal `gathered(definition, amount, interactor)` | Implemented; 14 tests |
| `EmergencySuitcase` / `RiverEdge` / `RiverDrinkZone` | `src/entities/props/suitcase/`, `src/entities/props/river_edge/`, `src/components/interaction/river_drink_zone.gd` | Suitcase: hold 1.0 s, grants 1 herbal bandage + 1 boiled water + 1 cockpit notes once, then blocks forever. `RiverEdge` (prop): hold 1.5 s, +25 Thirst, -8 Hunger, 15 real-second cooldown per player; `RiverEdge.apply_drink(interactor)` is the shared effect. `RiverDrinkZone` is a child of Player in `island.tscn`: drink anywhere in `IslandZones.Zone.RIVER` or within 32 px of its banks; it joins group `interactable` only while in/near water, so land interactions are untouched | Implemented; `test_island_props.gd`, `test_river_drink_zone.gd` |
| `cockpit_notes` item | `src/data/items/cockpit_notes.tres` | SPECIAL item "Catatan Kokpit", `max_stack` 1, registered in `ItemCatalog` | Implemented; tested |
| `StructureDefinition` / `CampStructure` / `BlueprintSlot` | `src/data/resources/camp/`, `src/data/camp/*.tres`, `src/entities/camp/` | Four structures (campfire/workbench/chest/tent) generated by `tools/generate_structures.gd`: HP, build cost/time, aggro priority, repair cost/HP, slot position. `CampStructure` (group `camp_structure`, non-blocking Node2D): `take_damage(amount, source)`, `repair(amount) -> float`, `is_damaged()`, `get_aggro_priority()`, `get_hp_bar()` (visible only when damaged); signals `damaged(amount, source)`, `repaired(amount)`, `destroyed`, `hp_changed`. `BlueprintSlot` (extends `Interactable`): hold-E builds `definition.scene`, consumes cost atomically, hides its translucent placeholder, reopens after `destroyed`; `get_structure()`, `built(structure)`. A missing scene, an uninstantiable scene, or a scene whose root is not `CampStructure` blocks with `"Blueprint rusak"` **before** any cost check, so materials can never be consumed | Implemented; 16 blueprint/structure tests. Wired into `island.tscn` via CampController |
| `Campfire` / `CampfireConfig` / `Workbench` | `src/entities/camp/campfire/`, `src/entities/camp/workbench/`, `src/data/resources/camp/campfire_config.gd` | Campfire station + fuel + light + rest bonus. 240 s start / 600 max, 0.25/s day, 1.0/s night, x `get_time_scale()`; refuel 2 wood -> +180 s, hold 0.5 s, blocked at >= 580 (`Bahan bakar penuh`) or with < 2 wood (`Butuh 2 Kayu`); lit light 240 px, ember 80 px, dazzle getter 180 px; `tick(delta)`, `is_lit()`, `get_fuel()`, `set_fuel()`, `get_light_radius()`, `get_dazzle_radius()`; signals `fuel_changed`, `lit_changed`, `fuel_depleted`. PointLight2D energy follows `DayNightVisual.get_world_darkness()`: 0.12 in daylight, 1.0 at night, updated every `_process`. Rest: lit fire within 120 px sets Needs override `&"campfire"` = 5.0 every 0.25 s. Workbench is always an active WORKBENCH station | Implemented; 19 campfire tests + `test_environment_light.gd` |
| `ChestComponent` / `Chest` | `src/components/storage/chest_component.gd`, `src/entities/camp/chest/` | 24-slot storage with the bag's stacking rules (top-up first, then leftmost empty, never reorder) | `add_item() -> int` leftover, `remove_item()` atomic, `get_slot()`, `count_of()`, `is_full()`, `clear()`, `move_to_bag(index, inventory)`, `move_from_bag(inventory, index)`, `get_slots()`; `slot_changed(index)`, `contents_changed()`. `Chest` (extends `CampStructure`) exposes `get_prompt()` -> `"Peti (24 slot)"`, `get_component()`, `interaction_requested`, and drops every stack as `ItemPickup` on destruction (panel deferred) | Implemented; 15 tests |
| `Tent` / `TentConfig` | `src/entities/camp/tent/`, `src/data/resources/camp/tent_config.gd` | Sleep by day and the Night Watch entry point at night | Sleep requires `is_day()`, remaining day > 60 s and >= 60 game seconds since the last sleep; reasons `Hanya bisa tidur di siang hari`, `Waktu siang kurang dari 60 detik`, `Tenda masih perlu istirahat`. On success it calls `clock.skip_time(config.skip_seconds)` **once** (Needs handles `time_skipped`). Hold 1.5 s (mission value). Prompts: `Tahan E: Tidur` / `Tahan E: Jaga Malam` / `... Berhenti Jaga Malam`; `sleep()`, `can_sleep()`, `get_sleep_block_reason()`, `perform_action()` | Implemented; 10 tests |
| `NightWatchController` | `src/levels/camp/night_watch_controller.gd` | Starts/stops Night Watch from the Tent | Start needs night + a lit Campfire (`Hanya saat malam`, `Butuh Api Unggun menyala`); ON/OFF call `clock.set_night_watch()`. Stops on `move_*` input, campfire `fuel_depleted`/`destroyed`, **any** `camp_structure` `damaged`, or dawn/`night_ended` (reasons `Bergerak`, `Api padam`, `Struktur diserang`, `Fajar`, `Dimatikan`); signals `watch_started`, `watch_stopped(reason)` | Implemented; 9 tests |
| `CampController` | `src/levels/camp/camp_controller.gd/.tscn` | Registry of built camp structures with 4 `BlueprintSlot` children at the spec positions | `get_structure(id)`, `get_structures()`, `has_built(id)`, `get_structures_by_priority()` (aggro ascending), `get_slots()`, `get_built_ids()`; signals `structure_built(id)`, `structure_destroyed(id)` | Implemented; 5 tests; wired into `island.tscn` |
| `RepairComponent` | `src/components/camp/repair_component.gd` | Hold **R** (action `repair`, registered by `InputSetup`) 1.0 s on the nearest `camp_structure` within 96 px; consumes `definition.repair_cost` atomically at completion, then `repair(definition.repair_hp)`; resets on release/out of range; reasons `Bahan kurang`, `Struktur sudah penuh`; `get_target()`, `get_progress_ratio()`, `get_target_prompt()`, `get_block_reason()`, `tick(delta)`; signals `progress_changed`, `repair_completed`, `repair_blocked`, `target_changed`. `InteractionHUD` shows the repair prompt/progress additively | Implemented; 11 tests; attached to the island Player |
| `RecipeDefinition` / `ItemAmount` / `CraftingComponent` | `src/data/resources/crafting/`, `src/data/resources/items/item_amount.gd`, `src/data/recipes/*.tres`, `src/components/crafting/` | 13 recipes in `.tres` (3 HAND, 7 WORKBENCH, 3 CAMPFIRE) generated by `tools/generate_recipes.gd`. `CraftingComponent`: `get_stations_in_range()` (group `crafting_station`, 140 px, `station_type` + `is_station_active()`), `get_available_recipes()`, `get_locked_recipes()`, `can_craft()`, `get_block_reason()` (Indonesian), `has_ingredients()`, `count_available()`, `start_craft()`, `cancel_craft()`, `tick(delta)` (real delta x `get_craft_time_factor()`); ingredients consumed atomically at completion (WEAPON-slot ingredient must match the equipped weapon); cancels on movement, HP loss or station loss; result equips WEAPON/TOOL/ARMOR (with better-weapon / already-owned / armor-occupied blocks) or `add_or_drop()`; signals `craft_started`, `craft_progress`, `craft_completed`, `craft_cancelled(recipe, reason)`, `crafted(recipe, count)`, `stations_changed()` (station set in range changed). `ItemAmount` statics `has_all()`, `consume_all()` (atomic + refund), `without_weapon_slot()`, `weapon_slot_amounts()` are shared with `BlueprintSlot` and `RepairComponent` | Implemented; 22 tests; wired into `island.tscn` (Player node) and shown as the `BagPanel` Crafting tab (`CraftingRow`, 8 panel tests) |
| `IslandZones` / `IslandLayoutConfig` / `IslandBuilder` | `src/levels/island/island_zones.gd`, `island_builder.gd`, `src/data/resources/island/`, `src/data/configs/island_layout.tres` | Zone lookup in the order CAMP, SOUTH_BEACH, EAST_BEACH, WEST_CLIFFS, RIVER, FOREST, OUTSIDE; deterministic seeded rejection-sampled layout with spacing/keep-out rules; 139 resource nodes and 16 `night_spawn_point` markers | Implemented; 17 tests |
| `island.tscn` / `GatherDebug` | `src/levels/island/island.tscn`, `island.gd`, `gather_debug.gd` | Minimum map: tinted ground per zone, coastline static walls at ±2400, PlaneWreckage, suitcase, SignalBeacon at South Beach, 9 river edges, full player/HUD wiring, builder node. `GatherDebug` (island only, off by default): F2 grants both tools, F3 teleports to the next zone, F4 skips to the next morning, F5 grants a crafting test kit (30 wood, 20 stone, 20 fiber, 10 bamboo, 10 bone, 10 hide, 6 raw meat, 6 berry) | Implemented; boots headless clean |
| `PlayerBaseStats` | `src/data/stats/player_base_stats.gd` | Base numbers (no `.tres` instance yet; script defaults are used) |
| `Player` | `src/entities/player/` | Top-down movement + sprint from `StatsComponent`; `can_sprint`, `facing_direction`, `sprint_state_changed`, additive `apply_knockback(direction, distance, duration)` + `knockback_multiplier` hook |
| `CombatComponent` / `PlayerDamageReceiver` / `HealthComponent` | `src/components/combat/` | Player attacks: auto only targets HOSTILE/PROVOKED (`can_be_auto_targeted()`), manual swing (click/Space, 90° cone, shared cooldown) provokes NEUTRAL/PASSIVE; weapon damage/range from equipped WEAPON, fatigue 1.2/hit, bone spear bleed, floating damage text + flash; `swing_manual()`, `get_attack_range()`, `get_attack_damage()`, signals `hit_dealt`, `swing`, `enemy_killed`. Receiver: dodge roll (seeded RNG) -> `dodged` + "DODGE!", damage through `calc_incoming_damage()`, knockback, `damaged`. `HealthComponent` owns fauna HP + bleed, group `damageable`, signals `hp_changed`, `damaged`, `died`. `CombatConfig` in `src/data/configs/combat_config.tres`. Additive `register_hit_modifier(source_id, callable)` / `unregister_hit_modifier(source_id)` let passives alter damage in registration order |
| `ProficiencyConfig` / `ProficiencyComponent` | `src/data/resources/proficiency/`, `src/data/configs/proficiency_config.tres`, `src/components/proficiency/` | XP, carry-over, `max_reached_level`, night combat bonus (1.5x), passives and the death debuff (§7.6). Levels are still written through `StatsComponent.strength_level` etc.; per-level stat effects stay in `StatsComponent`. XP sources are wired from existing signals (hit/kill/dodge/gather/craft/boar dash-miss) plus real player displacement for Speed; inside the 180 px camp radius Speed XP is 0. Passives: Heavy Strike (every 4th landed hit x1.3 via hit modifier), Sturdy (knockback x0.5), Second Wind (campfire idle-regen x1.25 via `set_idle_regen_multiplier`), Quick Reflex (+8% dodge below 40% HP), Swift Counter (next hit after a dodge x1.25). Light Footed stays in `StatsComponent` (not duplicated). Master Chef +10 restore diterapkan lewat bonus campfire (`get_campfire_restore_bonus()`); lihat §13 untuk status keputusan | Implemented; 11 tests |
| `DeathController` / `LootBag` / `DeathScreen` | `src/core/managers/death_controller.gd`, `src/entities/props/loot_bag/`, `src/ui/menus/death_screen.gd/.tscn` | 3 respawn tokens dari `PlayerBaseStats.max_respawn_tokens` lewat `StatsComponent.get_base_stats()` (fallback konstanta `RESPAWN_TOKENS` = 3 bila stat tidak ada; kematian setelah token habis = game over permanen), loot bag from all 12 bag slots at the death position (equipment kept), respawn at (0,64) with 70% HP and 60/60/80 needs, proficiency death debuff, player hidden + `PROCESS_MODE_DISABLED` while dead. The clock keeps running. `died(respawns_remaining)`, `respawned`, `game_over`; `respawn()`, `can_respawn()`, `get_last_loot_bag()`. `DeathScreen` only emits `respawn_requested`/`main_menu_requested`; `GameOverScreen` (`src/ui/menus/game_over_screen.gd/.tscn`, CanvasLayer + `PROCESS_MODE_ALWAYS`, buttons Mulai Baru / Menu Utama) emits `restart_requested`/`main_menu_requested` and `island.gd` shows it on `game_over` | Implemented; 5 + 3 + 1 screen tests |
| `EndgameController` / `SignalBeacon` / `EndgameHUD` | `src/core/managers/endgame_controller.gd`, `src/entities/props/beacon/signal_beacon.gd`, `src/ui/hud/endgame/` | Day-7 banner (only on `day_started == max_days`), rescue banner, beacon direction/distance arrow, Victory when the beacon is used during rescue while holding `signal_flare`. Beacon: `Interactable`, hold 1.5 s, blocks with `Belum waktunya` / `Butuh Suar Darurat`; flare is consumed on victory (keputusan Mission 7). Anti-softlock boars are handled by `FaunaQuota.rescue_started` | Implemented; 4 tests; 3 beacon tests |
| `RunController` / `MainMenu` | `src/core/managers/run_controller.gd`, `src/ui/menus/main_menu.gd/.tscn` | `main_menu_requested` / `restart_requested`; freezes the clock with `set_time_scale(0.0)` before the menu and calls `DayNightManager.restart()` on a new run. Scene change goes through the overridable `_change_scene()`. `main_menu.tscn` is **not** the main scene | Implemented; boots headless
| `FaunaBase` / `WildBoar` / `IslandDeer` | `src/entities/fauna/` | `FaunaBase` (CharacterBody2D, group `fauna`, layer 0/mask 1): HealthComponent child, temperament PASSIVE/NEUTRAL/HOSTILE, `provoke()`, `can_be_auto_targeted()`, speed/attack modifier dictionaries, `apply_night_scaling()` keeping HP ratio, `reset_night_scaling()`, Dazzled from lit Campfire (0.70 speed / 0.75 attack), wander, flee+despawn, `drop_loot()` via ItemPickup, `flash_hit()`. Boar: bite 12/50 px/1.2 s, dash 110–240 px with 0.8 s telegraph then 330 px/s (20 + 60 px knockback to player, 40 to structures), camp aggro (player <=140, raid_camp, priority structures), leash 380. Deer: 40 HP, always PASSIVE, flees 175 px/s for 5 s at 130 px or when hit. Configs `boar_config.tres` / `deer_config.tres` |
| `FaunaQuota` / `NightSpawner` / `NightScalingConfig` | `src/core/managers/`, `src/data/resources/fauna/` | Quota: 2 Boar + 3 Deer at start, no mid-day respawn, dawn rule (extras flee, survivors NEUTRAL x1.0, top-up 2/3) for days 2-7, rescue rule (flee, >=2 boars, 45 s REAL respawn, max 4), spawn-point rule (>=600 px from player else farthest). Spawner: night start makes residents HOSTILE + scaled, one spawn immediately then per interval while hostile count < table max (timer x time_scale). Table 3/4/5/6/7/9/12, 45..15 s, x1.0..1.5 |
| `CampAnchor` / `BaseSiteConfig` / `BaseSiteRules` | `src/core/managers/camp_anchor.gd`, `src/data/resources/camp/base_site_config.gd`, `src/utils/base_site_rules.gd` | Camp is dynamic: the anchor is founded once (island founds it at `Vector2.ZERO`), then every consumer reads its centre/radius. `CampAnchor`: `founded`, `get_center()`, `get_ring_radius()`, statics `find_anchor(node)`, `camp_center(node)`, `ring_radius(node)`. `BaseSiteRules` validates placement (water/river clearance, coast margin) | Implemented; 13 tests |
| `BasePlacementController` / `BaseHUD` | `src/components/base/`, `src/ui/hud/base/` | B opens build mode, ghost follows the cursor, invalid sites blocked with an Indonesian reason, left-click founds the base. Signals `placement_changed`, `base_founded(center, radius)` | Implemented; unit-tested |
| `FenceRing` / `FenceSegment` / `FenceConfig` / `FenceGeometry` | `src/levels/camp/fence_ring.gd`, `fence_geometry.gd`, `src/entities/camp/fence/`, `src/data/resources/camp/fence_config.gd`, `src/data/configs/fence_config.tres` | Ring of ~20 fence segments (200 px radius, 66 px segments, 10 wood + 60 hp each) on `PhysicsLayers.FENCE_LAYER` (bit 3, value 8). Boars path around fences, bite/chew blocking segments and can break through; gaps are valid. `FenceSegment` extends `CampStructure` (`repair()` restores 30 hp for 1 wood) | Implemented; 9 tests |
| `FireStarterController` / `FireStarterConfig` / `FireStarterHUD` | `src/components/crafting/fire_starter_controller.gd`, `src/data/resources/combat/fire_starter_config.gd`, `src/data/configs/fire_starter_config.tres`, `src/ui/hud/crafting/` | Campfire ignition QTE: a COLD campfire (fuel refilled but never lit) needs 3 stone strikes in a 1.1 s window; `request_ignition()` blocks with `Butuh Batu`, cancel at 96 px or on state change. RNG injected for tests | Implemented; 7 tests |
| `CombatFeedback` / `JuiceConfig` | `src/components/combat/combat_feedback.gd`, `src/data/resources/combat/juice_config.gd`, `src/data/configs/juice_config.tres` | Visual-only juice: hit-stop via `freeze_for`, camera shake through `Camera2D.offset`, flash/squash, one-shot particles, `feedback_event(kind, position)`, death corpse animation (a detached visual, fauna still frees immediately), boar telegraph line and input buffer (`CombatComponent.swing_buffer_time`). Mission 7: intensity and screenshake also obey `SettingsService` | Implemented; 10 tests |
| `SettingsService` | `src/core/managers/settings_service.gd` | Player settings node (group `settings_service`, not an autoload): `juice_intensity`, `screenshake_enabled`, `hints_enabled`; `get_value/set_value`, `changed(key, value)`, ConfigFile at `user://settings.cfg`, tolerant of missing/corrupt files | Implemented; save/load tested |
| `PauseMenu` / `SettingsPanel` / `HelpPanel` | `src/ui/menus/` | Pause (layer 40, `PROCESS_MODE_ALWAYS`) guarded by visible HUD/panels, stores and restores the exact clock time scale, tree pause; settings slider/toggles; static help list toggled with H; all UI panels use `_unhandled_input` only for toggle/close | Implemented; 10 tests |
| `HintManager` / `HintDefinition` | `src/ui/hud/hints/`, `src/data/resources/hints/`, `src/data/hints/*.tres`, `tools/generate_hints.gd` | One hint at a time, 5 s each, once per run, reset on restart, skipped when hints are off. Triggers: base missing after 3 s, first interactable, first night (day 1), need tier LOW, structure damaged, neutral animal hit, and `trigger()` for the rest | Implemented; queue/reset/off tested |
| `ChestPanel` | `src/ui/panels/chest/chest_panel.gd` | 24 chest slots + 12-slot bag mirror (layer 21): right-click transfers, "Ambil semua", Esc/interact/chest destroyed/120 px closes; locks `BagPanel` while open; no pause | Implemented; 5 tests |
| `small_tree` / `ChopFeedback` | `src/data/gathering/small_tree.tres`, `src/entities/props/resource_node/chop_feedback.gd` | Hand-choppable tree (4.0 s, 2 wood, 3 fatigue, 0.5x with axe) plus chop feedback: shake 2 px/12 Hz, chips every 0.25 s, fall 85 deg/0.6 s, stump until respawn, regrow 0.3→1.0 over 0.5 s, `feedback_event(chop_hit/tree_fall)` | Implemented; 11 tests |
| `RespawnRecapHUD` / `ProficiencyHUD` / `NightBanner` / `NightSurvivalHUD` | `src/ui/hud/` | Read-only HUD: 8 s death-debuff recap from `DeathController.debuff_applied`, 3 s red row flash, night/dawn banner 4 s (dawn skipped while rescue), night survival "Malam N | HH:MM | Fajar dalam mm:ss | Musuh X/Y" (fallback "Bertahan mm:ss" tanpa jam) with progress, hidden by day | Implemented; 4 tests |
| `InputSetup` | `src/utils/input_setup.gd` | Input Map helper: most actions (`move_*`, `sprint`, `hotbar_1..5`, `debug_*`) are declared in `project.godot` `[input]`; `interact` (E), `repair` (R) and `debug_island_*` (F2/F3/F4/F5) are registered by `ensure_actions()`, which only fills gaps idempotently. Also owns `MOVE_ACTIONS` and `is_movement_pressed()`, the single movement poll used by `CraftingComponent` and `NightWatchController`. **Input rule:** gameplay components poll Input actions (`Input.is_action_pressed()`, `is_action_just_pressed()`, `get_vector()`) inside `_process`/tick and never match raw keycodes; UI panels such as `BagPanel` may use `_unhandled_input` for toggle/close only. No gameplay code uses `_unhandled_input` |
| `SafeZone` | `scenes/practice/safe_zone.gd` | **Practice-only** camera zoom + speed modifier example |
| Tests / sandbox / integration | `tests/unit/`, `tests/sandbox/`, `tests/integration/` | GUT unit tests, a manual stats sandbox, and scene-level integration tests on `island.tscn`. `island_harness.gd` (preload, no `class_name`) instantiates the island, resolves the real components, creates `/root/DayNightManager` only when absent (and frees it in teardown), and drives time through `clock.advance()` + the public `tick()` of each node. Scenarios: `test_island_wiring.gd` (S1), `_survival` (S2), `_night` (S3), `_death` (S4), `_endgame` (S5), `_soak` (7-day, 0.5 s step) | Implemented; 7 tests |

| `BodyProfile` / `BodyProfileApplier` | `src/data/resources/physics/`, `src/data/configs/physics/body_*.tres` | Mission 10. Profil massa/kolisi badan (LIGHT/MEDIUM/HEAVY) + satu titik pasang. `apply(body, profile, apply_layers := false)` dipanggil satu baris di `Player._ready` dan `FaunaBase._ready`; `profile_of()`, `knockback_multiplier()`. Nilai: player LIGHT r12 kb 1.0, babi HEAVY r12 kb 0.35, rusa MEDIUM r10 kb 0.6; semua `pushable_by_others = false` |
| `BodySeparation` | `src/components/fauna/body_separation.gd` | Mission 10. Melepas badan yang bertumpuk > `max_overlap_px` (2 px) paling jauh `separation_speed x delta`; tidak menembus dinding/pagar, tidak masuk sungai, tidak mendorong ke arah pemain. Dipanggil `FaunaBase.tick()` |
| `SpawnClearance` | `src/utils/spawn_clearance.gd` | Mission 10. `is_clear(tree, point, min_px := 60.0, ignore)`; dipakai `FaunaQuota` dan `NightSpawner`. Fallback "paling jauh" tidak pernah memakai penanda di dalam ring base |
| `IslandDeer` (Mission 10 states) | `src/entities/fauna/island_deer/island_deer.gd`, `src/data/resources/fauna/deer_config.gd` | WANDER -> ALERT (0.45 s) -> STARTLE (`startle_seconds` 0.9 s, tetap bisa dipukul) -> FLEE (ramp linear 0 -> 175 px/s selama `flee_accel_seconds` 0.5 s). Damage di WANDER/ALERT/STARTLE langsung FLEE + `hit_stun` 0.35 s. `sneak_notice_floor_px` 24 px adalah lantai radius deteksi jongkok |
| `AudioCueDefinition` / `AudioRegistry` / `AudioGuideGenerator` | `src/data/resources/audio/`, `src/data/audio/audio_registry.tres`, `src/core/docs/audio_guide_generator.gd` | Mission 10. 103 cue (kategori, trigger Indonesia, hook, loop, spatial, varian, durasi, bus, prioritas, pola file). **Data dan dokumentasi saja**: tidak ada playback, `AudioManager`, atau file `.ogg`. `AUDIO_GUIDE.md` digenerate dari registry; 19 cue masih `HOOK BELUM ADA` |

| `StationPanel` | `src/ui/panels/station/station_panel.gd/.tscn` | Panel Meja Kerja/Api Unggun: `open(station, interactor) -> bool`, `close()`, `is_open()`, `tick(delta)`, `get_rows()`, `get_title_text()`, `get_status_text()`. Esc atau jarak > 120 px menutup; mengunci gerak pemain tanpa mem-pause dunia, craft lewat `CraftingComponent` yang sama | Implemented; `test_station_panel_craft.gd` |
| `HotbarSelectionComponent` | `src/components/inventory/hotbar_selection_component.gd` | Angka 1-5 memilih slot bila `InventoryConfig.hotbar_select_mode`; `use_held()` dipanggil action `use_held` (klik kanan/F) dan hanya memakai consumable | Implemented; `test_mission10_held_items.gd` |
| `HeldItemVisual` | `src/components/visual/held_item_visual.gd` | State visual item di tangan (`resolve_item()`, `get_shape_points()`, `notify_swing()`); hanya kosmetik, tanpa aturan gameplay | Implemented; `test_mission10_held_items.gd` |
| `UiBackStack` | `src/ui/ui_back_stack.gd` | `close_top(context)` menutup lapisan UI paling atas dulu; panel mendaftar/keluar lewat helper ini supaya Esc konsisten | Implemented; `test_pause_menu.gd` |
| `FaunaBase` (contact stop) | `src/entities/fauna/fauna_base.gd` | Mission 11: `is_touching_player()` + contact-stop di `_wander()`; fauna non-chasing berhenti mendorong badan saat menyentuh pemain. `last_separation` untuk diagnosa | Implemented; `test_mission11_drag_real.gd`, `test_boar_mass.gd` |
| `PhysicsTraceRecorder` | `src/core/debug/physics_trace_recorder.gd` | Mission 11: `start_recording()`/`stop_recording()` merekam 6 detik jejak fisika (posisi, kecepatan, state, overlap, separation) ke CSV `user://drag_trace_<ts>.csv`; tombol K (`debug_drag_trace`) | Implemented; `test_physics_trace_recorder.gd` |
| `Assets` (SpriteFrames) / `ResolvedVisual` | `src/core/assets/assets.gd`, `resolved_visual.gd` | Mission 12: `spriteframes_path()`, `sprite_frames_at()` (cache; resource dibagi), `pick_animation()` (rantai fallback sama dengan PNG), `audit_sprite_frames()`; `ResolvedVisual.animation`/`from_spriteframes`; `.tres` menang atas PNG dan fps/loop ikut resource | Implemented; `test_assets_spriteframes.gd`, `test_assets_core.gd`, `test_visual_slot.gd` |
| `ClockFormatConfig` / `GameClockFormat` (jam dunia nyata) | `src/data/resources/environment/clock_format_config.gd`, `src/core/clock/game_clock_format.gd`, `src/data/configs/environment/clock_format.tres` | Mission 12: presentasi jam tanpa mengubah siklus. Fase DAY = `day_start_hour`->`night_start_hour` (06:00->18:00), NIGHT = 18:00->06:00; kecepatan jam ikut panjang fase. Murni: `hour_of()`, `text()`, `period_of()`, `hours_between()`, `seconds_until_hour()`, `next_period_start_hour()`, `sleep_toast_text()`. Manager: `get_clock_hour()/get_clock_text()/get_clock_period()/get_clock_format()` + sinyal `hour_changed(hour)` | Implemented; `test_game_clock_format.gd` |
| `SunSweep` / `SunSweepOverlay` / `SunConfig` / `SunArc` | `src/core/environment/sun_sweep.gd`, `src/levels/components/environment/sun_sweep_overlay.gd`, `src/data/resources/environment/sun_config.gd`, `src/ui/hud/time/sun_arc.gd` | Mission 13: `mask()`/`rim()`/`ratio()`/`plan()` murni; overlay CanvasLayer 2 `blend_mul` dengan mask 128x1; `SunConfig` (arah, detik, softness, warm rim, arc); `SunArc` read-only di TimeHUD | Implemented; `test_sun_sweep.gd`, `test_environment_light.gd` |
| `WorldSource` / `WorldRules` | `src/levels/world/world_source.gd`, `world_rules.gd` | Mission 13. Satu kontrak sumber dunia (`id`, `zone_at`, `is_walkable`, `is_buildable`, `bounds`, `distance_to_coast/zone`, `poi`, `night_spawn_points`, `water_access_points`, `zone_center`, `has_resource_plan`, `resource_plan`) + fasad statis yang dipakai gameplay/AI/UI. `get_source()`, `set_source()`, `reset()`. Semua kode lama (IslandZones, BaseSiteRules, IslandBuilder, GatherDebug, CampAnchor) lewat fasad ini | Implemented; 14 tes `test_world_rules.gd` + 5 tes golden |
| `FormulaWorld` | `src/levels/world/formula_world.gd` | Sumber dunia FORMULA: memakai `IslandZones` + `IslandLayoutConfig` apa adanya, angka POI/zona sama persis dengan sebelum refactor | Implemented; `test_world_golden.gd` 5 tes/438 assert |
| `WorldConfig` | `src/data/resources/world/world_config.gd`, `src/data/configs/world/world_config.tres` | `mode` (FORMULA/AUTHORED), `authored_scene_path`, `fallback_to_formula`, `cell_size`, `min_spawn_points`, `min_spawn_distance`, `min_corridor_width`, `base_clearance_extra`, `reachability_required_ratio`, `warn_node_ratio`, `polygon_vertex_limit`, `min_forest_area`, `overlay_cell_px` | Implemented; dibaca controller, validator, overlay |
| `WorldController` | `src/levels/world/world_controller.gd` | Memuat sumber sesuai `WorldConfig.mode`, spawn POI/air/malam, collision AUTHORED, fallback ke FORMULA bila scene gagal dimuat (`_authored_failed`). `apply_config()`, `get_source_id()`, `get_authored_root()` | Implemented; 8 tes `test_world_controller_authored.gd` |
| `AuthoredWorld` / `ZoneArea` / `ResourceArea` / `ResourceSpawnEntry` | `src/levels/world/authored_world.gd`, `zone_area.gd`, `resource_area.gd`, `src/data/resources/world/resource_spawn_entry.gd` | Kontrak scene AUTHORED (`@tool`, tanpa autoload): anak Visual/Zones/Markers/Resources/Decor, marker wajib, tombol **Validasi dunia**, `last_validation_summary`, `make_source()`, `build_collision()`, `configuration_warnings()` | Implemented; 12 tes `test_authored_world.gd` + 3 tes integrasi |
| `ZoneGrid` / `AuthoredWorldSource` | `src/levels/world/zone_grid.gd`, `authored_world_source.gd` | Rasterisasi polygon ke grid sel (prioritas, walkable, buildable, blocked) dan sumber AUTHORED: lookup zona, reachability grid, `resource_plan`, `get_shortfalls()` | Implemented; 8 tes `test_world_zone_grid.gd` |
| `WorldValidator` | `src/levels/world/world_validator.gd`, `tools/validate_world.gd` | Validator murni statis: `CODES` W001-W017 (severity, pesan, fix Indonesia), `validate()`, `static_checks()`, `format_report()`, `validate_scene(path, cfg)`, `flood_fill()`, `erode()`. CLI exit 0/1 | Implemented; 25 tes `test_world_validator.gd` |
| `WorldDebugOverlay` | `src/levels/world/world_debug_overlay.gd` | Overlay sel (warna zona, blocked, tak terjangkau), POI/spawn/air berlabel, panel hitungan ERROR/WARN + 8 pesan. Action `debug_world_overlay` = **O**, default OFF, jalan di FORMULA dan AUTHORED; validasi dihitung sekali per sumber (bukan tiap 0.25 s) | Implemented; 2 tes + boot island |
| `WorldGuideGenerator` | `src/core/docs/world_guide_generator.gd`, `docs/editable/WORLD_BUILDING_GUIDE.md` | Panduan membangun dunia untuk PM: 16 bagian, tabel GENERATED dari WorldConfig/IslandLayoutConfig/AuthoredWorld/ZoneArea/ResourceNodeDefinition/WorldValidator.CODES | Implemented; `test_world_guide_sync.gd` 6 tes |

### What does NOT exist yet

Audio playback and `AudioManager` (only cue data + `AUDIO_GUIDE.md` exist),
save system, `EventBus`, `GameManager`, production art and the level loader (`island.tscn` is now a
working minimum map wired for death/endgame; only the art is missing) and
post-MVP fauna (Wolf, Shadow Stalker, Snare Trap, NPCs). Proficiency XP/passives,
death/respawn/loot bag/debuff, the Day-7 banner, beacon arrow, Signal Flare use
and Victory now exist. `practice1.tscn` is still the main scene and is **not**
wired for death/proficiency; `island.tscn` is. Do not assume the missing APIs exist.

Physics since Mission 10: fauna bodies use `PhysicsLayers.FAUNA_BODY` and the
player mask includes it, so the player **cannot** walk through deer or boar;
fences (layer 8) block fauna only, and nothing pushes anything by contact.

Note: `StatsComponent` owns the proficiency **levels** and their per-level stat
effects only (§6.2). XP, `max_reached_level`, passives and the death debuff live
in `ProficiencyComponent` (§7.6).

---

## 5. Architecture rules (follow these)

- **Domain-driven, feature-packaged composition.** Prefer composition over inheritance.
- Layout:
  - `src/core/` — autoloads, managers (global systems).
  - `src/components/<component>/` — reusable, scene-agnostic components.
  - `src/entities/<entity>/` — self-contained entity scene + script.
  - `src/data/resources/` and `src/data/<domain>/` — Resource definitions.
  - `src/data/configs/` — tuning `.tres` files.
  - `src/levels/components/` — reusable level components.
  - `src/ui/hud/<name>/` — read-only HUD; no gameplay state.
  - `tests/unit/` mirrors domains; manual debug scenes go in `tests/sandbox/`.
- Identifiers **English**; Indonesian comments are acceptable and common.
- Use static typing (`func f(x: float) -> void`); `snake_case` files/vars,
  `PascalCase` classes/nodes, `SCREAMING_SNAKE_CASE` constants.
- Tuning numbers belong in `.tres`/Resources, not scattered constants.
- No second clock. Consume `DayNightManager` signals/getters.
- Change stats only via `StatsComponent.add_modifier()` with a stable namespaced
  `source_id` (e.g. `&"lapar"`). Never write base stats or `velocity` from outside.
- Prefer adding new signals/getters over changing existing signatures.
- No `EventBus` yet — direct signals/getters are the pattern.
- `DayNightManager` has **no `class_name`** (avoids singleton name clash). Access
  via `get_node_or_null("/root/DayNightManager")` or preload its script in tests.
- Never add a second `CanvasModulate` for world tint.

---

## 6. Key contracts

### 6.1 DayNightManager

Signals:

```gdscript
started
day_started(day: int)
night_started(day: int)
day_changed(day: int)
phase_changed(phase: int)          # ONE argument
time_updated(day: int, phase: int, remaining_seconds: float)
dusk_started(day: int)
night_ended(day: int)
time_scale_changed(scale: float)
night_watch_changed(active: bool)
time_skipped(seconds: float)
rescue_started                      # final dawn / day 7 00:00
```

Signal order:

```text
night_ended -> (day_changed) -> day_started -> phase_changed -> time_updated
dusk_started -> night_started -> phase_changed -> time_updated
night_ended -> time_updated(forced) -> time_scale_changed(0) -> rescue_started
```

Read API: `current_day`, `current_phase`, `get_current_day()`, `get_max_days()`,
`get_phase()`, `is_day()`, `is_night()`, `get_phase_name()`,
`get_phase_duration()`, `get_phase_elapsed()`, `get_phase_progress()`,
`get_remaining_seconds()`, `get_remaining_text()`, `get_total_elapsed_seconds()`,
`get_day_duration(day=-1)`, `get_night_duration(day=-1)`, `get_day_ratio(day=-1)`,
`get_time_scale()`, `is_night_watch_active()`, `get_config()`.

Control: `start()`, `advance(delta)` (scaled manual tick), `skip_time(seconds)`
(raw seconds, emits `time_skipped(actual)`), `set_night_watch(active)`,
`set_time_scale(value)`.

Rules for survival systems: use `get_time_scale()` (0 at final dawn, 2× during
Night Watch) or listen to `time_skipped`. Do not count your own delta.

### 6.2 StatsComponent

- Proficiency: `strength_level`, `speed_level`, `mastery_level`, `agility_level`
  (clamped 1..10). XP/level-up flow does **not** exist yet.
- Modifiers: `add_modifier(source_id, stat, StatModifier.Kind.FLAT|PERCENT, value)`,
  `remove_modifier(source_id)`.
- Supported stats: `max_hp`, `damage_reduction`, `move_speed`, `sprint_speed`,
  `attack_damage`, `attack_speed`, `dodge`, `craft_time`, `gather_time`,
  `sprint_fatigue_drain`.
- HP: use `set_hp()` / `heal()`; signals `hp_changed(current, max_value)`,
  `stats_changed()`.
- Useful getters: `get_max_hp()`, `get_move_speed()`, `get_sprint_speed()`,
  `get_attack_damage(weapon_base=-1)`, `get_attack_speed()`,
  `get_attack_cooldown()`, `get_dodge_chance()`, `get_damage_reduction()`,
  `get_craft_time_factor()`, `get_gather_time_factor()`,
  `get_sprint_fatigue_drain_factor()`, `calc_incoming_damage(raw)`.

### 6.3 Player

- `StatsComponent` is a child of `Player`. Do not add a second one.
- The `player` group is set on the **Player instance in every scene** that uses
  it (`practice1.tscn` and `island.tscn`), not inside `player.tscn`. New maps
  must add their instance to the group.
- `can_sprint` is externally locked (e.g. Fatigue <= 25). Player does not track needs.
- Camera is not part of `player.tscn`; `practice1.tscn` owns `Camera2D` +
  `PhantomCamera2D`.

---

## 7. MVP spec quick reference

Full detail in the spec; these are the numbers most likely needed while coding.

### Clock

| Days | Day : Night | Day | Night |
|---|---:|---:|---:|
| 1–3 | 5 : 5 | 300 s | 300 s |
| 4–5 | 4 : 6 | 240 s | 360 s |
| 6–7 | 3 : 7 | 180 s | 420 s |

Total 1 cycle = 600 s, full run = 4200 s. Dusk tint + warning in the last 15 s.

### Player base

- HP 100, no passive regen; 3 respawn tokens (4th death = permanent game over).
- Move 160 px/s; sprint 240 px/s (1.5×).
- Auto-attack: 8 damage, 45 px range, 1.2 attacks/s (0.83 s cooldown).
- Dodge 0%, hard cap 50%.
- Inventory: 12 bag slots (1–5 quick bar) + 3 permanent equipment slots
  (weapon/tool/armor); stack max 20 (`Waterskin` and `Flare` = 1).

### Needs (0–100, start 100)

| Need | Day drain | Night drain | Low effect (≤25) | Zero effect |
|---|---:|---:|---|---|
| Hunger | -0.16/s | -0.20/s | move -15%, damage -15% | -1.5 HP/s |
| Thirst | -0.24/s | -0.18/s | fatigue drain +30%, attack speed -20% | -2.0 HP/s |
| Fatigue | walk -0.08/s, sprint -2.5/s (-cap 0.4/s), idle +1.0/s, attack -1.2/hit, gather -2.0/action | same | sprint locked, move -20%, gather +30% time | move -45%, attack speed -50% |

- Fatigue recover: idle within 120 px of lit Campfire +5/s; sleep in Tent
  (day only, >60 s remaining, 60 s cooldown) restores 100% and `skip_time(45)`;
  berry/coconut +10.
- **Implemented today (differs from the spec, intentional tuning):** Fatigue has a
  cap that starts at `max_value` (100). Sprinting drains the value at -2.5/s **and**
  lowers the cap by `fatigue_sprint_cap_drain` (-0.4/s, e.g. 100 -> 80 after 50 s
  of sprinting). Walking drains the value at -0.08/s but never the cap. Standing
  still regenerates `fatigue_idle_regen` (+1.0/s) up to the cap. Eating calls
  `restore_fatigue_capacity(amount)`, which raises the cap **and** fills the
  current Fatigue by the same amount (bounded by the new cap); Berry and Coconut
  use `ItemEffect.fatigue_cap_restore` = 10, other consumables use 0. Sleeping
  (`time_skipped`) restores `sleep_fatigue_cap_restore` (+25) and fills Fatigue to
  the new cap. Campfire-adjacent +5/s **is implemented**: a lit `Campfire` within
  120 px calls `NeedsComponent.set_idle_regen_override(&"campfire", 5.0)` every
  0.25 s and clears it when the player leaves, the fire goes out, or it is
  destroyed.

### Items & consumables (implemented)

Items are `ItemDefinition` resources in `src/data/items/<id>.tres`, reached through
`ItemCatalog`. `ItemEffect` carries `hunger`, `thirst`, `fatigue`, `hp` (instant)
plus `regen_hp_per_second`/`regen_duration` (stored only). Items never call
`add(Need.FATIGUE, ...)`: `fatigue` is applied through
`restore_fatigue_capacity()` so the Fatigue cap rises with the value. Berry +12
hunger / +10 fatigue, Coconut +10 hunger +30 thirst / +10 fatigue, Raw Meat +15
hunger -10 thirst, Cooked Meat +45 hunger +15 HP, Bone Broth +35 hunger +40
thirst (+1 HP/s for 20 s stored), Boiled Water +60 thirst, Herbal Bandage +35 HP.
`InventoryComponent.use_slot(index)` applies them, consumes one item even when
the stat is full, and ignores non-CONSUMABLE categories; keys **1-5** use the
first five bag slots. 23 definitions exist (6 resources, 7 consumables, 4
special, 3 weapons, 2 tools, 1 armor); equipment slots WEAPON/ARMOR/TOOL are
implemented (TOOL = ownership set), and only Leather Vest changes stats.
- Sleep must clamp hunger/thirst to at least 1.0 (sleep cannot kill).
- Campfire idle at 120 px radius; camp radius = 180 px.

### Camp (4 fixed blueprints, all destroyed → blueprint slot again)

> **Mission 6:** the camp is now dynamic. `CampAnchor` stores the founded
> centre/radius and every consumer (raid target, camp fire radius, respawn,
> fauna spawn keep-out, blueprint slots) reads it with `Vector2.ZERO` / 180 px
> defaults, so scenes and tests without an anchor behave exactly as before.
> The blueprint coordinates below are the defaults relative to that centre.

| Structure | Pos | HP | Build cost | Notes |
|---|---|---:|---|---|
| Campfire | (0,0) | 250 | 4 wood + 3 stone + 2 fiber | starts with 240 s fuel, max 600; fuel -1/s night, -0.25/s day; +180 s per 2 wood |
| Workbench | (-96,-32) | 180 | 5 wood + 2 stone + 3 fiber | unlocks tool/weapon/armor/flare recipes |
| Camp Chest | (+96,-32) | 200 | 6 wood + 2 fiber | 24 slots |
| Leaf Tent | (0,-110) | 120 | 6 wood + 6 fiber + 2 bamboo | sleep + Night Watch |

Campfire light 240 px; `Dazzled` inside 180 px: enemy move -30%, attack speed -25%.
Night Watch doubles game time (and hunger/thirst/fuel drain) only while night.

### Fauna / night scaling (MVP fallback = 100% Wild Boar)

- Wild Boar: 80 HP, 12 dmg, 115 px/s day / 150 night, bite ≤50 px CD 1.2 s,
  dash 110–240 px telegraph 0.8 s then 330 px/s (20 dmg + knockback; 40 vs structures).
- Island Deer: 40 HP, passive, flees.
- Night: max enemies 3/4/5/6/7/9/12, spawn interval 45/40/35/30/25/20/15 s,
  HP/damage multiplier 1.0/1.0/1.1/1.2/1.3/1.4/1.5 for nights 1–7.

### Death / victory

- Death: drop all 12 bag slots at death location (loot bag), keep equipment.
  Respawn at (0,+64) with 70% HP, 60 hunger, 60 thirst, 80 fatigue.
  Debuff: reduce up to 2 eligible proficiencies by 1 level.
- Day 7 00:00: clock freezes, needs stop, extra enemies flee; guarantee ≥2
  boars for bone drops; HUD arrow to beacon; player needs `Signal Flare`
  (workbench: 5 wood + 3 bone + 2 hide + 2 fiber), hold E 1.5 s at beacon
  (0,+2100) → Victory.

### Spec details beyond the quick reference (V8, **[MVP]** unless marked)

These were missing from earlier revisions of this file. Numbers are copied from
the spec; if anything disagrees, the spec wins.

#### 7.1 Controls & actions

- Move WASD/arrows. Sprint = hold Shift, only while Fatigue > 25.
- Base placement: B starts/confirms, Q rotates fence ring 15° (Shift+Q reverse), Esc cancels; center snaps to a 16 px grid.
- Bag: right-click uses a consumable, Shift+left-click splits a stack, "Urutkan" merges and sorts slots; craft rows have a 1..5 quantity.
- Hold **E** to interact (gather, build, drink, loot, beacon). Radial progress;
  releasing early or leaving range resets to 0%.
- Hold **R** for 1.0 s near a damaged camp structure to repair it (consumes
  materials from the bag). Costs are in §7.4.
- **Tab / I** opens the bag + Hand-Crafting tab (`BagPanel` implements the bag and
the drag/right-click rules; the Crafting tab is still a "Segera hadir"
placeholder). Keys **1-5** use the item in that hotbar slot. In the bag UI:
right-click = use, left-click drag = move slot.
- Crafting/gathering progress cancels cleanly (no material loss) if the player
  moves or is hit.
- Bag rules: new items fill the leftmost empty slot or stack onto the same item;
  order is never shuffled. Bag full -> item drops as an Area2D pickup at the feet.
- Equipment (permanent, not in the bag, not dropped on death): Weapon = best spear
  crafted; Tool = ownership of Stone Axe / Stone Pickaxe; Armor = Leather Vest.

#### 7.2 Combat & provocation

- Auto-attack targets only **HOSTILE** entities (night enemies, provoked fauna),
  inside or outside camp.
- **NEUTRAL** (Boar/Wolf by day) and **PASSIVE** (Deer) are ignored by auto-attack
  until one manual trigger hits them: **Left Click** (toward cursor) or **Space**
  (nearest target in a 90 degree cone in front, within `attack_range`). After that
  the entity joins the active-target list and auto-attack locks on while in range.
- Day: all fauna NEUTRAL (wander, never chase, never attack camp) unless provoked
  -> AGGRESSIVE until the leash is exceeded. Night: Boar/Wolf/Spider HOSTILE.
  Deer is always PASSIVE.
- Dodge: passive RNG on hit; floating "DODGE!" text, damage becomes 0.
- Knockback from Dash Charge: 60 px over 0.2 s (Sturdy, Strength Lv6, halves it).
- Damage taken = raw x (1 - damage_reduction). Percent modifiers are additive with
  clamp >= 0.25; Dodge additive clamp [0, 50%]; Heavy Strike / Swift Counter are
  multiplicative at the final damage step.
- Weapons (Weapon slot): Wooden Spear 18 dmg / 75 px; Stone Spear 28 / 85 px;
  Bone Spear 30 / 85 px + Bleed (-2 HP/s for 3 s).
- Night combat (hit, dodge, kill) gives +50% proficiency XP.

#### 7.3 Fauna & spawning

- **Wild Boar** extras: day NEUTRAL, leash 380 px; night HOSTILE, detect 300 px;
  Dash cooldown 6 s day / 4 s night. Drops 2 Raw Meat + 1 Bone (100%).
- **Island Deer** (**MVP**): 40 HP, damage 0, 175 px/s, always PASSIVE. Flees 5 s
  when the player is within 130 px or after being hit. Drops 2 Raw Meat + 1 Hide
  (Kulit). Deer is the **only Hide source in MVP** (Wolf is post-MVP), and Hide is
  required for Leather Vest (3), Waterskin (2) and Signal Flare (2). Do not skip it.
- Daytime quota from 00:00 Day 1: **2 Boar (NEUTRAL) + 3 Deer**. No respawn timer
  during the day; a killed animal returns at the next dawn.
- Dawn (Day 2-6 per spec): extra night enemies FLEE until at most 2 Boar remain
  (back to NEUTRAL); Deer refilled to 3 at random off-camera forest points.
- Night spawn points: 16 `Marker2D` in Zone 6 at radius >= 1100 px from camp. If
  all are < 600 px from the player, use the farthest one outside the camera view.
  A killed enemy frees a slot; the replacement appears on the next spawn interval.
- **[POST-MVP]** Island Wolf, Shadow Stalker (spider), Snare Trap, Silk Bandage,
  NPCs Bima / Sari / Raka. Leave hooks only (see §10).

#### 7.4 Camp, defense & structures

- Plane Wreckage (0,-185): indestructible `StaticBody2D`. Emergency Suitcase
  (-48,+40): indestructible, lootable once (hold E 1.0 s) for 1 Herbal Bandage,
  1 Boiled Water, Cockpit Notes. Player spawns at (0,+64) facing north.
- Build by holding E on a blueprint slot: Campfire 2.5 s, Workbench 3.0 s,
  Chest 2.5 s, Tent 4.0 s. Campfire starts lit with 240 s fuel.
- Destroyed structure -> blueprint slot again. Destroyed Chest drops its contents
  as a Loot Bag. HP bar only shows when `current_hp < max_hp`.
- Repair (hold R, 1.0 s): Campfire 1 wood + 1 stone -> +80 HP; Workbench 1 wood +
  1 fiber -> +70; Chest 2 wood -> +80; Tent 1 wood + 2 fiber -> +60.
- Light does not block enemies. **Dazzled** (Campfire fuel > 0, enemy within
  180 px): move -30%, attack speed -25%; removed when fire is out/destroyed.
- Light radii: player 110 px (190 px with Torch, 300 s); Campfire lit 240 px;
  built but out of fuel 80 px; not built/destroyed = no camp light. Night tint
  `CanvasModulate` = `#1a2238`.
- Enemies attack structures only after detecting the player in camp (500 px from
  (0,0)) or chasing the player in. Far-forest spawns never raid an empty camp.
- Aggro split: player within 140 px -> target player; otherwise nearest built
  structure by priority Campfire -> Workbench/Chest -> Tent. Boar Dash deals 40
  to structures, bite 12.
- **Ember Snuff** (nights 5-7): each physical hit on the Campfire also removes
  8 s of fuel (6 s with Bima, post-MVP).
- Night Watch: lit Campfire required; started from the Tent (or the Campfire if
  no Tent). Stops on: movement input, fuel == 0, a camp structure being attacked,
  or dawn.
- Tent sleep also simulates the skipped 45 s proportionally: Hunger -7.2,
  Thirst -10.8, fuel -11.25 s (clamp Hunger/Thirst to >= 1.0).

#### 7.5 Resources, recipes & consumables

| Resource | Node (tool) | Time | Yield | Respawn |
|---|---|---:|---|---|
| Wood | twig (hand) / tree (Stone Axe) | 1.0 / 2.5 s | 1 / 3 | each morning |
| Stone | small rock (hand) / big rock (Stone Pickaxe) | 1.5 / 3.0 s | 1 / 3 | each morning |
| Fiber | bush (hand) | 1.0 s | 2 | each morning |
| Berry | bush (hand) | 0.8 s | 2 | each morning |
| Coconut | coastal palm (hand/axe) | 1.2 s | 1-2 | every 2 days (odd mornings) |
| Bamboo | river clump (hand/axe) | 1.5 s | 2 | each morning |
| River water | river edge | 1.5 s | drink / refill | unlimited |

Zone 1 starter nodes: 6 twigs, 4 small rocks, 5 fiber bushes, 4 berry bushes.
They respawn **at most 3 times** (last at Day 4 morning); from Day 5 they are
gone for good.

**Hand-Crafting** (Tab/I, or hold E on a blueprint):

| Result | Ingredients | Time |
|---|---|---:|
| Campfire / Workbench / Chest / Tent | see §7 Camp table (Tent 6 wood + 6 fiber + 2 bamboo) | 2.5 / 3.0 / 2.5 / 4.0 s |
| Wooden Spear | 3 wood + 2 fiber | 2.0 s |
| Torch | 2 wood + 1 fiber | 1.5 s |
| Herbal Bandage (+35 HP) | 3 fiber + 2 berry | 1.5 s |

**Workbench**: Stone Axe 2 wood + 2 stone + 1 fiber (2.5 s); Stone Pickaxe 2 wood
+ 3 stone + 1 fiber (2.5 s); Stone Spear 1 Wooden Spear + 2 stone + 2 fiber
(3.0 s); Bone Spear 1 Wooden Spear + 2 bone + 2 fiber (3.0 s); Leather Vest
3 hide + 3 fiber (3.0 s; -20% damage taken, +15 max HP); Waterskin 2 hide + 1 fiber
(2.5 s); Signal Flare 5 wood + 3 bone + 2 hide + 2 fiber (4.0 s).

**Campfire** (must be lit): Refuel 2 wood, instant, +180 s (cap 600, disabled at
>= 580); Cooked Meat 1 raw meat (2.0 s); Boiled Water 1 bamboo (2.0 s); Bone Broth
2 bone + 1 raw meat (2.5 s).

Upgrade recipes: `has_ingredients()` checks the 12 bag slots first, then the
Weapon slot. On completion the consumed Wooden Spear is removed from the Weapon
slot and the new spear is equipped.

**Consumables**:

| Item | Effect |
|---|---|
| Berry | +12 Hunger, +10 Fatigue |
| Coconut | +10 Hunger, +30 Thirst, +10 Fatigue |
| Raw Meat | +15 Hunger, -10 Thirst |
| Cooked Meat | +45 Hunger, +15 HP |
| Bone Broth | +35 Hunger, +40 Thirst, +1 HP/s for 20 s |
| Boiled Water | +60 Thirst, no Hunger penalty |
| Herbal Bandage | +35 HP |
| River drink (hold E 1.5 s) | +25 Thirst, -8 Hunger, 15 s cooldown |
| Waterskin | +25 Thirst per sip, -5 Hunger, becomes `waterskin_empty`; refill at river (hold E 1.5 s) |

#### 7.6 Proficiency, XP & death debuff

- Four proficiencies, Lv 1-10. XP to level = `100 x current_level`. Overflow XP
  carries over (`current_xp -= xp_needed`). At Lv 10, `current_xp` is locked at 0
  and XP gain stops. Each keeps `max_reached_level` (start 1, updated on level up).
- Per-level effects start at Lv 2 (factor `level - 1`): Strength +10% melee damage
  and +5 max HP; Speed +4% move speed and -3% sprint fatigue drain; Mastery -6%
  craft and gather time; Agility +5% attack speed and +2% dodge.
- Passives: Strength Lv3 **Heavy Strike** (every 4th hit x1.30), Lv6 **Sturdy**
  (-50% knockback). Speed Lv3 **Light Footed** (+10% sprint speed), Lv6 **Second
  Wind** (+25% camp Fatigue regen). Mastery Lv3 **Resourceful** (20% chance of
  +1 resource), Lv6 **Master Chef** (+10 extra restore from Campfire food/drink).
  Agility Lv3 **Quick Reflex** (+8% dodge while HP < 40%), Lv6 **Swift Counter**
  (next hit after a dodge x1.25).
- XP sources: Strength: hit +10, tree +15, rock +15. Speed: walking outside the
  180 px camp radius +1 per 100 px, sprinting outside it +3/s, **0 inside camp**
  (anti-farm). Mastery: craft +25/item, cook +20/item, gather +8/action. Agility:
  dodge +20 (3 s per-enemy cooldown), surviving a Boar Dash telegraph +25 (max 2x
  per boar), kill +30.
- Death flow: HP 0 -> `respawns_remaining -= 1`. If >= 0: "Kamu Tewas" UI with
  "Sisa Kesempatan Respawn: X / 3" + Respawn / Main Menu. If < 0: permanent Game
  Over (Mulai Baru / Main Menu). Loot bags from multiple deaths coexist.
- Debuff algorithm: eligible = `current_level > 1` AND
  `current_level > max_reached_level - 2`; sort by `current_level` desc (tie:
  Strength > Speed > Mastery > Agility); take the top 2; each loses 1 level and
  `current_xp = 0` (only those two).
- If the player is on the death screen when the Day-7 timer hits 00:00, the dawn
  state and beacon indicator stay active after Respawn.

#### 7.7 World layout (production map)

- Island 4800 x 4800 px (-2400..+2400), coastline `StaticBody2D`, about 15 s on
  foot from centre to coast. `CrashSiteOrigin = (0,0)`.
- Zones are evaluated in this order: **1 Crash Site/Camp** (distance <= 800);
  **2 South Beach** (Y > +1400): 12 coconut palms + Signal Beacon (0,+2100);
  **3 East Beach** (X > +1400, |Y| <= 1400); **4 West Cliffs** (X < -1400,
  Y <= +1400): 22 rocks; **5 River** (-1050 <= X <= -850, |Y| <= 1400): river
  water + 14 bamboo; **6 Dense Forest** (the rest): 30 trees, 24 fiber bushes,
  18 berry bushes, fauna habitat, night spawn points.
- **[POST-MVP]** NPC spawn points: Bima (2100,0) from Day 2; Sari (0,-1500) from
  Day 4; Raka (-1600,0) from Day 5.

#### 7.8 Day 7 & rescue

- Morning of Day 7: HUD banner ("Kapal penyelamat terlihat di cakrawala! Siapkan
  Suar Darurat dan bertahanlah melewati malam terakhir...").
- Night 7 runs the max wave until the timer reaches 00:00. Then: dawn sky, clock
  frozen, Hunger/Thirst drain 0, extra enemies flee and despawn, HUD arrow points
  to the Beacon (0,+2100).
- Anti-softlock: at that moment, if fewer than 2 Boar exist, spawn up to 2 (NEUTRAL)
  in Zone 6. If killed afterwards they respawn after 45 s, max 4 extra respawns.
- Victory: hold E for 1.5 s at the Beacon while carrying the Signal Flare.

---

## 8. Suggested build order (revised against spec V8)

Supersedes the order in `MVP_CHECKLIST` §19 (update that file to match).

1. **P0 - foundation cleanup (small). — DONE.** Tests green; `set_time_scale(-1)`
   resets to config; stale docs and README links fixed; `docs/editable` +
   `docs/noneditable` move staged for commit.
2. **P1a - survival core.**
   1. `NeedsComponent` + needs HUD (§7 Needs table). Effects go through
      `StatsComponent` modifiers; read `get_time_scale()` / `time_skipped`.
      **— DONE** (`NeedsComponent`/`NeedsConfig`, 27 tests; `NeedsHUD`
      read-only, not visually verified).
   2. Inventory: 12 bag slots, hotbar 1-5, 3 equipment slots, `ItemDefinition`,
      pickup/drop, consumable effects (§7.1, §7.5). **— DONE**
      (`InventoryComponent`, `ItemPickup`, 23 tests; bag panel Step 2B with
      drag/drop and equipment column, 17 tests; Crafting tab is real since Step
      5 Phase 4, plus its own 8 panel tests).
   3. Resource nodes + hold-E gathering, tool gates, Fatigue cost, Zone 1 respawn
      limits (§7.5). **— DONE** (`Interactable`/`InteractorComponent` + 8
      `ResourceNodeDefinition` .tres, 14 tests).
   4. Minimum production map: Zone 1 plus enough of Zones 2/4/5/6 to reach every
      resource, wreckage, Emergency Suitcase, Beacon (§7.4, §7.7). Grow it
      incrementally; keep `practice1.tscn` working. **— MINIMUM DONE**
      (`src/levels/island/island.tscn`: zones, 139 nodes, 16 night markers,
      wreckage, suitcase, `SignalBeacon`, river edges; art and level loader
      still open).
   5. Crafting (hand / Workbench / Campfire), blueprint slots, structures with HP,
      repair (hold R), fuel, Tent sleep, Night Watch (§7.4, §7.5). **— PARTIAL
      (Step 5 Phases 1-2)**: 13 `.tres` recipes + `CraftingComponent` (station
      range check, atomic consume, weapon-slot upgrade, equip rules, cancel
      rules, 22 tests); 4 `StructureDefinition` `.tres` + `CampStructure` /
      `BlueprintSlot` / `Campfire` / `Workbench` / `RepairComponent` + Needs rest
      override; `ChestComponent`/`Chest`, `Tent`/`TentConfig`,
      `NightWatchController` and `CampController` (Phase 3, 58 tests); Phase 4
      added the Crafting tab, the `island.tscn` wiring (CampController instance +
      `CraftingComponent`/`RepairComponent` on Player) and the F5 kit. Still open:
      the Chest panel.
3. **P1b - threat loop. — DONE.**
   1. Combat: auto-attack + manual provocation (click/Space), dodge (no
i-frames), knockback, weapon slot stats (§7.2). `CombatComponent`,
`PlayerDamageReceiver`, `HealthComponent`, `Player.apply_knockback`.
   2. Island Deer (only Hide source) + Wild Boar day/night AI + daytime quota
      (§7.3). `FaunaBase`/`WildBoar`/`IslandDeer` + `FaunaQuota`.
   3. Night spawner (16 markers, caps/intervals/multipliers), camp-aggro logic,
      Dazzled, Ember Snuff (§7.3, §7.4). `NightSpawner` + `NightScalingConfig` +
Campfire `remove_fuel()`/Ember Snuff. 55 new tests in total; F6-F10 debug helpers.
4. **P1c - Proficiency. — DONE.** `ProficiencyComponent` (XP, carry-over,
   `max_reached_level`, passives, night XP bonus, Speed displacement, death
   debuff) + `ProficiencyConfig`/generator; additive `register_hit_modifier` on
   `CombatComponent`, `set_idle_regen_multiplier` on `NeedsComponent`, and
   `DayNightManager.restart()`. 18 tests.
5. **P2 - death and endgame. — DONE.** `DeathController` + `LootBag` +
   `DeathScreen`, `RunController` + `MainMenu`, `EndgameController` +
   `SignalBeacon` + `EndgameHUD`, island wiring, F11 (kill) / F12 (rescue)
   debug keys. 12 tests.
6. **Mission 5 - integration + stabilization. — DONE.** Scene-level harness on
   `island.tscn` with S1-S5 scenarios plus a 7-day soak (0.5 s step, ~11 s,
   node growth 3.96%). 7 integration tests; whole suite 393 tests.
7. **P3 - polish.** Main menu, pause, audio, sprites/animations, balancing,
   playtest, export. Post-MVP items only after the MVP gate (§12).
8. **Mission 12 (owner) - jam dunia nyata. — DONE.** `ClockFormatConfig` +
   `GameClockFormat` + generator `.tres`; `DayNightManager` hanya menambah
   getter jam dan sinyal `hour_changed` (siklus/fase/durasi tidak berubah);
   TimeHUD menampilkan jam besar + periode + Hari N/7 (arc matahari ikut jam),
   NightSurvivalHUD menampilkan jam + "Fajar dalam", DeathScreen/Victory/Tenda
   memakai jam, debug `Y` melompat ke awal periode. 22 tes
   (`test_game_clock_format.gd`).
9. **Mission 11 - fauna drag fix + trace. — DONE.** Contact-stop di
   `FaunaBase._wander()` (`is_touching_player()`) + `last_separation`, dan
   `PhysicsTraceRecorder` (tombol K, CSV) untuk diagnosa. `test_mission11_drag_real.gd`
   (12 kasus tarik, semua < 0.05 rasio geser), `test_physics_trace_recorder.gd`,
   `test_boar_mass.gd`, `test_mission10_physics_matrix.gd`.

Recommended new locations (keep conventions):

```text
src/components/needs/needs_component.gd
src/components/inventory/inventory_component.gd
src/components/proficiency/proficiency_component.gd
src/components/combat/hitbox.gd (or similar)
src/entities/props/resource_node/resource_node.gd/.tscn   # DONE
src/components/interaction/interactable.gd                # DONE
src/entities/props/camp/campfire.gd ... etc.
src/entities/enemies/wild_boar/wild_boar.gd/.tscn
src/entities/fauna/island_deer/island_deer.gd/.tscn
src/core/managers/night_spawner.gd
src/core/managers/fauna_quota.gd
src/levels/island/ (production map, zones, spawn markers)
src/ui/hud/needs/needs_hud.gd/.tscn
src/ui/hud/inventory/...
src/ui/menus/death_screen.tscn
tests/unit/test_needs_component.gd   # etc.
```

Create tuning resources under `src/data/configs/` (e.g. `needs_config.tres`,
`night_scaling.tres`, `proficiency_config.tres`, `fauna_quota.tres`) and recipe
resources under `src/data/recipes/`.

---

### Mission 7 — Decisions, Trees, MVP completeness (21 Nov 2026)

Deer are guaranteed at rescue, the flare is consumed at the Beacon, fire-starting
stones are only consumed on a failed attempt, Master Chef adds its +10 through
`InventoryComponent.item_used`, the camp starter ring gained hand-choppable
small trees (total 153 resource nodes), pause/settings/help/hints/chest panel and
the missing night/debuff HUDs exist. No audio, no art, no balance changes.

### Mission 6 — Base & Feel (21 Nov 2026)

Day-time boars are neutral again (temperament is derived every tick, aggro
requires `can_be_auto_targeted()`), the player founds a dynamic base (B), a fence
ring exists, campfires need an ignition QTE when they were never lit, and combat
has visual juice. None of it changes balance numbers.

### Mission 9 — Balance & Feel, pass 2 (23 Nov 2026)

Fase 0-4 dikerjakan (fase 5-6 belum): raid menjadi event terjadwal dengan
peringatan + cap populasi, babi punya massa (tidak bisa ditembus/didorong),
api unggun dibangun COLD lalu dinyalakan QTE, kematian membekukan game dengan
perlindungan respawn, needs dikalibrasi ulang (Hunger <= 30 mengunci sprint, HP
pulih lebih lambat saat lapar/haus), pemain bisa jongkok (Ctrl) dengan deteksi
fauna 0.6x, rusa waspada dulu sebelum kabur, dan air sungai memperlambat serta
memblokir sprint. Rincian angka: `CONFIG_GUIDE` dan laporan misi.

### Mission 10 — Physics matrix, deer first hit, audio data (23 Nov 2026)

- Profil massa player/babi/rusa + `BodyProfileApplier` (satu baris di `_ready`),
  `BodySeparation` di `FaunaBase.tick`, dan aturan spawn 60 px
  (`SpawnClearance`) di `FaunaQuota`/`NightSpawner`.
- Rusa: WANDER -> ALERT -> STARTLE -> FLEE dengan ramp kecepatan 0.5 s dan
  hit-stun 0.35 s; damage di tiga state pertama langsung memicu FLEE.
- Matriks fisika (A-F) dan simulasi first-hit S1-S5 terbukti dengan badan
  karakter sungguhan; akar masalah yang diperbaiki: ring pagar tidak mengikuti
  pusat base, dan fallback spawn memilih penanda di dalam ring base.
- Registri audio 103 cue + `docs/editable/AUDIO_GUIDE.md`; **tanpa playback**.
- Gate: 754/754 tes lulus, tiga boot headless bersih.

### Spec deviations approved by the owner

- Fence ring is a separate ring of segments, not 4 extra blueprint slots.
- `PhysicsLayers.FENCE_LAYER = 8` (bit 3) because `project.godot` may not be edited.
- Campfire COLD state: refuelling an unlit campfire no longer relights it.
- Death animation uses a detached corpse visual; fauna frees immediately so
  quota/spawn/soak timing is unchanged.
- Mission 7: `small_tree` + new CAMP starter counts (twig 10, small_rock 8,
  small_tree 6; total 153); fire-start stone is consumed only on a failed
  attempt; the signal flare is consumed at the Beacon; Master Chef is implemented
  simply (+10 to the related need); deer guarantee at rescue is ON.
- Mission 9: raid adalah EVENT terjadwal (`RaidConfig.mode = EVENT_ONLY`) dengan
  cap populasi (`night_active_hostile_cap` 2/3/3/4/5/6/8, `day_boar_cap` 2,
  `day_deer_cap` 3); boar hostile lama di atas cap tidak pernah dicull.
- Mission 9: babi punya badan fisik (`PhysicsLayers.FAUNA_BODY`/`PLAYER_BODY`)
  sehingga pemain tidak bisa menembus/mendorongnya; rusa tetap bisa ditembus.
- Mission 9: api unggun dibangun COLD (`CampfireConfig.start_lit = false`),
  bahan bakar tersimpan tidak mengalir, cahaya 0 sampai pernah menyala.
- Mission 9: kematian membekukan game (jam berhenti selama layar mati); ini
  menggantikan aturan lama "jam tetap berjalan saat mati".
- Mission 9: perlindungan respawn 5 dtk nyata (musuh mengabaikan pemain,
  kedip visual, bisa dimatikan lewat `RunConfig`).
- Mission 9: kebutuhan dikalibrasi ulang (Hunger/Thirst 0.6/0.57 x drain spec),
  Hunger <= 30 mengunci sprint dan regen HP berskala min(Hunger, Thirst).
- Mission 9 fase 4: jongkok `Ctrl` (0.55 kecepatan, 0.6 radius deteksi, tanpa
  sprint); rusa waspada 1.25x radius kabur selama 0.45 dtk sebelum kabur; air
  sungai 0.55 kecepatan tanpa sprint. Angka air/jongkok tidak ada di spec V8
  (tuning awal, dicatat di laporan).
- Mission 9 fase 4: state waspada rusa memakai art `idle`; registry aset tidak
  berubah dan tidak ada state animasi baru.
- Mission 9 fase 4: tell mode gerak = `Label` runtime (`MotionTell` di bawah
  `Player`, `AlertMark` "!" di rusa). Tidak ada aset/state baru; hilang otomatis
  saat mode berakhir.
- Mission 9 fase 4: `test_sneak.gd` membuktikan kecepatan nyata (velocity dan
  jarak tempuh di frame fisika dengan `Input.action_press`), bukan cuma config.
- Mission 9 feedback pemain: getaran pohon hanya saat menebang (dulu ikut
  bergetar hanya karena berdiri dekat), menu Jeda punya tombol, daftar
  profisiensi pindah ke tab tas, dan art yang masih kosong diberi label nama
  slot. Panduan tombol lengkap: `docs/editable/PANDUAN_INPUT.md`.

- Mission 10: sistem massa (`BodyProfile`) dan startle rusa disetujui owner;
  rusa kini badan padat (`blocks_player = true`) dan menerima knockback 0.6
  (sebelumnya pemain bisa menembusnya).
- Mission 10: satu action penempatan base (`base_place` B) dengan preview pagar;
  tidak ada action kedua.
- Mission 10: panel stasiun (Meja Kerja / Api Unggun) dibuka lewat `E`
  (`StationPanel`), bukan tombol UI baru.
- Mission 10: item di tangan (held item) hanya state visual, tanpa aturan baru.
- Mission 10: pause memakai back-stack (Esc menutup lapisan paling atas dulu).
- Mission 10: batas waktu tes 120 s per perintah, dijalankan hanya lewat
  `tools/run_tests.ps1`; `-Slow` untuk tes berat.
- Mission 11: pemain yang menempel ke fauna tidak menyeretnya; fauna non-chasing
  berhenti mendorong badannya sendiri saat kontak (contact-stop), tanpa
  `motion_mode` baru atau penulisan posisi dari luar.
- Mission 12: SpriteFrames-first — `.tres` per slot di atas strip/PNG, nama
  animasi `<state>`/`<state>_<dir>`, fps/loop milik resource (config hanya untuk
  strip), satu `AnimatedSprite2D` berbagi resource tanpa salinan.
- Mission 13: sapuan fajar dari `dawn_side`, senja dari sisi seberang;
  CanvasModulate memakai endpoint lebih terang + overlay multiply pada bagian
  yang belum dilewati; `sweep_enabled=false` tetap fade seragam lama.
- Mission 13 (dunia): dua mode dunia disetujui owner — FORMULA (default, pulau
  lama tidak berubah) dan AUTHORED (scene `world.tscn`). Zona AUTHORED berupa
  polygon `ZoneArea` dengan prioritas, bukan rumus `IslandZones`; angka FORMULA
  tetap Jadi default `WorldConfig.mode`. Fallback ke FORMULA = true.

## 9. Commands & upkeep

### Commands

`GODOT` below is `D:\Programming\Gamedev\Godot_v4.7.2-stable_win64_console.exe`.

```text
# Unit tests (GUT)
GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit

# Unit + integration tests (GUT)
GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit,res://tests/integration -gexit

# One test file
GODOT --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/<file>.gd -gexit

# Boot the main practice scene for 120 frames
GODOT --headless --path . --quit-after 120 res://scenes/practice/practice1.tscn

# Boot the island (second integration scene, not the main scene)
GODOT --headless --path . --quit-after 120 res://src/levels/island/island.tscn
```

### Upkeep

When adding a feature, add or extend a GUT test in `tests/unit/` and update every
doc in the allowed-edit list. Only these files are editable by agents:

- `docs/editable/AI_CONTEXT.md` (this handoff: state, contracts, build order)
- `docs/editable/architecture.md` (module table, dependency direction, gaps)
- `docs/editable/PANDUAN_MODUL.md` (how to use the module, practice wiring tree)
- `docs/editable/MVP_CHECKLIST.md` (check items only after code + runtime/test verification)

`docs/noneditable/` (the spec and work list) is input only — never edit it.

---

## 10. Working agreements

- Do not rename or reshape existing public functions/signals just for style.
- Do not change `phase_changed` to carry `day`; add a new signal instead.
- Do not make modules count their own game time; read the clock.
- Do not put gameplay state in HUD; HUD is read-only.
- Do not hardcode spec durations/ratios in scripts; use `.tres` resources.
- Do not assume `EventBus`, `AudioManager`, or save/load exist.
- Keep `practice1.tscn` working; it is the main scene and must keep booting.
  `src/levels/island/island.tscn` is the second integration scene (not the
  main scene), so both must stay green.
- Only add `class_name` when it does not clash with an autoload singleton name.
- Post-MVP items (Island Wolf, Shadow Stalker, Snare Trap, Silk Bandage, NPCs
  Bima/Sari/Raka) stay out of scope until the MVP gate in §12 passes. Leave
  hooks, not implementations.
- Island Deer is MVP, not optional: Hide only comes from it.
- Auto-attack must not target NEUTRAL/PASSIVE entities until they are provoked.

---

## 11. Repo state

- Git: branch `main`, remote `origin https://github.com/Sndivrgwn/gimersia-2026.git`.
- Asset guide: `docs/editable/ASSET_GUIDE.md` digenerate oleh
  `tools/generate_guides.gd`. Cakupannya menyeluruh: slot registry (dunia/UI),
  ikon semua item (`assets/icons/items/<id>.png`), art item di tangan
  (`assets/held/<id>.png`), semua resep crafting, ringkasan cakupan file, dan
  visual yang dibuat runtime. Sumber daftarnya sama dengan gameplay:
  `ItemCatalog.ALL` dan `CraftingComponent.RECIPE_FILES`; item/resep baru muncul
  setelah didaftarkan di sana lalu generator dijalankan.
  `tools/check_assets.gd` juga mengecek cakupan/typo/duplikat/bentuk ikon item
  dan held item; `tests/unit/test_docs_in_sync.gd` menjaga panduan tetap sinkron.
  Jangan edit blok di antara penanda HTML dengan tangan.

## 12. Definition of done (MVP gate)

All of these must be true in one playable session:

1. Start game, control the character on the island.
2. Gather resources and return to camp.
3. Clock shows days and day/night ratios correctly.
4. Hunger, thirst, fatigue are visible and functional.
5. Wild animals threaten the player and can be fought.
6. Player survives the night Survival Timer.
7. Death shows Respawn / Main Menu.
8. Respawn returns to camp, drops items, applies limited debuffs.
9. Player reaches day 7 and triggers rescue.
10. Build is playable with no blocker bugs.

Full acceptance detail: `docs/editable/MVP_CHECKLIST.md` §15.

## 13. Keputusan dan pertanyaan terbuka

### Pertanyaan terbuka (riwayat)

Found while cross-checking spec V8. Confirm with the design owner; keep the
numbers in `.tres` so tuning stays cheap. Beberapa butir sudah selesai; lihat
"Keputusan yang sudah diambil" di bawah.

1. **Day-1 material bottleneck.** Zone 1 yields only 6 wood and 4 stone on Day 1.
   Campfire (4 wood + 3 stone) + Workbench (5 wood + 2 stone) needs 9 wood and
   5 stone, and trees need the Stone Axe, which needs the Workbench. Realistically
   the Workbench lands on Day 2 morning (after respawn) unless wood or stone is
   found elsewhere. Possibly intentional early pressure; verify in playtest.
2. **Hide may soft-lock the Signal Flare.** The Day-7 anti-softlock guarantees
   Boars (Bone) but not Deer (Hide). If all Deer are dead and the player holds
   fewer than 2 Hide, the Flare cannot be crafted. Consider extending the
   guarantee to Deer.
3. **Dawn of Day 7 is ambiguous.** The spec covers the flee/refill rule for dawns
   of Day 2-6 and uses "dawn of Day 7" for the 00:00 rescue moment. The dawn that
   starts Day 7 (after Night 6) is not clearly covered. Likely the same rule
   applies; confirm.
4. **Workbench dependency at the end.** The Flare is crafted at the Workbench. If
   it is destroyed late, the player must rebuild it (5 wood + 2 stone + 3 fiber)
   before crafting. Make sure Zone 1 materials or stock cover this.
5. **P1b assumptions implemented (confirm with design).** The dawn rule runs for
   days 2-7 (question 3 treated as "same rule"). The Deer guarantee flag
   `FaunaQuota.guarantee_deer_at_rescue` is **ON** in `island.tscn` (question 2
   resolved). Resident boars count toward the night maximum. Night spawner spawns
   one boar immediately at night start. The first ember-snuff hit on nights >= 5
   also removes fuel on top of the normal structure damage.
6. **P1c/P2 assumptions implemented (confirm with design).** Speed sprint XP uses
   real delta (spec gives "per second" without saying game time). Resourceful
   grants the extra item via `inventory.add_or_drop`. The Signal Flare **is**
   consumed at the Beacon (`src/entities/props/beacon/signal_beacon.gd`). The 3
   respawn tokens are a `DeathController` constant; `PlayerBaseStats.max_respawn_tokens`
   is still unused. "Master Chef" (+10 Campfire food/drink restore) **is applied**
   lewat `ProficiencyComponent.get_campfire_restore_bonus()` + jalur
   `InventoryComponent.item_used`. A manual swing that displaces the player
   by more than 200 px in one tick (debug teleport) is ignored for Speed XP.
   `practice1.tscn` is not wired for proficiency/death/endgame; `island.tscn` is.
7. **Mission 5 leftovers (no open code bugs).** Every Part A/B check passed, so no
   code bug is left unfixed. `ProficiencyHUD` **ada** (`src/ui/hud/proficiency/`)
   dan dipasang di `island.tscn`. Satu sisa nyata:
   `PlayerBaseStats.max_respawn_tokens` belum dipakai (item 6).

### Keputusan yang sudah diambil

- Deer guarantee **ON** (`FaunaQuota.guarantee_deer_at_rescue = true`).
- Signal Flare **dikonsumsi** saat Victory.
- Master Chef sederhana: bonus restore lewat campfire, tanpa hook konsumsi baru.
- Batu hanya dihabiskan pada percobaan ignition yang gagal.
- `small_tree` ada sebagai node resource tersendiri; starter camp memakai
  hitungan di `island_builder.gd` (lihat `test_mission7_trees.gd`).
- Aset: konvensi nama file di atas konfigurasi; tanpa art tampilan lama tetap.

- Mission 10: rusa dan babi sama-sama padat; tidak ada body yang mendorong body
  lain lewat kontak (semua `pushable_by_others = false`).
- Mission 10: STARTLE 0.9 s + ramp 0.5 s dipilih supaya serangan pertama tetap
  bisa mendarat tanpa membuat rusa terlalu mudah ditangkap.
- Mission 10: aturan spawn 60 px ditambahkan di samping aturan 600 px lama;
  fallback "paling jauh" tetap ada tetapi berhenti di luar ring base.
- Mission 10: audio hanya data + panduan; playback menunggu `AudioManager`.
- Mission 11: pemain yang menempel ke fauna tidak menyeretnya; fauna non-chasing
  berhenti mendorong badannya sendiri saat kontak (contact-stop di
  `FaunaBase._wander()`), tanpa mengubah `motion_mode`.
- Mission 12: SpriteFrames-first — `.tres` slot diutamakan di atas strip/PNG,
  nama animasi `<state>`/`<state>_<dir>`, fps/loop milik resource, satu
  `AnimatedSprite2D` berbagi resource yang sama.
- Mission 13: sapuan fajar dari `dawn_side` dan senja dari sisi seberang;
  CanvasModulate memakai endpoint yang lebih terang dan overlay multiply
  menggelapkan bagian yang belum dilewati; `sweep_enabled=false` = fade lama.

### Riwayat misi

Label misi dipakai bebas di dokumen lain; tabel ini peta label -> fitur.

| Label | Di dokumen | Yang dikerjakan |
| --- | --- | --- |
| P0 | §8 build order | Bersih-bersih fondasi: `set_time_scale(-1)`, tautan docs/README |
| P1a / P1b / P1c / P2 | §8 build order | Survival core; threat loop; proficiency; death + endgame |
| Mission 5 | §8 item 6 | Integrasi skala scene: harness `island.tscn`, S1-S5, soak 7 hari |
| Mission 6 | §8 (Mission 6) | Base dinamis (B), ring pagar, QTE api unggun, juice tempur |
| Mission 7 | §8 (Mission 7) | `small_tree`, hint, panel Peti, pause/settings/help, HUD malam & debuff, `SettingsService` |
| Mission 8 | architecture | Sistem aset (`Assets`/`VisualSlot`/`UiSkin`/registry), `StatusEffectsComponent` |
| Mission 9 (fase 1-3) | MVP §27 | Balance pass 2: raid event + cap, massa babi, api unggun COLD, freeze/proteksi, needs, regen HP |
| Mission 9 fase 4 | MVP §27, PANDUAN §25c | Jongkok Ctrl, rusa waspada, air sungai, `MotionTell` |
| Mission 9 lanjutan | MVP §28 | Getaran pohon berirama, isi menu Jeda, tab Profisiensi, `PlaceholderLabels`, `PANDUAN_INPUT` |
| Mission 9 fase 5 | MVP §27 (fase 5) | Sweep arah matahari — dikerjakan sebagai **Mission 13** |
| Mission 9 fase 6 | MVP §27 (fase 6) | SpriteFrames-first (**Mission 12**) + data audio (**Mission 10**) |
| Mission 10 (feedback) | MVP §26 | Channel feedback: toast, angka damage, arah serangan |
| Mission 10 (fisika + audio) | MVP §29, architecture | `BodyProfile`, `BodySeparation`, `SpawnClearance`, state rusa, registri audio 103 cue |
| Mission 10 lanjutan (MVP §30) | MVP §30 | Panel stasiun, minum di sungai, koreksi transisi sore/fajar, kunang-kunang, cahaya api |
| Mission 10 lanjutan (architecture) | architecture | Perbaikan atmosfer/transisi yang sama, ditambah pembersihan warning editor |
| Mission 11 | §8 item 8 | Anti-seret fauna (contact-stop) + `PhysicsTraceRecorder` (K) |
| Mission 12 | §4, ASSET_GUIDE | SpriteFrames-first: `.tres` per slot, rantai fallback animasi, `check_assets` validasi, panduan |
| Mission 13 (matahari) | §4, CONFIG_GUIDE | Sapuan fajar/senja (`SunConfig`/`SunSweep`/`SunSweepOverlay`) + `SunArc` di TimeHUD |
| Mission 12 (jam) | §4, MVP §32 | Jam dunia nyata: `GameClockFormat`, `hour_changed`, HUD/tombstone/victory berjam |
| Mission 13 (dunia) | §4, WORLD_BUILDING_GUIDE | Dua mode dunia (FORMULA/AUTHORED), `WorldRules`/`WorldSource`, validator W001-W017, overlay O, panduan membangun dunia |

## 14. Masih terbuka

- Pertanyaan "fajar Hari 7" untuk desain akhir (durasi/urutan banner).
- Ketergantungan Workbench untuk resep Signal Flare (belum final).
- Sign-off owner atas deviasi spec (mis. Dodge tanpa i-frame).
- `PlayerBaseStats.max_respawn_tokens` belum dipakai kode.
- Balance setelah playtest manual.
- `fx_slash`/`fx_dust` sudah punya slot tetapi belum ada node efek pemakainya.
- ~~Mission 9 fase 5 (sweep arah matahari)~~ **DONE** (Mission 13): `SunConfig`,
  `SunSweep`, `SunSweepOverlay`, `SunArc` — `test_sun_sweep.gd`.
- ~~SpriteFrames-first (Mission 9 fase 6)~~ **DONE** (Mission 12 blok asset):
  `assets.gd` SpriteFrames-first + `check_assets` — `test_assets_spriteframes.gd`.
  Data audio tetap belum punya playback.
- Tidur Tenda masih `skip_seconds` 45 dtk nyata (≈1,8 jam game); belum ada
  pilihan "tidur sampai pagi".
- Audio: playback, `AudioManager`, mixing, dan file `.ogg` belum ada; 19 cue
  berstatus `HOOK BELUM ADA` (lihat `AUDIO_GUIDE.md`).

## 15. Polish pass (Mission 9)

- Node baru di `island.tscn`: `AmbientLife`, `CameraFeel`, `LowHpVignette`,
  `OpeningSequence`, `CampArrow`, `DeathFX`, `VictoryFX`. Semua read-only.
- `ScreenFade` & `UiMotion` sengaja **tanpa** `class_name` (cache global tidak
  diperbarui headless) — dipakai lewat `const ... := preload(...)`.
- Efek visual no-op saat `DisplayServer.get_name() == "headless"`; fade memakai
  callback `Tween.finished`, bukan `await`.
- Prompt pembuka memakai `HintManager.show_text(..., priority: true)`/`skip_current()`
  — satu kanal hint dengan antrean prioritas, jadi hint gameplay tidak bisa memotong intro.
- `CampArrow` memakai anchor Control (pojok kanan-atas), bukan posisi piksel.
- `DeathFX` menghormati setelan "Guncangan layar": bila OFF, slow-mo + zoom
  kematian dilewati (tes: `test_death_slow_mo_respects_screenshake_setting`).
- `SettingsService` kunci baru `fullscreen` (DisplayServer runtime, bukan project.godot).
- Gamepad terdaftar di `InputSetup.ensure_actions()`.
- `FenceGeometry.first_blocking_segment` kini bertipe `-> Node2D`; sebelumnya
  tanpa tipe sehingga `test_fence.gd` gagal parse dan 9 tesnya tidak pernah jalan.

## 16. Feedback channel (Mission 10)

- `ToastHUD`, `DamageNumbers`, `HitDirection` di `island.tscn`, disambung oleh
  `island.gd::_wire_feedback_hud(player)`.
- `InventoryComponent` menambah sinyal `add_blocked(item, remaining)`; itu satu-
  satunya perubahan pada komponen gameplay (additive, tanpa ubah perilaku).
- `ToastHUD` mendengar `SceneTree.node_added` untuk campfire yang dibangun
  runtime; pesan low-fuel memakai meta `toast_low_fuel`.
- Kill memakai penanda `KO` (`DamageNumbers.KILL_TEXT`), bukan angka 0.
- Tes: `tests/unit/test_feedback_hud.gd` (10 tes: toast cap/dedupe/expire,
  wiring craft-cancel, wiring campfire fuel, angka damage, kill marker, busur arah).

## 17. Perbaikan panel stasiun, sungai, dan atmosfer (Mission 10 lanjutan)

- `ChestPanel` hanya menyambung peti: `_scan_chests()`/`_connect_chest()` memfilter
  `node is Chest`, dan `_sender_chest()` memilih peti terdekat. Sebelumnya semua
  node grup `camp_structure` (termasuk Campfire/Workbench yang sinyalnya
  `interaction_requested(station, interactor)`) disambung ke handler 1 argumen,
  sehingga log penuh `Method expected 1 argument(s), but called with 2`.
- `island.gd::_connect_station()` hanya menyambung struktur yang punya
  `request_station_panel()`, jadi sinyal peti tidak bocor ke `StationPanel`.
- `StationPanel.open()` memanggil `Player.set_input_locked(true)`; `close()` dan
  `_exit_tree()` membukanya lagi. Tidak memakai `SceneTree.paused`: jam, fauna,
  dan api unggun tetap berjalan, hanya input gerak pemain yang diabaikan.
  `CraftingComponent.tick()` juga berhenti membatalkan craft karena tombol gerak
  selama input dikunci (dulu craft langsung batal ketika panel masih bisa gerak).
- `RiverDrinkZone` (anak Player di `island.tscn`) memberi aksi minum di mana saja
  di `IslandZones.Zone.RIVER` atau maksimal 32 px dari tepinya, memakai efek dan
  cooldown yang sama dengan `RiverEdge` (`RiverEdge.apply_drink`). Node hanya ikut
  grup `interactable` saat berada di air/tepi, jadi interaksi di darat tidak
  terganggu.
- Transisi siang/sore/malam memakai sisa waktu fase: `DayNightVisual` menghitung
  progress lewat `DayLightCurve.transition_progress()` dan durasi 60 dtk
  (`day_night_visual_default.tres`). Untuk siklus 300 dtk, sore mulai di menit
  ke-4 dan malam tepat di menit ke-5; fajar mulai di menit ke-9 dan pagi tepat di
  menit ke-10. `SunOverlay` (CanvasLayer 1) menggambar gradien aditif dari arah
  matahari (`DayLightCurve.sun_direction`).
- `DayNightVisual._update_effects()`: kunang-kunang hanya menyala di `NIGHT`;
  partikel debu siang tampil di fase lain.
- `Campfire` mengatur `PointLight2D.energy` dari `DayNightVisual.get_world_darkness()`:
  0.12 saat siang, 1.0 saat malam, sehingga cahaya api tidak lagi terlihat seperti
  malam di siang hari.
- Warning editor dibersihkan: shadowing `name`/`show`/`offset`/`seed`/`sign`,
  parameter tak terpakai (`_wire_hud`, `notify_hit`), unreachable code di
  `_resolve_text()`, dan `get_meta("ui_motion_tween")` tanpa `has_meta()`.
  `IslandLayoutConfig.seed` diganti `layout_seed` (termasuk `.tres` dan tes).
- Tes baru: `test_day_light_curve.gd`, `test_river_drink_zone.gd`,
  `test_environment_light.gd`, `test_station_panel_craft.gd`.

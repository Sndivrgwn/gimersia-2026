# Architecture & Project Conventions

Godot **4.7.2**, GDScript, top-down 2D survival. The project follows **domain-driven, feature-packaged composition**: a system owns its data, logic, scene, and tests close together. Prefer composition over deep inheritance, and keep global state in autoloads only when it is genuinely global.

This document describes the code that exists **today**. Planned systems are marked as planned, not as implemented.

---

## 1. Runtime Entry Points and Autoloads

| Entry point | Path | Owner / purpose |
|---|---|---|
| Main scene | `res://scenes/practice/practice1.tscn` | Practice map used to wire the current modules together |
| `DayNightManager` autoload | `res://src/core/managers/day_night_manager.tscn` | Game clock, day/phase state, dusk, Night Watch, final dawn |
| `PhantomCameraManager` autoload | Phantom Camera addon (UID in `project.godot`) | Third-party camera manager |
| GUT | `addons/gut` (9.7.1) | Unit test runner; see §8 for the command line |

Not present yet: `EventBus`, `GameManager`, `AudioManager`, `SaveManager`, main menu, or a production level loader. Do not design new modules around them as if they already exist.

`project.godot` is the authority for autoload registration, Input Map actions, renderer, and project-wide settings. Module scripts must not rewrite project settings at runtime.

---

## 2. Actual Directory Layout

```text
gimersia-2026/
├── assets/                              # Raw/imported art, audio, fonts, shaders, textures
├── addons/
│   └── phantom_camera/                  # Third-party camera addon
├── docs/                                # Architecture, specs, MVP checklist, module guide
├── scenes/
│   └── practice/                        # Practice maps and practice-only helpers
│       ├── practice1.tscn
│       ├── safe_zone.gd
│       ├── something_move.gd
│       └── somethingMove.tscn
├── src/
│   ├── components/
│   │   ├── inventory/                   # 12-slot inventory + hotbar use
│   │   ├── needs/                       # Hunger/Thirst/Fatigue component
│   │   └── stats/                       # Reusable stat component + modifier value object
│   ├── core/
│   │   └── managers/                    # DayNightManager autoload scene + script
│   ├── data/
│   │   ├── configs/environment/         # Day/night tuning resources (.tres)
│   │   ├── configs/                     # needs_config.tres, inventory_config.tres
│   │   ├── items/                       # Item definitions (.tres per item)
│   │   ├── resources/environment/       # Day/night Resource definitions
│   │   ├── resources/items/             # ItemDefinition, ItemEffect, ItemStack, InventoryConfig, ItemCatalog
│   │   ├── resources/needs/             # NeedsConfig Resource definition
│   │   └── stats/                       # PlayerBaseStats definition
│   ├── entities/
│   │   ├── player/                      # Player scene + controller
│   │   └── props/                       # World props (ItemPickup)
│   ├── levels/
│   │   └── components/environment/      # Reusable level components (day/night visual)
│   ├── ui/
│   │   ├── hud/
│   │   │   ├── inventory/               # Hotbar HUD (5 slots)
│   │   │   ├── needs/                   # Needs HUD
│   │   │   ├── stats/                   # Player stat readout HUD
│   │   │   └── time/                    # Day/night HUD
│   │   └── panels/inventory/            # BagPanel + BagSlot (interactive bag UI)
│   └── utils/                           # Static helpers (InputSetup)
└── tests/
    ├── sandbox/                         # Manual stats sandbox
    └── unit/                            # GUT tests for stats, clock, needs
```

Empty placeholder folders such as `src/entities/enemies`, `src/entities/props`, `src/ui/menus`, and `src/ui/theme` indicate intended future areas, not implemented modules.

### Layout notes

- **Gameplay entities** live with their scene and controller in `src/entities/<entity>/`.
- **Reusable components** live in `src/components/<component>/`; they must not depend on a specific scene.
- **Level-specific reusable components** live in `src/levels/components/`; playable/practice maps currently live in `scenes/practice/` until a production level pipeline exists.
- **Tuning data** belongs in `src/data/configs/` as `.tres`; **data definitions** belong in `src/data/resources/` or `src/data/<domain>/`.
- **HUD** is read-only and lives under `src/ui/hud/`; it owns no gameplay state.
- **Tests** mirror domains under `tests/unit/`; manual debug scenes belong in `tests/sandbox/`.

---

## 3. Implemented Modules and Ownership

| Module | Files | Responsibility | Public contract | State |
|---|---|---|---|---|
| **DayNightManager** (GameClock) | `src/core/managers/day_night_manager.gd/.tscn` | Owns game time, current day, phase, phase durations, dusk, Night Watch, final dawn | Signals and getters listed in §6; `start()`, `advance()`, `skip_time()`, `set_night_watch()`, `set_time_scale()` | Implemented; runtime/tests not yet executed |
| **DayNightConfig / DayNightPeriod** | `src/data/resources/environment/day_night_config.gd`, `day_night_period.gd`; `.tres` in `src/data/configs/environment/` | Single source of cycle length, day ratios, max days | `cycle_duration`, `time_scale`, `max_days`, `periods`; duration/ratio getters | Implemented |
| **DayNightVisual / Config** | `src/levels/components/environment/day_night_visual.gd/.tscn`; `src/data/resources/environment/day_night_visual_config.gd`; visual `.tres` | World tint, dawn/dusk color transition, particles | `atmosphere_changed(atmosphere)`, `get_atmosphere()`, `get_atmosphere_name()`, `visual_config` | Implemented; depends on `DayNightManager` |
| **TimeHUD** | `src/ui/hud/time/time_hud.gd/.tscn` | Displays day, phase, remaining time, progress, night Survival label | No public API; listens to `time_updated` and `rescue_started` | Implemented; read-only |
| **NeedsHUD** | `src/ui/hud/needs/needs_hud.gd/.tscn` | Displays Hunger/Thirst/Fatigue bars with a warning color at tier <= LOW | No public API; listens to `value_changed` and `tier_changed`, finds `NeedsComponent` via the `player` group | Implemented; read-only, not visually verified |
| **StatsHUD** | `src/ui/hud/stats/stats_hud.gd/.tscn` | Readout of HP, move/sprint speed, attack, gather time, sprint drain and the three need tiers | No public API; listens to `stats_changed`, `hp_changed`, `tier_changed`; finds the player via the `player` group | Implemented; read-only, not visually verified |
| **StatsComponent / StatModifier** | `src/components/stats/stats_component.gd`, `stat_modifier.gd` | Derived stats, HP, modifier stacking | `add_modifier()`, `remove_modifier()`, stat getters, `heal()`, `set_hp()`, `hp_changed`, `stats_changed` | Implemented; tests passing |
| **NeedsComponent / NeedsConfig** | `src/components/needs/needs_component.gd`; `src/data/resources/needs/needs_config.gd`; `src/data/configs/needs_config.tres` | Owns Hunger/Thirst/Fatigue (0..100) and the Fatigue cap, clock-scaled drain, sleep-skip drain, walk drain / sprint drain + cap loss / idle regen, tier effects, ZERO HP loss | `get_value()`, `set_value()`, `add()`, `spend_fatigue()`, `get_tier()`, `get_fatigue_cap()`, `restore_fatigue_capacity()`, `tick(delta)`, `setup(clock, stats, player)`, `get_config()`; `value_changed(need, value)`, `tier_changed(need, tier)`, `fatigue_cap_changed(cap)` | Implemented; 27 tests passing |
| **InventoryComponent** | `src/components/inventory/inventory_component.gd` | Owns 12 bag slots (0-4 = hotbar) of `ItemStack`, stacking, item use, drop-on-full, and WEAPON/ARMOR equipment + TOOL ownership | `add_item() -> int`, `remove_item() -> bool` (atomic, item or id), `has_item()`, `count_of()`/`count_item()`, `get_slot()`/`get_slot_item()`/`get_slot_count()`, `is_full()`, `move_slot()`, `use_slot()`, `add_or_drop()`, `equip()`/`unequip()`/`has_tool()`/`get_equipped()`, `get_capacity()`, `get_hotbar_size()`, `clear()`, `setup()`; `slot_changed(index)`, `equipment_changed(slot)`, `inventory_changed()`; keys 1-5 use slots | Implemented; 23 tests passing |
| **ItemDefinition / ItemEffect / ItemStack / ItemCatalog / InventoryConfig** | `src/data/resources/items/`; `.tres` in `src/data/items/`, `src/data/configs/inventory_config.tres` | Item content, consumable effects, slot stacks and inventory tuning | `id`, `display_name`, `description`, `category`, `max_stack`, `icon`, `consume_effect`, `equipment_slot`, `weapon_damage/range`, `armor_damage_reduction/max_hp_bonus`; effect `hunger`/`thirst`/`fatigue`/`hp`/`regen_*`; `ItemCatalog.get_by_id()`; `InventoryConfig` bag_size/hotbar_size/pickup_delay/pickup_radius | Implemented; 23 `.tres` validated by tests (includes SPECIAL `cockpit_notes`). `ItemEffect.fatigue` is applied via `NeedsComponent.restore_fatigue_capacity()` (raises the Fatigue **cap** and fills the value), not as a plain Fatigue delta; the field keeps its name |
| **ItemPickup** | `src/entities/props/item_pickup.gd/.tscn` | Pickup Area2D that adds its item to a body in the `player` group | `item`, `count`, `config` exports; ignores overlaps during `pickup_delay`; keeps leftovers; frees itself at 0 | Implemented; partial pickup + delay tested |
| **HotbarHUD** | `src/ui/hud/inventory/hotbar_hud.gd/.tscn` | Read-only 5-slot hotbar: key number, display_name or icon, count | No public API beyond `refresh()`; listens to `slot_changed(index)` | Implemented; read-only, not visually verified |
| **BagPanel / BagSlot** | `src/ui/panels/inventory/bag_panel.gd/.tscn`, `bag_slot.gd/.tscn` | Interactive bag UI on its own `CanvasLayer` (layer 20): 12-slot grid with hotbar markers 1-5, read-only equipment column (Weapon / Tool ownership / Armor), Crafting placeholder tab. No pause; refreshes only from the three inventory signals | `is_open()`, `toggle_panel()`, `get_slots()`; drag-drop → `move_slot()`, right-click → `use_slot()`, tooltip from `ItemDefinition`/`ItemEffect` | Implemented; 17 tests; not visually verified |
| **PlayerBaseStats** | `src/data/stats/player_base_stats.gd` | Base stat numbers as a Resource | Exported base values | Implemented; no `.tres` instance yet |
| **Interactable / InteractorComponent / InteractionHUD** | `src/components/interaction/`, `src/ui/hud/interaction/`, `src/data/configs/interaction_config.tres` | Hold-E framework reused by gathering, looting, building and the beacon | `Interactable`: group `interactable`, virtual `get_prompt()`, `get_hold_time()`, `can_interact()`, `get_block_reason()`, `interact()`. `InteractorComponent`: 0.1 s scan, range from config, real-delta progress, re-press after completion; signals `target_changed`, `progress_changed`, `interaction_completed`, `interaction_blocked`, `interaction_cancelled`; `cancel()`, `get_stats()/get_inventory()/get_needs()` | Implemented; 13 tests |
| **ResourceNodeDefinition / ResourceNode** | `src/data/resources/gathering/`, `src/data/gathering/*.tres`, `src/entities/props/resource_node/` | Eight gatherable resources with tool gates, stats-scaled hold time, seeded yield, single Fatigue spend and day-based respawn | `id`, `display_name`, `item`, `yield_min/max`, `required_tool`, `gather_time`, `fatigue_cost`, `respawn_rule`; `ResourceNode` exports `definition`, `last_respawn_day`, `rng_seed`, `clock`; `gathered(definition, amount, interactor)`; `is_depleted()`, `setup_clock()` | Implemented; 14 tests |
| **EmergencySuitcase / RiverEdge** | `src/entities/props/suitcase/`, `src/entities/props/river_edge/` | One-time starter loot and river drinking | Suitcase: `interact()` grants 3 items once, `looted` signal, `is_looted()`. RiverEdge: +25 Thirst / -8 Hunger, 15 s real-second per-player cooldown, `advance_cooldowns()`, `get_cooldown_remaining()` | Implemented; tested |
| **IslandZones / IslandLayoutConfig / IslandBuilder** | `src/levels/island/island_zones.gd`, `island_builder.gd`, `src/data/resources/island/`, `src/data/configs/island_layout.tres` | Zone classification and deterministic island population | `IslandZones.zone_at()`, `zone_name()`, `zone_center()`; layout exports seed/spacing/keep-out/counts; `IslandBuilder.plan()` and `build()` spawn 139 `ResourceNode` + 16 `night_spawn_point` markers | Implemented; 17 tests |
| **island.tscn / GatherDebug** | `src/levels/island/island.tscn`, `island.gd`, `gather_debug.gd` | Minimum island composition and island-only debug keys (F2 tools, F3 zone teleport, F4 next morning) | Scene only; `GatherDebug.is_debug_enabled()` | Implemented; boots headless clean; not the main scene |
| **Player** | `src/entities/player/player.gd/.tscn` | Top-down movement and sprint using StatsComponent | `can_sprint`, `facing_direction`, `sprint_state_changed`, `stats` | Implemented; no combat yet (interaction lives in `InteractorComponent`) |
| **InputSetup** | `src/utils/input_setup.gd` | Input Map helper; most actions (`move_*`, `sprint`, `hotbar_1..5`, `debug_*`) live in `project.godot` `[input]` while `interact` and `debug_island_*` are registered at runtime; `ensure_actions()` only fills missing entries idempotently | `InputSetup.ensure_actions()`, `INTERACT`, `DEBUG_ISLAND_*` | Implemented. **Input rule:** gameplay components poll Input actions and never use `_unhandled_input` or raw keycodes; `BagPanel` is the only UI panel allowed `_unhandled_input`, and only for toggle/close (Tab/I, Esc) |
| **SafeZone** | `scenes/practice/safe_zone.gd`, inside `practice1.tscn` | Practice-only camera zoom and movement slow modifier | `phantom_camera`, zoom/slow exports | Practice only; not production camp logic |
| **Tests / sandbox** | `tests/unit/`, `tests/sandbox/` | Unit tests and manual stats sandbox | GUT tests; sandbox scene | Written; run with GUT 9.7.1 |
| **StructureDefinition / CampStructure / BlueprintSlot** | `src/data/resources/camp/structure_definition.gd`, `src/data/camp/*.tres`, `src/entities/camp/camp_structure.gd`, `blueprint_slot.gd/.tscn`, `tools/generate_structures.gd` | Structure data, HP/damage/repair base class, and hold-E blueprint construction | `StructureDefinition`: `id`, `display_name`, `scene`, `max_hp`, `build_cost`, `build_time`, `aggro_priority`, `repair_cost`, `repair_hp`, `slot_position`, `format_amounts()`. `CampStructure` (group `camp_structure`): `take_damage()`, `repair()`, `is_damaged()`, `get_aggro_priority()`, `get_hp_bar()`, `apply_definition()`; signals `damaged`, `repaired`, `destroyed`, `hp_changed`. `BlueprintSlot` (extends `Interactable`): `get_structure()`, `is_built()`, `get_placeholder()`, `built(structure)` | Implemented; 13 tests; slots not placed in `island.tscn` yet |
| **Campfire / CampfireConfig / Workbench** | `src/entities/camp/campfire/`, `src/entities/camp/workbench/`, `src/data/resources/camp/campfire_config.gd` | Fuel/light/rest Campfire and always-on Workbench, both in group `crafting_station` | `Campfire`: `tick(delta)`, `is_lit()`, `get_fuel()`, `set_fuel()`, `get_light_radius()`, `get_dazzle_radius()`, `can_refuel()`, `get_refuel_block_reason()`, `refuel()`, `is_full()`, `get_light()`; signals `fuel_changed`, `lit_changed(is_lit)`, `fuel_depleted`. `CampfireRefuel` child interactable (hold 0.5 s). `Workbench`: `station_type`, `is_station_active()` | Implemented; 19 campfire tests |
| **RepairComponent** | `src/components/camp/repair_component.gd`; `InteractionHUD` extension | Hold-R repair of the nearest damaged structure | `tick(delta)`, `get_target()`, `get_progress_ratio()`, `get_target_prompt()`, `get_block_reason()`, `repair_range`, `hold_time`; signals `progress_changed`, `repair_completed`, `repair_blocked(structure, reason)`, `target_changed` | Implemented; 11 tests |
| **RecipeDefinition / ItemAmount / CraftingComponent** | `src/data/resources/crafting/recipe_definition.gd`, `src/data/resources/items/item_amount.gd`, `src/data/recipes/*.tres`, `src/components/crafting/crafting_component.gd`, `tools/generate_recipes.gd` | Recipe data and player crafting logic (no UI, no station scenes yet) | `RecipeDefinition`: `id`, `display_name`, `result`, `result_count`, `ingredients: Array[ItemAmount]`, `station` {HAND, WORKBENCH, CAMPFIRE}, `craft_time`, `get_station_name()`, `get_station_block_reason()`. `CraftingComponent`: `get_stations_in_range()`, `get_available_recipes()`, `get_locked_recipes()`, `get_all_recipes()`, `can_craft()`, `get_block_reason()`, `has_ingredients()`, `count_available()`, `start_craft()`, `cancel_craft()`, `tick(delta)`, `get_progress_ratio()`, `is_crafting()`; signals `craft_started`, `craft_progress`, `craft_completed`, `craft_cancelled(recipe, reason)`, `crafted(recipe, count)` | Implemented; 21 tests; not wired into a scene yet |

---

## 4. Dependency Direction

```text
InputSetup ──> Player ──> StatsComponent ──> PlayerBaseStats
                                      └──> StatModifier

NeedsComponent ──> NeedsConfig
       ├── add_modifier()/remove_modifier() ──> StatsComponent
       ├── get_time_scale()/is_night() ───────> DayNightManager
       └── time_skipped(seconds) ─────────────> DayNightManager

InventoryComponent ──> ItemDefinition ──> ItemEffect
       ├── add()/restore_fatigue_capacity() ──> NeedsComponent
       └── heal()/set_hp() ───────────────────> StatsComponent

ItemPickup ──> InventoryComponent
HotbarHUD ──> InventoryComponent (read-only)
BagPanel ──> InventoryComponent (move_slot()/use_slot(); refresh from signals)
practice1.tscn Pickups (ItemPickup instances) ──> Player/InventoryComponent

Interactable ◄── InteractorComponent ──> InventoryComponent/NeedsComponent/StatsComponent
InteractionHUD ──> InteractorComponent (read-only)
ResourceNode ──> ResourceNodeDefinition ──> ItemDefinition
            ├── add_or_drop() ─────────> InventoryComponent
            ├── spend_fatigue() ───────> NeedsComponent
            ├── get_gather_time_factor() ──> StatsComponent
            └── day_started(day) ──────> DayNightManager

CraftingComponent ──> RecipeDefinition ──> ItemAmount ──> ItemDefinition
            ├── group "crafting_station" (station_type, is_station_active())
            ├── remove_item()/unequip()/equip()/add_or_drop() ──> InventoryComponent
            └── get_craft_time_factor() ──> StatsComponent

BlueprintSlot ──> StructureDefinition ──> ItemAmount
            ├── has_item()/remove_item() ──> InventoryComponent
            ├── get_craft_time_factor() ──> StatsComponent
            └── instantiates scene ──> CampStructure

CampFire / Workbench ──> CampStructure (base)
            ├── Campfire: is_night()/get_time_scale() ──> DayNightManager
            ├── Campfire: set_idle_regen_override()/clear_...() ──> NeedsComponent
            └── group "crafting_station" ──> CraftingComponent

RepairComponent ──> group "camp_structure" ──> CampStructure
            ├── remove_item() ──> InventoryComponent
            └── repair() ──> CampStructure
InteractionHUD ──> RepairComponent (read-only, additive panel)
EmergencySuitcase / RiverEdge ──> InventoryComponent / NeedsComponent

IslandBuilder ──> IslandLayoutConfig
            ├── zone_at() ─────────────> IslandZones
            └── spawns ───────────────> ResourceNode + Marker2D (night_spawn_point)
GatherDebug ──> InventoryComponent (tools), DayNightManager (skip_time), IslandZones

DayNightManager ──> DayNightConfig ──> DayNightPeriod
        ▲
        ├── DayNightVisual ──> DayNightVisualConfig
        └── TimeHUD

practice1.tscn
  ├── Player + StatsComponent
  ├── Camera2D + PhantomCamera2D
  ├── SafeZone ──> Player.stats (modifier source `safe_zone`)
  ├── DayNightVisual
  └── TimeHUD
```

Rules:

1. **Resources do not know scenes.** `DayNightConfig`, `DayNightPeriod`, `PlayerBaseStats`, and visual configs are data only.
2. **Components do not reach into scene trees.** `StatsComponent` exposes values and signals; `Player` composes it.
3. **Readers depend on the manager, not the reverse.** `DayNightVisual` and `TimeHUD` read `DayNightManager`; the manager never references HUD, visual, enemy, or player nodes.
4. **No duplicate clocks.** Other systems use `time_updated`, `time_skipped`, `get_remaining_seconds()`, or `get_time_scale()` instead of counting their own delta.
5. **Stats are changed through modifiers.** Do not write `PlayerBaseStats` fields or override computed speeds at runtime. Use a stable `source_id` so effects can be removed together.
6. **Signal up, call down.** A parent may call a child method (`player.stats.set_hp(...)`); a child reports upward with signals (`hp_changed`, `stats_changed`, `sprint_state_changed`).
7. **No EventBus yet.** Direct signals and getters are sufficient for the current scope. Introduce an EventBus only when a genuinely distant cross-system event needs it.
8. **Autoload without `class_name`.** `DayNightManager` has no `class_name` to avoid clashing with the singleton name. Access it with `get_node_or_null("/root/DayNightManager")` or a string-based reference. Unit tests preload the script directly instead of relying on the autoload.

---

## 5. Runtime Composition (practice1)

`practice1.tscn` is the current reference wiring:

1. `DayNightManager` autoload starts first because `auto_start = true`; it begins Day 1 daytime and emits `started`/`day_started(1)`.
2. `Player` is instanced in the `player` group. Its `StatsComponent` child supplies move/sprint speed.
3. `SafeZone` listens for `body_entered`/`body_exited`; while the player is inside, it adds a `move_speed` percent modifier with source id `safe_zone` and zooms the Phantom Camera.
4. `DayNightVisual` starts from the manager's current phase, applies a `CanvasModulate` tint, and transitions through morning/evening on `phase_changed`.
5. `TimeHUD` is a separate `CanvasLayer`; it reads the manager and displays day/phase/remaining time/progress. Its Survival label mirrors the night remaining time.
6. No node owns a second timer. All time comes from `DayNightManager`.

Ordering caveat: `SafeZone` relies on the player being in the `player` group; the group is set on the `Player` instance in `practice1.tscn`, not inside the base `player.tscn`.

**Needs:** `NeedsComponent` is a child of `Player` inside `player.tscn`, next to `StatsComponent`; it resolves its stats node and the `/root/DayNightManager` autoload itself. `NeedsHUD` is a second `CanvasLayer` in `practice1.tscn` that finds the component through the `player` group and never writes need values.

**Inventory:** `InventoryComponent` is added to the `Player` **instance** inside `practice1.tscn`, not to `player.tscn`, so the sandbox scene and tests keep using keys 1-4 for proficiency. It resolves `NeedsComponent`/`StatsComponent` from its parent. `HotbarHUD` reads it through the `player` group. Four `ItemPickup` nodes sit in a practice-only `DemoPickups` node (wood, stone, berry, raw meat) so the map can test pickup and eating; practice debug keys stay F1/X/C/V/B/M and do not overlap with hotbar keys 1-5. `BagPanel` (action `inventory_toggle`: Tab/I) adds the bag UI and drag-and-drop, using the same signals, so `HotbarHUD` and the panel stay in sync. `interact` (E) and crafting do not exist yet.

---

### 5.1 Island Composition (`island.tscn`)

`src/levels/island/island.tscn` is the minimum production map (not the main
scene; `practice1.tscn` stays `run/main_scene`):

```text
Island (island.gd: start facing north)
├── Ground (tinted Polygon2D per zone)
├── Coastline (4 static walls at ±2450)
├── Wreckage (0,-185) · Suitcase (-48,40) · Beacon placeholder (0,2100)
├── RiverEdges (9 RiverEdge, x=-950, y -1400..1400)
├── Player (group "player", (0,64)) + InventoryComponent + InteractorComponent
├── Camera2D / PhantomCameraHost / PhantomCamera2D (follow Player)
├── IslandBuilder (island_layout.tres) → ResourceNode + night markers
├── DayNightVisual + TimeHUD + NeedsHUD + StatsHUD + HotbarHUD + InteractionHUD + BagPanel
└── GatherDebug (F2 tools · F3 zone teleport · F4 next morning)
```

The clock is not started by the scene: the `DayNightManager` autoload already
`auto_start`s, exactly like `practice1.tscn`. The beacon is a placeholder with
no Victory logic, and the 16 `night_spawn_point` markers are read by nothing yet.

---

## 6. Time and State Contracts

### 6.1 Clock state

- Game time is measured in **seconds** of gameplay time.
- `current_day` starts at `1` and is capped by `DayNightConfig.max_days` (7 for MVP).
- `current_phase` is `DayNightManager.Phase.DAY` or `.NIGHT`.
- Phase durations come only from `DayNightConfig`; the manager does not hardcode 300/240/180.
- The spec target is a 600-second cycle: 300/300, 240/360, 180/420, 4200 seconds total. The shipped `day_night_default.tres` currently has `cycle_duration = 55.0` (see §9).

### 6.2 Signal order

Day start (including night → day):

```text
night_ended(previous_day)      # only if the previous phase was NIGHT
day_changed(new_day)           # only when announce_change is true
day_started(new_day)
phase_changed(Phase.DAY)
time_updated(day, DAY, remaining)
```

Night start:

```text
dusk_started(day)              # once per day, when remaining <= 15 s
night_started(day)
phase_changed(Phase.NIGHT)
time_updated(day, NIGHT, remaining)
```

Final dawn:

```text
night_ended(final_day)
time_updated(final_day, NIGHT, 0)   # forced
time_scale_changed(0.0)
rescue_started
```

`time_updated` is normally emitted once per displayed second. `started` is emitted by `start()` after the Day 1 setup.

### 6.3 Time scaling and Night Watch

- `get_time_scale()` returns:
  - `0.0` after final dawn (`rescue_triggered`);
  - `2.0 × base` while Night Watch is active;
  - the runtime override if set, otherwise `DayNightConfig.time_scale`.
- `set_night_watch(true)` only succeeds at night and before final dawn.
- Dawn/final dawn automatically deactivates Night Watch.
- `skip_time(seconds)` advances **raw game seconds** without the Night Watch multiplier. `time_skipped` reports the seconds that actually advanced, capped at final dawn.
- `advance(delta)` is the manual scaled tick used by tests and tools; it is not a second clock.

### 6.4 Final dawn

At 00:00 on the final night:

- `rescue_triggered = true`, `is_running = false`;
- phase remains `NIGHT`, day remains 7, remaining time is 0;
- `get_time_scale()` is 0;
- `advance()` and `skip_time()` are no-ops;
- `rescue_started` is the canonical “final dawn reached” signal. No duplicate `final_dawn_reached` signal exists.

### 6.5 Public read contract

| Need | Use |
|---|---|
| Current day / max days | `current_day`, `get_current_day()`, `get_max_days()` |
| Phase | `current_phase`, `get_phase()`, `is_day()`, `is_night()`, `get_phase_name()` |
| Phase duration / elapsed / progress | `get_phase_duration()`, `get_phase_elapsed()`, `get_phase_progress()` |
| Remaining time | `get_remaining_seconds()`, `get_remaining_text()` |
| Total elapsed game time | `get_total_elapsed_seconds()` |
| Day/night duration for a day | `get_day_duration(day)`, `get_night_duration(day)` |
| Time multiplier | `get_time_scale()` |
| Night Watch state | `is_night_watch_active()` |
| Active configuration | `get_config()` |

---

## 7. Configuration and Tuning Data

| Resource | Path | Current values / purpose |
|---|---|---|
| `DayNightConfig` | `src/data/configs/environment/day_night_default.tres` | **`cycle_duration = 600.0`** (script default; the `.tres` no longer overrides it), 7 days, periods 1–3 (0.5), 4–5 (0.4), 6–7 (0.3) |
| `NeedsConfig` | `src/data/configs/needs_config.tres`, numbers in `src/data/resources/needs/needs_config.gd` | Drain rates (hunger/thirst/walk/sprint), `fatigue_idle_regen`, `fatigue_sprint_cap_drain`, `fatigue_meal_cap_restore`, `sleep_fatigue_cap_restore`, thresholds, tier modifiers, ZERO HP loss, sleep clamp; the `.tres` overrides nothing |
| Debug fast config | `src/data/configs/environment/day_night_debug_fast.tres` | `cycle_duration = 60.0`; attached to the autoload scene as `debug_config`, but `use_debug_config = false` |
| `DayNightVisualConfig` | `src/data/configs/environment/day_night_visual_default.tres` | Default colors, light intensity, 30 s transition, particles |
| `PlayerBaseStats` | `src/data/stats/player_base_stats.gd` | Base HP/speed/combat/survival numbers; no `.tres` instance yet |
| `StructureDefinition` | `src/data/camp/*.tres` (generated), numbers in `src/data/resources/camp/structure_definition.gd` docs | Campfire 250 HP / 4 wood + 3 stone + 2 fiber / 2.5 s / aggro 0 / repair 1 wood + 1 stone -> 80; Workbench 180 / 5 wood + 2 stone + 3 fiber / 3.0 s / 1 / 1 wood + 1 fiber -> 70; Chest 200 / 6 wood + 2 fiber / 2.5 s / 1 / 2 wood -> 80; Tent 120 / 6 wood + 6 fiber + 2 bamboo / 4.0 s / 2 / 1 wood + 2 fiber -> 60 |
| `CampfireConfig` | `src/data/resources/camp/campfire_config.gd` | 240 s start, 600 max, 0.25/s day, 1.0/s night, full at 580, refuel 2 wood -> +180 s with a 0.5 s hold, light 240/80 px, dazzle 180 px, rest 120 px at 5/s checked every 0.25 s. No `.tres` instance; script defaults are used |

Guidelines:

- Keep cycle length and ratios in `DayNightConfig`, not in gameplay scripts.
- Add a new `DayNightPeriod` entry when a day range needs a different ratio. The first matching period wins.
- Keep base stats in `PlayerBaseStats`; put derived formulas and modifier application in `StatsComponent`.
- Prefer creating `.tres` variants for tuning instead of changing code constants.

---

## 8. Testing and Verification

- Unit tests use **GUT 9.x** and live in `tests/unit/`.
- `tests/unit/test_stats_component.gd` covers base stats, proficiency bonuses, modifiers, HP clamps, and dodge caps.
- `tests/unit/test_game_clock.gd` covers durations, carry-over, dusk, Night Watch, `skip_time()`, final dawn, signal order, and remaining-time text.
- `tests/unit/test_inventory_component.gd` covers 12-slot capacity, stacking order (top up first, then leftmost empty, never reorder), `max_stack` 1 and 20, full-inventory leftover, atomic `remove_item`, `has_item`/`count_of` across stacks, `move_slot` swap/merge, exact consume deltas for all seven consumables (including consume-when-full and rejecting non-consumables), armor modifier add/remove/replace, weapon replacement, TOOL ownership, `add_or_drop` spawning an `ItemPickup`, partial pickup plus `pickup_delay`, once-per-change signals, hotbar actions 1-5, `HotbarHUD` following `slot_changed(index)`, and `tests/unit/test_bag_panel.gd` covering the Tab/I toggle in `project.godot` `[input]`, the 12-slot grid with hotbar markers, tooltips, drag-drop swap/merge, right-click use, no pause, and the read-only equipment column.
- `tests/unit/test_item_definitions.gd` loads every `.tres` in `src/data/items/` and validates unique ids, `max_stack >= 1`, display names, categories, equipment slots, weapon/armor numbers and consume effects against the spec.
- `tests/unit/test_needs_component.gd` covers day/night drain, `time_scale` 0 and 2, `time_skipped` plus the 1.0 sleep clamp, 0..100 clamping, tier changes at exactly 25 and 0 (asserted through `StatsComponent` getters), ZERO HP loss stacking, sprint drain through `get_sprint_fatigue_drain_factor()`, `can_sprint` locking, walk drain without cap loss, idle regeneration up to the cap, sprint lowering the Fatigue cap, `restore_fatigue_capacity()`, sleep raising the cap and refilling Fatigue, and one signal per change. It drives `tick()` with a stub clock and stub player (the stub has a `velocity` field, so moving vs standing still is testable).
- The clock test creates its own `DayNightConfig` with `cycle_duration = 600.0`, `auto_start = false`, disables `_process`, and calls `start()`/`advance()` explicitly. It does not depend on the autoload’s current `.tres`.
- `tests/sandbox/stats_sandbox.tscn` is a manual scene for stat debugging; it is not an automated test.
- **GUT 9.7.1 is installed in `addons/gut`** (`plugin.cfg` reports the version). The suite runs through the GUT command line and passes; the clock test count is tracked in the handoff doc (`docs/editable/AI_CONTEXT.md` §3).

Static review is not a substitute for running Godot/GUT. See `docs/editable/PANDUAN_MODUL.md` for commands and the current verification limits.

---

## 9. Known Gaps and Technical Debt

These are deliberate notes so future modules do not build on incorrect assumptions.

1. **Default cycle is 600 s (resolved).** `day_night_config.gd` defaults `cycle_duration` to `600.0` and `day_night_default.tres` no longer overrides it, so the live autoload matches the 1.D spec (300/300, 240/360, 180/420; 4200 s total). The accelerated 60 s config remains available through `debug_config`.
2. **`_process` keeps multi-phase overflow (resolved).** `_process` uses a carry-over `while` loop: overflow past a phase boundary is passed on until it fits, so a long frame or a high `time_scale` still lands on the correct phase. `advance()`/`skip_time()` keep the equivalent guarantee in `_advance_game_seconds()`.
3. **`set_time_scale(-1)` resets to config (resolved).** Only negatives clear the override and fall back to `DayNightConfig.time_scale`; `0.0` stays a real override and is what the final-dawn freeze uses.
4. **`phase_changed(phase)` has no `day` argument.** Adding one would break the existing one-argument listener in `day_night_visual.gd`. Use `day_started`/`night_started`/`day_changed`, or add a separate signal if the day is required.
5. **`get_time_scale()` changed at final dawn.** It now returns 0 while `rescue_triggered`; this is required for the final-dawn freeze but is a semantic change to an existing getter. No other module currently calls it, but future survival systems must use it consistently.
6. **No combat, enemies, Tent sleep/Night Watch, Chest storage, crafting UI, death/respawn, menus, or audio yet.** Do not assume those APIs exist. `NeedsComponent`/`NeedsHUD`, `InventoryComponent`/`HotbarHUD`, all item data, drops and equipment slots exist (see §3), and so does gathering: the `Interactable`/`InteractorComponent` framework, 8 `ResourceNodeDefinition` .tres, `ResourceNode`, `island.tscn`, and the suitcase/river edges are implemented. Crafting logic (13 recipes + `CraftingComponent`), structure data/scenes (`CampStructure`, `BlueprintSlot`, `Campfire`, `Workbench`) and hold-R repair exist and are tested, and a lit Campfire gives the +5/s rest regen. What is still missing: placing camp slots/components in `island.tscn`, the Chest and Tent scenes, the Crafting tab UI, and drop-on-death. The MVP checklist tracks them.
7. **Progression is data-only.** `StatsComponent` accepts proficiency levels, but there is no XP gain, level-up flow, or death debuff implementation.
8. **`SafeZone` is practice-only.** It is a useful reference for modifier-based effects, not a production camp system.
9. **No `EventBus`.** The generic “decouple with EventBus” advice remains a future option, not current architecture.
10. **Runtime verification is limited.** Godot 4.7.2 and GUT 9.7.1 are available: the unit suite passes, and **both** `practice1.tscn` (main scene) and `src/levels/island/island.tscn` boot headless for 120 frames without errors. Playtest, balancing and export are still unverified.

---

## 10. Naming and Code Conventions

| Item | Convention | Example |
|---|---|---|
| Folders & files | `snake_case` | `day_night_manager.gd`, `time_hud.tscn` |
| Classes / nodes | `PascalCase` | `StatsComponent`, `Player`, `DayNightVisual` |
| Variables & functions | `snake_case` | `current_day`, `get_remaining_text()` |
| Private members | `_snake_case` | `_active_config`, `_emit_dusk_if_due()` |
| Constants & enums | `SCREAMING_SNAKE_CASE` / `PascalCase` enum | `DUSK_WARNING_SECONDS`, `Phase.DAY` |
| Signals | `snake_case`, past tense | `day_started`, `time_skipped` |
| Modifier source ids | `StringName`, stable and namespaced | `&"safe_zone"`, `&"lapar"` |

Additional project rules:

- Identifiers are English; comments may be Indonesian.
- Use static typing consistently for new code (`func foo(value: float) -> void`).
- Do not rename or reshape existing public functions/signals just for style.
- Prefer adding new signals/getters over changing existing signal signatures.
- Keep tuning numbers in resources; keep formulas in components.
- New gameplay modules should be co-located under `src/<domain>/` and documented in `docs/editable/PANDUAN_MODUL.md`.

---

## 11. Documentation Map

| Document | Purpose |
|---|---|
| [`README.md`](../../README.md) | Project entry point and quick structure |
| [`docs/noneditable/spesifikasi_teknis_mekanisme_gameplay_V8.md`](../noneditable/spesifikasi_teknis_mekanisme_gameplay_V8.md) | Gameplay specification |
| [`docs/noneditable/MVP_dan_Daftar_Pekerjaan_RTRw_Studio.docx.md`](../noneditable/MVP_dan_Daftar_Pekerjaan_RTRw_Studio.docx.md) | MVP scope and division work list |
| [`docs/editable/MVP_CHECKLIST.md`](MVP_CHECKLIST.md) | Actionable MVP checklist and current status |
| [`docs/editable/PANDUAN_MODUL.md`](PANDUAN_MODUL.md) | How to use every implemented module |
| `docs/editable/architecture.md` (this file) | Structure, ownership, dependency rules, and technical debt |

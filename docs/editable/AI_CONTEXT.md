# AI Context — Continue the Gimersia 2026 MVP

> Purpose: handoff document for an AI agent (or a new developer) picking up this
> repository. Read this file first, then the linked docs. **Code is the source of
> truth** when a doc disagrees with it.

Last verified: 2026-11-19, Godot 4.7.2, GUT 9.7.1, 156/156 tests passing.
Spec cross-check: 2026-11-18 against spec V8. Gaps found are listed in §4
(missing systems), §7.1-7.8 (spec details), §8 (revised build order) and §13
(open design questions).

---

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
| Unit tests | see §9 | **156/156 passing**, 1160 asserts, ~1.5 s |
| Main scene boot | see §9 | `practice1.tscn` runs headless for 120 frames with **no errors** |
| Island boot | see §9 | `src/levels/island/island.tscn` runs headless for 120 frames with **no errors** |
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
| `DayNightVisual` / `DayNightVisualConfig` | `src/levels/components/environment/`, `src/data/resources/environment/` | World tint via one `CanvasModulate`, dawn/dusk transitions, particles |
| `TimeHUD` | `src/ui/hud/time/` | Read-only day/phase/remaining/progress/night-survival label |
| `StatsComponent` / `StatModifier` | `src/components/stats/` | Derived stats, proficiency, modifier stacking, HP, `hp_changed`, `stats_changed` |
| `NeedsComponent` / `NeedsConfig` | `src/components/needs/`, `src/data/resources/needs/` | Owns Hunger/Thirst/Fatigue (0..100) plus a Fatigue cap that sprint lowers and food/sleep restores. `get_value()`, `set_value()`, `add()`, `spend_fatigue()`, `get_tier()`, `get_fatigue_cap()`, `restore_fatigue_capacity()`, `tick(delta)`; signals `value_changed(need, value)`, `tier_changed(need, tier)`, `fatigue_cap_changed(cap)`. Tiers NORMAL/LOW/ZERO apply stats via `&"lapar"`/`&"haus"`/`&"lelah"`. Drains via `get_time_scale()`; no own clock |
| `NeedsHUD` | `src/ui/hud/needs/` | Read-only Hunger/Thirst/Fatigue bars, warning color at tier <= LOW |
| `StatsHUD` | `src/ui/hud/stats/` | Read-only readout of HP, speeds, attack, gather time, sprint drain, Fatigue value/cap and the three need tiers; makes ZERO-tier effects visible |
| `InventoryComponent` | `src/components/inventory/` | Owns 12 bag slots (0-4 = hotbar) of `ItemStack`, plus WEAPON/ARMOR equipment and TOOL ownership. `add_item() -> int` (leftover), atomic `remove_item() -> bool`, `has_item()`, `count_of()`, `get_slot()`/`get_slot_item()`/`get_slot_count()`, `is_full()`, `move_slot()`, `use_slot()`, `add_or_drop()`, `equip()`/`unequip()`/`has_tool()`, `get_capacity()`, `get_hotbar_size()`, `clear()`; `slot_changed(index)`, `equipment_changed(slot)`, `inventory_changed()`. Keys 1-5 use slots; effects via `NeedsComponent.add()` / `StatsComponent` / `restore_fatigue_capacity()`; armor modifiers use `&"equip_armor"` |
| `ItemDefinition` / `ItemEffect` / `ItemStack` / `ItemCatalog` / `InventoryConfig` | `src/data/resources/items/`, `.tres` in `src/data/items/` + `src/data/configs/inventory_config.tres` | Item content: `id`, `display_name`, `description`, `category` {RESOURCE, CONSUMABLE, WEAPON, TOOL, ARMOR, SPECIAL}, `max_stack`, `icon`, `consume_effect`, `equipment_slot`, `weapon_damage/range`, `armor_damage_reduction/max_hp_bonus`; effect `hunger`, `thirst`, `fatigue`, `hp`, `regen_hp_per_second`, `regen_duration`. `ItemCatalog.ALL` + 22 constants + `get_by_id()` |
| `ItemPickup` | `src/entities/props/item_pickup.gd/.tscn` | Area2D pickup: a body in the `player` group adds `item` x `count` through `InventoryComponent.add_item()`; leftover stays in the world, frees itself at 0. Ignores overlaps during `InventoryConfig.pickup_delay` and sizes its shape from `pickup_radius` |
| `HotbarHUD` | `src/ui/hud/inventory/` | Read-only 5-slot hotbar (key number, display_name or icon, count); binds to `slot_changed(index)` and finds `InventoryComponent` via the `player` group or `@export inventory` |
| `BagPanel` / `BagSlot` | `src/ui/panels/inventory/` | Interactive bag UI on its own `CanvasLayer` (layer 20): 12-slot grid with hotbar markers 1-5, a read-only equipment column (Weapon / Tool ownership / Armor) and a `Crafting` placeholder tab. Toggled by the `inventory_toggle` action (Tab or I) in `_unhandled_input`; Esc (`ui_cancel`) closes it but never opens it; it never pauses the game. Slots use `_get_drag_data`/`_can_drop_data`/`_drop_data` → `move_slot()`, right-click → `use_slot()`, hover tooltip from `ItemDefinition`/`ItemEffect`. Refreshes only from `slot_changed`, `equipment_changed`, `inventory_changed` |
| `Interactable` / `InteractorComponent` / `InteractionHUD` | `src/components/interaction/`, `src/ui/hud/interaction/`, `src/data/configs/interaction_config.tres` | Hold-E framework reused by gather/loot/build/beacon: `Interactable` (group `interactable`, virtual `get_prompt(interactor)`, `get_hold_time(interactor)`, `can_interact()`, `get_block_reason()`, `interact()`), `InteractorComponent` (scan 0.1 s, range 64 from config, progress uses real delta, release/lost target/out of range resets, must re-press after completion; signals `target_changed`, `progress_changed`, `interaction_completed`, `interaction_blocked`, `interaction_cancelled`; `cancel()`, `get_stats()/get_inventory()/get_needs()`), read-only prompt + progress bar + blocked-reason HUD | Implemented; 13 tests |
| `ResourceNodeDefinition` / `ResourceNode` | `src/data/resources/gathering/`, `src/data/gathering/*.tres`, `src/entities/props/resource_node/` | Eight definitions (twig, tree, small/big rock, fiber/berry bush, coconut palm, bamboo clump) with tool gates (`stone_axe`/`stone_pickaxe`), hold time = `gather_time` x `StatsComponent.get_gather_time_factor()`, seeded yield, `spend_fatigue()` once, DAILY / EVERY_OTHER_DAY / NEVER respawn through `DayNightManager.day_started(day)`, permanent removal after `last_respawn_day`; signal `gathered(definition, amount, interactor)` | Implemented; 14 tests |
| `EmergencySuitcase` / `RiverEdge` | `src/entities/props/suitcase/`, `src/entities/props/river_edge/` | Suitcase: hold 1.0 s, grants 1 herbal bandage + 1 boiled water + 1 cockpit notes once, then blocks forever. River edge: hold 1.5 s, +25 Thirst, -8 Hunger, 15 real-second cooldown per player | Implemented; tested |
| `cockpit_notes` item | `src/data/items/cockpit_notes.tres` | SPECIAL item "Catatan Kokpit", `max_stack` 1, registered in `ItemCatalog` | Implemented; tested |
| `IslandZones` / `IslandLayoutConfig` / `IslandBuilder` | `src/levels/island/island_zones.gd`, `island_builder.gd`, `src/data/resources/island/`, `src/data/configs/island_layout.tres` | Zone lookup in the order CAMP, SOUTH_BEACH, EAST_BEACH, WEST_CLIFFS, RIVER, FOREST, OUTSIDE; deterministic seeded rejection-sampled layout with spacing/keep-out rules; 139 resource nodes and 16 `night_spawn_point` markers | Implemented; 17 tests |
| `island.tscn` / `GatherDebug` | `src/levels/island/island.tscn`, `island.gd`, `gather_debug.gd` | Minimum map: tinted ground per zone, coastline static walls at ±2400, PlaneWreckage, suitcase, beacon placeholder (no logic), 9 river edges, full player/HUD wiring, builder node. `GatherDebug` (island only, off by default): F2 grants both tools, F3 teleports to the next zone, F4 skips to the next morning | Implemented; boots headless clean |
| `PlayerBaseStats` | `src/data/stats/player_base_stats.gd` | Base numbers (no `.tres` instance yet; script defaults are used) |
| `Player` | `src/entities/player/` | Top-down movement + sprint from `StatsComponent`; `can_sprint`, `facing_direction`, `sprint_state_changed` |
| `InputSetup` | `src/utils/input_setup.gd` | Input Map helper: most actions (`move_*`, `sprint`, `hotbar_1..5`, `debug_*`) are declared in `project.godot` `[input]`; `interact` (E) and `debug_island_*` (F2/F3/F4) are registered by `ensure_actions()`, which only fills gaps idempotently. Gameplay code polls `Input.is_action_just_pressed()`/`Input.get_vector()`, never `_unhandled_input` or raw keycodes |
| `SafeZone` | `scenes/practice/safe_zone.gd` | **Practice-only** camera zoom + speed modifier example |
| Tests / sandbox | `tests/unit/`, `tests/sandbox/` | GUT tests and a manual stats sandbox |

### What does NOT exist yet

Drop-on-death loot, crafting recipes/stations (the bag panel's Crafting tab is a
placeholder), camp structures + blueprint slots + repair (hold R), combat
(auto-attack + manual provocation trigger, dodge), enemy AI (Wild Boar **and
Island Deer**), daytime fauna quota, night spawner + camp-aggro logic (the 16
`night_spawn_point` markers exist, but nothing reads them yet), Proficiency XP /
passives / death debuff, death/respawn/loot bag, main/pause/death/victory UI,
audio, save system, `EventBus`, `GameManager`, `AudioManager`, the production
island map (only `practice1.tscn` and the placeholder `island.tscn` exist — no
production art, no level loader). Do not assume these APIs exist.

Note: `StatsComponent` has proficiency **levels** only (§6.2). XP,
`max_reached_level` and passive abilities are not implemented (see §7.6).

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
- The `player` group is set on the **instance** in `practice1.tscn`, not in
  `player.tscn`. New maps must add the instance to the group.
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
  the new cap. Campfire-adjacent +5/s is not implemented yet.

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
first five bag slots. 22 definitions exist (6 resources, 7 consumables, 3
special, 3 weapons, 2 tools, 1 armor); equipment slots WEAPON/ARMOR/TOOL are
implemented (TOOL = ownership set), and only Leather Vest changes stats.
- Sleep must clamp hunger/thirst to at least 1.0 (sleep cannot kill).
- Campfire idle at 120 px radius; camp radius = 180 px.

### Camp (4 fixed blueprints, all destroyed → blueprint slot again)

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
| Waterskin | +25 Thirst per sip, 3 charges, -5 Hunger; refill at river (hold E 1.5 s) |

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
   2. Inventory: 12 bag slots, hotbar 1-5, 3 equipment slots, `ItemDefinition`,
      pickup/drop, consumable effects (§7.1, §7.5).
   3. Resource nodes + hold-E gathering, tool gates, Fatigue cost, Zone 1 respawn
      limits (§7.5). **— DONE** (`Interactable`/`InteractorComponent` + 8
      `ResourceNodeDefinition` .tres, 14 tests).
   4. Minimum production map: Zone 1 plus enough of Zones 2/4/5/6 to reach every
      resource, wreckage, Emergency Suitcase, Beacon (§7.4, §7.7). Grow it
      incrementally; keep `practice1.tscn` working. **— MINIMUM DONE**
      (`src/levels/island/island.tscn`: zones, 139 nodes, 16 night markers,
      wreckage, suitcase, beacon placeholder, river edges; art and level loader
      still open).
   5. Crafting (hand / Workbench / Campfire), blueprint slots, structures with HP,
      repair (hold R), fuel, Tent sleep, Night Watch (§7.4, §7.5).
3. **P1b - threat loop.**
   1. Combat: auto-attack + manual provocation (click/Space), dodge, knockback,
      weapon slot stats (§7.2).
   2. Island Deer (only Hide source) + Wild Boar day/night AI + daytime quota
      (§7.3).
   3. Night spawner (16 markers, caps/intervals/multipliers), camp-aggro logic,
      Dazzled, Ember Snuff (§7.3, §7.4).
4. **P1c - Proficiency.** `ProficiencyComponent`: XP, carry-over,
   `max_reached_level`, passives, night XP bonus; hook XP from gather/craft/hit/
   kill/dodge/distance (§7.6). Must exist before the death debuff.
5. **P2 - death and endgame.** Death screen + token counter, loot bag, respawn,
   debuff (§7.6), Day-7 banner, Signal Flare, anti-softlock boars, Beacon,
   Victory (§7.8). A stub Victory (press E at Beacon) can be added earlier to
   test the full day-1 -> day-7 loop.
6. **P3 - polish.** Main menu, pause, audio, sprites/animations, balancing,
   playtest, export. Post-MVP items only after the MVP gate (§12).

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

## 9. Commands & upkeep

### Commands

Standard Godot/GUT CLI forms; the exact console executable name was not
re-verified, so adjust if a command fails.

```text
# Unit tests (GUT)
Godot_v4.7.2-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit

# Boot the main scene for 120 frames
Godot_v4.7.2-stable_win64_console.exe --headless --quit-after 120 res://scenes/practice/practice1.tscn
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
- Keep `practice1.tscn` working; it is the only integration scene today.
- Only add `class_name` when it does not clash with an autoload singleton name.
- Post-MVP items (Island Wolf, Shadow Stalker, Snare Trap, Silk Bandage, NPCs
  Bima/Sari/Raka) stay out of scope until the MVP gate in §12 passes. Leave
  hooks, not implementations.
- Island Deer is MVP, not optional: Hide only comes from it.
- Auto-attack must not target NEUTRAL/PASSIVE entities until they are provoked.

---

## 11. Repo state

- Git: branch `main`, remote `origin https://github.com/Sndivrgwn/gimersia-2026.git`.

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

## 13. Open design questions & balance flags

Found while cross-checking spec V8. Confirm with the design owner; keep the
numbers in `.tres` so tuning stays cheap.

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

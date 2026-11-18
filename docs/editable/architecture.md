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
│   │   └── stats/                       # Reusable stat component + modifier value object
│   ├── core/
│   │   └── managers/                    # DayNightManager autoload scene + script
│   ├── data/
│   │   ├── configs/environment/         # Day/night tuning resources (.tres)
│   │   ├── resources/environment/       # Day/night Resource definitions
│   │   └── stats/                       # PlayerBaseStats definition
│   ├── entities/
│   │   └── player/                      # Player scene + controller
│   ├── levels/
│   │   └── components/environment/      # Reusable level components (day/night visual)
│   ├── ui/
│   │   └── hud/time/                    # Day/night HUD
│   └── utils/                           # Static helpers (InputSetup)
└── tests/
    ├── sandbox/                         # Manual stats sandbox
    └── unit/                            # GUT tests for stats and clock
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
| **StatsComponent / StatModifier** | `src/components/stats/stats_component.gd`, `stat_modifier.gd` | Derived stats, HP, modifier stacking | `add_modifier()`, `remove_modifier()`, stat getters, `heal()`, `set_hp()`, `hp_changed`, `stats_changed` | Implemented; tests written, not run |
| **PlayerBaseStats** | `src/data/stats/player_base_stats.gd` | Base stat numbers as a Resource | Exported base values | Implemented; no `.tres` instance yet |
| **Player** | `src/entities/player/player.gd/.tscn` | Top-down movement and sprint using StatsComponent | `can_sprint`, `facing_direction`, `sprint_state_changed`, `stats` | Implemented; no combat/interaction yet |
| **InputSetup** | `src/utils/input_setup.gd` | Idempotent runtime registration of movement/sprint actions | `InputSetup.ensure_actions()` | Implemented |
| **SafeZone** | `scenes/practice/safe_zone.gd`, inside `practice1.tscn` | Practice-only camera zoom and movement slow modifier | `phantom_camera`, zoom/slow exports | Practice only; not production camp logic |
| **Tests / sandbox** | `tests/unit/`, `tests/sandbox/` | Unit tests and manual stats sandbox | GUT tests; sandbox scene | Written; run with GUT 9.7.1 |

---

## 4. Dependency Direction

```text
InputSetup ──> Player ──> StatsComponent ──> PlayerBaseStats
                                      └──> StatModifier

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
| `DayNightConfig` | `src/data/configs/environment/day_night_default.tres` | **`cycle_duration = 55.0`**, 7 days, periods 1–3 (0.5), 4–5 (0.4), 6–7 (0.3) |
| Debug fast config | `src/data/configs/environment/day_night_debug_fast.tres` | `cycle_duration = 60.0`; attached to the autoload scene as `debug_config`, but `use_debug_config = false` |
| `DayNightVisualConfig` | `src/data/configs/environment/day_night_visual_default.tres` | Default colors, light intensity, 30 s transition, particles |
| `PlayerBaseStats` | `src/data/stats/player_base_stats.gd` | Base HP/speed/combat/survival numbers; no `.tres` instance yet |

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
6. **No needs, combat, enemies, items, camp, crafting, death/respawn, menus, or audio yet.** Do not assume those APIs exist. The MVP checklist tracks them.
7. **Progression is data-only.** `StatsComponent` accepts proficiency levels, but there is no XP gain, level-up flow, or death debuff implementation.
8. **`SafeZone` is practice-only.** It is a useful reference for modifier-based effects, not a production camp system.
9. **No `EventBus`.** The generic “decouple with EventBus” advice remains a future option, not current architecture.
10. **Runtime verification is limited.** Godot 4.7.2 and GUT 9.7.1 are available: the unit suite passes and `practice1.tscn` boots headless for 120 frames without errors. Playtest, balancing and export are still unverified.

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

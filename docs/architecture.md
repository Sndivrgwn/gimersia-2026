# Architecture & Project Conventions

This project adheres to Godot 4 best practices: **domain-driven, feature-packaged composition** over pure type-based categorization.

---

## 1. Directory Breakdown

### `assets/`
Contains media and raw files. Assets used across multiple features or imported directly from external digital content creation (DCC) tools live here:
- **`audio/`**: Split into `music/` (streaming BGM) and `sfx/` (sound effects, voice).
- **`fonts/`**: Base font files (`.ttf`, `.otf`) and imported font variations.
- **`models/`**: 3D meshes, exports (`.blend`, `.gltf`), materials, and skeletal rigs.
- **`shaders/`**: Reusable `.gdshader` files (post-processing, outlines, water, dissolve).
- **`textures/`**: Subdivided by context (`characters/`, `environment/`, `ui/`, `vfx/`).

### `src/`
All game logic, scenes, and engine-native components live under `src/`:
- **`core/`**: Autoloads and global systems (e.g. `event_bus.gd`, `game_manager.gd`, `audio_manager.gd`, `save_manager.gd`). Keep these minimal to avoid tightly coupled spaghetti code.
- **`data/`**: Custom `Resource` definitions and instances (`.tres`), stats tables, item databases, and game configuration files.
- **`entities/`**: Self-contained gameplay entities. Follow the **co-location principle**: keep `player.tscn`, `player.gd`, and entity-specific subcomponents in the same folder (`src/entities/player/`).
- **`levels/`**: Playable maps, test chambers, and base level templates (`templates/base_level.tscn`).
- **`ui/`**: 
  - `menus/`: Main menu, pause menu, settings, credits.
  - `hud/`: On-screen displays, health bars, inventory popups, reticles.
  - `theme/`: Global UI theme (`default_theme.tres`), styleboxes, and font settings.
- **`utils/`**: General-purpose helper scripts, math extensions, state machine base classes, and debug tools.

### `tests/`
Unit and integration tests (recommended: [GUT - Godot Unit Testing](https://github.com/bitwes/Gut)).

### `docs/`
Game design documents (GDD), story bibles, lore notes, and technical references.

---

## 2. Naming Conventions (Godot Style Guide)

| Item | Convention | Example |
| :--- | :--- | :--- |
| **Folders & Files** | `snake_case` | `player_controller.gd`, `main_menu.tscn` |
| **Classes / Nodes** | `PascalCase` | `class_name CharacterStats`, `PlayerSpawner` |
| **Variables & Functions** | `snake_case` | `health`, `move_and_slide()` |
| **Private Variables/Funcs** | `_snake_case` (prefixed) | `_update_cache()`, `_internal_timer` |
| **Constants & Enums** | `SCREAMING_SNAKE_CASE` | `MAX_SPEED`, `enum State { IDLE, RUN }` |
| **Signals** | `snake_case` (past tense) | `health_changed`, `target_acquired` |

---

## 3. Best Practices & Design Principles

1. **Favor Composition over Inheritance**:
   Build entities out of reusable nodes (e.g., `HitboxComponent`, `HurtboxComponent`, `HealthComponent`) rather than monolithic deep inheritance hierarchies.
2. **Co-location over Separation**:
   Keep a scene, its root script, and tightly coupled resources together in the same entity folder. Avoid placing scripts in a global `scripts/` folder and scenes in a global `scenes/` folder once a project scales.
3. **Signal Up, Call Down**:
   - Parent nodes call methods on children directly: `child.take_damage(10)`.
   - Child nodes emit signals to communicate upwards: `emit_signal("health_depleted")`.
4. **Decouple with an EventBus**:
   For distant cross-system communications (e.g., an enemy dying awarding score to the HUD), use an `EventBus` singleton rather than hard node references.

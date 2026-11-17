# gimersia-2026

A Godot 4 game project configured with a modular, scalable architecture.

## 📁 Project Structure

```text
gimersia-2026/
├── assets/                       # Raw and processed external assets
│   ├── audio/                    # Music tracks, sound effects, ambience
│   │   ├── music/
│   │   └── sfx/
│   ├── fonts/                    # Font files (.ttf, .otf, .tres)
│   ├── models/                   # 3D meshes, materials, and rigs (.blend, .gltf, .obj)
│   ├── shaders/                  # Custom shader files (.gdshader)
│   └── textures/                 # 2D art, sprites, tilesets, VFX, UI textures
│       ├── characters/
│       ├── environment/
│       ├── ui/
│       └── vfx/
├── src/                          # Game source logic and scene components
│   ├── core/                     # Autoloads, singletons, EventBus, game managers
│   ├── data/                     # Custom resources (.tres), configuration, databases
│   ├── entities/                 # Self-contained game objects (scene + script)
│   │   ├── player/
│   │   ├── enemies/
│   │   └── props/
│   ├── levels/                   # Game worlds, arenas, rooms, and level templates
│   │   └── templates/
│   ├── ui/                       # Interface screens, HUD, dialogs, and themes
│   │   ├── hud/
│   │   ├── menus/
│   │   └── theme/
│   └── utils/                    # Reusable helper scripts, math utils, state machines
├── tests/                        # Automated unit and integration tests (GUT)
└── docs/                         # Game design documentation and architecture guides
```

## 📚 Documentation

- [Architecture & conventions](docs/architecture.md)
- [Module usage guide](docs/PANDUAN_MODUL.md)
- [MVP checklist](docs/MVP_CHECKLIST.md)
- [Gameplay specification](docs/spesifikasi_teknis_mekanisme_gameplay_V8.md)
- [MVP scope & division work list](docs/MVP_dan_Daftar_Pekerjaan_RTRw_Studio.docx.md)

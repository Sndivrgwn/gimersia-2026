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

- [Architecture & conventions](docs/editable/architecture.md)
- [Module usage guide](docs/editable/PANDUAN_MODUL.md)
- [AI context (status terverifikasi)](docs/editable/AI_CONTEXT.md)
- [MVP checklist](docs/editable/MVP_CHECKLIST.md)
- [Gameplay specification](docs/noneditable/spesifikasi_teknis_mekanisme_gameplay_V8.md)
- [MVP scope & division work list](docs/noneditable/MVP_dan_Daftar_Pekerjaan_RTRw_Studio.docx.md)

## Panduan

- `docs/editable/ASSET_GUIDE.md` — cara menaruh art (slot, nama file, fallback).
- `docs/editable/CONFIG_GUIDE.md` — semua Resource `.tres` dan efek tuning-nya.
- `docs/editable/PANDUAN_MODUL.md` — wiring modul, Input Map, sistem aset.
- `docs/editable/PANDUAN_INPUT.md` — arti setiap tombol (Tab, I, P, F1-F12, J, Esc, ...), dibuat dari Input Map yang hidup.

## Status

Mission 9 "Balance & Feel, pass 2" fase 0-4 selesai (raid event, massa babi,
api unggun COLD, freeze kematian + perlindungan respawn, balans needs, jongkok,
waspada rusa, mengarungi sungai). Build headless bersih di `island.tscn`,
`practice1.tscn`, dan `main_menu.tscn`. Fase 5-6 (sweep matahari, tab Profil,
SpriteFrames, data audio) belum dikerjakan; detail di
`docs/editable/AI_CONTEXT.md` §15.

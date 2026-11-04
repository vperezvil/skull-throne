# Codebase layout

Godot **4.7** project. Main scene: `res://scenes/main/world.tscn` (see `project.godot`). Overworld tiles live on the **`Map`** `TileMapLayer` in that scene.

## Scripts (`scripts/`)

| Folder | Purpose |
|--------|---------|
| `core/` | Autoload helpers (`global.gd`, `game_constants.gd`) |
| `run/` | Run persistence (`run_state`, `meta_progress`, `run_modifiers`, `run_end_payload`) |
| `data/` | Registries, definitions, zone music |
| `world/` | Overworld, map generation, events, `run_director.gd` |
| `combat/` | Battle, combatants, enemies, biome combat |
| `ui/` | HUD, hub commerce, party HUD, pause settings |
| `tools/` | Headless CI scripts (`content_validator.gd`, `smoke_test.gd`, `check_gdscript_patterns.gd`) |

Script files use **snake_case** (e.g. `map.gd`, `ui.gd`, `character.gd`). `class_name` types may stay PascalCase (`Character`, `Item`).
| `characters/` | Playable party scripts |
| `items/` | Inventory and pickups |
| `systems/` | Shrines, soul marks, stress |

Autoload order is defined in `project.godot`.

## Scenes (`scenes/`)

| Folder | Purpose |
|--------|---------|
| `main/` | World entry, battle overlay, UI root |
| `characters/` | Party member scenes |
| `enemies/` | Boss, trolls, spawnable enemy template |
| `objects/` | Potions, sword, healing fountain |

## Related docs

- [Upgrading Godot](godot-upgrade.md)
- [Releasing a version](releasing.md)
- [Third-party licenses](third-party-licenses.md)

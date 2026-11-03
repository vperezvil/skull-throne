# Releasing a version

Player-facing information stays in the [root README](../README.md).

## Automated checks (GitHub Actions)

Workflow: [.github/workflows/godot-ci.yml](../.github/workflows/godot-ci.yml) on push/PR to `main`, `master`, and `feature/**`.

| Step | What it checks |
|------|----------------|
| Import project | Godot imports assets headless (broken paths, missing resources). |
| Validate game content | `scripts/tools/content_validator.gd` |
| Smoke run | Main scene loads and runs briefly |

CI does not replace a full playtest or export binaries.

## Before you tag

1. Bump `config/version` in [project.godot](../project.godot) if needed.
2. Open the project once in Godot 4.2.x so new assets import locally (optional if CI is green).
3. Manual playtest: sanctum (mirror, preview) → descent → waystation/campfire → throne → relaunch (meta save) → stain purify / early abandon.
4. Export via **Project → Export** ([export_presets.cfg](../export_presets.cfg) → `build/`).
5. GitHub release: attach builds; include [README](../README.md) and [third-party-licenses.md](third-party-licenses.md); tag matches `project.godot` version.

## Optional later CI

- Export on tag (export templates in Actions).
- Broader content validation (zones, character skills).

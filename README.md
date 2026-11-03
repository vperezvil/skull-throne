# Skull Throne
[![Latest Release](https://img.shields.io/github/v/release/vperezvil/skull-throne)](https://github.com/vperezvil/skull-throne/releases/latest)
## Table of Contents
- [Introduction](#introduction)
- [Usage](#usage)
- [Documentation](#contributing--releases)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Introduction

Skull Throne is a top-down 2D roguelike inspired by *Darkest Dungeon* and *Warhammer 40,000* lore. You assemble a party of disposable heroes, invest in the **Blood Sanctum** between descents, and push through procedurally generated biomes until you reach **Khorne** on the Skull Throne.

Each fallen hero adds a skull to that throne. Over time, the Blood God grows tougher, and the finale arena fills with the cost of your runs. Heroes can roll **slightly different stats** each time you **Begin descent**, so the same roster can play differently from run to run.

The engine is **Godot 4.2** with **GDScript**. Maps are built from rooms linked by a minimum spanning tree so every floor is connected and playable, with biome-specific tiles, enemies, and music.

## Usage

### Installation

1. **Download the Latest Release**
	- You can download the latest release from the [Releases](https://github.com/vperezvil/skull-throne/releases) page.
	- Place the downloaded exe file to your desired location.

2. **Clone the Repository**
	- Open your terminal and run the following command to clone the repository:
	  ```bash
	  git clone https://github.com/vperezvil/skull-throne.git
	  ```

### Running the Game

#### From Source

1. **Prerequisites**
	- Ensure you have [Godot Engine](https://godotengine.org/) installed. The game is developed using Godot version 4.2.1.

2. **Open the Project**
	- Launch Godot Engine.
	- Click on the "Import" button and navigate to the folder where you cloned the repository.
	- Select the `project.godot` file and open it.

3. **Run the Game**
	- Click on the "Play" button (the one with the play icon) to run the game.

#### From Release

1. **Download and Run the Executable**
	- Navigate to the [Releases](https://github.com/vperezvil/skull-throne/releases) page.
	- Download the latest `.exe` file.
	- Run the downloaded `.exe` file to start the game.

### Controls

- **Movement:** Arrow keys or **WASD**.
- **Pause:** Press `Escape` to pause the game and open the menu (inventory, audio volumes, credits, abandon run).

### Run flow

1. Pick up to four characters (some unlock after you clear floors across all runs), then **Start run** to enter the **Blood Sanctum** (shop, upgrades, trainers, equipment stash).
2. **Begin descent** to roll minor stat variance for the party, then enter a random sequence of biome floors ending at the **Skull Throne** finale.
3. Clear a floor by defeating its **Blood Warden** boss. Every two cleared floors, a **waystation** offers Grum and the Enchantress using **run gold**.
4. Each descent rolls a **run modifier** (Bounty Hunters, Blood Frenzy, etc.) for extra variety. **Elite** foes (gold tint) pay more XP and gold. **Gold caches** on the map grant run gold (sometimes a potion).
5. Deaths add **skulls on the throne** (saved between sessions). Khorne and late bosses scale with that count; the throne room shows skull props matching your total.
6. Overworld music follows the biome; combat uses separate battle and boss tracks (see `scripts/data/zone_music.gd`).

### Shrines, statuses, events, Ascended

- **Shrines:** After some floor clears (~45% when not a waystation), pick **one of three run blessings** (attack, HP, crit, MP regen, gold, or cleanse).
- **Bleed / poison:** Stack over time (bleed 3× stacks, poison 2× stacks per turn). Swamps, catacombs, skirmishers, and map traps apply them; healing is weaker while poisoned.
- **Map events:** Random encounters on each floor - springs, gambles, XP wisdom, gas traps, and **ambush fights**.
- **Ascended descent:** Toggle in the sanctum after your **first victory** - harder modifiers, +15% enemy damage, +elite chance, tougher bosses; slightly less run gold from pickups.

### Additional Information

- **Blood Tithe:** Meta currency earned at the end of each run (more for deeper runs and victory). Spend it in the sanctum; **run gold** only lasts for the current descent and waystations.
- **Open Inventory:** Pause menu or battle menu.
- **Items:** Healing fountain (overworld), potions and swords from shops or inventory.
- **Equipment:** Buy at Grum, stash, then equip on party members; stats apply in combat.
- **Skills:** Train tiers at the Enchantress (tier 2 and 3 unlock extra skills). Beth and Trece keep level progress between runs as veterans.
- **Combat:** Click targets; flee from normal fights, not bosses. Biome rules and enemy traits (skirmisher, bruiser, arcane) change who gets hit and how hard. See `scripts/combat/biome_combat.gd`.
- **Soul marks:** Leaving a descent early can leave **Stains** on heroes (lasting penalties on the roster). A full **victory** can forge **Oaths** (small bonuses). See marks on the sanctum party line; purify Stains at the Enchantress for Blood Tithe (`scripts/systems/character_traits.gd`).
- **Stress:** Builds in combat from hits, low HP, and fleeing. At 100 stress, heroes may gain a Stain, rarely an Oath, or vent. Waystation **Campfire** lowers stress and may purify one Stain.
- **Abandon run:** Early return (before clearing enough floors) penalizes tithe, XP, and may inflict Stains; the confirmation dialog explains the cost.

### Contributing / releases

Pull requests run **Godot CI** (import, content validation, smoke run).

| Doc | Audience |
| --- | --- |
| [docs/codebase-layout.md](docs/codebase-layout.md) | Scripts and scenes folder map |
| [docs/releasing.md](docs/releasing.md) | Version tags, export, playtest |
| [docs/third-party-licenses.md](docs/third-party-licenses.md) | Ship with builds (also linked from [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md)) |

## License

### Skull Throne (original work)

Game code and original art created for this repository are licensed under [Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)](https://creativecommons.org/licenses/by-nc-nd/4.0/deed).

[![License: CC BY-NC-ND 4.0](https://licensebuttons.net/l/by-nc-nd/4.0/88x31.png)](https://creativecommons.org/licenses/by-nc-nd/4.0/deed)

You may share unmodified copies for **non-commercial** use with attribution. You may **not** distribute modified versions of those original assets under this license. This is a hobby / non-commercial project; contact the repository owner before any commercial use.

### Third-party assets

Many sprites and audio files are **third-party** resources from [OpenGameArt.org](https://opengameart.org) and similar sources. They remain under **their authors' licenses**, not CC BY-NC-ND. Details: [docs/third-party-licenses.md](docs/third-party-licenses.md) and [Acknowledgements](#acknowledgements).

| License (summary) | Used for (examples) |
| --- | --- |
| CC BY 3.0 / CC BY 4.0 | Miguel Herrero music, Telaron *The Road's End*, Marcus Rasseli battle tracks |
| CC BY-SA 3.0 | pheonton themes (main/dark/rescue/funeral), remaxim battle/boss/win/magical/old city/medieval loop tracks |
| Various (see OGA pages) | LPC sprites, dungeon tiles, SFX |

**How we use them:** Third-party files are included **unmodified** (or as engine imports) and combined into the game as separate media. Attribution is given in this README and in-game where practical (`ZoneMusic.get_track_label` on the floor title).

**Share-alike (CC BY-SA):** If you redistribute **those specific audio files** (not the whole game), you must follow the corresponding CC BY-SA terms (credit, license, share alike). Redistributing a **built release** of Skull Throne should preserve this README and the third-party notices.

**No legal advice:** This section summarizes our intent for an indie game bundle. For commercial publishing or remixing third-party assets, read each asset's license on OpenGameArt and consult qualified counsel.

## Acknowledgements

Thanks to the following opengameart users for their contributions used for this project, here you'll find the links to said resources:

- Sprites:
	- [andreyin](https://opengameart.org/content/hand-cursor)
	- [Antifarea](https://opengameart.org/content/antifareas-rpg-sprite-set-1-enlarged-w-transparent-background)
	- [bleutailfly](https://opengameart.org/content/wizards )
	- [Chris Hamons](http://opengameart.org/content/dungeon-crawl-32x32-tiles)
	- [Nidhoggn](https://opengameart.org/content/backgrounds-3)
	- [Reemax](https://opengameart.org/content/lpc-rat-cat-and-dog)
	- [wulax](https://opengameart.org/content/lpc-medieval-fantasy-character-sprites)

- Music / Sounds:
	- [Baŝto](https://opengameart.org/content/nes-sounds)
	- [Marcus Rasseli](https://opengameart.org/content/the-battle)
	- [Miguel Herrero](https://opengameart.org/content/medieval)
	- [pheonton](https://opengameart.org/content/maintheme) ([dark](https://opengameart.org/content/dark), [rescue](https://opengameart.org/content/rescue), [funeral](https://opengameart.org/content/funeral))
	- [remaxim](https://opengameart.org/content/win-music-1)
	- [remaxim](https://opengameart.org/content/win-music-2)
	- [remaxim](https://opengameart.org/content/boss-theme)
	- [remaxim](https://opengameart.org/content/battle-theme)
	- [remaxim](https://opengameart.org/content/magical-theme)
	- [remaxim](https://opengameart.org/content/old-city-theme)
	- [remaxim](https://opengameart.org/content/short-medieval-loop)
	- [Telaron](https://opengameart.org/content/the-roads-end)

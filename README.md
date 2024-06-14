# Skull Throne
[![Latest Release](https://img.shields.io/github/v/release/vperezvil/skull-throne)](https://github.com/vperezvil/skull-throne/releases/latest)
## Table of Contents
- [Introduction](#introduction)
- [Usage](#usage)
- [License](#license)
- [Acknowledgements](#acknowledgements)
	
## Introduction

This project’s objective is to create a videogame. This game is similar to ‘Darkest Dungeon’, but in a top-down 2D pixelart style. There’s an initial pool of characters to choose to start the adventure. The idea is that every character is not meant to last, they’re disposable and the player needs to make the best out of a bad situation like in ‘Darkest Dungeon’. The player needs to progress through different zones until they reach the zone’s boss. In case the player doesn’t complete a zone, they can select new characters to join the party if the previous party has any survivors, otherwise the player needs to select new characters to form a party. Depending on the zones completed new characters become available to join the party, every time the characters are generated they will have different stats, allowing the player to experiment with new strategies. The zones are ever changing, allowing the experience to be different every time.
With every character death, a new skull will be added to the final boss’s throne, giving the name to the game ‘Skull Throne’, this name comes from a ‘Warhammer 40,000’ warcry: "Blood for the Blood God! Skulls for the Skull Throne!".
The story setting is that the party of characters want to free their planet from the Chaos God Khorne, inspired from ‘Warhammer 40,000’ lore, the characters will visit different zones until they reach the lair of the Chaos God, sitting on the skull throne.
The game engine used is Godot, a free and open source game engine perfect for developing a 2D pixelart game. The programming language used to develop is GDScript, a high-level programming language with object orientation and native language for Godot’s engine, it is similar to Python. The challenges found are the programming of a generation of the zones using a procedural approach in a way that the map is different each time but with static things related to the zone, like the sprites. Another important element for the map generation is that the map is playable and every room is properly connected, in order to achieve it a shortest path tree algorithm was used, to connect every room to the one nearest with corridors. Another challenge will be storing all the dead characters to appear on the final boss fight and how to generate characters/enemies with ever-changing stats.

## Usage

### Installation
	
1. **Download the Latest Release**
	- You can download the latest release from the [Releases](https://github.com/vperezvil/skull-throne/releases) page.
	- Place the downloaded exe file to your desired location.
	- You 

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

- **Movement:** Use the arrow keys to move your character.
- **Pause:** Press `Escape` to pause the game and open the menu.

### Additional Information

- **Open Inventory:** From the pause menu or the battle menu you can access the Inventory.
- **Items:** There's currently a small amount of items:
		1. **Healing fountain:** will heal completely the party and is interacted via the overworld
		2. **Potion:** will heal the selected character from the inventory menu
		3. **Sword:** will increase the attack power of the selected character from the inventory menu
- **Combat:** During combat you can select clicking the target you want to attack
- **Run:** During combat you can escape all the encounters except the boss

## License

This work is licensed under a [Creative Commons Attribution-NonCommercial-NoDerivs 4.0 License](https://creativecommons.org/licenses/by-nc-nd/4.0/deed).

[![License: CC BY-NC-ND 4.0](https://licensebuttons.net/l/by-nc-nd/4.0/88x31.png)](https://creativecommons.org/licenses/by-nc-nd/4.0/deed)

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
	- [pheonton](https://opengameart.org/content/maintheme)
	- [remaxim](https://opengameart.org/content/win-music-1)
	- [remaxim](https://opengameart.org/content/win-music-2)
	- [remaxim](https://opengameart.org/content/boss-theme) 
	- [Telaron](https://opengameart.org/content/the-roads-end)

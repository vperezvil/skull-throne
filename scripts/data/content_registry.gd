extends Node

var zones: Array[ZoneDefinition] = []
var zones_by_id: Dictionary = {}
var run_biome_ids: Array[String] = []
var characters: Array[CharacterDefinition] = []
var enemies: Dictionary = {}

const CHARACTER_SCENE_IDS := {
	0: "tinybones",
	1: "beth",
	2: "dalf",
	3: "trece",
}

const SPAWNABLE_ENEMY_SCENE := preload("res://scenes/enemies/spawnable_enemy.tscn")
const FINAL_ZONE_ID := "skull_throne"

func _ready() -> void:
	_register_enemies()
	_register_zones()
	_register_characters()

func get_zone_count() -> int:
	return zones.size()

func get_run_biome_count() -> int:
	return run_biome_ids.size()

func get_zone(index: int) -> ZoneDefinition:
	return zones[clampi(index, 0, zones.size() - 1)]

func get_zone_by_id(zone_id: String) -> ZoneDefinition:
	return zones_by_id.get(zone_id)

func build_run_plan() -> Array[String]:
	var biome_count := randi_range(GameConstants.RUN_BIOME_FLOORS_MIN, GameConstants.RUN_BIOME_FLOORS_MAX)
	var plan: Array[String] = []
	if run_biome_ids.is_empty():
		plan.append("grim_fields")
	else:
		for _i in biome_count:
			plan.append(run_biome_ids[randi() % run_biome_ids.size()])
	if zones_by_id.has(FINAL_ZONE_ID):
		plan.append(FINAL_ZONE_ID)
	return plan

func get_enemy(enemy_id: String) -> EnemyDefinition:
	return enemies.get(enemy_id)

func spawn_enemy_from_id(enemy_id: String) -> ConfigurableEnemy:
	var definition := get_enemy(enemy_id)
	if definition == null:
		return null
	var instance: ConfigurableEnemy = SPAWNABLE_ENEMY_SCENE.instantiate()
	instance.configure(definition)
	return instance

func get_character_for_menu_index(menu_index: int) -> CharacterDefinition:
	for def in characters:
		if def.character_id == CHARACTER_SCENE_IDS.get(menu_index, ""):
			return def
	return null

func roll_stat_variant(definition: CharacterDefinition) -> Dictionary:
	if definition == null:
		return {}
	return {
		"max_hp": maxi(40, definition.max_hp + randi_range(-10, 10)),
		"attack": maxi(4, definition.attack + randi_range(-3, 3)),
		"initiative": clampi(definition.initiative + randi_range(-8, 8), 1, 100),
		"max_mp": maxi(0, definition.max_mp + randi_range(-5, 5)),
		"crit_rate": clampf(definition.crit_rate + randf_range(-0.03, 0.03), 0.0, 0.55),
	}

func get_character_by_id(id: String) -> CharacterDefinition:
	for def in characters:
		if def.character_id == id:
			return def
	return null

func get_next_character_unlock(lifetime_floors: int) -> String:
	var best_name := ""
	var best_need := 99999
	for def in characters:
		if lifetime_floors >= def.unlock_after_zones_cleared:
			continue
		if def.unlock_after_zones_cleared < best_need:
			best_need = def.unlock_after_zones_cleared
			best_name = def.display_name
	return best_name

func get_unlock_floor_for(display_or_id: String) -> int:
	for def in characters:
		if def.display_name == display_or_id or def.character_id == display_or_id:
			return def.unlock_after_zones_cleared
	return 0

func _register_enemies() -> void:
	_register_enemy("rock_troll", "Rock Troll", "res://assets/monsters/rock_troll.png", 100, 14, 40, 30, "bruiser")
	_register_enemy("harpy", "Harpy", "res://assets/monsters/harpy.png", 55, 16, 65, 28, "skirmisher")
	_register_enemy("dwarf", "Dwarf", "res://assets/monsters/dwarf.png", 90, 12, 35, 26)
	_register_enemy("swamp_drake", "Swamp Drake", "res://assets/monsters/swamp_dragon.png", 120, 18, 45, 35, "bruiser")
	_register_enemy("deep_elf_soldier", "Deep Elf Soldier", "res://assets/monsters/deep_elf_soldier.png", 75, 15, 55, 32)
	_register_enemy("deep_elf_mage", "Deep Elf Mage", "res://assets/monsters/deep_elf_mage.png", 60, 22, 50, 40, "arcane")
	_register_enemy("death_drake", "Death Drake", "res://assets/monsters/death_drake.png", 140, 24, 48, 45, "bruiser")
	_register_enemy("orc_wizard", "Orc Wizard", "res://assets/monsters/orc_wizard.png", 80, 20, 42, 38, "arcane")
	_register_enemy("grum", "Grum", "res://assets/monsters/unique/grum.png", 110, 19, 38, 50, "bruiser")
	_register_enemy("sigmund", "Sigmund", "res://assets/monsters/unique/sigmund.png", 95, 21, 52, 55, "skirmisher")
	_register_enemy("enchantress", "Enchantress", "res://assets/monsters/unique/enchantress.png", 70, 24, 58, 48, "arcane")
	_register_enemy("giant_brain", "Giant Orange Brain", "res://assets/monsters/giant_orange_brain.png", 160, 16, 30, 60, "lurker")
	_register_enemy("ettin", "Ettin", "res://assets/monsters/ettin.png", 180, 22, 35, 65, "bruiser")

func _register_enemy(
	id: String,
	display: String,
	texture: String,
	hp: int,
	atk: int,
	init: int,
	xp: int,
	trait: String = "standard"
) -> void:
	var def := EnemyDefinition.new()
	def.enemy_id = id
	def.display_name = display
	def.texture_path = texture
	def.max_hp = hp
	def.attack = atk
	def.initiative = init
	def.xp_reward = xp
	def.combat_trait = trait
	enemies[id] = def

func _register_zones() -> void:
	_add_biome("grim_fields", "Grim Fields", "grim_fields",
		["rock_troll", "harpy", "dwarf", "swamp_drake"],
		GameConstants.NUM_ROOMS, GameConstants.ENEMIES_TOTAL, 0)
	_add_biome("blood_cathedral", "Blood Cathedral", "blood_cathedral",
		["deep_elf_soldier", "deep_elf_mage", "death_drake", "orc_wizard", "dwarf"],
		GameConstants.NUM_ROOMS + 2, GameConstants.ENEMIES_TOTAL + 4, 91337)
	_add_biome("swamp_mire", "Swamp Mire", "swamp_mire",
		["swamp_drake", "harpy", "dwarf", "rock_troll"],
		GameConstants.NUM_ROOMS + 1, GameConstants.ENEMIES_TOTAL + 3, 12001)
	_add_biome("ice_citadel", "Ice Citadel", "ice_citadel",
		["deep_elf_soldier", "deep_elf_mage", "dwarf", "harpy"],
		GameConstants.NUM_ROOMS + 2, GameConstants.ENEMIES_TOTAL + 5, 22002)
	_add_biome("bone_crypt", "Bone Crypt", "bone_crypt",
		["death_drake", "deep_elf_mage", "orc_wizard", "dwarf"],
		GameConstants.NUM_ROOMS + 3, GameConstants.ENEMIES_TOTAL + 6, 33003)
	_add_biome("crystal_depths", "Crystal Depths", "crystal_depths",
		["deep_elf_mage", "enchantress", "orc_wizard", "deep_elf_soldier"],
		GameConstants.NUM_ROOMS + 2, GameConstants.ENEMIES_TOTAL + 5, 44004)
	_add_biome("nerve_catacombs", "Nerve Catacombs", "nerve_catacombs",
		["giant_brain", "death_drake", "orc_wizard", "enchantress"],
		GameConstants.NUM_ROOMS + 4, GameConstants.ENEMIES_TOTAL + 7, 55005)
	_add_biome("sandstone_ruins", "Sandstone Ruins", "sandstone_ruins",
		["rock_troll", "dwarf", "harpy", "deep_elf_soldier"],
		GameConstants.NUM_ROOMS + 1, GameConstants.ENEMIES_TOTAL + 4, 66006)
	_add_biome("marble_halls", "Marble Halls", "marble_halls",
		["deep_elf_soldier", "deep_elf_mage", "sigmund", "enchantress"],
		GameConstants.NUM_ROOMS + 3, GameConstants.ENEMIES_TOTAL + 6, 77007)
	_add_biome("throne_approach", "Throne Approach", "throne_approach",
		["grum", "sigmund", "enchantress", "giant_brain", "ettin"],
		GameConstants.NUM_ROOMS + 5, GameConstants.ENEMIES_TOTAL + 9, 184903)

	var skull_throne := ZoneDefinition.new()
	skull_throne.zone_id = FINAL_ZONE_ID
	skull_throne.display_name = "Skull Throne"
	skull_throne.map_theme_id = "skull_throne"
	skull_throne.is_run_biome = false
	skull_throne.is_final_zone = true
	skull_throne.boss_kind = "khorne"
	skull_throne.build_skull_throne_arena = true
	skull_throne.map_music = ZoneMusic.get_overworld_music_for_theme("skull_throne")
	skull_throne.enemy_spawn_ids = ["death_drake", "ettin", "giant_brain", "orc_wizard", "sigmund", "grum"]
	skull_throne.num_rooms = GameConstants.NUM_ROOMS + MapThemeSettings.get_room_count_bonus("skull_throne")
	skull_throne.enemy_count = GameConstants.ENEMIES_TOTAL + 12
	skull_throne.noise_seed_offset = 666013
	_register_zone(skull_throne)

func _add_biome(
	zone_id: String,
	display_name: String,
	theme_id: String,
	enemy_ids: Array,
	rooms: int,
	enemy_count: int,
	seed_offset: int
) -> void:
	var def := ZoneDefinition.new()
	def.zone_id = zone_id
	def.display_name = display_name
	def.map_theme_id = theme_id
	def.map_music = ZoneMusic.get_overworld_music_for_theme(theme_id)
	def.enemy_spawn_ids.assign(enemy_ids)
	def.num_rooms = rooms
	def.enemy_count = enemy_count
	def.noise_seed_offset = seed_offset
	_register_zone(def)

func _register_zone(def: ZoneDefinition) -> void:
	zones.append(def)
	zones_by_id[def.zone_id] = def
	if def.is_run_biome and !def.is_final_zone:
		run_biome_ids.append(def.zone_id)

func _register_characters() -> void:
	characters.append(_make_character("tinybones", "TinyBones", 100, 15, 55, 0, 20, 0.35, 300.0, 2))
	characters.append(_make_character("beth", "Beth", 130, 8, 45, 0, 80, 0.05, 280.0, 7))
	characters.append(_make_character("dalf", "Dalf", 85, 18, 20, 0, 60, 0.08, 270.0, 6))
	characters.append(_make_character("trece", "Trece", 110, 12, 95, 1, 25, 0.12, 380.0, 3))

func _make_character(
	id: String,
	display: String,
	hp: int,
	atk: int,
	init: int,
	unlock: int,
	mp: int,
	crit: float,
	speed: float,
	mp_regen: int
) -> CharacterDefinition:
	var def := CharacterDefinition.new()
	def.character_id = id
	def.display_name = display
	def.max_hp = hp
	def.attack = atk
	def.initiative = init
	def.unlock_after_zones_cleared = unlock
	def.max_mp = mp
	def.crit_rate = crit
	def.move_speed = speed
	def.mp_regen_per_turn = mp_regen
	def.retains_progress = id == "beth" or id == "trece"
	return def

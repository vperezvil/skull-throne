extends Node

var zones: Array[ZoneDefinition] = []
var characters: Array[CharacterDefinition] = []

const CHARACTER_SCENE_IDS := {
	0: "tinybones",
	1: "beth",
	2: "dalf",
	3: "trece",
}

func _ready() -> void:
	_register_zones()
	_register_characters()

func get_zone_count() -> int:
	return zones.size()

func get_zone(index: int) -> ZoneDefinition:
	return zones[clampi(index, 0, zones.size() - 1)]

func get_character_for_menu_index(menu_index: int) -> CharacterDefinition:
	for def in characters:
		if def.character_id == CHARACTER_SCENE_IDS.get(menu_index, ""):
			return def
	return null

func get_character_by_id(id: String) -> CharacterDefinition:
	for def in characters:
		if def.character_id == id:
			return def
	return null

func _register_zones() -> void:
	var grim := ZoneDefinition.new()
	grim.zone_id = "grim_fields"
	grim.display_name = "Grim Fields"
	grim.floor_source_id = 0
	grim.wall_source_id = 6
	grim.map_music = load("res://assets/music/medieval.ogg")
	grim.enemy_scenes = [
		load("res://scenes/rock_troll.tscn"),
		load("res://scenes/rock_troll_b.tscn"),
	]
	grim.num_rooms = GameConstants.NUM_ROOMS
	grim.enemy_count = GameConstants.ENEMIES_TOTAL
	zones.append(grim)

	var cathedral := ZoneDefinition.new()
	cathedral.zone_id = "blood_cathedral"
	cathedral.display_name = "Blood Cathedral"
	cathedral.floor_source_id = 1
	cathedral.wall_source_id = 6
	cathedral.map_music = load("res://assets/music/medieval.ogg")
	cathedral.enemy_scenes = [
		load("res://scenes/rock_troll_b.tscn"),
		load("res://scenes/rock_troll.tscn"),
	]
	cathedral.num_rooms = GameConstants.NUM_ROOMS + 3
	cathedral.enemy_count = GameConstants.ENEMIES_TOTAL + 5
	cathedral.noise_seed_offset = 91337
	zones.append(cathedral)

func _register_characters() -> void:
	characters.append(_make_character("tinybones", "TinyBones", 100, 15, 60, 0))
	characters.append(_make_character("beth", "Beth", 150, 10, 50, 0))
	characters.append(_make_character("dalf", "Dalf", 70, 20, 15, 0))
	characters.append(_make_character("trece", "Trece", 150, 12, 100, 1))

func _make_character(id: String, display: String, hp: int, atk: int, init: int, unlock: int) -> CharacterDefinition:
	var def := CharacterDefinition.new()
	def.character_id = id
	def.display_name = display
	def.max_hp = hp
	def.attack = atk
	def.initiative = init
	def.unlock_after_zones_cleared = unlock
	return def

extends Node

# Autoload used by world (Map Theme), battle, and hub UI.

const PATH_MEDIEVAL := "res://assets/music/medieval.ogg"
const PATH_MEDIEVAL_LOOP := "res://assets/music/medieval loop.wav"
const PATH_HERRERO_SADNESS := "res://assets/music/herrero_sadness.ogg"
const PATH_HERRERO_MEMORIES := "res://assets/music/herrero_memories.ogg"
const PATH_HERRERO_DISCOVERY := "res://assets/music/herrero_discovery.ogg"
const PATH_HERRERO_SPACE := "res://assets/music/herrero_space.ogg"
const PATH_ROADS_END := "res://assets/music/the road&#039;s end.mp3"
const PATH_MAIN_THEME := "res://assets/music/pheonton - war - 01 - maintheme.mp3"
const PATH_PHEONTON_DARK := "res://assets/music/pheonton - war - 02 - dark.mp3"
const PATH_PHEONTON_RESCUE := "res://assets/music/pheonton - war - 03 - rescue.mp3"
const PATH_PHEONTON_FUNERAL := "res://assets/music/pheonton - war - 04 - funeral.mp3"
const PATH_OLD_CITY := "res://assets/music/old city theme.ogg"
const PATH_MAGICAL := "res://assets/music/magical theme.ogg"
# remaxim battle / boss themes and Rasseli osn2u - combat only
const PATH_ENEMY_BATTLE := "res://assets/music/battle theme.ogg"
const PATH_BOSS_BATTLE := "res://assets/music/boss theme.ogg"
const PATH_RASSELI_BATTLE := "res://assets/music/osn2u.mp3"
const PATH_WIN_1 := "res://assets/music/win music 1-2.mp3"
const PATH_WIN_2 := "res://assets/music/win music 2.wav"
const PATH_WIN_3 := "res://assets/music/win music 3.wav"

const _VICTORY_PATHS: Array[String] = [PATH_WIN_1, PATH_WIN_2, PATH_WIN_3]

const _EXPLORE_PATHS: Array[String] = [
	PATH_MEDIEVAL,
	PATH_MEDIEVAL_LOOP,
	PATH_HERRERO_SADNESS,
	PATH_HERRERO_MEMORIES,
	PATH_HERRERO_DISCOVERY,
	PATH_HERRERO_SPACE,
	PATH_ROADS_END,
	PATH_MAIN_THEME,
	PATH_PHEONTON_DARK,
	PATH_PHEONTON_RESCUE,
	PATH_PHEONTON_FUNERAL,
	PATH_OLD_CITY,
	PATH_MAGICAL,
]

const _COMBAT_PATHS: Array[String] = [
	PATH_ENEMY_BATTLE,
	PATH_BOSS_BATTLE,
	PATH_RASSELI_BATTLE,
]

var _cache: Dictionary = {}

func _ready() -> void:
	for path in _EXPLORE_PATHS + _COMBAT_PATHS + _VICTORY_PATHS:
		_load(path)

func get_enemy_battle_music_for_zone(zone: ZoneDefinition) -> AudioStream:
	if zone != null and !zone.is_final_zone and RunState.get_run_depth() >= 3:
		return _load(PATH_RASSELI_BATTLE)
	return get_enemy_battle_music()

func get_enemy_battle_music() -> AudioStream:
	return _load(PATH_ENEMY_BATTLE)

func get_victory_music(finale: bool) -> AudioStream:
	if finale:
		return _load(PATH_WIN_3)
	var idx: int = RunState.floors_cleared_this_run % _VICTORY_PATHS.size()
	return _load(_VICTORY_PATHS[idx])

func get_boss_battle_music_for_zone(zone: ZoneDefinition) -> AudioStream:
	if zone != null and zone.boss_kind == "khorne":
		return _load(PATH_BOSS_BATTLE)
	return _load(PATH_RASSELI_BATTLE)

func get_overworld_music_for_zone(zone: ZoneDefinition) -> AudioStream:
	if zone == null:
		return _load(PATH_MEDIEVAL)
	return get_overworld_music_for_theme(zone.map_theme_id)

func get_overworld_music_for_theme(theme_id: String) -> AudioStream:
	match theme_id:
		"grim_fields":
			return _load(PATH_MEDIEVAL)
		"blood_cathedral":
			return _load(PATH_HERRERO_SADNESS)
		"swamp_mire":
			return _load(PATH_HERRERO_MEMORIES)
		"ice_citadel":
			return _load(PATH_HERRERO_SPACE)
		"bone_crypt":
			return _load(PATH_ROADS_END)
		"crystal_depths":
			return _load(PATH_HERRERO_DISCOVERY)
		"nerve_catacombs":
			return _load(PATH_PHEONTON_DARK)
		"sandstone_ruins":
			return _load(PATH_MEDIEVAL_LOOP)
		"marble_halls":
			return _load(PATH_OLD_CITY)
		"throne_approach":
			return _load(PATH_PHEONTON_RESCUE)
		"skull_throne":
			return _load(PATH_PHEONTON_FUNERAL)
		_:
			return _load(PATH_MEDIEVAL)

func get_hub_music() -> AudioStream:
	return _load(PATH_MAIN_THEME)

func get_track_label(theme_id: String) -> String:
	match theme_id:
		"grim_fields":
			return "Medieval - Miguel Herrero"
		"blood_cathedral":
			return "Sadness - Miguel Herrero"
		"swamp_mire":
			return "Memories - Miguel Herrero"
		"ice_citadel":
			return "Space - Miguel Herrero"
		"bone_crypt":
			return "The Road's End - Telaron"
		"crystal_depths":
			return "Discovery - Miguel Herrero"
		"nerve_catacombs":
			return "Dark - pheonton"
		"sandstone_ruins":
			return "Medieval Loop - remaxim"
		"marble_halls":
			return "Old City Theme - remaxim"
		"throne_approach":
			return "Rescue - pheonton"
		"skull_throne":
			return "Funeral - pheonton"
		_:
			return "Medieval - Miguel Herrero"

func _load(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var stream: AudioStream = load(path)
	if stream:
		_cache[path] = stream
	elif path != PATH_MEDIEVAL:
		return _load(PATH_MEDIEVAL)
	return stream

func apply_to_player(player: AudioStreamPlayer, stream: AudioStream, normal_db: float = 0.0) -> void:
	if player == null or stream == null:
		return
	if player.stream == stream and player.playing:
		return
	player.volume_db = normal_db - 10.0
	player.stream = stream
	player.play()
	var tween := player.create_tween()
	tween.tween_property(player, "volume_db", normal_db, 0.65)

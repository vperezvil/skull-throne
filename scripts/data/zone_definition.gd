extends Resource
class_name ZoneDefinition

@export var zone_id: String = ""
@export var display_name: String = "Unknown Zone"
@export var floor_source_id: int = 0 # TileSet source ids used in Map.gd
@export var wall_source_id: int = 6
@export var map_music: AudioStream
@export var enemy_scenes: Array[PackedScene] = []
@export var num_rooms: int = 15
@export var enemy_count: int = 15
@export var noise_seed_offset: int = 0
@export var enemy_spawn_ids: Array[String] = []
@export var map_theme_id: String = "grim_fields"
@export var is_run_biome: bool = true
@export var is_final_zone: bool = false
@export var boss_kind: String = "warden" # khorne on Skull Throne; drives boss fight music
@export var build_skull_throne_arena: bool = false

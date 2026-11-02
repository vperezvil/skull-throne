extends Resource
class_name ZoneDefinition

@export var zone_id: String = ""
@export var display_name: String = "Unknown Zone"
## TileSet source id used for floor tiles in Map.gd
@export var floor_source_id: int = 0
## TileSet source id used for wall / corridor borders
@export var wall_source_id: int = 6
@export var map_music: AudioStream
@export var enemy_scenes: Array[PackedScene] = []
@export var num_rooms: int = 15
@export var enemy_count: int = 15
@export var noise_seed_offset: int = 0

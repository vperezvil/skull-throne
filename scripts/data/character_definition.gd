extends Resource
class_name CharacterDefinition

@export var character_id: String = ""
@export var display_name: String = ""
@export var scene_path: String = ""
@export var max_hp: int = 150
@export var attack: int = 10
@export var initiative: int = 50
@export var max_mp: int = 0
@export var crit_rate: float = 0.05
@export var move_speed: float = 300.0
@export var mp_regen_per_turn: int = 2
@export var unlock_after_zones_cleared: int = 0
@export var retains_progress: bool = false # veterans: level/xp stored in MetaProgress.roster_progress

extends Resource
class_name CharacterDefinition

@export var character_id: String = ""
@export var display_name: String = ""
@export var scene_path: String = ""
@export var max_hp: int = 150
@export var attack: int = 10
@export var initiative: int = 50
## Number of zones cleared required before this character can be selected
@export var unlock_after_zones_cleared: int = 0

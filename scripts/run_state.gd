extends Node

## Persists meta-progress across runs (zone unlocks, campaign position, skull throne scaling).

var zones_cleared: int = 0
var current_zone_index: int = 0
var campaign_active: bool = false

func begin_campaign() -> void:
	campaign_active = true
	current_zone_index = 0

func reset_campaign() -> void:
	campaign_active = false
	current_zone_index = 0

func record_zone_cleared() -> void:
	zones_cleared += 1

func advance_zone() -> void:
	current_zone_index += 1

func has_more_zones() -> bool:
	return current_zone_index + 1 < ContentRegistry.get_zone_count()

func get_skull_throne_bonus_hp() -> int:
	return Global.total_deaths * 5

func is_character_unlocked(definition: CharacterDefinition) -> bool:
	return zones_cleared >= definition.unlock_after_zones_cleared

extends RefCounted
class_name SpawnHelpers

# Random tile pick / room cleanup for world spawn helpers.

static func take_random_tile(walkable_tiles: Array) -> Variant:
	if walkable_tiles.is_empty():
		return null
	var index: int = randi() % walkable_tiles.size()
	var tile = walkable_tiles[index]
	walkable_tiles.remove_at(index)
	return tile

static func erase_tiles_in_rect(walkable_tiles: Array, room: Rect2) -> void:
	var pos := room.position
	var end := room.position + room.size
	for x in range(int(pos.x), int(end.x)):
		for y in range(int(pos.y), int(end.y)):
			walkable_tiles.erase(Vector2i(x, y))

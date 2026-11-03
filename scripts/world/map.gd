extends TileMapLayer

var map = FastNoiseLite.new()
var width = 570
var height = 550
var level = 0
var wall_level = 6
var border_width = 1
var corridor_width = 2
var floor_noise_divisor: float = 1.3
var wall_noise_divisor: float = 5.0
var _theme_id := "grim_fields"

func _ready() -> void:
	map.seed = randi()

func apply_zone(zone: ZoneDefinition) -> void:
	if zone == null:
		return
	_theme_id = zone.map_theme_id
	var theme_sources: Dictionary = MapTileBuilder.apply_theme(self, _theme_id)
	level = theme_sources["floor"]
	wall_level = theme_sources["wall"]
	floor_noise_divisor = MapThemeSettings.get_floor_noise_divisor(_theme_id)
	wall_noise_divisor = MapThemeSettings.get_wall_noise_divisor(_theme_id)
	map.seed = randi() + zone.noise_seed_offset
	map.frequency = 0.04 if zone.is_final_zone else 0.05

func clear_map() -> void:
	clear()

func stamp_throne_arena(room: Rect2) -> void:
	var center: Vector2 = room.get_center()
	for offset in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2)]:
		var coord := Vector2i(int(center.x) + offset.x, int(center.y) + offset.y)
		if get_used_cells().has(coord):
			set_cell(coord, level, Vector2i(0, 0))

func generate_chunk(room_position, room_size):
	for x in range(int(room_size.x)):
		for y in range(int(room_size.y)):
			var coord = Vector2i(int(room_position.x) + x, int(room_position.y) + y)
			if !get_used_cells().has(coord):
				var floor_map = map.get_noise_2d(coord.x, coord.y) * 10
				set_cell(coord, level, _atlas_coord(floor_map, floor_noise_divisor))

func seal_room_corners(room: Rect2) -> void:
	var left := int(room.position.x)
	var top := int(room.position.y)
	var right := int(room.position.x + room.size.x) - 1
	var bottom := int(room.position.y + room.size.y) - 1
	for corner in [Vector2i(left, top), Vector2i(right, top), Vector2i(left, bottom), Vector2i(right, bottom)]:
		_force_wall(corner)

func stamp_corridor_junction(center_a: Vector2, center_b: Vector2) -> void:
	var junction := Vector2i(int(center_b.x), int(center_a.y))
	var hx := signi(int(center_b.x) - int(center_a.x))
	var vy := signi(int(center_b.y) - int(center_a.y))
	if hx == 0 or vy == 0:
		return
	var outer := corridor_width + border_width
	_force_wall(Vector2i(junction.x + hx * outer, junction.y - border_width))
	_force_wall(Vector2i(junction.x - border_width, junction.y + vy * outer))

func _force_wall(coord: Vector2i) -> void:
	var floor_map := map.get_noise_2d(coord.x, coord.y) * 10.0
	set_cell(coord, wall_level, _wall_atlas_coord(floor_map))

func print_room_border(room_position, room_size):
	var room_right = int(room_position.x + room_size.x)
	var room_bottom = int(room_position.y + room_size.y)
	var room_left = int(room_position.x)
	var room_top = int(room_position.y)
	for x in range(room_left, room_right):
		_set_wall(Vector2i(x, room_top))
	for x in range(room_left, room_right):
		_set_wall(Vector2i(x, room_bottom))
	for y in range(room_top, room_bottom):
		_set_wall(Vector2i(room_left, y))
	for y in range(room_top, room_bottom):
		_set_wall(Vector2i(room_right - 1, y))

func _set_wall(coord: Vector2i) -> void:
	if get_used_cells().has(coord):
		return
	var floor_map = map.get_noise_2d(coord.x, coord.y) * 10
	set_cell(coord, wall_level, _wall_atlas_coord(floor_map))

func draw_corridor(start, end):
	var is_vertical = start.x == end.x
	var main_coord = start.x if is_vertical else start.y
	var range_start = min(start.y, end.y) if is_vertical else min(start.x, end.x)
	var range_end = max(start.y, end.y) if is_vertical else max(start.x, end.x)
	range_end += border_width + 1
	var total_width = corridor_width + 2 * border_width
	for offset in range(-border_width, total_width - border_width):
		for i in range(int(range_start), int(range_end)):
			var coord = Vector2i(main_coord + offset, i) if is_vertical else Vector2i(i, main_coord + offset)
			var floor_map = map.get_noise_2d(coord.x, coord.y) * 10
			var is_border_tile = offset < 0 or offset >= corridor_width
			if is_border_tile and !get_used_cells().has(coord):
				set_cell(coord, wall_level, _wall_atlas_coord(floor_map))
			elif !is_border_tile:
				set_cell(coord, level, _atlas_coord(floor_map, floor_noise_divisor))

func _atlas_coord(noise_sample: float, divisor: float) -> Vector2i:
	var atlas_index: int = int(round((noise_sample + 10.0) / divisor))
	atlas_index = clampi(atlas_index, 0, _max_atlas_index_for_source(level))
	return Vector2i(atlas_index, 0)

func _wall_atlas_coord(noise_sample: float) -> Vector2i:
	var atlas_index: int = int(round((noise_sample + 10.0) / wall_noise_divisor))
	atlas_index = clampi(atlas_index, 0, _max_atlas_index_for_source(wall_level))
	return Vector2i(atlas_index, 0)

func _max_atlas_index_for_source(source_id: int) -> int:
	if tile_set == null or !tile_set.has_source(source_id):
		return 11
	var source := tile_set.get_source(source_id) as TileSetAtlasSource
	if source == null or source.texture == null:
		return 11
	var cols: int = maxi(1, int(source.texture.get_width()) / source.texture_region_size.x)
	return clampi(cols - 1, 0, 11)

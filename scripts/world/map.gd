extends TileMapLayer

var map = FastNoiseLite.new()
var width = 570
var height = 550
var level = 0
var wall_level = 6
var border_width: int = GameConstants.MAP_CORRIDOR_BORDER_WIDTH
var corridor_width: int = GameConstants.MAP_CORRIDOR_WALK_WIDTH
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
	MapTileBuilder.ensure_wall_physics(tile_set, wall_level)
	floor_noise_divisor = MapThemeSettings.get_floor_noise_divisor(_theme_id)
	wall_noise_divisor = MapThemeSettings.get_wall_noise_divisor(_theme_id)
	map.seed = randi() + zone.noise_seed_offset
	map.frequency = 0.04 if zone.is_final_zone else 0.05

func clear_map() -> void:
	clear()

func refresh_physics() -> void:
	update_internals()

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
		if !_cell_is_walkable_floor(corner):
			_paint_wall(corner)

func stamp_corridor_junction(center_a: Vector2, center_b: Vector2) -> void:
	var junction := Vector2i(int(center_b.x), int(center_a.y))
	var hx := signi(int(center_b.x) - int(center_a.x))
	var vy := signi(int(center_b.y) - int(center_a.y))
	if hx == 0 or vy == 0:
		return
	# Outer convex corner of the L (single tile); avoids extra rim walls that thicken corridors.
	var outer := Vector2i(junction.x + hx * (corridor_width + border_width), junction.y + vy * (corridor_width + border_width))
	if !_cell_is_walkable_floor(outer):
		_paint_wall(outer)

func carve_connection_mouths(rooms: Array, center_a: Vector2, center_b: Vector2) -> void:
	var ax := int(center_a.x)
	var ay := int(center_a.y)
	var bx := int(center_b.x)
	var by := int(center_b.y)
	for room in rooms:
		if !(room is Rect2):
			continue
		var rect: Rect2 = room
		if rect.has_point(center_a):
			_carve_horizontal_mouth(rect, ay, signi(bx - ax))
		if rect.has_point(center_b):
			_carve_vertical_mouth(rect, bx, signi(by - ay))

func _carve_horizontal_mouth(room: Rect2, corridor_y: int, dir_x: int) -> void:
	if dir_x == 0:
		return
	var left := int(room.position.x)
	var right := int(room.position.x + room.size.x) - 1
	var top := int(room.position.y)
	var bottom := int(room.position.y + room.size.y) - 1
	var y0 := clampi(corridor_y, top, bottom - corridor_width + 1)
	var wall_x := right if dir_x > 0 else left
	var out_x := wall_x + dir_x
	for w in corridor_width:
		_force_floor(Vector2i(wall_x, y0 + w))
		_force_floor(Vector2i(out_x, y0 + w))

func _carve_vertical_mouth(room: Rect2, corridor_x: int, dir_y: int) -> void:
	if dir_y == 0:
		return
	var left := int(room.position.x)
	var right := int(room.position.x + room.size.x) - 1
	var top := int(room.position.y)
	var bottom := int(room.position.y + room.size.y) - 1
	var x0 := clampi(corridor_x, left, right - corridor_width + 1)
	var wall_y := bottom if dir_y > 0 else top
	var out_y := wall_y + dir_y
	for w in corridor_width:
		_force_floor(Vector2i(x0 + w, wall_y))
		_force_floor(Vector2i(x0 + w, out_y))

func _force_floor(coord: Vector2i) -> void:
	var floor_map := map.get_noise_2d(coord.x, coord.y) * 10.0
	set_cell(coord, level, _atlas_coord(floor_map, floor_noise_divisor))

func _cell_is_walkable_floor(coord: Vector2i) -> bool:
	return get_cell_source_id(coord) == level

func _paint_wall(coord: Vector2i) -> void:
	if _cell_is_walkable_floor(coord):
		return
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
	_paint_wall(coord)

func draw_corridor(start, end):
	var is_vertical := int(start.x) == int(end.x)
	var main_coord := int(start.x) if is_vertical else int(start.y)
	var range_start := mini(int(start.y), int(end.y)) if is_vertical else mini(int(start.x), int(end.x))
	var range_end := maxi(int(start.y), int(end.y)) if is_vertical else maxi(int(start.x), int(end.x))
	range_end += 1
	var outer_min := -border_width
	var outer_max := corridor_width + border_width - 1
	for offset in range(outer_min, outer_max + 1):
		var is_border_tile := offset < 0 or offset >= corridor_width
		for i in range(range_start, range_end + 1):
			var coord := Vector2i(main_coord + offset, i) if is_vertical else Vector2i(i, main_coord + offset)
			if is_border_tile:
				_paint_wall(coord)
			elif !_cell_is_walkable_floor(coord):
				_force_floor(coord)

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

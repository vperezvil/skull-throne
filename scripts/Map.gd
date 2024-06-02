extends TileMap

var map = FastNoiseLite.new()
var width = 570
var height = 550
var level = 0
var wall_level = 6
var border_width = 1
var corridor_width = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	map.seed = randi()

func generate_chunk(room_position, room_size):
	var tile_pos = local_to_map(room_position)
	for x in range(room_size.x):
		for y in range(room_size.y):
			var coord = Vector2i(room_position.x+ x, room_position.y + y)
			if !get_used_cells(0).has(coord):
				var floor_map = map.get_noise_2d(room_position.x + x, room_position.y + y)*10
				set_cell(0,coord,level,Vector2i(round((floor_map+10)/1.3),0))

# 'room_position' is the top-left corner of the room and 'room_size' is its size
func print_room_border(room_position, room_size):
	var room_right = room_position.x + room_size.x
	var room_bottom = room_position.y + room_size.y

	# Print top border
	for x in range(room_position.x, room_right):
		var coord = Vector2i(x, room_position.y)
		if !get_used_cells(0).has(coord):
			var floor_map = map.get_noise_2d(x, room_position.y) * 10
			set_cell(0, coord, wall_level, Vector2i(round((floor_map + 10) / 5), 0))

	# Print bottom border
	for x in range(room_position.x, room_right):
		var coord = Vector2i(x, room_bottom)
		if !get_used_cells(0).has(coord):
			var floor_map = map.get_noise_2d(x, room_bottom) * 10
			set_cell(0, coord, wall_level, Vector2i(round((floor_map + 10) / 5), 0))

	# Print left border
	for y in range(room_position.y, room_bottom):
		var coord = Vector2i(room_position.x, y)
		if !get_used_cells(0).has(coord):
			var floor_map = map.get_noise_2d(room_position.x, y) * 10
			set_cell(0, coord, wall_level, Vector2i(round((floor_map + 10) / 5), 0))

	# Print right border
	for y in range(room_position.y, room_bottom):
		var coord = Vector2i(room_right - 1, y)
		if !get_used_cells(0).has(coord):
			var floor_map = map.get_noise_2d(room_right - 1, y) * 10
			set_cell(0, coord, wall_level, Vector2i(round((floor_map + 10) / 5), 0))
			
func draw_corridor(start, end):
	# Determine the range for corridor drawing based on orientation
	var is_vertical = start.x == end.x
	var main_coord = start.x if is_vertical else start.y
	var range_start = min(start.y, end.y) if is_vertical else min(start.x, end.x)
	var range_end = max(start.y, end.y) if is_vertical else max(start.x, end.x)
	range_end += border_width + 1
	# Calculate total width including borders
	var total_width = corridor_width + 2 * border_width
	# Loop over the corridor width (including borders)
	for offset in range(-border_width,total_width - border_width):  
		# Loop over the length of the corridor
		for i in range(range_start, range_end):
			# Calculate the current tile coordinate
			var coord = Vector2i(main_coord + offset, i) if is_vertical else Vector2i(i, main_coord + offset)
			var floor_map = map.get_noise_2d(coord.x, coord.y) * 10

			# Determine if this is a border tile
			var is_border_tile = offset < 0 or offset >= corridor_width
			
			if (i == range_start or i == range_end) and (offset == -border_width or offset == total_width):
				# Calculate the edges
				var top_left_corner = Vector2i(main_coord + offset, i-1) if is_vertical else Vector2i(i-1, main_coord + offset)
				var top_right_corner = Vector2i(main_coord + offset, i-1) if is_vertical else Vector2i(i+1, main_coord + offset)
				var bottom_left_corner = Vector2i(main_coord + offset, i+1) if is_vertical else Vector2i(i-1, main_coord + offset)
				var bottom_right_corner = Vector2i(main_coord + offset, i+1) if is_vertical else Vector2i(i+1, main_coord + offset)
				if !get_used_cells(0).has(top_left_corner):
					set_cell(0, top_left_corner, wall_level, Vector2i(round((floor_map + 10) / 5), 0))
				if !get_used_cells(0).has(top_right_corner ):
					set_cell(0, top_right_corner , wall_level, Vector2i(round((floor_map + 10) / 5), 0))
				if !get_used_cells(0).has(bottom_left_corner):
					set_cell(0, bottom_left_corner, wall_level, Vector2i(round((floor_map + 10) / 5), 0))
				if !get_used_cells(0).has(bottom_right_corner):
					set_cell(0, bottom_right_corner, wall_level, Vector2i(round((floor_map + 10) / 5), 0))
			# Place border tiles only if there is no existing tile
			if is_border_tile and !get_used_cells(0).has(coord):
				set_cell(0, coord, wall_level, Vector2i(round((floor_map + 10) / 5), 0))
			# Place main corridor tiles (potentially overwriting existing tiles if they're part of the corridor path)
			elif !is_border_tile:
				set_cell(0, coord, level, Vector2i(round((floor_map + 10) / 1.3), 0))
			

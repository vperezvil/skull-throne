extends TileMap

var map = FastNoiseLite.new()
var width = 70
var height = 50
var level = 0
var wall_level = 6
@onready var player = get_parent().get_child(1)

# Called when the node enters the scene tree for the first time.
func _ready():
	map.seed = randi()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#generate_chunk(player.position)
	
func generate_chunk(position, size_x,size_y):
	var tile_pos = local_to_map(position)
	for x in range(size_x):
		for y in range(size_y):
			if !get_used_cells(0).has(Vector2i(tile_pos.x - size_x/2 + x, tile_pos.y - size_y/2 + y)):
				var floor_map = map.get_noise_2d(tile_pos.x - size_x/2 + x, tile_pos.y - size_y/2 + y)*10
				set_cell(0,Vector2i(tile_pos.x - size_x/2 + x, tile_pos.y - size_y/2 + y),level,Vector2i(round((floor_map+10)/1.3),0))

# Assuming `room_position` is the top-left corner of the room and `room_size` is its size
func print_room_border(room_position, room_size):
	var room_right = room_position.x + room_size.x
	var room_bottom = room_position.y + room_size.y

	var tile_pos = local_to_map(room_position)
	# Print top border
	for x in range(room_position.x, room_right):
		var floor_map = map.get_noise_2d(x, room_position.y)*10
		# Set tile at (x, room_position.y) to represent the top border
		set_cell(0,Vector2i(x, room_position.y),wall_level,Vector2i(round((floor_map+10)/4),0))

	# Print bottom border
	for x in range(room_position.x, room_right):
		var floor_map = map.get_noise_2d(x, room_position.y)*10
		# Set tile at (x, room_bottom) to represent the bottom border
		set_cell(0,Vector2i(x, room_bottom),wall_level,Vector2i(round((floor_map+10)/4),0))

	# Print left border
	for y in range(room_position.y, room_bottom):
		var floor_map = map.get_noise_2d(room_position.x, y)*10
		# Set tile at (room_position.x, y) to represent the left border
		set_cell(0,Vector2i(room_position.x, y),wall_level,Vector2i(round((floor_map+10)/4),0))

	# Print right border
	for y in range(room_position.y, room_bottom):
		var floor_map = map.get_noise_2d(room_right, y)*10
		# Set tile at (room_right, y) to represent the right border
		set_cell(0,Vector2i(room_right, y),wall_level,Vector2i(round((floor_map+10)/4),0))

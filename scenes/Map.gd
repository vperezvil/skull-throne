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
	
func generate_chunk(room_position, room_size):
	var tile_pos = local_to_map(room_position)
	for x in range(room_size.x):
		for y in range(room_size.y):
			if !get_used_cells(0).has(Vector2i(room_position.x + x, room_position.y + y)):
				var floor_map = map.get_noise_2d(room_position.x + x, room_position.y + y)*10
				set_cell(0,Vector2i(room_position.x+ x, room_position.y + y),level,Vector2i(round((floor_map+10)/1.3),0))

# Assuming `room_position` is the top-left corner of the room and `room_size` is its size
func print_room_border(room_position, room_size):
	var room_right = room_position.x + room_size.x
	var room_bottom = room_position.y + room_size.y

	# Print top border
	for x in range(room_position.x, room_right):
		var floor_map = map.get_noise_2d(x, room_position.y) * 10
		set_cell(0, Vector2i(x, room_position.y), wall_level, Vector2i(round((floor_map + 10) / 5), 0))

	# Print bottom border
	for x in range(room_position.x, room_right):
		var floor_map = map.get_noise_2d(x, room_bottom) * 10
		set_cell(0, Vector2i(x, room_bottom), wall_level, Vector2i(round((floor_map + 10) / 5), 0))

	# Print left border
	for y in range(room_position.y, room_bottom):
		var floor_map = map.get_noise_2d(room_position.x, y) * 10
		if !get_used_cells(0).has(Vector2i(room_position.x, y)):
			set_cell(0, Vector2i(room_position.x, y), wall_level, Vector2i(round((floor_map + 10) / 5), 0))

	# Print right border
	for y in range(room_position.y, room_bottom):
		var floor_map = map.get_noise_2d(room_right - 1, y) * 10
		if !get_used_cells(0).has(Vector2i(room_right - 1, y)):
			set_cell(0, Vector2i(room_right - 1, y), wall_level, Vector2i(round((floor_map + 10) / 5), 0))

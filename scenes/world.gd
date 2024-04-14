extends Node2D

var tilemap = null
var player = null
var boss_room_position = Vector2()

var rooms = []
# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap = $Map
	player = $TinyBones

	# Generate the map layout
	generate_map()

	# Generate player spawn position
	for r in rooms:
		var shape = ShapeCast2D.new() 
		shape.shape = player.get_child(0)
		if !shape.is_colliding():
			player.set_position(r.end / 2)

	# Place boss room
	#place_boss_room()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func generate_map():
	var map_size = tilemap.get_used_rect().size
	var room_min_size = 10
	var room_max_size = 20
	var num_rooms = 1


	# Generate rooms
	for r in range(num_rooms):
		var room_size = Vector2(randi_range(room_min_size, room_max_size), randi_range(room_min_size, room_max_size))
		var room_position = Vector2(randi_range(1, map_size.x - room_size.x - 1), randi_range(1, map_size.y - room_size.y - 1))
		rooms.append(Rect2(room_position, room_size))

		# Place border tiles
		tilemap.print_room_border(room_position, room_size)

		# Place room tiles
		for x in range(room_size.x):
			for y in range(room_size.y):
				tilemap.generate_chunk(room_position + Vector2(x, y), room_size.x, room_size.y)
				
	# Connect rooms with corridors
	#for i in range(rooms.size() - 1):
		#var room_a_center = rooms[i].position + rooms[i].size / 2
		#var room_b_center = rooms[i + 1].position + rooms[i + 1].size / 2
		#connect_rooms(room_a_center, room_b_center)

func connect_rooms(center_a, center_b):
	var delta = center_b - center_a

	while center_a != center_b:
		if abs(delta.x) > abs(delta.y):
			center_a.x += sign(delta.x)
		else:
			center_a.y += sign(delta.y)

		#tilemap.generate_chunk(center_a)

extends Node2D

var tilemap = null
var boss_room_position = Vector2()
var game_state
var room_min_size = 10
var room_max_size = 20
var num_rooms = 5
enum GameState {IDLE, RUNNING, ENDED}
@onready var ui = $ui
signal map_generated
var rooms = []
var characters = []
# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap = $Map
	#Add characters
	characters.append($TinyBones)
	for character in characters:
		character.visible = false
	ui.game_started.connect(game_started)
	

func game_started():
	# Generate the map layout
	generate_map()

	# Generate player spawn position
	spawn_player()
	# Place boss room
	#place_boss_room()
	map_generated.emit()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func generate_map():
	var map_size = Vector2i(100,100)
	# Generate rooms
	for r in range(num_rooms):
		var candidate_room = generate_room(map_size)
		while check_intersect_room(candidate_room):
			candidate_room = generate_room(map_size)
			
					
		rooms.append(candidate_room)	
		# Place border tiles
		tilemap.print_room_border(candidate_room.position,candidate_room.size)

		# Place room tiles
		tilemap.generate_chunk(candidate_room.position, candidate_room.size)
				
	# Connect rooms with corridors
	for i in range(rooms.size() - 1):
		connect_rooms(rooms[i], rooms[i + 1])

func spawn_player():
	# Randomly select a room or select a specific one
	var starting_room = rooms[randi() % rooms.size()]
	for character in characters:
		character.spawn(starting_room, tilemap)
		
func generate_room(map_size):
	var room_size = Vector2(randi_range(room_min_size, room_max_size), randi_range(room_min_size, room_max_size))
	var room_position = Vector2(randi_range(1, map_size.x - room_size.x - 1), randi_range(1, map_size.y - room_size.y - 1))
	return Rect2(room_position, room_size)
func check_intersect_room(candidate_room):
	for room in rooms:
		if candidate_room.intersects(room):
			return true
	return false
func connect_rooms(room_a, room_b):
	var center_a = room_a.position +room_a.size / 2
	var center_b = room_b.position + room_b.size / 2
	# Connect horizontally first, then vertically
	var horizontal_start = Vector2(min(center_a.x, center_b.x), center_a.y)
	var horizontal_end = Vector2(max(center_a.x, center_b.x), center_a.y)
	var vertical_start = Vector2(center_b.x, center_a.y)
	var vertical_end = Vector2(center_b.x, center_b.y)

	# Draw corridor tiles (or set corridor floor cells)
	tilemap.draw_corridor(horizontal_start, horizontal_end)
	tilemap.draw_corridor(vertical_start, vertical_end)

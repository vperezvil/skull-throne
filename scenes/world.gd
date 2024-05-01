extends Node2D

var tilemap = null
var boss_room_position = Vector2()
var game_state
var room_min_size = 10
var room_max_size = 20
var num_rooms = 1
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
	var map_size = tilemap.get_used_rect().size
	# Generate rooms
	for r in range(num_rooms):
		var room_size = Vector2(randi_range(room_min_size, room_max_size), randi_range(room_min_size, room_max_size))
		var room_position = Vector2(randi_range(1, map_size.x - room_size.x - 1), randi_range(1, map_size.y - room_size.y - 1))
		rooms.append(Rect2(room_position, room_size))
		
		# Place border tiles
		tilemap.print_room_border(room_position, room_size)

		# Place room tiles
		tilemap.generate_chunk(room_position, room_size)
				
	# Connect rooms with corridors
	#for i in range(rooms.size() - 1):
		#var room_a_center = rooms[i].position + rooms[i].size / 2
		#var room_b_center = rooms[i + 1].position + rooms[i + 1].size / 2
		#connect_rooms(room_a_center, room_b_center)

func spawn_player():
	# Randomly select a room or select a specific one
	var starting_room = rooms[randi() % rooms.size()]
	for character in characters:
		character.spawn(starting_room, tilemap)
		
func connect_rooms(center_a, center_b):
	var delta = center_b - center_a

	while center_a != center_b:
		if abs(delta.x) > abs(delta.y):
			center_a.x += sign(delta.x)
		else:
			center_a.y += sign(delta.y)

		#tilemap.generate_chunk(center_a)

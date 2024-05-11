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
var path #AStar2D
var starting_room
var boss_room
var boss
@onready var character_dict = {
	0: $Characters/TinyBones,
	1: $Characters/Beth,
	2: $Characters/Dalf,
	3: $Characters/Trece
}
# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap = $Map
	boss = $Enemies/Boss
	ui.game_started.connect(game_started)
	ui.character_added.connect(add_character)
	ui.character_removed.connect(remove_character)
	
func add_character(id):
	#Add characters
	var character = character_dict[id]
	if !characters.has(character):
		characters.append(character)

func remove_character(id):
	#Remove characters
	var character = character_dict[id]
	if characters.has(character):
		characters.erase(character)

func game_started():
	# Generate the map layout
	generate_map()

	# Generate player spawn position
	spawn_player()
	spawn_boss()
	# Place boss room
	#place_boss_room()
	map_generated.emit()

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
	path = find_mst()
	var connections_visited = []
	if path:
		for p in path.get_point_ids():
			for c in path.get_point_connections(p):
				var pp = path.get_point_position(p)
				var cp = path.get_point_position(c)
				if !connections_visited.has(c):
					connect_rooms(pp,cp)
			connections_visited.append(p)

func spawn_player():
	# Randomly select a room or select a specific one
	starting_room = rooms[randi() % rooms.size()]
	# Remove unneeded character nodes
	for key in character_dict:
		var character = character_dict[key]
		if !characters.has(character):
			character.queue_free()
	characters[0].spawn(starting_room, tilemap)
	characters[0].get_node("Camera2D").visible = true
		
func spawn_boss():
	boss_room = find_boss_room()
	boss.spawn(boss_room, tilemap)
		
func generate_room(map_size):
	var room_size = Vector2(randi_range(room_min_size, room_max_size), randi_range(room_min_size, room_max_size))
	var room_position = Vector2(randi_range(1, map_size.x - room_size.x - 1), randi_range(1, map_size.y - room_size.y - 1))
	return Rect2(room_position, room_size)
	
func check_intersect_room(candidate_room):
	for room in rooms:
		if candidate_room.intersects(room):
			return true
	return false
	
func find_mst():
	var nodes = rooms.duplicate()
	#Prim's algorithmn
	var path = AStar2D.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front().get_center())
	while nodes:
		var min_dist = INF #Minimum distance
		var min_p = null # Position of that node
		var p = null # Current node
		for p1_id in path.get_point_ids():
			var p1 = path.get_point_position(p1_id)
			for p2 in nodes:
				if p1.distance_to(p2.get_center())<min_dist:
					min_dist = p1.distance_to(p2.get_center())
					min_p = p2
					p = p1
		var n = path.get_available_point_id()
		path.add_point(n, min_p.get_center())
		path.connect_points(path.get_closest_point(p),n)
		nodes.erase(min_p)
	return path

func connect_rooms(center_a, center_b):
	# Connect horizontally first, then vertically
	var horizontal_start = Vector2(min(center_a.x, center_b.x), center_a.y)
	var horizontal_end = Vector2(max(center_a.x, center_b.x), center_a.y)
	var vertical_start = Vector2(center_b.x, center_a.y)
	var vertical_end = Vector2(center_b.x, center_b.y)

	# Draw corridor tiles (or set corridor floor cells)
	tilemap.draw_corridor(horizontal_start, horizontal_end)
	tilemap.draw_corridor(vertical_start, vertical_end)
	
func find_boss_room():
	var nodes = rooms.duplicate()
	nodes.erase(starting_room)
	var start_position = starting_room.get_center()
	var max_p = null # Position of the node with max distance
	var max_dist = 0 #Maximum distance
	for p1_id in path.get_point_ids():
		var p1 = path.get_point_position(p1_id)
		if p1 != start_position and p1.distance_to(start_position)>max_dist:
			max_dist = p1.distance_to(start_position)
			max_p = p1
	return max_p

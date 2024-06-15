extends Node2D

var tilemap = null
var boss_room_position = Vector2()
var game_state
var room_min_size = 10
var room_max_size = 20
var num_rooms = 15
var enemies_total = 15
enum GameState {IDLE, RUNNING, ENDED}
@onready var ui = $ui
@onready var battle_scene = $Battle
@onready var enemy_node = $Enemies
@onready var items_node = $Objects/Items
signal map_generated
signal paused_game
var rooms = []
var characters = []
var enemies = []
var walkable_tiles = []
var items = []
var path #AStar2D
var starting_room
var boss_room
var fountain_room
var boss
var enemy1
var enemy2
var fountain
@onready var map_music = $"Map Theme"
@onready var character_dict = {
	0: $Characters/TinyBones,
	1: $Characters/Beth,
	2: $Characters/Dalf,
	3: $Characters/Trece
}
@onready var items_dict = {
	0: $Objects/Items/Potion,
	1: $Objects/Items/Sword
}
# Called when the node enters the scene tree for the first time.
func _ready():
	tilemap = $Map
	boss = $"Enemies/Evil Geanie Boss"
	enemy1 = $"Enemies/Rock Troll Enemy"
	enemy2 = $"Enemies/Rock Troll Enemy Variant"
	fountain = $"Objects/Healing Fountain"
	ui.game_started.connect(game_started)
	ui.character_added.connect(add_character)
	ui.character_removed.connect(remove_character)
	ui.restart_game.connect(restart_game)
	battle_scene.battle_ended.connect(end_battle)
	battle_scene.inventory_pressed.connect(battle_inventory_pressed)


func _process(delta):
	read_input()
		
func read_input():
	var map_is_rendered =  map_music.playing
	var game_is_paused = ui.game_menu.visible == true
	var esc_pressed = Input.is_action_just_pressed("ui_cancel")
	if esc_pressed and map_is_rendered and !game_is_paused:
		tilemap.get_tree().paused = true
		characters[0].get_tree().paused = true
		paused_game.emit(true, characters)
	elif esc_pressed and game_is_paused:
		resume_paused_game()
	elif esc_pressed and ui.in_battle and game_is_paused:
		resume_paused_game()

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
	spawn_fountain()
	collect_walkable_tiles()
	spawn_enemies()
	spawn_items()
	map_generated.emit()
	map_music.play()

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
	# Randomly select a room
	starting_room = rooms[randi() % rooms.size()]
	# Remove unneeded character nodes
	for key in character_dict:
		var character = character_dict[key]
		if !characters.has(character):
			character.queue_free()
	characters[0].spawn(starting_room, tilemap)
	characters[0].boss_battle_start.connect(start_boss_battle)
	characters[0].enemy_battle_start.connect(start_battle)
	characters[0].item_picked.connect(item_picked)
	characters[0].get_node("Camera2D").make_current()
		
func spawn_boss():
	boss_room = find_boss_room()
	boss.spawn(boss_room, tilemap)

func collect_walkable_tiles():
	walkable_tiles = tilemap.get_used_cells_by_id(0, tilemap.level)
	# Remove tiles in the starting room, fountain room and boss room
	for x in range(starting_room.position.x, starting_room.position.x + starting_room.size.x):
		for y in range(starting_room.position.y, starting_room.position.y + starting_room.size.y):
			var tile = Vector2i(x, y)
			walkable_tiles.erase(tile)
			
	for x in range(fountain_room.position.x, fountain_room.position.x + fountain_room.size.x):
		for y in range(fountain_room.position.y, fountain_room.position.y + fountain_room.size.y):
			var tile = Vector2i(x, y)
			walkable_tiles.erase(tile)
	
	for x in range(boss_room.x - room_max_size / 2, boss_room.x + room_max_size / 2):
		for y in range(boss_room.y - room_max_size / 2, boss_room.y + room_max_size / 2):
			var tile = Vector2i(x, y)
			walkable_tiles.erase(tile)

func spawn_enemies():
	for i in range(enemies_total):
		if walkable_tiles.size() == 0:
			break  # No more walkable tiles available to spawn enemies

		var index = randi() % (walkable_tiles.size() - 1)
		var spawn_position = walkable_tiles[index]
		walkable_tiles.erase(index)  # Remove the tile to avoid multiple enemies in the same spot

		# Randomly select an enemy type
		var enemy
		var random_num = randi() % 2 
		if random_num == 0:
			enemy = enemy1.duplicate()
			enemy.name = enemy1.name + " " + str(i)
		else:
			enemy = enemy2.duplicate()
			enemy.name = enemy2.name + " " + str(i)
		enemy_node.add_child(enemy)
		enemy.request_ready()
		enemy.spawn(spawn_position, tilemap, characters[0])
		enemy.enemy_battle_start.connect(start_battle)
		enemies.append(enemy)

func spawn_fountain():
	# Randomly select a room
	fountain_room = rooms[randi() % rooms.size()]
	if fountain_room != starting_room and fountain_room.get_center() != boss_room_position:
		fountain.spawn(fountain_room, tilemap, characters)
	else:
		spawn_fountain()

func spawn_items():
	# Randomly select how many items are spawned, we want at least 3
	var total_items = randi_range(3,items_dict.size())
	for i in range(total_items):
		if walkable_tiles.size() == 0:
			break  # No more walkable tiles available to spawn enemies

		var index = randi() % (walkable_tiles.size() - 1)
		var spawn_position = walkable_tiles[index]
		walkable_tiles.erase(index)  # Remove the tile to avoid multiple enemies in the same spot

		# Randomly select an item
		var random_num = randi() % items_dict.size()
		var item = items_dict[random_num].duplicate()
		item.name = items_dict[random_num].name + " " + str(i)
		items_node.add_child(item)
		item.request_ready()
		item.spawn(spawn_position, tilemap)
		items.append(item)
		
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

func start_boss_battle():
	ui.in_battle = true
	map_music.stop()
	boss.battle_started = true
	for character in characters:
		character.battle_started = true
	for item in items:
		item.visible = false	
	for e in enemies:
		if !e.battle_started:
			e.visible = false
			e.is_chasing = false
	fountain.visible = false
	battle_scene.start_battle(characters,[boss])
	battle_scene.visible = true
	tilemap.visible = false

func start_battle(enemy):
	ui.in_battle = true
	map_music.stop()
	boss.visible = false
	enemy.battle_started = true
	fountain.visible = false
	var enemies_to_battle = [enemy]
	var num_enemies = randi() % 2 + 1
	for i in range(num_enemies):
		var dup_enemy = enemy.duplicate()
		dup_enemy.name = enemy.name + " ("+str(i)+ ") "
		enemy_node.add_child(dup_enemy)
		dup_enemy.request_ready()
		dup_enemy.spawn(enemy.position, tilemap, characters[0])
		dup_enemy.battle_started = true
		enemies_to_battle.append(dup_enemy)
	for character in characters:
		character.battle_started = true
	for item in items:
		item.visible = false
	for e in enemies:
		if !e.battle_started:
			e.visible = false
			e.is_chasing = false
	battle_scene.start_battle(characters,enemies_to_battle)
	battle_scene.visible = true
	tilemap.visible = false

func end_battle(remaining_characters):
	ui.in_battle = false
	map_music.play()
	battle_scene.visible = false
	tilemap.visible = true
	characters = remaining_characters
	for character in characters:
		character.ap.stop()
		character.battle_started = false
		character.progress_bar.visible = false
	var main_character = characters[0]
	main_character.visible = true
	fountain.players = characters
	fountain.visible = true
	if boss.battle_started:
		boss.visible = false
		boss.battle_started = false
	else:
		boss.visible = true
	for e in enemies:
		if !e.battle_started:
			e.visible = true
			e.player = main_character
	for item in items:
		item.visible = true
	if main_character.has_node("Camera2D"):
		var camera = main_character.get_node("Camera2D")
		camera.enabled = true
		camera.make_current()
	resume_paused_game()

func restart_game():
	Inventory.items.clear()
	get_tree().reload_current_scene()

func item_picked(item):
	Inventory.add_item(item)
	item.visible = false
	item.collider.disabled = true
	items.erase(item)


func resume_paused_game():
	paused_game.emit(false)
	tilemap.get_tree().paused = false
	characters[0].get_tree().paused = false
	battle_scene.get_tree().paused = false

func battle_inventory_pressed():
	ui.characters = characters
	battle_scene.get_tree().paused = true
	ui._on_inventory_pressed()	

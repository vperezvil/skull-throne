extends Node2D

var tilemap = null
var game_state
var room_min_size = GameConstants.ROOM_MIN_SIZE
var room_max_size = GameConstants.ROOM_MAX_SIZE
var num_rooms = GameConstants.NUM_ROOMS
var enemies_total = GameConstants.ENEMIES_TOTAL
var current_zone: ZoneDefinition
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
var enemy_templates: Array[Enemy] = []
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

const PARTY_FOLLOW_OFFSETS := [
	Vector2.ZERO,
	Vector2(36, 0),
	Vector2(-36, 0),
	Vector2(0, 36),
]

func _ready():
	tilemap = $Map
	boss = $"Enemies/Evil Geanie Boss"
	enemy_templates = [
		$"Enemies/Rock Troll Enemy" as Enemy,
		$"Enemies/Rock Troll Enemy Variant" as Enemy,
	]
	fountain = $"Objects/Healing Fountain"
	ui.game_started.connect(_on_game_started)
	ui.character_added.connect(add_character)
	ui.character_removed.connect(remove_character)
	ui.restart_game.connect(restart_game)
	battle_scene.battle_ended.connect(end_battle)
	battle_scene.battle_fled.connect(end_battle)
	battle_scene.inventory_pressed.connect(battle_inventory_pressed)

func _process(_delta):
	read_input()

func read_input():
	if characters.is_empty():
		return
	var map_is_rendered = map_music.playing
	var game_is_paused = ui.game_menu.visible
	var esc_pressed = Input.is_action_just_pressed("ui_cancel")
	if !esc_pressed:
		return
	if game_is_paused:
		resume_paused_game()
	elif map_is_rendered or ui.in_battle:
		get_tree().paused = true
		paused_game.emit(true, characters)

func add_character(id: int) -> void:
	var character: Character = character_dict[id]
	var definition := ContentRegistry.get_character_for_menu_index(id)
	if definition != null:
		character.apply_definition(definition)
	if !characters.has(character):
		characters.append(character)

func remove_character(id: int) -> void:
	var character = character_dict[id]
	if characters.has(character):
		characters.erase(character)

func _on_game_started() -> void:
	RunState.begin_campaign()
	start_zone_run()

func start_zone_run() -> void:
	_apply_zone_config()
	generate_map()
	spawn_player()
	spawn_boss()
	spawn_fountain()
	collect_walkable_tiles()
	spawn_enemies()
	spawn_items()
	map_generated.emit()
	map_music.play()
	tilemap.visible = true

func advance_to_next_zone() -> void:
	if !RunState.has_more_zones():
		return
	RunState.advance_zone()
	_cleanup_zone_entities()
	start_zone_run()

func _apply_zone_config() -> void:
	current_zone = ContentRegistry.get_zone(RunState.current_zone_index)
	tilemap.apply_zone(current_zone)
	num_rooms = current_zone.num_rooms
	enemies_total = current_zone.enemy_count
	if current_zone.map_music:
		map_music.stream = current_zone.map_music
	ui.set_zone_title(current_zone.display_name)

func _cleanup_zone_entities() -> void:
	tilemap.clear_map()
	rooms.clear()
	walkable_tiles.clear()
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	for item in items:
		if is_instance_valid(item):
			item.queue_free()
	items.clear()
	boss.battle_started = false
	boss.visible = false
	fountain.visible = false

func generate_map():
	var map_size = GameConstants.MAP_SIZE
	for r in range(num_rooms):
		var candidate_room = generate_room(map_size)
		while check_intersect_room(candidate_room):
			candidate_room = generate_room(map_size)
		rooms.append(candidate_room)
		tilemap.print_room_border(candidate_room.position, candidate_room.size)
		tilemap.generate_chunk(candidate_room.position, candidate_room.size)
	path = find_mst()
	var connections_visited = []
	if path:
		for p in path.get_point_ids():
			for c in path.get_point_connections(p):
				var pp = path.get_point_position(p)
				var cp = path.get_point_position(c)
				if !connections_visited.has(c):
					connect_rooms(pp, cp)
			connections_visited.append(p)

func spawn_player():
	if characters.is_empty():
		push_error("No characters selected for the run.")
		return
	starting_room = rooms[randi() % rooms.size()]
	for key in character_dict:
		var character = character_dict[key]
		if !characters.has(character) and is_instance_valid(character):
			character.queue_free()
	for i in range(characters.size()):
		var member: Character = characters[i]
		member.is_party_leader = i == 0
		if i == 0:
			member.spawn(starting_room, tilemap)
			_wire_party_leader(member)
		else:
			var offset := PARTY_FOLLOW_OFFSETS[mini(i, PARTY_FOLLOW_OFFSETS.size() - 1)]
			member.spawn_as_follower(starting_room, tilemap, characters[0], offset)
		member.battle_started = false
		_update_overworld_visibility(member)

func _wire_party_leader(lead: Character) -> void:
	if !lead.boss_battle_start.is_connected(start_boss_battle):
		lead.boss_battle_start.connect(start_boss_battle)
	if !lead.enemy_battle_start.is_connected(start_battle):
		lead.enemy_battle_start.connect(start_battle)
	if !lead.item_picked.is_connected(item_picked):
		lead.item_picked.connect(item_picked)
	if lead.has_node("Camera2D"):
		lead.get_node("Camera2D").make_current()

func _get_party_leader() -> Character:
	for member in characters:
		if member.is_party_leader and member.current_hp > 0:
			return member
	return null

func _reassign_party_leadership() -> void:
	var leader: Character = null
	for member in characters:
		if member.current_hp > 0:
			leader = member
			break
	if leader == null:
		return
	characters.erase(leader)
	characters.insert(0, leader)
	for i in range(characters.size()):
		var member := characters[i]
		member.is_party_leader = member == leader
		if member.is_party_leader:
			member.follow_target = null
			member.follow_offset = Vector2.ZERO
		else:
			member.follow_target = leader
			member.follow_offset = PARTY_FOLLOW_OFFSETS[mini(i, PARTY_FOLLOW_OFFSETS.size() - 1)]
		member._configure_party_collision()
		_update_overworld_visibility(member)
	_wire_party_leader(leader)

func _update_overworld_visibility(member: Character) -> void:
	if ui.in_battle:
		member.visible = member.current_hp > 0
		return
	member.visible = member.is_party_leader and member.current_hp > 0
	if member.follow_target != null:
		member.position = member.follow_target.position + member.follow_offset

func spawn_boss():
	boss_room = find_boss_room()
	boss.spawn(boss_room, tilemap)

func collect_walkable_tiles():
	walkable_tiles = tilemap.get_used_cells_by_id(0, tilemap.level)
	SpawnHelpers.erase_tiles_in_rect(walkable_tiles, starting_room)
	SpawnHelpers.erase_tiles_in_rect(walkable_tiles, fountain_room)
	SpawnHelpers.erase_tiles_in_rect(walkable_tiles, boss_room)

func spawn_enemies():
	var sources: Array = current_zone.enemy_scenes if current_zone.enemy_scenes.size() > 0 else enemy_templates
	for i in range(enemies_total):
		var spawn_position = SpawnHelpers.take_random_tile(walkable_tiles)
		if spawn_position == null:
			break
		var source = sources[randi() % sources.size()]
		var enemy: Enemy
		if source is PackedScene:
			enemy = (source as PackedScene).instantiate() as Enemy
		else:
			enemy = (source as Enemy).duplicate() as Enemy
		enemy.name = "Enemy %s" % str(i)
		enemy_node.add_child(enemy)
		enemy.request_ready()
		enemy.spawn(spawn_position, tilemap, characters[0])
		enemy.enemy_battle_start.connect(start_battle)
		enemies.append(enemy)

func spawn_fountain():
	fountain_room = rooms[randi() % rooms.size()]
	if fountain_room == starting_room or fountain_room == boss_room:
		spawn_fountain()
		return
	fountain.spawn(fountain_room, tilemap, characters)

func spawn_items():
	var max_items := mini(GameConstants.ITEMS_MAX_SPAWN, items_dict.size())
	var total_items := randi_range(GameConstants.ITEMS_MIN_SPAWN, max_items)
	for i in range(total_items):
		var spawn_position = SpawnHelpers.take_random_tile(walkable_tiles)
		if spawn_position == null:
			break
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
	var path = AStar2D.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front().get_center())
	while nodes:
		var min_dist = INF
		var min_p = null
		var p = null
		for p1_id in path.get_point_ids():
			var p1 = path.get_point_position(p1_id)
			for p2 in nodes:
				if p1.distance_to(p2.get_center()) < min_dist:
					min_dist = p1.distance_to(p2.get_center())
					min_p = p2
					p = p1
		var n = path.get_available_point_id()
		path.add_point(n, min_p.get_center())
		path.connect_points(path.get_closest_point(p), n)
		nodes.erase(min_p)
	return path

func connect_rooms(center_a, center_b):
	var horizontal_start = Vector2(min(center_a.x, center_b.x), center_a.y)
	var horizontal_end = Vector2(max(center_a.x, center_b.x), center_a.y)
	var vertical_start = Vector2(center_b.x, center_a.y)
	var vertical_end = Vector2(center_b.x, center_b.y)
	tilemap.draw_corridor(horizontal_start, horizontal_end)
	tilemap.draw_corridor(vertical_start, vertical_end)

func find_boss_room() -> Rect2:
	var start_position := starting_room.get_center()
	var farthest_room: Rect2 = starting_room
	var max_dist := 0.0
	for room in rooms:
		if room == starting_room:
			continue
		var dist := room.get_center().distance_to(start_position)
		if dist > max_dist:
			max_dist = dist
			farthest_room = room
	return farthest_room

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
	battle_scene.start_battle(characters, [boss])
	battle_scene.visible = true
	tilemap.visible = false

func start_battle(enemy):
	ui.in_battle = true
	map_music.stop()
	boss.visible = false
	enemy.battle_started = true
	fountain.visible = false
	var enemies_to_battle = [enemy]
	var extra_count := randi() % 2 + 1
	for i in range(extra_count):
		var dup_enemy: Enemy = enemy.duplicate()
		dup_enemy.name = enemy.name + " (" + str(i) + ")"
		dup_enemy.set_meta("battle_spawn", true)
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
	battle_scene.start_battle(characters, enemies_to_battle)
	battle_scene.visible = true
	tilemap.visible = false

func end_battle(remaining_characters):
	ui.in_battle = false
	map_music.play()
	battle_scene.visible = false
	tilemap.visible = true
	_cleanup_battle_spawned_enemies()
	characters = remaining_characters
	if characters.is_empty():
		return
	for character in characters:
		character.ap.stop()
		character.battle_started = false
		character.progress_bar.visible = false
	_reassign_party_leadership()
	var main_character := _get_party_leader()
	if main_character == null:
		return
	fountain.players = characters
	fountain.visible = true
	if boss.battle_started:
		boss.visible = false
		boss.battle_started = false
	else:
		boss.visible = true
	_prune_defeated_enemies()
	for e in enemies:
		if is_instance_valid(e) and !e.battle_started:
			e.visible = true
			e.player = main_character
	for item in items:
		item.visible = true
	if main_character.has_node("Camera2D"):
		var camera = main_character.get_node("Camera2D")
		camera.enabled = true
		camera.make_current()
	resume_paused_game()

func _prune_defeated_enemies() -> void:
	var survivors: Array = []
	for e in enemies:
		if is_instance_valid(e):
			if e.battle_started:
				e.queue_free()
			else:
				e.battle_started = false
				survivors.append(e)
	enemies = survivors

func restart_game():
	Inventory.items.clear()
	RunState.reset_campaign()
	get_tree().reload_current_scene()

func item_picked(item):
	Inventory.add_item(item)
	item.visible = false
	item.collider.disabled = true
	items.erase(item)

func resume_paused_game():
	paused_game.emit(false)
	get_tree().paused = false

func _cleanup_battle_spawned_enemies() -> void:
	for child in enemy_node.get_children():
		if child.get_meta("battle_spawn", false):
			child.queue_free()

func battle_inventory_pressed():
	ui.characters = characters
	get_tree().paused = true
	ui._on_inventory_pressed()

func on_zone_cleared(remaining_characters: Array) -> void:
	characters = remaining_characters
	if characters.is_empty():
		return
	for character in characters:
		character.battle_started = true
		character.progress_bar.visible = false
		character.visible = character.current_hp > 0
	_reassign_party_leadership()
	ui.in_battle = false
	battle_scene.visible = false
	tilemap.visible = false
	map_music.stop()
	fountain.visible = false
	for item in items:
		item.visible = false
	for e in enemies:
		if is_instance_valid(e):
			e.visible = false
			e.is_chasing = false
	boss.visible = false
	boss.battle_started = false
	RunState.record_zone_cleared()
	ui.show_zone_cleared(characters, not RunState.has_more_zones())

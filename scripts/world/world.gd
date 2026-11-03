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
var treasure_caches: Array = []
var map_events: Array = []
var path #AStar2D
var starting_room
var boss_room
var fountain_room
var boss
var zone_decor: Node2D
var enemy_templates: Array[Enemy] = []
var fountain
@onready var map_music = $"Map Theme"
var _map_music_normal_db := 0.0
const MAP_MUSIC_DUCK_DB := -16.0
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
	zone_decor = Node2D.new()
	zone_decor.name = "ZoneDecor"
	add_child(zone_decor)
	enemy_templates = [
		$"Enemies/Rock Troll Enemy" as Enemy,
		$"Enemies/Rock Troll Enemy Variant" as Enemy,
	]
	fountain = $"Objects/Healing Fountain"
	ui.game_started.connect(_on_game_started)
	ui.character_added.connect(add_character)
	ui.character_removed.connect(remove_character)
	ui.return_to_hub.connect(return_to_hub)
	ui.continue_waystation.connect(advance_to_next_zone)
	battle_scene.battle_ended.connect(end_battle)
	battle_scene.battle_fled.connect(end_battle)
	battle_scene.inventory_pressed.connect(battle_inventory_pressed)
	Global.assign_music_bus(map_music)
	_map_music_normal_db = map_music.volume_db
	tilemap.visible = false

func _process(_delta):
	read_input()
	_update_party_hud()

func _update_party_hud() -> void:
	if ui == null:
		return
	var show_hud := (
		RunState.campaign_active
		and !ui.hub_panel.visible
		and !ui.waystation_panel.visible
		and !ui.in_battle
		and (ui.shrine_panel == null or !ui.shrine_panel.visible)
		and tilemap.visible
	)
	ui.update_party_hud(characters, show_hud)

func read_input():
	if characters.is_empty():
		return
	var map_is_rendered = map_music.playing
	var game_is_paused = ui.game_menu.visible
	var esc_pressed = Input.is_action_just_pressed("ui_cancel")
	if !esc_pressed:
		return
	if game_is_paused:
		if ui.settings_open:
			ui._on_settings_back_pressed()
		else:
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
	RunState.roll_party_stats(characters)
	for member in characters:
		if member is Character:
			member.stress = 0
			var def := ContentRegistry.get_character_by_id(member.character_id)
			if def != null:
				member.apply_definition(def)
			MetaProgress.apply_meta_to_character(member)
			member.apply_run_equipment()
			var init_bonus := RunModifiers.party_initiative_bonus(RunState.run_modifier_id)
			if init_bonus > 0:
				member.initiative = clampi(member.initiative + init_bonus, 1, 100)
	MetaProgress.grant_run_start_supplies()
	RunState.snapshot_party_progress(characters)
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
	spawn_treasure_caches()
	spawn_map_events()
	map_generated.emit()
	map_music.play()
	tilemap.visible = true

func advance_to_next_zone() -> void:
	if !RunState.has_more_floors():
		return
	RunState.advance_floor()
	_cleanup_zone_entities()
	start_zone_run()

func _apply_zone_config() -> void:
	current_zone = RunState.get_current_zone()
	tilemap.apply_zone(current_zone)
	var depth := RunState.get_run_depth()
	num_rooms = current_zone.num_rooms + depth
	enemies_total = current_zone.enemy_count + depth * 2
	if current_zone != null:
		var next_stream := ZoneMusic.get_overworld_music_for_zone(current_zone)
		if map_music.stream != next_stream:
			ZoneMusic.apply_to_player(map_music, next_stream, _map_music_normal_db)
	ui.set_zone_title(current_zone.display_name)

func _cleanup_zone_entities() -> void:
	tilemap.clear_map()
	_clear_zone_decor()
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
	for cache in treasure_caches:
		if is_instance_valid(cache):
			cache.queue_free()
	treasure_caches.clear()
	for ev in map_events:
		if is_instance_valid(ev):
			ev.queue_free()
	map_events.clear()
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

func _sync_enemy_chase_targets() -> void:
	var leader := _get_party_leader()
	for e in enemies:
		if is_instance_valid(e) and e is Enemy:
			e.set_chase_target(leader)

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
	_sync_enemy_chase_targets()

func _update_overworld_visibility(member: Character) -> void:
	if ui.in_battle:
		member.visible = member.current_hp > 0
		return
	member.visible = member.is_party_leader and member.current_hp > 0
	if member.follow_target != null:
		member.position = member.follow_target.position + member.follow_offset

func spawn_boss():
	boss_room = find_boss_room()
	if current_zone != null and current_zone.build_skull_throne_arena:
		tilemap.stamp_throne_arena(boss_room)
		_build_skull_throne_arena(boss_room)
	boss.configure_for_zone(current_zone)
	boss.spawn(boss_room, tilemap)

func _clear_zone_decor() -> void:
	if zone_decor == null:
		return
	for child in zone_decor.get_children():
		child.queue_free()

func _build_skull_throne_arena(room: Rect2) -> void:
	_clear_zone_decor()
	var center := tilemap.map_to_local(room.get_center())
	var props := [
		{"path": "res://assets/map/dngn_blood_fountain.png", "offset": Vector2(-96, -64), "scale": 2.0},
		{"path": "res://assets/map/dngn_blood_fountain2.png", "offset": Vector2(96, -64), "scale": 2.0},
		{"path": "res://assets/map/altars/dngn_altar.png", "offset": Vector2(0, -120), "scale": 2.5},
		{"path": "res://assets/map/dngn_orcish_idol.png", "offset": Vector2(-160, 32), "scale": 2.0},
		{"path": "res://assets/map/dngn_orcish_idol.png", "offset": Vector2(160, 32), "scale": 2.0},
	]
	for prop in props:
		var sprite := Sprite2D.new()
		sprite.texture = load(prop["path"])
		sprite.position = center + prop["offset"]
		sprite.scale = Vector2.ONE * prop["scale"]
		sprite.z_index = 1
		zone_decor.add_child(sprite)
	_spawn_throne_skulls(center)

func _spawn_throne_skulls(arena_center: Vector2) -> void:
	var skull_count := Global.get_skull_count()
	if skull_count <= 0:
		return
	var texture: Texture2D = load("res://assets/monsters/undead/flying_skull.png")
	if texture == null:
		return
	const MAX_SKULL_SPRITES := 40
	var visible_count := mini(skull_count, MAX_SKULL_SPRITES)
	for i in visible_count:
		var skull := Sprite2D.new()
		skull.texture = texture
		var ring := 1 + (i % 3)
		var angle := TAU * float(i) / float(visible_count)
		var radius := 72.0 + ring * 28.0
		skull.position = arena_center + Vector2(cos(angle), sin(angle)) * radius
		skull.scale = Vector2(1.4, 1.4)
		skull.modulate = _throne_skull_tint()
		skull.z_index = 2
		zone_decor.add_child(skull)
	if skull_count > MAX_SKULL_SPRITES:
		var overflow := Label.new()
		overflow.text = "+%d more skulls" % (skull_count - MAX_SKULL_SPRITES)
		overflow.position = arena_center + Vector2(-80, 96)
		overflow.add_theme_font_size_override("font_size", 22)
		overflow.modulate = Color(1.0, 0.75, 0.7)
		overflow.z_index = 3
		zone_decor.add_child(overflow)

func _throne_skull_tint() -> Color:
	if current_zone == null:
		return Color(0.92, 0.88, 0.88, 0.95)
	match current_zone.map_theme_id:
		"blood_cathedral":
			return Color(1.0, 0.75, 0.75, 0.95)
		"ice_citadel":
			return Color(0.8, 0.9, 1.0, 0.95)
		"swamp_mire":
			return Color(0.75, 0.95, 0.75, 0.95)
		_:
			return Color(0.92, 0.88, 0.88, 0.95)

func collect_walkable_tiles():
	walkable_tiles = tilemap.get_used_cells_by_id(0, tilemap.level)
	SpawnHelpers.erase_tiles_in_rect(walkable_tiles, starting_room)
	SpawnHelpers.erase_tiles_in_rect(walkable_tiles, fountain_room)
	SpawnHelpers.erase_tiles_in_rect(walkable_tiles, boss_room)

func spawn_enemies():
	var spawn_ids: Array = current_zone.enemy_spawn_ids
	for i in range(enemies_total):
		var spawn_position = SpawnHelpers.take_random_tile(walkable_tiles)
		if spawn_position == null:
			break
		var enemy: Enemy
		if spawn_ids.size() > 0:
			var pick_id: String = spawn_ids[randi() % spawn_ids.size()]
			enemy = ContentRegistry.spawn_enemy_from_id(pick_id)
			if enemy == null:
				continue
			if enemy is ConfigurableEnemy:
				var cfg := enemy as ConfigurableEnemy
				cfg.apply_run_scaling(RunState.get_run_depth())
				var elite_roll := GameConstants.ELITE_SPAWN_CHANCE + RunState.get_run_depth() * 0.015
				elite_roll += RunModifiers.elite_chance_bonus(RunState.run_modifier_id)
				elite_roll += RunModifiers.ascended_elite_chance_bonus(RunState.ascended_run)
				if randf() < elite_roll:
					cfg.mark_elite()
		else:
			var template: Enemy = enemy_templates[randi() % enemy_templates.size()]
			enemy = template.duplicate() as Enemy
		enemy.name = enemy.name + " " + str(i)
		enemy_node.add_child(enemy)
		enemy.request_ready()
		enemy.spawn(spawn_position, tilemap, _get_party_leader())
		enemy.enemy_battle_start.connect(start_battle)
		enemies.append(enemy)
	_sync_enemy_chase_targets()

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

func spawn_treasure_caches() -> void:
	var count := RunModifiers.extra_cache_count(RunState.run_modifier_id)
	for _i in range(count):
		var spawn_position = SpawnHelpers.take_random_tile(walkable_tiles)
		if spawn_position == null:
			break
		var cache := TreasureCache.new()
		items_node.add_child(cache)
		var gold := 12 + RunState.get_run_depth() * 4 + randi_range(0, 10)
		cache.setup(tilemap, spawn_position, gold)
		treasure_caches.append(cache)

func spawn_map_events() -> void:
	var count := GameConstants.MAP_EVENTS_PER_FLOOR + RunState.get_run_depth() / 3
	if RunState.ascended_run:
		count += 1
	for _i in range(count):
		var spawn_position = SpawnHelpers.take_random_tile(walkable_tiles)
		if spawn_position == null:
			break
		var event_id := MapEventHandler.roll_event_id()
		var event := MapEvent.new()
		event.event_id = event_id
		items_node.add_child(event)
		event.setup(tilemap, spawn_position, event_id)
		event.triggered.connect(_on_map_event_triggered)
		map_events.append(event)

func _on_map_event_triggered(event_id: String) -> void:
	var msg := MapEventHandler.resolve(event_id, self, characters)
	if msg != "":
		ui.show_map_toast(msg)

func start_map_ambush() -> void:
	if characters.is_empty():
		return
	ui.in_battle = true
	_duck_map_music()
	_prepare_party_for_combat()
	var foes: Array = []
	for _i in range(2):
		var pick_id: String = ["harpy", "dwarf", "deep_elf_soldier"][randi() % 3]
		var foe = ContentRegistry.spawn_enemy_from_id(pick_id)
		if foe == null:
			continue
		enemy_node.add_child(foe)
		foe.request_ready()
		if foe is ConfigurableEnemy:
			var cfg := foe as ConfigurableEnemy
			cfg.apply_run_scaling(RunState.get_run_depth())
			if randf() < GameConstants.ELITE_SPAWN_CHANCE:
				cfg.mark_elite()
		foes.append(foe)
	if foes.is_empty():
		ui.in_battle = false
		_restore_map_music_volume()
		return
	for item in items:
		item.visible = false
	fountain.visible = false
	battle_scene.start_battle(characters, foes)
	battle_scene.visible = true
	tilemap.visible = false

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

func _duck_map_music() -> void:
	if !map_music.playing:
		map_music.play()
	var tween := create_tween()
	tween.tween_property(map_music, "volume_db", _map_music_normal_db + MAP_MUSIC_DUCK_DB, 0.35)

func _restore_map_music_volume() -> void:
	var tween := create_tween()
	tween.tween_property(map_music, "volume_db", _map_music_normal_db, 0.5)

func _prepare_party_for_combat() -> void:
	for character in characters:
		if character is Character:
			character.apply_blessing_bonuses()
			character.refresh_skills_from_training()
			character.apply_run_equipment()
		character.battle_started = true

func start_boss_battle():
	ui.in_battle = true
	_duck_map_music()
	boss.battle_started = true
	_prepare_party_for_combat()
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
	_duck_map_music()
	boss.visible = false
	_prepare_party_for_combat()
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
		dup_enemy.spawn(enemy.position, tilemap, _get_party_leader())
		dup_enemy.battle_started = true
		enemies_to_battle.append(dup_enemy)
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
	_restore_map_music_volume()
	if !map_music.playing:
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
		character.hide_battle_bars()
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
			e.is_chasing = false
			if e is Enemy:
				e.set_chase_target(main_character)
	for item in items:
		item.visible = true
	if main_character.has_node("Camera2D"):
		var camera = main_character.get_node("Camera2D")
		camera.enabled = true
		camera.make_current()
	if current_zone != null:
		ui.set_zone_title(current_zone.display_name)
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

func return_to_hub(victory: bool, voluntary_abandon: bool = false) -> void:
	resume_paused_game()
	var payload := RunDirector.build_end_payload(self, victory, voluntary_abandon)
	RunDirector.apply_hub_return(self, payload)

func abandon_run() -> void:
	return_to_hub(false, true)

func _refresh_party_at_hub() -> void:
	for member in characters:
		if member is Character:
			var def := ContentRegistry.get_character_by_id(member.character_id)
			if def != null:
				member.apply_definition(def)
			MetaProgress.apply_meta_to_character(member)
			member.apply_run_equipment()
			member.battle_started = false
			member.visible = false
			member.hide_battle_bars()
			member.follow_target = null
			member.is_party_leader = false
			if member.has_node("Camera2D"):
				member.get_node("Camera2D").enabled = false

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
	RunDirector.after_zone_cleared(self, remaining_characters)

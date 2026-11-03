extends Control
class_name HubSanctumMap

class WalkerPhysicsDriver extends Node:
	var sanctum_map: HubSanctumMap

	func _physics_process(_delta: float) -> void:
		if sanctum_map != null:
			sanctum_map._drive_player_physics(_delta)

signal service_picked(tab_index: int)

const TOWN_TILES_W := 22
const TOWN_TILES_H := 16
const TILE_SIZE := 32
const MOVE_SPEED := 120.0

const NPC_DEFS: Array[Dictionary] = [
	{"tab": 0, "label": "Grum — Shop", "tile": Vector2i(4, 4), "icon": "res://assets/monsters/unique/grum.png"},
	{"tab": 1, "label": "Train — Enchantress", "tile": Vector2i(17, 4), "icon": "res://assets/monsters/unique/enchantress.png"},
	{"tab": 2, "label": "Sanctum Boons", "tile": Vector2i(4, 11), "icon": ""},
	{"tab": 3, "label": "Equip Stash", "tile": Vector2i(17, 11), "icon": ""},
]

var _viewport_container: SubViewportContainer
var _viewport: SubViewport
var _world_root: Node2D
var _tilemap: TileMapLayer
var _player: CharacterBody2D
var _walker_ap: AnimationPlayer
var _camera: Camera2D
var _prompt: Label
var _has_party: bool = false
var _near_service_tab: int = -1
var _floor_source: int = 0
var _wall_source: int = 6
var _physics_driver: WalkerPhysicsDriver
var _template_tile_set: TileSet
var _last_move_dir := Vector2.DOWN

func set_template_tile_set(source: TileSet) -> void:
	_template_tile_set = source

func _find_live_world_tile_set() -> TileSet:
	if _template_tile_set != null:
		return _template_tile_set
	var node: Node = self
	while node != null:
		var parent: Node = node.get_parent()
		if parent != null:
			var map_layer := parent.get_node_or_null("Map") as TileMapLayer
			if map_layer != null and map_layer.tile_set != null:
				return map_layer.tile_set
		node = parent
	return null

func _ready() -> void:
	custom_minimum_size = Vector2(720, 520)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_viewport()
	_build_town_map()
	_build_player()
	_build_npcs()
	var driver := WalkerPhysicsDriver.new()
	driver.sanctum_map = self
	_physics_driver = driver
	_world_root.add_child(driver)
	_prompt = Label.new()
	_prompt.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt.offset_top = -36.0
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override("font_size", Global.get_ui_font_size(15))
	_prompt.modulate = HubUiHelpers.COLOR_ACCENT
	add_child(_prompt)
	set_process_unhandled_input(true)

func _build_viewport() -> void:
	_viewport_container = SubViewportContainer.new()
	_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewport_container.stretch = true
	add_child(_viewport_container)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(TOWN_TILES_W * TILE_SIZE, TOWN_TILES_H * TILE_SIZE)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport_container.add_child(_viewport)
	_world_root = Node2D.new()
	_viewport.add_child(_world_root)

func _build_town_map() -> void:
	_tilemap = TileMapLayer.new()
	_tilemap.name = "SanctumTownMap"
	_tilemap.collision_enabled = true
	var src_tile_set: TileSet = _find_live_world_tile_set()
	if src_tile_set == null:
		push_error("HubSanctumMap: could not resolve TileSet from World/Map.")
		_world_root.add_child(_tilemap)
		return
	_tilemap.tile_set = src_tile_set.duplicate(true)
	_world_root.add_child(_tilemap)
	var zone: ZoneDefinition = ContentRegistry.get_zone_by_id("blood_cathedral")
	if zone == null:
		zone = ContentRegistry.get_zone_by_id("grim_fields")
	var theme: Dictionary = MapTileBuilder.apply_theme(_tilemap, zone.map_theme_id if zone != null else "blood_cathedral")
	_floor_source = int(theme["floor"])
	_wall_source = int(theme["wall"])
	MapTileBuilder.ensure_wall_physics(_tilemap.tile_set, _wall_source)
	_paint_sanctum_town()
	_tilemap.update_internals()

func _max_atlas_index(source_id: int) -> int:
	if _tilemap == null or _tilemap.tile_set == null or !_tilemap.tile_set.has_source(source_id):
		return 0
	var source := _tilemap.tile_set.get_source(source_id) as TileSetAtlasSource
	if source == null or source.texture == null:
		return 0
	var cols: int = maxi(1, int(source.texture.get_width()) / maxi(source.texture_region_size.x, 1))
	return maxi(cols - 1, 0)

func _floor_atlas(cell: Vector2i) -> Vector2i:
	var max_i := _max_atlas_index(_floor_source)
	for attempt in range(max_i + 1):
		var idx: int = (cell.x * 5 + cell.y * 11 + attempt * 3) % (max_i + 1)
		var atlas := Vector2i(idx, 0)
		if !_hub_floor_blocks_movement(atlas):
			return atlas
	return Vector2i(0, 0)

func _hub_floor_blocks_movement(atlas: Vector2i) -> bool:
	if _tilemap == null or _tilemap.tile_set == null or !_tilemap.tile_set.has_source(_floor_source):
		return false
	var source := _tilemap.tile_set.get_source(_floor_source) as TileSetAtlasSource
	if source == null:
		return false
	var data: TileData = source.get_tile_data(atlas, 0)
	if data == null:
		return true
	return data.get_collision_polygons_count(0) > 0

func _wall_atlas(cell: Vector2i) -> Vector2i:
	var max_i := _max_atlas_index(_wall_source)
	var idx: int = (cell.x + cell.y * 3) % (max_i + 1)
	return Vector2i(idx, 0)

func _set_floor(cell: Vector2i) -> void:
	_tilemap.set_cell(cell, _floor_source, _floor_atlas(cell))

func _set_wall(cell: Vector2i) -> void:
	_tilemap.set_cell(cell, _wall_source, _wall_atlas(cell))

func _paint_sanctum_town() -> void:
	for x in TOWN_TILES_W:
		for y in TOWN_TILES_H:
			_set_floor(Vector2i(x, y))
	for x in TOWN_TILES_W:
		_set_wall(Vector2i(x, 0))
		_set_wall(Vector2i(x, TOWN_TILES_H - 1))
	for y in TOWN_TILES_H:
		_set_wall(Vector2i(0, y))
		_set_wall(Vector2i(TOWN_TILES_W - 1, y))
	var mid_x := TOWN_TILES_W / 2
	var mid_y := TOWN_TILES_H / 2
	for x in range(1, TOWN_TILES_W - 1):
		_set_floor(Vector2i(x, mid_y))
		_set_floor(Vector2i(x, mid_y - 1))
	for y in range(1, TOWN_TILES_H - 1):
		_set_floor(Vector2i(mid_x, y))
		_set_floor(Vector2i(mid_x - 1, y))
	for def in NPC_DEFS:
		_stamp_service_building(def["tile"] as Vector2i, Vector2i(mid_x, mid_y))

func _stamp_service_building(npc_tile: Vector2i, plaza_center: Vector2i) -> void:
	var rect := Rect2i(npc_tile.x - 2, npc_tile.y - 2, 5, 5)
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			var cell := Vector2i(x, y)
			if cell.x <= 0 or cell.y <= 0 or cell.x >= TOWN_TILES_W - 1 or cell.y >= TOWN_TILES_H - 1:
				continue
			var on_edge := x == rect.position.x or x == rect.position.x + rect.size.x - 1 or y == rect.position.y or y == rect.position.y + rect.size.y - 1
			if on_edge:
				_set_wall(cell)
			else:
				_set_floor(cell)
	var door := npc_tile + Vector2i(signi(plaza_center.x - npc_tile.x), signi(plaza_center.y - npc_tile.y))
	if door.x > 0 and door.y > 0 and door.x < TOWN_TILES_W - 1 and door.y < TOWN_TILES_H - 1:
		_set_floor(door)
	_set_floor(npc_tile)

func _build_player() -> void:
	_player = CharacterBody2D.new()
	_player.name = "HubWalker"
	_player.collision_layer = 1
	_player.collision_mask = 1
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	col.shape = circle
	_player.add_child(col)
	_world_root.add_child(_player)
	_camera = Camera2D.new()
	_camera.enabled = true
	_player.add_child(_camera)
	_reset_player_spawn()

func _build_npcs() -> void:
	if _tilemap == null or _tilemap.tile_set == null:
		return
	for def in NPC_DEFS:
		var tile: Vector2i = def["tile"]
		var world_pos := _tilemap.map_to_local(tile) + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
		var npc_root := Node2D.new()
		npc_root.position = world_pos
		npc_root.name = "NPC_%d" % int(def["tab"])
		var sprite := Sprite2D.new()
		var icon_path: String = String(def.get("icon", ""))
		if icon_path != "" and ResourceLoader.exists(icon_path):
			sprite.texture = load(icon_path)
			sprite.scale = Vector2(0.55, 0.55)
		else:
			sprite.texture = load("res://assets/monsters/harpy.png")
			sprite.modulate = Color(0.85, 0.75, 0.95)
			sprite.scale = Vector2(0.5, 0.5)
		npc_root.add_child(sprite)
		var tag := Label.new()
		tag.text = String(def["label"]).split(" — ")[0]
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.position = Vector2(-48, -42)
		tag.add_theme_font_size_override("font_size", Global.get_ui_font_size(12))
		npc_root.add_child(tag)
		var area := Area2D.new()
		area.collision_layer = 0
		area.collision_mask = 1
		var area_shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(TILE_SIZE * 2.2, TILE_SIZE * 2.2)
		area_shape.shape = rect
		area.add_child(area_shape)
		var tab_index: int = int(def["tab"])
		area.body_entered.connect(func(body: Node) -> void: _on_npc_zone_enter(body, tab_index, String(def["label"])))
		area.body_exited.connect(func(body: Node) -> void: _on_npc_zone_exit(body, tab_index))
		npc_root.add_child(area)
		_world_root.add_child(npc_root)

func _reset_player_spawn() -> void:
	if _tilemap == null or _player == null or _tilemap.tile_set == null:
		return
	var spawn := Vector2i(TOWN_TILES_W / 2, TOWN_TILES_H / 2 + 1)
	_player.position = _tilemap.map_to_local(spawn) + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)

func _drive_player_physics(_delta: float) -> void:
	if !_has_party or !is_visible_in_tree() or _player == null:
		return
	var dir := _read_move_vector()
	if dir.length_squared() > 0.001:
		_player.velocity = dir.normalized() * MOVE_SPEED
		_last_move_dir = dir
		_update_walker_animation(dir)
	else:
		_player.velocity = Vector2.ZERO
		_update_walker_animation(Vector2.ZERO)
	_player.move_and_slide()

func _update_walker_animation(dir: Vector2) -> void:
	if _walker_ap == null or !_walker_ap.is_inside_tree():
		return
	if dir.length_squared() < 0.001:
		if _walker_ap.has_animation("walk_down"):
			_walker_ap.play("walk_down")
		return
	if absf(dir.x) >= absf(dir.y):
		if dir.x >= 0.0 and _walker_ap.has_animation("walk_right"):
			_walker_ap.play("walk_right")
		elif _walker_ap.has_animation("walk_left"):
			_walker_ap.play("walk_left")
	else:
		if dir.y >= 0.0 and _walker_ap.has_animation("walk_down"):
			_walker_ap.play("walk_down")
		elif _walker_ap.has_animation("walk_up"):
			_walker_ap.play("walk_up")

func _read_move_vector() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	return dir

func _unhandled_input(event: InputEvent) -> void:
	if !_has_party or _near_service_tab < 0:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		service_picked.emit(_near_service_tab)
		_prompt.text = ""

func _on_npc_zone_enter(body: Node, tab_index: int, label: String) -> void:
	if body != _player:
		return
	_near_service_tab = tab_index
	_prompt.text = "E — Open %s" % label

func _on_npc_zone_exit(body: Node, tab_index: int) -> void:
	if body != _player or _near_service_tab != tab_index:
		return
	_near_service_tab = -1
	_prompt.text = "WASD — Walk to a marker · E — Talk"

func set_hub_state(has_party: bool, _hint_text: String) -> void:
	_has_party = has_party
	if _player:
		_player.visible = has_party
	if has_party:
		_reset_player_spawn()
		_prompt.text = "WASD — Walk to a marker · E — Talk"
	else:
		_prompt.text = "Select a party, then explore the sanctum."
		_near_service_tab = -1

func set_party_lead_source(source: Character) -> void:
	_clear_walker_visual()
	if source == null or _player == null:
		return
	var walker := source.duplicate() as Character
	_strip_walker_for_hub(walker)
	_player.add_child(walker)
	walker.visible = true
	walker.position = Vector2.ZERO
	_walker_ap = walker.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if _walker_ap != null:
		_update_walker_animation(Vector2.ZERO)

func set_party_walker_texture(tex: Texture2D) -> void:
	_clear_walker_visual()
	if tex == null or _player == null:
		return
	var sprite := Sprite2D.new()
	sprite.name = "Body"
	sprite.texture = tex
	sprite.scale = Vector2(0.95, 0.95)
	_player.add_child(sprite)

func _strip_walker_for_hub(walker: Character) -> void:
	walker.visible = true
	walker.battle_started = true
	walker.set_process(false)
	walker.set_physics_process(false)
	walker.collision_layer = 0
	walker.collision_mask = 0
	for node_name in ["ProgressBar", "MpBar", "XpBar", "DamageReceived", "Camera2D", "Focus", "CollisionShape2D"]:
		var node := walker.get_node_or_null(node_name)
		if node != null:
			node.queue_free()
	for child in walker.get_children():
		if child is AudioStreamPlayer:
			child.queue_free()

func _clear_walker_visual() -> void:
	if _player == null:
		return
	for child in _player.get_children():
		if child == _camera:
			continue
		if child is CollisionShape2D:
			continue
		child.queue_free()
	_walker_ap = null

func set_descent_plan(_zone_ids: Array[String]) -> void:
	pass

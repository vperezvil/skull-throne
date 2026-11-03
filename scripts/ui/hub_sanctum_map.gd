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
var _player_sprite: Sprite2D
var _camera: Camera2D
var _prompt: Label
var _has_party: bool = false
var _near_service_tab: int = -1
var _floor_source: int = 0
var _wall_source: int = 6
var _physics_driver: WalkerPhysicsDriver
var _template_tile_set: TileSet

## Call before add_child when the hub map is built (UI _ready runs before Map may be easy to reach).
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
	for x in TOWN_TILES_W:
		for y in TOWN_TILES_H:
			var cell := Vector2i(x, y)
			var edge := x == 0 or y == 0 or x == TOWN_TILES_W - 1 or y == TOWN_TILES_H - 1
			if edge:
				_tilemap.set_cell(cell, _wall_source, Vector2i((x + y) % 8, 0))
			else:
				_tilemap.set_cell(cell, _floor_source, Vector2i((x * 3 + y) % 8, 0))
	_tilemap.update_internals()
	_stamp_service_shrines()

func _stamp_service_shrines() -> void:
	var center := Vector2i(TOWN_TILES_W / 2, TOWN_TILES_H / 2)
	for def in NPC_DEFS:
		var npc_tile: Vector2i = def["tile"]
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue
				var cell := npc_tile + Vector2i(dx, dy)
				if cell.x <= 0 or cell.y <= 0 or cell.x >= TOWN_TILES_W - 1 or cell.y >= TOWN_TILES_H - 1:
					continue
				_tilemap.set_cell(cell, _wall_source, Vector2i((cell.x + cell.y) % 8, 0))
		var door := npc_tile + Vector2i(signi(center.x - npc_tile.x), signi(center.y - npc_tile.y))
		if door != npc_tile and door.x > 0 and door.y > 0 and door.x < TOWN_TILES_W - 1 and door.y < TOWN_TILES_H - 1:
			_tilemap.set_cell(door, _floor_source, Vector2i((door.x * 3 + door.y) % 8, 0))
	_tilemap.update_internals()

func _build_player() -> void:
	_player = CharacterBody2D.new()
	_player.name = "HubWalker"
	_player.collision_layer = 1
	_player.collision_mask = 1
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 11.0
	col.shape = circle
	_player.add_child(col)
	_player_sprite = Sprite2D.new()
	_player_sprite.name = "Body"
	_player_sprite.texture = load("res://assets/monsters/harpy.png")
	_player_sprite.scale = Vector2(0.9, 0.9)
	_player.add_child(_player_sprite)
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
		var world_pos := _tilemap.map_to_local(tile + Vector2i(0, 0)) + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)
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
		rect.size = Vector2(TILE_SIZE * 1.6, TILE_SIZE * 1.6)
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
	else:
		_player.velocity = Vector2.ZERO
	_player.move_and_slide()

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

func set_party_walker_texture(tex: Texture2D) -> void:
	if _player_sprite != null and tex != null:
		_player_sprite.texture = tex

func set_descent_plan(_zone_ids: Array[String]) -> void:
	pass

extends SceneTree

# Run: godot --headless --path . --script res://scripts/tools/smoke_test.gd

const WORLD_SCENE := "res://scenes/main/world.tscn"
const ContentRegistryScript := preload("res://scripts/data/content_registry.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: PackedStringArray = []
	errors.append_array(_check_world_scene())
	errors.append_array(_check_map_generation())
	if errors.is_empty():
		print("Smoke test OK")
		quit(0)
		return
	for e in errors:
		push_error(e)
	quit(1)

func _check_world_scene() -> PackedStringArray:
	var packed: PackedScene = load(WORLD_SCENE)
	if packed == null:
		return PackedStringArray(["Failed to load %s" % WORLD_SCENE])
	var world: Node = packed.instantiate()
	if world == null:
		return PackedStringArray(["Failed to instantiate %s" % WORLD_SCENE])
	world.free()
	return PackedStringArray()

func _content_registry() -> Node:
	var root := get_root()
	if root == null:
		return null
	return root.get_node_or_null("/root/ContentRegistry")

func _check_map_generation() -> PackedStringArray:
	var registry: Node = _content_registry()
	if registry == null:
		registry = ContentRegistryScript.new()
		registry.call("_ready")
	if registry == null:
		return PackedStringArray(["ContentRegistry unavailable"])
	var zone: ZoneDefinition = registry.call("get_zone_by_id", "grim_fields") as ZoneDefinition
	if zone == null:
		return PackedStringArray(["ContentRegistry missing zone: grim_fields"])
	var packed: PackedScene = load(WORLD_SCENE)
	var world: Node = packed.instantiate()
	get_root().add_child(world)
	var map = world.get_node_or_null("Map")
	if map == null:
		world.queue_free()
		return PackedStringArray(["World scene missing Map (TileMapLayer) node"])
	map.clear_map()
	map.apply_zone(zone)
	map.generate_chunk(Vector2i(10, 10), Vector2i(4, 4))
	var floor_cells = map.get_used_cells_by_id(map.level)
	world.queue_free()
	if floor_cells.is_empty():
		return PackedStringArray(["Map.generate_chunk produced no floor tiles"])
	return PackedStringArray()

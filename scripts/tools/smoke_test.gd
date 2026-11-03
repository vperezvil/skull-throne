extends SceneTree

# Run: godot --headless --path . --script res://scripts/tools/smoke_test.gd

const WORLD_SCENE := "res://scenes/main/world.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: PackedStringArray = []
	errors.append_array(_check_world_scene())
	errors.append_array(_check_map_generation())
	if errors.is_empty():
		print("Smoke test OK")
		quit(0)
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

func _check_map_generation() -> PackedStringArray:
	var zone: ZoneDefinition = ContentRegistry.get_zone_by_id("grim_fields")
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

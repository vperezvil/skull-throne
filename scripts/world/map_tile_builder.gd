extends RefCounted
class_name MapTileBuilder

# Registers floor/wall atlases from assets/map per map_theme_id.

const SOURCE_GRASS_FLOOR := 0
const SOURCE_COBBLE_FLOOR := 1
const SOURCE_GRASS_WALL := 6

const _THEME_CACHE: Dictionary = {}

static func apply_theme(tile_map: TileMap, theme_id: String) -> Dictionary:
	var tile_set: TileSet = tile_map.tile_set
	if tile_set == null:
		push_error("Map has no TileSet.")
		return {"floor": 0, "wall": 6}
	if _THEME_CACHE.has(theme_id):
		return _THEME_CACHE[theme_id]
	var result := _build_theme(tile_set, theme_id)
	_THEME_CACHE[theme_id] = result
	return result

static func _build_theme(tile_set: TileSet, theme_id: String) -> Dictionary:
	match theme_id:
		"grim_fields":
			return {"floor": SOURCE_GRASS_FLOOR, "wall": SOURCE_GRASS_WALL}
		"blood_cathedral":
			return {"floor": SOURCE_COBBLE_FLOOR, "wall": SOURCE_GRASS_WALL}
		"throne_approach":
			return _theme_composite_floor_dark_wall(tile_set, _blood_floor_paths(), "throne_approach")
		"swamp_mire":
			return _theme_composite_floor_wall_strip(
				tile_set,
				["res://assets/map/floor/swamp3.png", "res://assets/map/floor/bog_green1.png", "res://assets/map/floor/bog_green2.png", "res://assets/map/floor/lair0.png"],
				"res://assets/map/wall/brick_brown-vines2.png",
				"swamp_mire"
			)
		"ice_citadel":
			return _theme_composite_floor_wall_strip(
				tile_set,
				["res://assets/map/floor/ice0.png", "res://assets/map/floor/ice2.png", "res://assets/map/floor/grey_dirt0.png"],
				"res://assets/map/wall/stone_gray0.png",
				"ice_citadel"
			)
		"bone_crypt":
			return _theme_composite_floor_wall_strip(
				tile_set,
				["res://assets/map/floor/tomb1.png", "res://assets/map/floor/lair0.png", "res://assets/map/floor/lair3.png"],
				"res://assets/map/wall/tomb1.png",
				"bone_crypt"
			)
		"crystal_depths":
			return _theme_composite_floor_wall_strip(
				tile_set,
				["res://assets/map/floor/crystal_floor0.png", "res://assets/map/floor/crystal_floor2.png", "res://assets/map/floor/crystal_floor4.png"],
				"res://assets/map/wall/crystal_wall02.png",
				"crystal_depths"
			)
		"nerve_catacombs":
			return _theme_composite_floor_wall_strip(
				tile_set,
				["res://assets/map/floor/floor_nerves2.png", "res://assets/map/floor/floor_nerves4.png", "res://assets/map/floor/floor_nerves5.png"],
				"res://assets/map/wall/wall_flesh6.png",
				"nerve_catacombs"
			)
		"sandstone_ruins":
			return _theme_composite_floor_wall_strip(
				tile_set,
				["res://assets/map/floor/sandstone_floor0.png", "res://assets/map/floor/sandstone_floor1.png", "res://assets/map/floor/dirt2.png"],
				"res://assets/map/wall/sandstone_wall0.png",
				"sandstone_ruins"
			)
		"marble_halls":
			return _theme_composite_floor_wall_strip(
				tile_set,
				["res://assets/map/floor/marble_floor1.png", "res://assets/map/floor/rect_gray0.png"],
				"res://assets/map/wall/marble_wall6.png",
				"marble_halls"
			)
		"skull_throne":
			var floor_id := _register_composite_floor(
				tile_set,
				_volcanic_floor_paths(),
				"skull_throne_floor"
			)
			var wall_id := _register_composite_floor(
				tile_set,
				_volcanic_wall_paths(),
				"skull_throne_wall"
			)
			_add_wall_physics(tile_set, wall_id)
			return {"floor": floor_id, "wall": wall_id}
		_:
			return {"floor": SOURCE_GRASS_FLOOR, "wall": SOURCE_GRASS_WALL}

static func _theme_composite_floor_dark_wall(tile_set: TileSet, floor_paths: PackedStringArray, cache_prefix: String) -> Dictionary:
	var floor_id := _register_composite_floor(tile_set, floor_paths, cache_prefix + "_floor")
	var wall_id := _register_strip(tile_set, "res://assets/map/wall/brick_dark0.png", cache_prefix + "_wall", true)
	return {"floor": floor_id, "wall": wall_id}

static func _theme_composite_floor_wall_strip(
	tile_set: TileSet,
	floor_paths: Array,
	wall_path: String,
	cache_prefix: String
) -> Dictionary:
	var packed := PackedStringArray()
	for p in floor_paths:
		packed.append(p)
	var floor_id := _register_composite_floor(tile_set, packed, cache_prefix + "_floor")
	var wall_id := _register_strip(tile_set, wall_path, cache_prefix + "_wall", true)
	return {"floor": floor_id, "wall": wall_id}

static func _blood_floor_paths() -> PackedStringArray:
	return PackedStringArray([
		"res://assets/map/floor/cobble_blood1.png",
		"res://assets/map/floor/cobble_blood4.png",
		"res://assets/map/floor/cobble_blood6.png",
		"res://assets/map/floor/cobble_blood8.png",
		"res://assets/map/floor/cobble_blood10.png",
		"res://assets/map/floor/cobble_blood12.png",
		"res://assets/map/floor/lava1.png",
		"res://assets/map/floor/lava3.png",
	])

static func _volcanic_floor_paths() -> PackedStringArray:
	return PackedStringArray([
		"res://assets/map/floor/volcanic_floor0.png",
		"res://assets/map/floor/volcanic_floor1.png",
		"res://assets/map/floor/volcanic_floor2.png",
		"res://assets/map/floor/volcanic_floor3.png",
		"res://assets/map/floor/volcanic_floor4.png",
		"res://assets/map/floor/volcanic_floor5.png",
		"res://assets/map/floor/cobble_blood12.png",
	])

static func _volcanic_wall_paths() -> PackedStringArray:
	return PackedStringArray([
		"res://assets/map/wall/volcanic_wall0.png",
		"res://assets/map/wall/volcanic_wall1.png",
		"res://assets/map/wall/volcanic_wall2.png",
		"res://assets/map/wall/volcanic_wall3.png",
		"res://assets/map/wall/volcanic_wall4.png",
		"res://assets/map/wall/volcanic_wall5.png",
	])

static func _register_composite_floor(tile_set: TileSet, paths: PackedStringArray, cache_key: String) -> int:
	var atlas_texture := _merge_horizontal(paths)
	if atlas_texture == null:
		return SOURCE_COBBLE_FLOOR
	return _register_atlas_texture(tile_set, atlas_texture, cache_key, false)

static func _register_strip(tile_set: TileSet, path: String, cache_key: String, with_physics: bool) -> int:
	var tex: Texture2D = load(path)
	if tex == null:
		return SOURCE_GRASS_WALL
	return _register_atlas_texture(tile_set, tex, cache_key, with_physics)

static func _register_atlas_texture(tile_set: TileSet, texture: Texture2D, _cache_key: String, with_physics: bool) -> int:
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(32, 32)
	var cols := maxi(1, int(texture.get_width()) / 32)
	for x in range(cols):
		source.create_tile(Vector2i(x, 0))
		if with_physics:
			source.set_tile_physics_layer_collision_polygon(0, Vector2i(x, 0), 0, PackedVector2Array([
				Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16),
			]))
	var source_id := tile_set.add_source(source)
	return source_id

static func _add_wall_physics(tile_set: TileSet, source_id: int) -> void:
	var source := tile_set.get_source(source_id) as TileSetAtlasSource
	if source == null:
		return
	var cols := maxi(1, int(source.texture.get_width()) / 32)
	for x in range(cols):
		source.set_tile_physics_layer_collision_polygon(0, Vector2i(x, 0), 0, PackedVector2Array([
			Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16),
		]))

static func _merge_horizontal(paths: PackedStringArray) -> Texture2D:
	if paths.is_empty():
		return null
	var images: Array[Image] = []
	for path in paths:
		var tex: Texture2D = load(path)
		if tex:
			images.append(tex.get_image())
	if images.is_empty():
		return null
	var tile := 32
	var atlas := Image.create(tile * images.size(), tile, false, Image.FORMAT_RGBA8)
	for i in images.size():
		atlas.blit_rect(images[i], Rect2i(0, 0, tile, tile), Vector2i(i * tile, 0))
	return ImageTexture.create_from_image(atlas)

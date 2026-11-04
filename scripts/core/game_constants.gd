extends RefCounted
class_name GameConstants

const MAP_SIZE := Vector2i(100, 100)
const ROOM_MIN_SIZE := 10
const ROOM_MAX_SIZE := 20
const NUM_ROOMS := 15
const ENEMIES_TOTAL := 15
const ITEMS_MIN_SPAWN := 1
const ITEMS_MAX_SPAWN := 3

# Run queue: random biomes then skull_throne (see ContentRegistry.build_run_plan).
const RUN_BIOME_FLOORS_MIN := 5
const RUN_BIOME_FLOORS_MAX := 7
const FLOORS_BETWEEN_WAYSTATIONS := 2
const RUN_GOLD_PER_FLOOR := 15
const BATTLE_GOLD_BASE := 10
const ELITE_SPAWN_CHANCE := 0.11
const MAP_EVENTS_PER_FLOOR := 2
const MAP_TILE_SIZE := 32.0
const EARLY_RETURN_SAFE_FLOORS := 3 # fewer cleared floors on abandon -> penalty in RunState
const FLEE_SUCCESS_CHANCE := 0.62

static func tile_map_cell_center(tilemap: Node2D, cell: Vector2i) -> Vector2:
	return tilemap.map_to_local(cell)

static func fit_sprite_to_map_tile(sprite: Sprite2D, fill_ratio: float = 1.0) -> void:
	if sprite == null or sprite.texture == null:
		return
	var tex_size := sprite.texture.get_size()
	var max_dim := maxf(tex_size.x, tex_size.y)
	if max_dim <= 0.0:
		return
	var factor := (MAP_TILE_SIZE * fill_ratio) / max_dim
	sprite.centered = true
	sprite.scale = Vector2(factor, factor)

static func fit_animated_sprite_to_map_tile(sprite: AnimatedSprite2D, fill_ratio: float = 1.0) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var anim := sprite.animation
	if !sprite.sprite_frames.has_animation(anim):
		return
	var tex: Texture2D = sprite.sprite_frames.get_frame_texture(anim, 0)
	if tex == null:
		return
	var tex_size := tex.get_size()
	var max_dim := maxf(tex_size.x, tex_size.y)
	if max_dim <= 0.0:
		return
	var factor := (MAP_TILE_SIZE * fill_ratio) / max_dim
	sprite.centered = true
	sprite.scale = Vector2(factor, factor)

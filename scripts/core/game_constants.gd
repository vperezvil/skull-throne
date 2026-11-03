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
const EARLY_RETURN_SAFE_FLOORS := 3 # fewer cleared floors on abandon -> penalty in RunState
const FLEE_SUCCESS_CHANCE := 0.62

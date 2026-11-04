extends RefCounted
class_name MapThemeSettings

static func get_floor_noise_divisor(theme_id: String) -> float:
	match theme_id:
		"skull_throne":
			return 1.1
		"throne_approach", "nerve_catacombs":
			return 1.2
		"crystal_depths", "ice_citadel":
			return 1.25
		_:
			return 1.3

static func get_wall_noise_divisor(theme_id: String) -> float:
	match theme_id:
		"skull_throne":
			return 4.5
		"nerve_catacombs", "bone_crypt":
			return 4.8
		_:
			return 5.0

static func get_room_count_bonus(theme_id: String) -> int:
	match theme_id:
		"skull_throne":
			return 6
		"throne_approach", "nerve_catacombs":
			return 4
		_:
			return 0

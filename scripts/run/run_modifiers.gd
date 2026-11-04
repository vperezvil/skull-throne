extends RefCounted
class_name RunModifiers

# One random modifier per descent for variety.

const IDS: Array[String] = [
	"bounty_hunters",
	"blood_frenzy",
	"heroes_haste",
	"plunder",
	"iron_wardens",
]

static func roll_modifier_id(ascended: bool = false) -> String:
	if ascended:
		var hard_pool: Array[String] = ["blood_frenzy", "iron_wardens", "blood_frenzy", "iron_wardens", "bounty_hunters"]
		return hard_pool[randi() % hard_pool.size()]
	return IDS[randi() % IDS.size()]

static func ascended_enemy_damage_multiplier(ascended: bool) -> float:
	return 1.15 if ascended else 1.0

static func ascended_boss_hp_multiplier(ascended: bool) -> float:
	return 1.12 if ascended else 1.0

static func ascended_elite_chance_bonus(ascended: bool) -> float:
	return 0.08 if ascended else 0.0

static func ascended_label() -> String:
	return "Ascended"

static func get_display_name(modifier_id: String) -> String:
	match modifier_id:
		"bounty_hunters":
			return "Bounty Hunters"
		"blood_frenzy":
			return "Blood Frenzy"
		"heroes_haste":
			return "Heroes' Haste"
		"plunder":
			return "Plunder"
		"iron_wardens":
			return "Iron Wardens"
		_:
			return "Standard descent"

static func get_description(modifier_id: String) -> String:
	match modifier_id:
		"bounty_hunters":
			return "+35% run gold from fights and floor clears."
		"blood_frenzy":
			return "Enemies hit 12% harder; +30% battle XP."
		"heroes_haste":
			return "Party +12 initiative for this descent."
		"plunder":
			return "Extra gold caches spawn on every floor."
		"iron_wardens":
			return "Bosses +22% HP; +25 bonus gold when you clear a floor."
		_:
			return ""

static func gold_multiplier(modifier_id: String) -> float:
	if modifier_id == "bounty_hunters":
		return 1.35
	return 1.0

static func xp_multiplier(modifier_id: String) -> float:
	if modifier_id == "blood_frenzy":
		return 1.3
	return 1.0

static func enemy_damage_multiplier(modifier_id: String) -> float:
	if modifier_id == "blood_frenzy":
		return 1.12
	return 1.0

static func party_initiative_bonus(modifier_id: String) -> int:
	if modifier_id == "heroes_haste":
		return 12
	return 0

static func extra_cache_count(modifier_id: String) -> int:
	if modifier_id == "plunder":
		return +2
	return 1

static func boss_hp_multiplier(modifier_id: String) -> float:
	if modifier_id == "iron_wardens":
		return 1.22
	return 1.0

static func floor_clear_gold_bonus(modifier_id: String) -> int:
	if modifier_id == "iron_wardens":
		return 25
	return 0

static func elite_chance_bonus(modifier_id: String) -> float:
	if modifier_id == "blood_frenzy":
		return 0.05
	return 0.0

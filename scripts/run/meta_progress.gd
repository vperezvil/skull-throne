extends Node

# Persistent hub currency, upgrades, veteran roster, soul marks, and mirror lock.
# Save keys (section meta): blood_tithe, runs_*, skulls_on_throne, lifetime_floors_cleared,
# sanctum_tutorial_seen, tutorial_waystation_seen, tutorial_stain_seen, ascended_next_run,
# vitality/fury/supply levels, skill_tiers, roster_progress, roster_traits,
# locked_stat_character_id, locked_stat_roll, save_version.

const SAVE_PATH := "user://meta_progress.cfg"
const SAVE_VERSION := 2

const POTION_SCENE := preload("res://scenes/objects/potion.tscn")
const SWORD_SCENE := preload("res://scenes/objects/sword.tscn")

var blood_tithe: int = 0
var runs_attempted: int = 0
var runs_won: int = 0
var skulls_on_throne: int = 0
var lifetime_floors_cleared: int = 0
var sanctum_tutorial_seen: bool = false
var tutorial_waystation_seen: bool = false
var tutorial_stain_seen: bool = false
var ascended_next_run: bool = false
var vitality_level: int = 0
var fury_level: int = 0
var supply_level: int = 0

const VITALITY_MAX := 3
const FURY_MAX := 2
const SUPPLY_MAX := 2

const VITALITY_HP_BONUS := 12
const FURY_ATK_BONUS := 2

var _potion_proto: Item
var _sword_proto: Item
var skill_tiers: Dictionary = {}
var roster_progress: Dictionary = {}
var roster_traits: Dictionary = {} # character_id -> Array of trait_id strings
var locked_stat_character_id: String = ""
var locked_stat_roll: Dictionary = {}

func grant_potion_to_inventory() -> bool:
	Inventory.add_item(_potion_proto, 1)
	return true

func _ready() -> void:
	_load()
	Global.total_deaths = skulls_on_throne
	_potion_proto = POTION_SCENE.instantiate() as Item
	_sword_proto = SWORD_SCENE.instantiate() as Item
	add_child(_potion_proto)
	add_child(_sword_proto)
	_potion_proto.visible = false
	_sword_proto.visible = false

func complete_run(floors_cleared: int, victory: bool, tithe_penalty_fraction: float = 0.0) -> int:
	var earned := maxi(0, floors_cleared) * 12
	if victory:
		earned += 100
	earned = int(earned * (1.0 - clampf(tithe_penalty_fraction, 0.0, 1.0)))
	blood_tithe += earned
	runs_attempted += 1
	if victory:
		runs_won += 1
	_save()
	return earned

func spend_tithe(cost: int) -> bool:
	if blood_tithe < cost:
		return false
	blood_tithe -= cost
	_save()
	return true

func can_buy_potion() -> bool:
	return blood_tithe >= 25

func buy_potion() -> bool:
	if !spend_tithe(25):
		return false
	return grant_potion_to_inventory()

func can_buy_sword() -> bool:
	return blood_tithe >= 40

func buy_sword() -> bool:
	if !spend_tithe(40):
		return false
	Inventory.add_item(_sword_proto, 1)
	return true

func upgrade_vitality_cost() -> int:
	return 30 + vitality_level * 35

func upgrade_fury_cost() -> int:
	return 40 + fury_level * 45

func upgrade_supply_cost() -> int:
	return 50 + supply_level * 55

func can_upgrade_vitality() -> bool:
	return vitality_level < VITALITY_MAX and blood_tithe >= upgrade_vitality_cost()

func can_upgrade_fury() -> bool:
	return fury_level < FURY_MAX and blood_tithe >= upgrade_fury_cost()

func can_upgrade_supply() -> bool:
	return supply_level < SUPPLY_MAX and blood_tithe >= upgrade_supply_cost()

func buy_upgrade_vitality() -> bool:
	if vitality_level >= VITALITY_MAX:
		return false
	var cost := upgrade_vitality_cost()
	if !spend_tithe(cost):
		return false
	vitality_level += 1
	_save()
	return true

func buy_upgrade_fury() -> bool:
	if fury_level >= FURY_MAX:
		return false
	var cost := upgrade_fury_cost()
	if !spend_tithe(cost):
		return false
	fury_level += 1
	_save()
	return true

func buy_upgrade_supply() -> bool:
	if supply_level >= SUPPLY_MAX:
		return false
	var cost := upgrade_supply_cost()
	if !spend_tithe(cost):
		return false
	supply_level += 1
	_save()
	return true

func get_traits(character_id: String) -> Array:
	var raw = roster_traits.get(character_id, [])
	if raw is Array:
		return raw.duplicate()
	return []

func try_add_trait(character_id: String, trait_id: String) -> bool:
	if trait_id == "" or !CharacterTraits.DEFINITIONS.has(trait_id):
		return false
	var list: Array = get_traits(character_id)
	if list.has(trait_id):
		return false
	if list.size() >= CharacterTraits.MAX_TRAITS_PER_HERO:
		if !_drop_trait_to_make_room(list, CharacterTraits.is_positive(trait_id)):
			return false
	list.append(trait_id)
	roster_traits[character_id] = list
	_save()
	return true

func _drop_trait_to_make_room(list: Array, incoming_positive: bool) -> bool:
	if incoming_positive:
		return false
	for i in range(list.size()):
		var tid: String = String(list[i])
		if !CharacterTraits.is_positive(tid):
			list.remove_at(i)
			return true
	return false

func remove_trait(character_id: String, trait_id: String) -> bool:
	if !roster_traits.has(character_id):
		return false
	var list: Array = get_traits(character_id)
	if !list.has(trait_id):
		return false
	list.erase(trait_id)
	if list.is_empty():
		roster_traits.erase(character_id)
	else:
		roster_traits[character_id] = list
	_save()
	return true

func treat_trait(character_id: String, trait_id: String) -> bool:
	var cost: int = CharacterTraits.treatment_cost(trait_id)
	if !spend_tithe(cost):
		return false
	return remove_trait(character_id, trait_id)

func apply_meta_to_character(character: Character) -> void:
	if character == null:
		return
	character.recalculate_combat_stats()
	character.current_hp = character.max_hp
	if character.progress_bar:
		character.progress_bar.max_value = character.max_hp

func grant_run_start_supplies() -> void:
	if supply_level >= 1:
		grant_potion_to_inventory()
	if supply_level >= 2:
		Inventory.add_item(_sword_proto, 1)

func get_skill_tier(character_id: String) -> int:
	return int(skill_tiers.get(character_id, 0))

func upgrade_skill_tier(character_id: String) -> bool:
	var tier := get_skill_tier(character_id)
	if tier >= 3:
		return false
	skill_tiers[character_id] = tier + 1
	_save()
	return true

func skill_tier_cost(_character_id: String) -> int:
	return 35

func save_veteran_progress(character: Character) -> void:
	if character == null:
		return
	var def: CharacterDefinition = ContentRegistry.get_character_by_id(character.character_id)
	if def == null or !def.retains_progress:
		return
	roster_progress[character.character_id] = {
		"level": character.level,
		"xp": character.xp,
	}

func get_locked_stat_character_id() -> String:
	return locked_stat_character_id

func get_locked_stat_roll() -> Dictionary:
	return locked_stat_roll.duplicate() if !locked_stat_roll.is_empty() else {}

func lock_stat_mirror(character_id: String, roll: Dictionary) -> bool:
	if character_id == "" or roll.is_empty():
		return false
	const COST := 60
	if !spend_tithe(COST):
		return false
	locked_stat_character_id = character_id
	locked_stat_roll = roll.duplicate()
	_save()
	return true

func clear_stat_mirror() -> void:
	locked_stat_character_id = ""
	locked_stat_roll.clear()
	_save()

func reset_meta_progress() -> void:
	blood_tithe = 0
	runs_attempted = 0
	runs_won = 0
	skulls_on_throne = 0
	lifetime_floors_cleared = 0
	vitality_level = 0
	fury_level = 0
	supply_level = 0
	skill_tiers.clear()
	roster_progress.clear()
	roster_traits.clear()
	locked_stat_character_id = ""
	locked_stat_roll.clear()
	sanctum_tutorial_seen = false
	tutorial_waystation_seen = false
	tutorial_stain_seen = false
	ascended_next_run = false
	Global.total_deaths = 0
	_save()

func mark_tutorial_waystation_seen() -> void:
	if tutorial_waystation_seen:
		return
	tutorial_waystation_seen = true
	_save()

func mark_tutorial_stain_seen() -> void:
	if tutorial_stain_seen:
		return
	tutorial_stain_seen = true
	_save()

func should_show_waystation_tip() -> bool:
	return !tutorial_waystation_seen

func should_show_stain_tip() -> bool:
	return !tutorial_stain_seen

func get_veteran_level_bonuses(character_id: String) -> Dictionary:
	var def: CharacterDefinition = ContentRegistry.get_character_by_id(character_id)
	if def == null or !def.retains_progress or !roster_progress.has(character_id):
		return {"hp": 0, "atk": 0, "levels": 0}
	var data: Dictionary = roster_progress[character_id]
	var levels: int = maxi(0, int(data.get("level", 1)) - 1)
	return {"hp": levels * 8, "atk": levels * 2, "levels": levels}

func apply_veteran_progress(character: Character) -> void:
	if character == null:
		return
	var def: CharacterDefinition = ContentRegistry.get_character_by_id(character.character_id)
	if def == null or !def.retains_progress:
		character._veteran_bonus_hp = 0
		character._veteran_bonus_atk = 0
		return
	if !roster_progress.has(character.character_id):
		character._veteran_bonus_hp = 0
		character._veteran_bonus_atk = 0
		return
	var data: Dictionary = roster_progress[character.character_id]
	var target_level: int = maxi(1, int(data.get("level", 1)))
	var levels: int = maxi(0, target_level - 1)
	character._veteran_bonus_hp = levels * 8
	character._veteran_bonus_atk = levels * 2
	character.xp = int(data.get("xp", 0))
	character.level = target_level

func get_skill_damage_multiplier(character_id: String) -> float:
	return 1.0 + get_skill_tier(character_id) * 0.12

func get_skull_count() -> int:
	return skulls_on_throne

func add_skull_to_throne() -> void:
	skulls_on_throne += 1
	Global.total_deaths = skulls_on_throne
	_save()

func record_lifetime_floor_cleared() -> void:
	lifetime_floors_cleared += 1
	_save()

func get_lifetime_floors_cleared() -> int:
	return lifetime_floors_cleared

func mark_sanctum_tutorial_seen() -> void:
	if sanctum_tutorial_seen:
		return
	sanctum_tutorial_seen = true
	_save()

func should_show_sanctum_tutorial() -> bool:
	return !sanctum_tutorial_seen

func can_use_ascended() -> bool:
	return runs_won >= 1

func set_ascended_next_run(enabled: bool) -> void:
	if !can_use_ascended():
		ascended_next_run = false
		return
	ascended_next_run = enabled
	_save()

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "save_version", SAVE_VERSION)
	cfg.set_value("meta", "blood_tithe", blood_tithe)
	cfg.set_value("meta", "runs_attempted", runs_attempted)
	cfg.set_value("meta", "runs_won", runs_won)
	cfg.set_value("meta", "vitality_level", vitality_level)
	cfg.set_value("meta", "fury_level", fury_level)
	cfg.set_value("meta", "supply_level", supply_level)
	cfg.set_value("meta", "skill_tiers", skill_tiers)
	cfg.set_value("meta", "roster_progress", roster_progress)
	cfg.set_value("meta", "roster_traits", roster_traits)
	cfg.set_value("meta", "skulls_on_throne", skulls_on_throne)
	cfg.set_value("meta", "lifetime_floors_cleared", lifetime_floors_cleared)
	cfg.set_value("meta", "sanctum_tutorial_seen", sanctum_tutorial_seen)
	cfg.set_value("meta", "tutorial_waystation_seen", tutorial_waystation_seen)
	cfg.set_value("meta", "tutorial_stain_seen", tutorial_stain_seen)
	cfg.set_value("meta", "ascended_next_run", ascended_next_run)
	cfg.set_value("meta", "locked_stat_character_id", locked_stat_character_id)
	cfg.set_value("meta", "locked_stat_roll", locked_stat_roll)
	cfg.save(SAVE_PATH)

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	blood_tithe = cfg.get_value("meta", "blood_tithe", blood_tithe)
	runs_attempted = cfg.get_value("meta", "runs_attempted", runs_attempted)
	runs_won = cfg.get_value("meta", "runs_won", runs_won)
	vitality_level = cfg.get_value("meta", "vitality_level", vitality_level)
	fury_level = cfg.get_value("meta", "fury_level", fury_level)
	supply_level = cfg.get_value("meta", "supply_level", supply_level)
	skill_tiers = cfg.get_value("meta", "skill_tiers", skill_tiers)
	roster_progress = cfg.get_value("meta", "roster_progress", roster_progress)
	roster_traits = cfg.get_value("meta", "roster_traits", roster_traits)
	skulls_on_throne = cfg.get_value("meta", "skulls_on_throne", skulls_on_throne)
	lifetime_floors_cleared = cfg.get_value("meta", "lifetime_floors_cleared", lifetime_floors_cleared)
	sanctum_tutorial_seen = cfg.get_value("meta", "sanctum_tutorial_seen", sanctum_tutorial_seen)
	tutorial_waystation_seen = cfg.get_value("meta", "tutorial_waystation_seen", tutorial_waystation_seen)
	tutorial_stain_seen = cfg.get_value("meta", "tutorial_stain_seen", tutorial_stain_seen)
	ascended_next_run = cfg.get_value("meta", "ascended_next_run", ascended_next_run)
	locked_stat_character_id = cfg.get_value("meta", "locked_stat_character_id", locked_stat_character_id)
	locked_stat_roll = cfg.get_value("meta", "locked_stat_roll", locked_stat_roll)
	var _ver: int = cfg.get_value("meta", "save_version", 0)
	if _ver < SAVE_VERSION and lifetime_floors_cleared == 0:
		lifetime_floors_cleared = int(cfg.get_value("meta", "zones_cleared_legacy", 0))

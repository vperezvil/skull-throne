extends RefCounted
class_name CharacterTraits

const MAX_TRAITS_PER_HERO := 5

# Persistent soul marks: Stains (from retreat) and Oaths (from victory). Saved in MetaProgress.roster_traits.

const MARKS_LABEL := "Soul marks"
const STAIN_LABEL := "Stain"
const OATH_LABEL := "Oath"

const DEFINITIONS: Dictionary = {
	# --- Stains (early retreat) ---
	"yellowed": {
		"title": "Faltering Step",
		"positive": false,
		"desc": "Hesitant when the descent turns ugly. -5 initiative.",
		"initiative": -5,
	},
	"shaken": {
		"title": "Frail Vigour",
		"positive": false,
		"desc": "The body remembers running. -8 max HP.",
		"max_hp": -8,
	},
	"deserter_guilt": {
		"title": "Turned Back",
		"positive": false,
		"desc": "Strikes lack conviction after abandoning the path. -3 attack.",
		"attack": -3,
	},
	"haunted": {
		"title": "Grave Whispers",
		"positive": false,
		"desc": "Dead voices claw at each turn of battle. Lose 4 HP at turn start in combat.",
		"turn_start_hp_loss": 4,
	},
	"thin_blood": {
		"title": "Seeping Wounds",
		"positive": false,
		"desc": "Blood does not hold. +12% damage taken.",
		"incoming_damage_mult": 1.12,
	},
	"gloom": {
		"title": "Dulled Recovery",
		"positive": false,
		"desc": "Salves and spells barely take. -20% healing received.",
		"healing_mult": 0.8,
	},
	# --- Oaths (full victory) ---
	"iron_nerves": {
		"title": "First to Blood",
		"positive": true,
		"desc": "Leaps into the fray. +5 initiative.",
		"initiative": 5,
	},
	"battle_hardened": {
		"title": "Throne-Tested",
		"positive": true,
		"desc": "Survived the worst and grew. +6 max HP, +2 attack.",
		"max_hp": 6,
		"attack": 2,
	},
	"clear_mind": {
		"title": "Red Focus",
		"positive": true,
		"desc": "Mind locked on the kill. +2 MP regen per turn.",
		"mp_regen": 2,
	},
	"lucky_scars": {
		"title": "Cleaving Eye",
		"positive": true,
		"desc": "Knows where bone breaks. +4% crit.",
		"crit_rate": 0.04,
	},
}

static func is_positive(trait_id: String) -> bool:
	var data: Dictionary = DEFINITIONS.get(trait_id, {})
	return bool(data.get("positive", false))

static func get_category_label(trait_id: String) -> String:
	return OATH_LABEL if is_positive(trait_id) else STAIN_LABEL

static func get_title(trait_id: String) -> String:
	return String(DEFINITIONS.get(trait_id, {}).get("title", trait_id))

static func get_description(trait_id: String) -> String:
	return String(DEFINITIONS.get(trait_id, {}).get("desc", ""))

static func get_stat_modifiers(character_id: String) -> Dictionary:
	var out := {
		"attack": 0,
		"max_hp": 0,
		"initiative": 0,
		"crit_rate": 0.0,
		"mp_regen": 0,
	}
	for trait_id in MetaProgress.get_traits(character_id):
		var data: Dictionary = DEFINITIONS.get(trait_id, {})
		out["attack"] += int(data.get("attack", 0))
		out["max_hp"] += int(data.get("max_hp", 0))
		out["initiative"] += int(data.get("initiative", 0))
		out["crit_rate"] += float(data.get("crit_rate", 0.0))
		out["mp_regen"] += int(data.get("mp_regen", 0))
	out = _apply_synergy_bonuses(character_id, out)
	return out

static func _apply_synergy_bonuses(character_id: String, mods: Dictionary) -> Dictionary:
	var out := mods.duplicate()
	var mod_id := RunState.run_modifier_id if RunState.campaign_active else ""
	if mod_id == "blood_frenzy" and MetaProgress.get_traits(character_id).has("clear_mind"):
		out["attack"] = int(out.get("attack", 0)) + 2
	if mod_id == "heroes_haste" and MetaProgress.get_traits(character_id).has("iron_nerves"):
		out["initiative"] = int(out.get("initiative", 0)) + 3
	if RunState.run_blessing_ids.has("khorne_might") and MetaProgress.get_traits(character_id).has("battle_hardened"):
		out["attack"] = int(out.get("attack", 0)) + 2
	return out

static func modify_run_gold_gain(base: int, character_id: String) -> int:
	if MetaProgress.get_traits(character_id).has("deserter_guilt"):
		return int(base * 0.9)
	return base

static func try_flee_stain_roll(character: Character) -> void:
	if character == null or randf() > 0.08:
		return
	roll_random_stain(character.character_id)

static func on_first_enemy_kill_in_battle(killer: Character) -> void:
	if killer == null or killer.get_meta("oath_kill_bonus", false):
		return
	killer.set_meta("oath_kill_bonus", true)
	if MetaProgress.get_traits(killer.character_id).has("iron_nerves"):
		killer.recalculate_combat_stats()
		killer.initiative = clampi(killer.initiative + 2, 1, 100)

static func roll_random_stain(character_id: String) -> Dictionary:
	var stains := _stain_pool()
	stains.shuffle()
	for tid in stains:
		if MetaProgress.try_add_trait(character_id, tid):
			return {"trait_id": tid, "title": get_title(tid), "category": STAIN_LABEL}
	return {}

static func roll_random_oath(character_id: String) -> Dictionary:
	var oaths := _oath_pool()
	oaths.shuffle()
	for tid in oaths:
		if MetaProgress.try_add_trait(character_id, tid):
			return {"trait_id": tid, "title": get_title(tid), "category": OATH_LABEL}
	return {}

static func get_incoming_damage_multiplier(character_id: String) -> float:
	var mult := 1.0
	for trait_id in MetaProgress.get_traits(character_id):
		var data: Dictionary = DEFINITIONS.get(trait_id, {})
		if data.has("incoming_damage_mult"):
			mult *= float(data["incoming_damage_mult"])
	return mult

static func get_healing_multiplier(character_id: String) -> float:
	var mult := 1.0
	for trait_id in MetaProgress.get_traits(character_id):
		var data: Dictionary = DEFINITIONS.get(trait_id, {})
		if data.has("healing_mult"):
			mult *= float(data["healing_mult"])
	return mult

static func tick_combat_turn_start(character: Character) -> String:
	if character == null:
		return ""
	for trait_id in MetaProgress.get_traits(character.character_id):
		var data: Dictionary = DEFINITIONS.get(trait_id, {})
		var loss := int(data.get("turn_start_hp_loss", 0))
		if loss <= 0:
			continue
		character.current_hp = maxi(0, character.current_hp - loss)
		character.update_progress_bar()
		return "%s -%d HP" % [get_title(trait_id), loss]
	return ""

static func format_roster_line(character_id: String, display_name: String) -> String:
	var traits := MetaProgress.get_traits(character_id)
	if traits.is_empty():
		return display_name
	var parts: PackedStringArray = []
	for tid in traits:
		var tag := OATH_LABEL if is_positive(tid) else STAIN_LABEL
		parts.append("%s: %s" % [tag, get_title(tid)])
	return "%s (%s)" % [display_name, "; ".join(parts)]

static func roll_early_retreat_traits(party: Array, penalty_fraction: float, is_early: bool) -> Array:
	var results: Array = []
	var stains := _stain_pool()
	if stains.is_empty():
		return results
	for member in party:
		if !(member is Character):
			continue
		var ch: Character = member
		var chance := 0.12
		if is_early:
			chance = 0.30 + penalty_fraction * 0.50
		if randf() > chance:
			continue
		stains.shuffle()
		for trait_id in stains:
			if MetaProgress.try_add_trait(ch.character_id, trait_id):
				results.append({
					"character_id": ch.character_id,
					"name": ch.name,
					"trait_id": trait_id,
					"title": get_title(trait_id),
					"category": STAIN_LABEL,
				})
				break
	return results

static func roll_victory_oaths(party: Array) -> Array:
	var results: Array = []
	var oaths := _oath_pool()
	if oaths.is_empty():
		return results
	for member in party:
		if !(member is Character):
			continue
		if member.current_hp <= 0:
			continue
		var ch: Character = member
		if randf() > 0.22:
			continue
		oaths.shuffle()
		for trait_id in oaths:
			if MetaProgress.try_add_trait(ch.character_id, trait_id):
				results.append({
					"character_id": ch.character_id,
					"name": ch.name,
					"trait_id": trait_id,
					"title": get_title(trait_id),
					"category": OATH_LABEL,
				})
				break
	return results

static func treatment_cost(trait_id: String) -> int:
	if is_positive(trait_id):
		return 75
	return 45

static func _stain_pool() -> Array[String]:
	var out: Array[String] = []
	for key in DEFINITIONS.keys():
		if !is_positive(key):
			out.append(String(key))
	return out

static func _oath_pool() -> Array[String]:
	var out: Array[String] = []
	for key in DEFINITIONS.keys():
		if is_positive(key):
			out.append(String(key))
	return out

# Back-compat alias for callers not yet updated.
static func roll_victory_virtues(party: Array) -> Array:
	return roll_victory_oaths(party)

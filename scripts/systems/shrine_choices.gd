extends RefCounted
class_name ShrineChoices

const OPTIONS: Dictionary = {
	"khorne_might": {
		"title": "Khorne's Might",
		"desc": "Party gains +4 attack for this run.",
	},
	"sanctum_vigor": {
		"title": "Sanctum Vigor",
		"desc": "Party gains +20 max HP for this run.",
	},
	"sharp_instinct": {
		"title": "Sharp Instinct",
		"desc": "Party gains +5% crit for this run.",
	},
	"blood_focus": {
		"title": "Blood Focus",
		"desc": "Party gains +2 MP regen per turn in combat.",
	},
	"gold_whisper": {
		"title": "Gold Whisper",
		"desc": "+20 run gold now; +10% gold for rest of run.",
	},
	"purifying_flame": {
		"title": "Purifying Flame",
		"desc": "Remove bleed and poison from the party.",
	},
}

static func roll_options(count: int = 3) -> Array[String]:
	var keys: Array = OPTIONS.keys()
	keys.shuffle()
	var out: Array[String] = []
	for i in mini(count, keys.size()):
		out.append(String(keys[i]))
	return out

static func get_title(option_id: String) -> String:
	var data: Dictionary = OPTIONS.get(option_id, {})
	return String(data.get("title", option_id))

static func get_description(option_id: String) -> String:
	var data: Dictionary = OPTIONS.get(option_id, {})
	return String(data.get("desc", ""))

static func apply(option_id: String, party: Array) -> String:
	if !OPTIONS.has(option_id):
		return "The shrine falls silent."
	RunState.add_blessing(option_id)
	match option_id:
		"gold_whisper":
			RunState.add_run_gold(20)
		"purifying_flame":
			for member in party:
				if member is Character:
					member.clear_status_effects()
	for member in party:
		if member is Character:
			member.apply_blessing_bonuses()
	return "%s - %s" % [get_title(option_id), get_description(option_id)]

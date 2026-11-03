extends RefCounted
class_name StressSystem

const STRESS_MAX := 100
const STRESS_BREAK := 100

static func add_stress(character: Character, amount: int, _reason: String = "") -> Array:
	var events: Array = []
	if character == null or amount <= 0 or !RunState.campaign_active:
		return events
	character.stress = clampi(character.stress + amount, 0, STRESS_MAX + 20)
	if character.stress >= STRESS_BREAK:
		character.stress = int(STRESS_BREAK * 0.35)
		if randf() < 0.55:
			var stain: Dictionary = CharacterTraits.roll_random_stain(character.character_id)
			if !stain.is_empty():
				events.append({
					"type": "stain",
					"name": character.name,
					"title": String(stain.get("title", "")),
				})
		elif randf() < 0.12:
			var oath: Dictionary = CharacterTraits.roll_random_oath(character.character_id)
			if !oath.is_empty():
				events.append({
					"type": "oath",
					"name": character.name,
					"title": String(oath.get("title", "")),
				})
		else:
			events.append({"type": "vent", "name": character.name, "title": "Shook it off"})
	return events

static func on_damage_taken(character: Character) -> void:
	add_stress(character, 8, "hit")

static func on_flee(party: Array) -> Array:
	var events: Array = []
	for member in party:
		if member is Character:
			events.append_array(add_stress(member, 25, "flee"))
			if randf() < 0.08:
				CharacterTraits.try_flee_stain_roll(member)
	return events

static func on_low_hp_turn(character: Character) -> void:
	if character.max_hp > 0 and character.current_hp <= int(character.max_hp * 0.25):
		add_stress(character, 5, "low_hp")

static func apply_retreat_stress(party: Array) -> Array:
	var events: Array = []
	for member in party:
		if member is Character:
			events.append_array(add_stress(member, 18, "retreat"))
	return events

static func reduce_stress_party(party: Array, amount: int) -> void:
	for member in party:
		if member is Character:
			member.stress = maxi(0, member.stress - amount)

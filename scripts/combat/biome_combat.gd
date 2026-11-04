extends RefCounted
class_name BiomeCombat

# Biome rules and enemy combat_trait targeting for battles.

static func get_battle_opening(theme_id: String) -> String:
	match theme_id:
		"swamp_mire":
			return "\nSwamp mire: enemy hits drain 1 MP."
		"nerve_catacombs":
			return "\nNerve catacombs: foes prefer wounded heroes."
		"ice_citadel":
			return "\nIce citadel: bruisers and ice bias target your toughest hero."
		"blood_cathedral":
			return "\nBlood cathedral: enemy strikes hit slightly harder."
		"crystal_depths":
			return "\nCrystal depths: hits may slow initiative."
		"marble_halls":
			return "\nMarble halls: arcane enemies deal extra magic harm."
		"bone_crypt":
			return "\nBone crypt: skirmishers finish low HP targets."
		"sandstone_ruins":
			return "\nSandstone ruins: enemy damage is slightly reduced."
		"grim_fields":
			return "\nGrim fields: standard skirmish."
		"throne_approach", "skull_throne":
			return "\nThe air thickens - Khorne's servants fight ruthlessly."
		_:
			return ""

static func pick_target(theme_id: String, enemy, targets: Array) -> Character:
	var alive: Array[Character] = []
	for t in targets:
		if t is Character and t.current_hp > 0:
			alive.append(t)
	if alive.is_empty():
		return null
	var combat_trait: String = _enemy_trait(enemy)
	match combat_trait:
		"skirmisher":
			return _lowest_hp(alive)
		"bruiser":
			return _highest_hp(alive)
		"arcane":
			return _lowest_mp_or_hp(alive)
		"lurker":
			if randf() < 0.4:
				return _lowest_hp(alive)
			return alive[randi() % alive.size()]
	match theme_id:
		"ice_citadel":
			return _highest_hp(alive)
		"nerve_catacombs", "bone_crypt":
			return _lowest_hp(alive)
		_:
			return alive[randi() % alive.size()]

static func compute_enemy_damage(theme_id: String, enemy, _target: Character) -> int:
	var damage: int = int(enemy.attack)
	var combat_trait: String = _enemy_trait(enemy)
	if combat_trait == "arcane":
		damage = int(damage * 1.12)
	if combat_trait == "bruiser":
		damage = int(damage * 1.05)
	if enemy.get("is_elite") == true:
		damage = int(damage * 1.1)
	match theme_id:
		"blood_cathedral", "throne_approach", "skull_throne":
			damage = int(damage * 1.08)
		"marble_halls":
			if combat_trait == "arcane":
				damage = int(damage * 1.12)
		"sandstone_ruins":
			damage = int(damage * 0.92)
	return modify_enemy_damage(damage)

static func apply_post_hit(theme_id: String, _enemy, target: Character, _damage: int) -> String:
	if target == null:
		return ""
	match theme_id:
		"swamp_mire":
			if target.max_mp > 0:
				target.current_mp = maxi(0, target.current_mp - 1)
				target._update_resource_bars()
			if target is Character and randf() < 0.35:
				target.apply_poison(1)
				return "\nMire saps %s's focus and poisons them." % target.name
			return "\nMire saps %s's focus." % target.name
		"blood_cathedral", "nerve_catacombs":
			if target is Character and randf() < 0.3:
				target.apply_bleed(1)
				return "\n%s begins to bleed." % target.name
		"crystal_depths":
			if randf() < 0.22:
				target.initiative = maxi(1, target.initiative - 4)
				return "\nCrystal shock slows %s." % target.name
	return ""

static func _enemy_trait(enemy) -> String:
	if enemy == null:
		return "standard"
	if enemy.get("combat_trait") != null:
		return String(enemy.combat_trait)
	return "standard"

static func modify_enemy_damage(base_damage: int) -> int:
	var d: int = float(base_damage) * RunModifiers.enemy_damage_multiplier(RunState.run_modifier_id)
	d *= RunModifiers.ascended_enemy_damage_multiplier(RunState.ascended_run)
	return maxi(1, int(d))

static func _lowest_hp(targets: Array) -> Character:
	var pick: Character = targets[0]
	for t in targets:
		if t.current_hp < pick.current_hp:
			pick = t
	return pick

static func _highest_hp(targets: Array) -> Character:
	var pick: Character = targets[0]
	for t in targets:
		if t.current_hp > pick.current_hp:
			pick = t
	return pick

static func _lowest_mp_or_hp(targets: Array) -> Character:
	var magic: Array[Character] = []
	for t in targets:
		if t.max_mp > 0:
			magic.append(t)
	if magic.is_empty():
		return _lowest_hp(targets)
	var pick: Character = magic[0]
	for t in magic:
		if t.current_mp < pick.current_mp:
			pick = t
	return pick

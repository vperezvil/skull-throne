extends RefCounted
class_name HubCommerce

# Shop and trainer purchases; use_run_gold = waystation, else Blood Tithe in sanctum.

static func buy_equipment(equipment_id: String, use_run_gold: bool) -> bool:
	var def: EquipmentDefinition = EquipmentRegistry.get_definition(equipment_id)
	if def == null:
		return false
	var price := def.waystation_price if use_run_gold else def.sanctum_price
	if use_run_gold:
		if !RunState.spend_run_gold(price):
			return false
	else:
		if !MetaProgress.spend_tithe(price):
			return false
	RunState.add_to_stash(equipment_id)
	return true

static func buy_potion(use_run_gold: bool) -> bool:
	var price := 18 if use_run_gold else 25
	if use_run_gold:
		if !RunState.spend_run_gold(price):
			return false
	else:
		if !MetaProgress.spend_tithe(price):
			return false
	return MetaProgress.grant_potion_to_inventory()

static func train_skill(character_id: String, use_run_gold: bool) -> bool:
	var price := 20 if use_run_gold else 35
	if use_run_gold:
		if !RunState.spend_run_gold(price):
			return false
	else:
		if !MetaProgress.spend_tithe(price):
			return false
	return MetaProgress.upgrade_skill_tier(character_id)

static func equip_on_character(character: Character, equipment_id: String) -> bool:
	if character == null or !RunState.stash_has(equipment_id):
		return false
	var def: EquipmentDefinition = EquipmentRegistry.get_definition(equipment_id)
	if def == null:
		return false
	RunState.equip(character.character_id, equipment_id, def.slot)
	character.apply_run_equipment()
	return true

static func rest_party(members: Array) -> void:
	for member in members:
		if member is Character and member.current_hp > 0:
			member.current_hp = member.max_hp
			member.current_mp = member.max_mp
			member.update_progress_bar()

static func treat_trait(character_id: String, trait_id: String) -> bool:
	return MetaProgress.treat_trait(character_id, trait_id)

static func waystation_campfire(party: Array) -> bool:
	const COST := 35
	if !RunState.spend_run_gold(COST):
		return false
	HubCommerce.rest_party(party)
	for member in party:
		if member is Character:
			member.clear_status_effects()
			member.stress = maxi(0, member.stress - 20)
	var purified: bool = false
	for member in party:
		if member is Character:
			var stains: Array = MetaProgress.get_traits(member.character_id)
			for tid in stains:
				if !CharacterTraits.is_positive(tid):
					MetaProgress.remove_trait(member.character_id, tid)
					purified = true
					break
			if purified:
				member.recalculate_combat_stats()
				break
	return true

static func lock_mirror_for_preview(character_id: String, roll: Dictionary) -> bool:
	return MetaProgress.lock_stat_mirror(character_id, roll)

extends RefCounted
class_name SkillLibrary

const ICON_HEAL := "res://assets/items/potion/i-heal.png"
const ICON_HOLY := "res://assets/items/scroll/i-holy_word.png"
const ICON_STAFF := "res://assets/items/staff/i-staff_fire.png"
const ICON_STAFF_WOOD := "res://assets/items/staff/staff08.png"
const ICON_BLADE := "res://assets/items/weapon/quickblade.png"
const ICON_CLUB := "res://assets/items/weapon/club.png"
const ICON_DEX := "res://assets/items/potion/i-gain-dexterity.png"
const ICON_BLOOD := "res://assets/items/potion/i-blood.png"

static func get_skills_for_character(character_id: String) -> Array[SkillDefinition]:
	var skills := _base_skills(character_id)
	var tier := MetaProgress.get_skill_tier(character_id)
	skills.append_array(_tier_bonus_skills(character_id, tier))
	return skills

static func _base_skills(character_id: String) -> Array[SkillDefinition]:
	match character_id:
		"trece":
			return [
				_make("trece_pounce", "Pounce", "Leap strike - high agility burst.", 5, 18, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.PHYSICAL, 0.05, 15, 2, ICON_DEX),
				_make("trece_claw", "Raking Claw", "Quick slashing attack.", 0, 12, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.PHYSICAL, 0.1, 0, 0, ICON_BLADE),
			]
		"tinybones":
			return [
				_make("tinybones_backstab", "Backstab", "Strike from the shadows - high crit.", 8, 10, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.PHYSICAL, 0.45, 0, 2, ICON_BLADE),
				_make("tinybones_filch", "Filch", "Cheap shot with extra crit chance.", 3, 6, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.PHYSICAL, 0.25, 0, 1, ICON_BLOOD),
			]
		"beth":
			return [
				_make("beth_heal", "Soothing Light", "Restore ally HP using MP.", 12, 35, SkillDefinition.TargetKind.ALLY, SkillDefinition.DamageKind.HEAL, 0.0, 0, 1, ICON_HEAL),
				_make("beth_holy_bolt", "Holy Bolt", "Radiant magic damage.", 10, 22, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.MAGICAL, 0.0, 0, 1, ICON_HOLY),
				_make("beth_prayer", "Prayer", "Heal yourself.", 8, 20, SkillDefinition.TargetKind.SELF, SkillDefinition.DamageKind.HEAL, 0.0, 0, 2, ICON_HEAL),
			]
		"dalf":
			return [
				_make("dalf_arcane_blast", "Arcane Blast", "Focused magical assault.", 14, 28, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.MAGICAL, 0.0, 0, 2, ICON_STAFF),
				_make("dalf_staff_strike", "Staff Strike", "Blunt physical blow.", 0, 16, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.PHYSICAL, 0.0, 0, 0, ICON_STAFF_WOOD),
				_make("dalf_fire_bolt", "Fire Bolt", "Less MP, moderate magic.", 8, 18, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.MAGICAL, 0.0, 0, 1, ICON_STAFF),
			]
	return []

static func _tier_bonus_skills(character_id: String, tier: int) -> Array[SkillDefinition]:
	var out: Array[SkillDefinition] = []
	if tier >= 2:
		match character_id:
			"trece":
				out.append(_make("trece_rend", "Savage Rend", "Heavy claw tear.", 6, 20, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.PHYSICAL, 0.15, 0, 2, ICON_BLADE))
			"tinybones":
				out.append(_make("tinybones_poison", "Venom Cut", "Wounding strike.", 5, 14, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.PHYSICAL, 0.1, 0, 2, ICON_BLOOD))
			"beth":
				out.append(_make("beth_smite", "Smite", "Extra holy damage.", 12, 26, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.MAGICAL, 0.0, 0, 2, ICON_HOLY))
			"dalf":
				out.append(_make("dalf_ice_lance", "Ice Lance", "Piercing frost magic.", 11, 24, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.MAGICAL, 0.0, 0, 2, ICON_STAFF))
	if tier >= 3:
		match character_id:
			"trece":
				out.append(_make("trece_frenzy", "Frenzy", "Wild multi-hit burst.", 10, 16, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.PHYSICAL, 0.2, 10, 3, ICON_DEX))
			"tinybones":
				out.append(_make("tinybones_assassinate", "Assassinate", "Devastating crit finisher.", 14, 12, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.PHYSICAL, 0.55, 0, 3, ICON_BLADE))
			"beth":
				out.append(_make("beth_benediction", "Benediction", "Strong party heal.", 16, 45, SkillDefinition.TargetKind.ALLY, SkillDefinition.DamageKind.HEAL, 0.0, 0, 3, ICON_HEAL))
			"dalf":
				out.append(_make("dalf_meteor", "Meteor", "High cost area blast.", 18, 34, SkillDefinition.TargetKind.ENEMY, SkillDefinition.DamageKind.MAGICAL, 0.0, 0, 3, ICON_STAFF))
	return out

static func _make(
	id: String,
	name: String,
	desc: String,
	mp: int,
	power: int,
	target: SkillDefinition.TargetKind,
	kind: SkillDefinition.DamageKind,
	crit: float,
	init_bonus: int,
	cooldown: int = 0,
	icon: String = ""
) -> SkillDefinition:
	var skill := SkillDefinition.new()
	skill.skill_id = id
	skill.display_name = name
	skill.description = desc
	skill.mp_cost = mp
	skill.power = power
	skill.target_kind = target
	skill.damage_kind = kind
	skill.crit_bonus = crit
	skill.initiative_bonus = init_bonus
	skill.cooldown_turns = cooldown
	skill.icon_path = icon
	return skill

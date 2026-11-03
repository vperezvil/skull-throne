extends RefCounted
class_name PartyHudUi

static func format_member_line(ch: Character) -> String:
	var mp_bit: String = ""
	if ch.max_mp > 0:
		mp_bit = " MP %d/%d" % [ch.current_mp, ch.max_mp]
	var status: String = ""
	if ch.bleed_stacks > 0:
		status += " Bl%d" % ch.bleed_stacks
	if ch.poison_stacks > 0:
		status += " Po%d" % ch.poison_stacks
	if ch.stress > 0:
		status += " Str%d" % ch.stress
	var marks: Array = MetaProgress.get_traits(ch.character_id)
	if marks.size() > 0:
		status += " Mk%d" % marks.size()
	var mod: String = ""
	if RunState.campaign_active and RunState.run_modifier_id != "":
		mod = " | %s" % RunModifiers.get_display_name(RunState.run_modifier_id)
	return "%s %d/%d HP%s%s%s" % [ch.name, ch.current_hp, ch.max_hp, mp_bit, status, mod]

static func tooltip_for_member(ch: Character) -> String:
	var parts: PackedStringArray = []
	for tid in MetaProgress.get_traits(ch.character_id):
		parts.append("%s: %s" % [
			CharacterTraits.OATH_LABEL if CharacterTraits.is_positive(tid) else CharacterTraits.STAIN_LABEL,
			CharacterTraits.get_title(tid),
		])
	if RunState.campaign_active and RunState.run_modifier_id != "":
		parts.append("Modifier: " + RunModifiers.get_description(RunState.run_modifier_id))
	if ch.stress > 0:
		parts.append("Stress %d/%d" % [ch.stress, StressSystem.STRESS_MAX])
	if parts.is_empty():
		return ch.name
	return ch.name + "\n" + "\n".join(parts)

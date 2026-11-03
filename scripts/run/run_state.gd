extends Node

var zones_cleared: int = 0
var campaign_active: bool = false
var run_floor_ids: Array[String] = [] # zone_id per floor; last entry is skull_throne
var current_floor_index: int = 0
var floors_cleared_this_run: int = 0
var run_gold: int = 0
var run_gold_earned_total: int = 0
var equipment_stash: Array[String] = []
var run_start_snapshots: Dictionary = {} # level/xp at run start (early abandon rollback)
var run_xp_gained: Dictionary = {}
var character_equipment: Dictionary = {} # character_id -> slot -> equipment_id
var party_stat_variants: Dictionary = {} # character_id -> rolled stat dict for current descent
var party_stat_preview: Dictionary = {}
var _preview_party_key: String = ""
var run_modifier_id: String = ""
var run_blessing_ids: Array[String] = []
var ascended_run: bool = false
var _pending_shrine_options: Array[String] = []

func build_run_summary(victory: bool) -> Dictionary:
	return {
		"floors_cleared": floors_cleared_this_run,
		"gold_earned": run_gold_earned_total,
		"modifier_id": run_modifier_id,
		"ascended": ascended_run,
		"blessings_taken": run_blessing_ids.size(),
		"victory": victory,
		"traits_gained": [],
	}

func add_run_gold(amount: int) -> void:
	if !campaign_active or amount <= 0:
		return
	var scaled := int(amount * RunModifiers.gold_multiplier(run_modifier_id))
	if run_blessing_ids.has("gold_whisper"):
		scaled = int(scaled * 1.1)
	if ascended_run:
		scaled = int(scaled * 0.95)
	run_gold += scaled
	run_gold_earned_total += scaled

func _party_key(party: Array) -> String:
	var ids: PackedStringArray = []
	for member in party:
		if member is Character:
			ids.append(member.character_id)
	ids.sort()
	return ",".join(ids)

func refresh_stat_preview(party: Array) -> void:
	var key := _party_key(party)
	if key == _preview_party_key and !party_stat_preview.is_empty():
		return
	_preview_party_key = key
	party_stat_preview.clear()
	for member in party:
		if member is Character:
			var def: CharacterDefinition = ContentRegistry.get_character_by_id(member.character_id)
			if def != null:
				var rolled := ContentRegistry.roll_stat_variant(def)
				if MetaProgress.get_locked_stat_character_id() == member.character_id:
					var locked := MetaProgress.get_locked_stat_roll()
					if !locked.is_empty():
						rolled = locked
				party_stat_preview[member.character_id] = rolled

func reroll_stat_preview(party: Array) -> void:
	_preview_party_key = ""
	party_stat_preview.clear()
	refresh_stat_preview(party)

func get_stat_preview(character_id: String) -> Dictionary:
	return party_stat_preview.get(character_id, {})

func format_stat_preview_line(character_id: String, display_name: String) -> String:
	var preview := get_stat_preview(character_id)
	if preview.is_empty():
		return display_name
	return "%s: HP %d  ATK %d  INIT %d  MP %d" % [
		display_name,
		int(preview.get("max_hp", 0)),
		int(preview.get("attack", 0)),
		int(preview.get("initiative", 0)),
		int(preview.get("max_mp", 0)),
	]

func roll_party_stats(party: Array) -> void:
	var key := _party_key(party)
	if key == _preview_party_key and !party_stat_preview.is_empty():
		party_stat_variants = party_stat_preview.duplicate(true)
		return
	party_stat_variants.clear()
	for member in party:
		if member is Character:
			var def: CharacterDefinition = ContentRegistry.get_character_by_id(member.character_id)
			if def != null:
				party_stat_variants[member.character_id] = ContentRegistry.roll_stat_variant(def)

func get_stat_variant(character_id: String) -> Dictionary:
	return party_stat_variants.get(character_id, {})

func begin_campaign() -> void:
	campaign_active = true
	current_floor_index = 0
	floors_cleared_this_run = 0
	run_gold = 0
	run_gold_earned_total = 0
	equipment_stash.clear()
	character_equipment.clear()
	run_start_snapshots.clear()
	run_xp_gained.clear()
	run_floor_ids = ContentRegistry.build_run_plan()
	run_blessing_ids.clear()
	ascended_run = MetaProgress.ascended_next_run and MetaProgress.can_use_ascended()
	run_modifier_id = RunModifiers.roll_modifier_id(ascended_run)
	_pending_shrine_options.clear()

func reset_campaign() -> void:
	campaign_active = false
	current_floor_index = 0
	floors_cleared_this_run = 0
	run_gold = 0
	run_gold_earned_total = 0
	equipment_stash.clear()
	character_equipment.clear()
	run_start_snapshots.clear()
	run_xp_gained.clear()
	run_floor_ids.clear()
	party_stat_variants.clear()
	party_stat_preview.clear()
	_preview_party_key = ""
	run_modifier_id = ""
	run_blessing_ids.clear()
	ascended_run = false
	_pending_shrine_options.clear()

func add_blessing(blessing_id: String) -> void:
	if blessing_id == "" or run_blessing_ids.has(blessing_id):
		return
	run_blessing_ids.append(blessing_id)

func get_blessing_attack_bonus() -> int:
	return 4 if run_blessing_ids.has("khorne_might") else 0

func get_blessing_hp_bonus() -> int:
	return 20 if run_blessing_ids.has("sanctum_vigor") else 0

func get_blessing_crit_bonus() -> float:
	return 0.05 if run_blessing_ids.has("sharp_instinct") else 0.0

func get_blessing_mp_regen_bonus() -> int:
	return 2 if run_blessing_ids.has("blood_focus") else 0

func should_offer_shrine() -> bool:
	if !campaign_active or !has_more_floors():
		return false
	if should_open_waystation():
		return false
	return randf() < 0.45

func roll_shrine_options() -> Array[String]:
	_pending_shrine_options = ShrineChoices.roll_options(3)
	return _pending_shrine_options

func get_shrine_options() -> Array[String]:
	return _pending_shrine_options

func record_zone_cleared() -> void:
	zones_cleared += 1
	MetaProgress.record_lifetime_floor_cleared()
	if campaign_active:
		floors_cleared_this_run += 1
		var floor_gold := GameConstants.RUN_GOLD_PER_FLOOR
		floor_gold += RunModifiers.floor_clear_gold_bonus(run_modifier_id)
		run_gold += int(floor_gold * RunModifiers.gold_multiplier(run_modifier_id))
		run_gold_earned_total += int(floor_gold * RunModifiers.gold_multiplier(run_modifier_id))

func snapshot_party_progress(party: Array) -> void:
	run_start_snapshots.clear()
	run_xp_gained.clear()
	for member in party:
		if member is Character:
			run_start_snapshots[member.character_id] = {
				"level": member.level,
				"xp": member.xp,
				"base_max_hp": member._base_max_hp,
				"base_attack": member._base_attack,
				"base_crit_rate": member._base_crit_rate,
				"max_mp": member.max_mp,
				"initiative": member.initiative,
			}
			run_xp_gained[member.character_id] = 0

func record_xp_gained(character_id: String, amount: int) -> void:
	if !campaign_active or amount <= 0:
		return
	run_xp_gained[character_id] = int(run_xp_gained.get(character_id, 0)) + amount

func is_early_return() -> bool:
	return campaign_active and floors_cleared_this_run < GameConstants.EARLY_RETURN_SAFE_FLOORS

func get_early_return_penalty_fraction() -> float:
	if !is_early_return():
		return 0.0
	var missing := GameConstants.EARLY_RETURN_SAFE_FLOORS - floors_cleared_this_run
	return clampf(missing * 0.25, 0.25, 0.75)

func get_voluntary_abandon_warning_text() -> String:
	if is_early_return():
		return get_early_return_warning_text()
	return (
		"You are leaving an active descent (%d floor(s) cleared this run).\n\n"
		% floors_cleared_this_run
		+ "You keep Blood Tithe from progress so far, but heroes may gain Stains or stress.\n\n"
		+ "Return to the Blood Sanctum?"
	)

func get_progression_hint_text() -> String:
	var lines: PackedStringArray = []
	var floors := MetaProgress.get_lifetime_floors_cleared()
	var next_unlock := ContentRegistry.get_next_character_unlock(floors)
	if next_unlock != "":
		lines.append("Next unlock: %s (clear %d lifetime floors)." % [next_unlock, ContentRegistry.get_unlock_floor_for(next_unlock)])
	if MetaProgress.can_use_ascended():
		lines.append("Ascended descent available in sanctum.")
	var est_tithe := maxi(0, GameConstants.RUN_BIOME_FLOORS_MIN) * 12
	lines.append("Typical failed run tithe: ~%d-%d (deeper = more)." % [est_tithe, est_tithe * 3])
	if MetaProgress.get_locked_stat_character_id() != "":
		lines.append("Mirror lock active for %s." % MetaProgress.get_locked_stat_character_id())
	return "\n".join(lines)

func get_early_return_warning_text() -> String:
	var penalty := get_early_return_penalty_fraction()
	var pct := int(round(penalty * 100.0))
	var tithe_estimate := int(maxi(0, floors_cleared_this_run) * 12 * (1.0 - penalty))
	return (
		"You are leaving the descent early (only %d floor(s) cleared).\n\n"
		% floors_cleared_this_run
		+ "Returning now imposes a %d%% penalty on rewards this run:\n"
		% pct
		+ "• Run gold (you have %d)\n" % run_gold
		+ "• XP progress gained this descent\n"
		+ "• Levels gained this descent\n\n"
		+ "Heroes may gain lasting soul marks (Stains from retreat) that persist in the Blood Sanctum.\n\n"
		+ "Estimated Blood Tithe after penalty: ~%d\n\n"
		% tithe_estimate
		+ "Continue back to the Blood Sanctum?"
	)

func apply_voluntary_abandon_penalties(party: Array, penalty_fraction: float) -> void:
	if penalty_fraction <= 0.0:
		return
	run_gold = int(run_gold * (1.0 - penalty_fraction))
	for member in party:
		if member is Character:
			_apply_character_progress_penalty(member, penalty_fraction)

func _apply_character_progress_penalty(character: Character, penalty_fraction: float) -> void:
	var snap: Dictionary = run_start_snapshots.get(character.character_id, {"level": 1, "xp": 0})
	var snap_level: int = int(snap.get("level", 1))
	var snap_xp: int = int(snap.get("xp", 0))
	var xp_gained: int = int(run_xp_gained.get(character.character_id, 0))
	var levels_gained: int = maxi(0, character.level - snap_level)
	var levels_kept: int = int(floor(levels_gained * (1.0 - penalty_fraction)))
	var xp_kept: int = int(xp_gained * (1.0 - penalty_fraction))
	var snap_base_hp: int = int(snap.get("base_max_hp", character._base_max_hp))
	var snap_base_atk: int = int(snap.get("base_attack", character._base_attack))
	var snap_base_crit: float = float(snap.get("base_crit_rate", character._base_crit_rate))
	var snap_mp: int = int(snap.get("max_mp", character.max_mp))
	var snap_init: int = int(snap.get("initiative", character.initiative))
	character._base_max_hp = snap_base_hp
	character._base_attack = snap_base_atk
	character._base_crit_rate = snap_base_crit
	character.max_hp = snap_base_hp
	character.max_mp = snap_mp
	character.initiative = snap_init
	character.attack = snap_base_atk
	character.crit_rate = snap_base_crit
	MetaProgress.apply_meta_to_character(character)
	character.apply_run_equipment()
	character.level = snap_level
	character.xp = snap_xp
	for _i in levels_kept:
		character.apply_level_up_bonus()
	character.gain_xp(xp_kept, false)
	character.current_hp = mini(character.current_hp, character.max_hp)
	character.current_mp = mini(character.current_mp, character.max_mp)
	if character.progress_bar:
		character.progress_bar.max_value = character.max_hp
		character.progress_bar.value = character.current_hp
	character._update_resource_bars()

func should_open_waystation() -> bool:
	if floors_cleared_this_run <= 0:
		return false
	return floors_cleared_this_run % GameConstants.FLOORS_BETWEEN_WAYSTATIONS == 0

func spend_run_gold(amount: int) -> bool:
	if run_gold < amount:
		return false
	run_gold -= amount
	return true

func add_to_stash(equipment_id: String) -> void:
	if !equipment_stash.has(equipment_id):
		equipment_stash.append(equipment_id)

func stash_has(equipment_id: String) -> bool:
	return equipment_stash.has(equipment_id)

func equip(character_id: String, equipment_id: String, slot: EquipmentDefinition.Slot) -> void:
	if !character_equipment.has(character_id):
		character_equipment[character_id] = {}
	character_equipment[character_id][int(slot)] = equipment_id

func get_equipped_id(character_id: String, slot: EquipmentDefinition.Slot) -> String:
	if !character_equipment.has(character_id):
		return ""
	var slots: Dictionary = character_equipment[character_id]
	return String(slots.get(int(slot), ""))

func advance_floor() -> void:
	current_floor_index += 1

func has_more_floors() -> bool:
	return current_floor_index + 1 < run_floor_ids.size()

func get_current_zone() -> ZoneDefinition:
	if run_floor_ids.is_empty():
		return ContentRegistry.get_zone_by_id("grim_fields")
	return ContentRegistry.get_zone_by_id(run_floor_ids[current_floor_index])

func get_run_floor_count() -> int:
	return run_floor_ids.size()

func get_current_floor_number() -> int:
	return current_floor_index + 1

func get_run_depth() -> int:
	return current_floor_index

func get_skull_throne_bonus_hp() -> int:
	return Global.total_deaths * 5

func is_character_unlocked(definition: CharacterDefinition) -> bool:
	return MetaProgress.get_lifetime_floors_cleared() >= definition.unlock_after_zones_cleared

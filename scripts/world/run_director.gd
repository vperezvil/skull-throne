extends RefCounted
class_name RunDirector

# Run lifecycle helpers used by world.gd (hub return, zone clear flow).

static func build_end_payload(world: Node, victory: bool, voluntary_abandon: bool) -> RunEndPayload:
	var penalty: float = 0.0
	if voluntary_abandon and !victory and RunState.is_early_return():
		penalty = RunState.get_early_return_penalty_fraction()
		RunState.apply_voluntary_abandon_penalties(world.characters, penalty)
	var trait_events: Array = []
	var stress_events: Array = []
	if voluntary_abandon and !victory and RunState.campaign_active:
		trait_events = CharacterTraits.roll_early_retreat_traits(
			world.characters, penalty, RunState.is_early_return()
		)
		stress_events = StressSystem.apply_retreat_stress(world.characters)
	elif victory:
		trait_events = CharacterTraits.roll_victory_oaths(world.characters)
	var earned: int = MetaProgress.complete_run(RunState.floors_cleared_this_run, victory, penalty)
	var run_summary: Dictionary = RunState.build_run_summary(victory)
	run_summary["traits_gained"] = trait_events
	var payload: RunEndPayload = RunEndPayload.from_run(victory, voluntary_abandon, penalty, earned, run_summary, trait_events, stress_events)
	return payload

static func apply_hub_return(world: Node, payload: RunEndPayload) -> void:
	RunState.reset_campaign()
	world._cleanup_zone_entities()
	world.battle_scene.visible = false
	world.tilemap.visible = false
	world.map_music.stop()
	world.ui.in_battle = false
	world.ui.hide_run_overlays()
	for member in world.characters:
		if member is Character:
			MetaProgress.save_veteran_progress(member)
	world._refresh_party_at_hub()
	world.ui.show_hub_after_run(payload)
	if payload.victory:
		Global.play_skull_fanfare_if_enabled()

static func after_zone_cleared(world: Node, remaining_characters: Array) -> void:
	world.characters = remaining_characters
	if world.characters.is_empty():
		return
	for character in world.characters:
		character.battle_started = true
		character.visible = character.current_hp > 0
		if character is Character:
			character.hide_battle_bars()
	world._reassign_party_leadership()
	world.ui.in_battle = false
	world.battle_scene.visible = false
	world.tilemap.visible = false
	world.map_music.stop()
	world.fountain.visible = false
	for item in world.items:
		item.visible = false
	for e in world.enemies:
		if is_instance_valid(e):
			e.visible = false
			e.is_chasing = false
	world.boss.visible = false
	world.boss.battle_started = false
	RunState.record_zone_cleared()
	if RunState.should_open_waystation() and RunState.has_more_floors():
		world.ui.show_waystation(world.characters)
	elif RunState.should_offer_shrine() and RunState.has_more_floors():
		RunState.roll_shrine_options()
		world.ui.show_shrine(world.characters, not RunState.has_more_floors())
	else:
		world.ui.show_zone_cleared(world.characters, not RunState.has_more_floors())

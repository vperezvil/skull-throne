extends Node2D


@onready var character_container = $CharacterContainer
@onready var enemy_container = $EnemyContainer
@onready var battle_menu = $UI/Options
@onready var battle_camera = $BattleCamera
@onready var combat_dialog = $UI/CombatDialog
@onready var background_boss = $"Background Boss"
@onready var background_enemy = $"Background Enemy"
@onready var boss_music = $"Boss Battle"
@onready var enemy_music = $"Enemy Battle"
@onready var win_music = $"Win Battle"
@onready var inventory_button = $UI/Options/Inventory
@onready var skill_panel = $UI/SkillPanel
var original_positions = {}
var original_scales = {}
var original_parents = {}
var enemy_original_state = {}
var combatants = []
var current_turn = 0
var BATTLE_STARTED = "Battle started"
var ATTACK_MSG = "\n{player1} attacking: {player2}"
var DEFEND_MSG = "\n{player1} is defending, will receive half damage on next attack"
var SELECT_ENEMY = "\nSelect Enemy to attack"
var DAMAGE_DEALT = "\n{player1} dealt {damage} damage to {player2}"
var RUN_BOSS = "\nCan't run from the boss!!!"
var RUN = "\nRun successfully"
var WIN_BATTLE = "\nBattle won!"
var SKILL_MSG = "\n{player1} uses {skill} on {player2}"
var CRIT_MSG = " Critical hit!"
var MP_FAIL = "\nNot enough MP!"
var COOLDOWN_FAIL = "\nSkill is on cooldown!"
var MP_REGEN_MSG = "\n{player1} recovered {amount} MP."
var LEVEL_UP_MSG = "\n{player1} reached level {level}!"
var dead_players = 0
var is_boss_battle = false
var is_run_pressed = false
var pending_skill: SkillDefinition = null
var battle_xp_reward: int = 0
var _boss_turn_counter: int = 0
var party_status_label: Label
signal battle_ended
signal battle_fled
signal level_ended
signal game_over
signal inventory_pressed
# Called when the node enters the scene tree for the first time.
func _ready():
	battle_camera.enabled = false
	Global.assign_music_bus(boss_music)
	Global.assign_music_bus(enemy_music)
	Global.assign_music_bus(win_music)
	party_status_label = Label.new()
	party_status_label.name = "PartyStatus"
	party_status_label.visible = false
	party_status_label.offset_left = 353.0
	party_status_label.offset_top = 908.0
	party_status_label.offset_right = 1640.0
	party_status_label.add_theme_font_size_override("font_size", Global.get_ui_font_size(14))
	party_status_label.modulate = Color(0.95, 0.9, 0.85)
	$UI.add_child(party_status_label)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	inventory_button.disabled = Inventory.items.keys().size() == 0
	_update_battle_party_status()

func _update_battle_party_status() -> void:
	if party_status_label == null:
		return
	if !visible or character_container.get_child_count() == 0:
		party_status_label.visible = false
		return
	party_status_label.visible = true
	var parts: PackedStringArray = []
	for ch in character_container.get_children():
		if !(ch is Character) or ch.current_hp <= 0:
			continue
		var tags: String = ""
		if ch.stress > 0:
			tags += " Str %d/%d" % [ch.stress, StressSystem.STRESS_MAX]
		if ch.bleed_stacks > 0:
			tags += " Bl%d" % ch.bleed_stacks
		if ch.poison_stacks > 0:
			tags += " Po%d" % ch.poison_stacks
		parts.append("%s%s" % [ch.name, tags])
	party_status_label.text = "Party: " + " | ".join(parts) if parts.size() > 0 else ""

func start_battle(characters, enemies):
	is_boss_battle = false
	is_run_pressed = false
	dead_players = 0
	background_boss.visible = false
	background_enemy.visible = false
	original_parents.clear()
	original_positions.clear()
	original_scales.clear()
	enemy_original_state.clear()
	pending_skill = null
	battle_xp_reward = 0
	_boss_turn_counter = 0
	for ch in characters:
		if ch is Character:
			ch.reset_battle_state()
	for foe in enemies:
		if foe is Enemy and foe.xp_reward:
			battle_xp_reward += foe.xp_reward
	fill_characters(characters)
	fill_enemies(enemies)
	battle_camera.make_current()
	initialize_combatants(characters,enemies)
	sort_combatants_by_initiative()
	combat_dialog.visible = true
	combat_dialog.text = BATTLE_STARTED
	var zone: ZoneDefinition = RunState.get_current_zone()
	if zone != null:
		combat_dialog.text += BiomeCombat.get_battle_opening(zone.map_theme_id)
	if RunState.run_modifier_id != "":
		combat_dialog.text += "\nRun modifier: %s - %s" % [
			RunModifiers.get_display_name(RunState.run_modifier_id),
			RunModifiers.get_description(RunState.run_modifier_id),
		]
	if is_boss_battle:
		combat_dialog.text += "\nBoss patterns: Warden Blood Cleave every 3 turns; Khorne rampage every 4."
	if RunState.ascended_run:
		combat_dialog.text += "\nAscended descent: deadlier foes and richer risk."
	inventory_button.disabled = Inventory.items.keys().size() == 0
	current_turn = 0
	start_turn()
	
func fill_characters(characters):
	var offset = 30
	var spacing_between_characters = 200
	var is_lonely_character = characters.size() == 1
	for character in characters:
		if character.get_parent() != character_container:
			if character.get_parent() != null:
				original_parents[character] = character.get_parent()
				original_positions[character] = character.position
				original_scales[character] = character.scale
				character.get_parent().remove_child(character)
			if character.has_node("Camera2D"):
				var camera = character.get_node("Camera2D")
				camera.enabled = false
			character.scale *= 2
			if is_lonely_character:
				var min_size = character_container.get_custom_minimum_size()
				character.position = Vector2(min_size.x,min_size.y/2)
			else:
				character.position = Vector2(0,offset)
			offset += spacing_between_characters
			character.collided_with_enemy()
			character.reset_battle_cooldowns()
			character.character_defeated.connect(_on_character_defeated.bind(character))
			character_container.add_child(character)
		character.visible = true
		
func fill_enemies(enemies):
	var is_lonely_enemy = enemies.size() == 1
	for enemy in enemies:
		if enemy is Boss:
			is_boss_battle = true
	if is_boss_battle:
		background_boss.visible = true
		# Music from zone boss_kind (warden vs khorne), set in ZoneMusic.
		boss_music.stream = ZoneMusic.get_boss_battle_music_for_zone(RunState.get_current_zone())
		boss_music.play()
		var zone: ZoneDefinition = RunState.get_current_zone()
		var depth: int = RunState.get_run_depth()
		battle_xp_reward = 200 if zone != null and zone.boss_kind == "khorne" else 120 + depth * 40
	else:
		background_enemy.visible = true
		enemy_music.stream = ZoneMusic.get_enemy_battle_music_for_zone(RunState.get_current_zone())
		enemy_music.play()
	var offset = 30
	var spacing_between_enemies = 250
	for enemy in enemies:
		if enemy.get_parent() != enemy_container:
			if enemy.get_parent() != null:
				enemy_original_state[enemy] = {
					"parent": enemy.get_parent(),
					"position": enemy.position,
					"scale": enemy.scale,
				}
				enemy.get_parent().remove_child(enemy)
			if is_lonely_enemy:
				var min_size = enemy_container.get_custom_minimum_size()
				enemy.position = Vector2(min_size.x,min_size.y/2)
			else:
				enemy.position = Vector2(0,offset)
				offset += spacing_between_enemies
			enemy.scale *= 3
			enemy.progress_bar.visible = true
			enemy.enemy_defeated.connect(_on_enemy_defeated.bind(enemy))
			enemy_container.add_child(enemy)
		enemy.visible = true

func end_battle():
	battle_camera.enabled = false
	battle_menu.visible = false
	if is_boss_battle:
		boss_music.stop()
	else:
		enemy_music.stop()
	if original_parents.size() == 0:
		game_over.emit(dead_players)
		visible = false
		return

	var fled: bool = is_run_pressed
	if !fled:
		var zone: ZoneDefinition = RunState.get_current_zone()
		var finale: bool = zone != null and zone.is_final_zone and is_boss_battle
		win_music.stream = ZoneMusic.get_victory_music(finale)
		win_music.play()
		combat_dialog.text += WIN_BATTLE
	else:
		combat_dialog.text += RUN
		is_run_pressed = false

	for enemy in enemy_container.get_children():
		enemy.focus.visible = false
	for character in character_container.get_children():
		character.focus.visible = false

	await get_tree().create_timer(2.0 if fled else 5.0).timeout
	if fled:
		var flee_party: Array = []
		for ch in character_container.get_children():
			if ch is Character:
				flee_party.append(ch)
		StressSystem.on_flee(flee_party)
	var remaining_characters: Array = _restore_party_members()
	if !fled:
		_award_battle_xp(remaining_characters)
		_award_battle_gold(remaining_characters)
	_restore_enemies_after_battle(fled)
	clear_battle_containers(fled)
	combat_dialog.visible = false
	win_music.stop()
	if fled:
		battle_fled.emit(remaining_characters)
	elif is_boss_battle:
		level_ended.emit(remaining_characters)
	else:
		battle_ended.emit(remaining_characters)

func _restore_party_members() -> Array:
	var remaining_characters: Array = []
	for character in original_parents.keys():
		var parent = original_parents[character]
		if character.get_parent() == character_container:
			character_container.remove_child(character)
		character.position = original_positions[character]
		character.scale = original_scales[character]
		character.visible = is_party_member_visible(character)
		character.ap.play("RESET")
		parent.add_child(character)
		remaining_characters.append(character)
	return remaining_characters

func is_party_member_visible(_character: Character) -> bool:
	return true

func _is_persistent_world_enemy(enemy) -> bool:
	return enemy is Boss

func _restore_enemies_after_battle(fled: bool) -> void:
	for enemy in enemy_original_state.keys():
		if !is_instance_valid(enemy):
			continue
		if enemy.get_parent() == enemy_container:
			enemy_container.remove_child(enemy)
		var state: Dictionary = enemy_original_state[enemy]
		enemy.position = state["position"]
		enemy.scale = state["scale"]
		enemy.battle_started = false
		enemy.progress_bar.visible = false
		if fled or _is_persistent_world_enemy(enemy):
			state["parent"].add_child(enemy)
			if _is_persistent_world_enemy(enemy) and !fled:
				enemy.visible = false
		else:
			enemy.queue_free()
	enemy_original_state.clear()

func clear_battle_containers(fled: bool) -> void:
	for child in character_container.get_children():
		character_container.remove_child(child)
	for child in enemy_container.get_children():
		enemy_container.remove_child(child)
		if child.get_meta("battle_spawn", false):
			child.queue_free()
		elif !fled and not _is_persistent_world_enemy(child):
			child.queue_free()
	combatants.clear()

func _on_attack_pressed():
	battle_menu.visible = false
	skill_panel.visible = false
	pending_skill = null
	show_enemy_options(false)

func _on_skills_pressed():
	battle_menu.visible = false
	skill_panel.visible = false
	for child in skill_panel.get_children():
		skill_panel.remove_child(child)
		child.queue_free()
	var current_combatant: Character = combatants[current_turn]
	if !check_if_container_has_child(character_container, current_combatant):
		advance_turn()
		return
	if current_combatant.skills.is_empty():
		combat_dialog.text += "\nNo skills available."
		battle_menu.visible = true
		return
	var user: Character = current_combatant
	var tier: int = MetaProgress.get_skill_tier(user.character_id)
	var mult: float = MetaProgress.get_skill_damage_multiplier(user.character_id)
	combat_dialog.text += "\nTier %d (damage x%.2f)." % [tier, mult]
	if tier < 2:
		combat_dialog.text += " Sanctum tier 2+ unlocks extra skills."
	for skill in current_combatant.skills:
		var btn := Button.new()
		var cd: int = current_combatant.get_skill_cooldown_remaining(skill.skill_id)
		var label: String = skill.display_name
		if skill.mp_cost > 0:
			label += " (%d MP)" % skill.mp_cost
		if user != null and skill.damage_kind != SkillDefinition.DamageKind.HEAL:
			label += " x%.0f%%" % (MetaProgress.get_skill_damage_multiplier(user.character_id) * 100.0)
		if cd > 0:
			label += " [CD %d]" % cd
		btn.text = label
		btn.disabled = !current_combatant.can_use_skill(skill)
		if skill.icon_path != "":
			var icon_tex: Texture2D = load(skill.icon_path)
			if icon_tex:
				btn.icon = icon_tex
				btn.expand_icon = true
		btn.tooltip_text = skill.description
		btn.pressed.connect(_on_skill_chosen.bind(skill))
		skill_panel.add_child(btn)
	skill_panel.visible = true
	combat_dialog.text += "\nChoose a skill."

func _on_skill_chosen(skill: SkillDefinition) -> void:
	skill_panel.visible = false
	var user: Character = combatants[current_turn]
	if user.get_skill_cooldown_remaining(skill.skill_id) > 0:
		combat_dialog.text += COOLDOWN_FAIL
		battle_menu.visible = true
		return
	if skill.mp_cost > 0 and user.current_mp < skill.mp_cost:
		combat_dialog.text += MP_FAIL
		battle_menu.visible = true
		return
	pending_skill = skill
	match skill.target_kind:
		SkillDefinition.TargetKind.ENEMY:
			show_enemy_options(true)
		SkillDefinition.TargetKind.ALLY:
			show_ally_options(user)
		SkillDefinition.TargetKind.SELF:
			_apply_skill(user, skill, user)

func show_enemy_options(for_skill: bool) -> void:
	if !for_skill:
		combat_dialog.text += SELECT_ENEMY
	else:
		combat_dialog.text += "\nSelect target."
	for enemy in enemy_container.get_children():
		enemy.focus.visible = true
		for connected in enemy.enemy_selected.get_connections():
			enemy.enemy_selected.disconnect(connected["callable"])
		enemy.enemy_selected.connect(_on_enemy_selected.bind(enemy))

func show_ally_options(_user: Character) -> void:
	combat_dialog.text += "\nSelect ally."
	for ally in character_container.get_children():
		if ally is Character:
			var btn := Button.new()
			btn.text = ally.name
			btn.pressed.connect(_on_ally_skill_pressed.bind(ally))
			skill_panel.add_child(btn)
	skill_panel.visible = true

func _on_ally_skill_pressed(ally: Character) -> void:
	skill_panel.visible = false
	var user: Character = combatants[current_turn]
	if pending_skill != null:
		_apply_skill(user, pending_skill, ally)

func _apply_skill(user: Character, skill: SkillDefinition, target) -> void:
	if user.get_skill_cooldown_remaining(skill.skill_id) > 0:
		combat_dialog.text += COOLDOWN_FAIL
		pending_skill = null
		battle_menu.visible = true
		return
	if skill.mp_cost > 0 and !user.spend_mp(skill.mp_cost):
		combat_dialog.text += MP_FAIL
		pending_skill = null
		battle_menu.visible = true
		return
	var target_name: String = target.name if target else user.name
	combat_dialog.text += SKILL_MSG.replace("{player1}", user.name).replace("{skill}", skill.display_name).replace("{player2}", target_name)
	match skill.damage_kind:
		SkillDefinition.DamageKind.HEAL:
			if target is Character:
				target.apply_healing(skill.power)
		SkillDefinition.DamageKind.PHYSICAL, SkillDefinition.DamageKind.MAGICAL:
			if target is Combatant or target is Boss:
				var was_crit: bool = false
				var damage: int = user.compute_skill_damage(skill, target)
				if user is Character and skill.damage_kind == SkillDefinition.DamageKind.PHYSICAL:
					was_crit = damage >= (user.attack + skill.power) * 2 - 1
				combat_dialog.text += DAMAGE_DEALT.replace("{player1}", user.name).replace("{damage}", str(damage)).replace("{player2}", target_name)
				if was_crit:
					combat_dialog.text += CRIT_MSG
				if target is Character:
					target.receive_damage(damage, was_crit)
				else:
					target.receive_damage(damage)
	if skill.initiative_bonus > 0:
		user.initiative = clampi(user.initiative + skill.initiative_bonus, 1, 100)
	user.start_skill_cooldown(skill)
	pending_skill = null
	remove_focus()
	remove_highlight(user)
	advance_turn()

func _on_enemy_selected(enemy):
	var current_combatant = combatants[current_turn]
	for connected in enemy.enemy_selected.get_connections():
		enemy.enemy_selected.disconnect(connected["callable"])
	if pending_skill != null and current_combatant is Character:
		_apply_skill(current_combatant, pending_skill, enemy)
		enemy.focus.visible = false
		return
	var damage: int = current_combatant.attack
	var was_crit: bool = false
	if current_combatant is Character:
		damage = current_combatant.compute_basic_attack_damage()
		was_crit = damage > current_combatant.attack
	combat_dialog.text += ATTACK_MSG.replace("{player1}", current_combatant.name).replace("{player2}", enemy.name)
	if check_if_container_has_child(character_container, current_combatant):
		enemy.receive_damage(damage)
		enemy.focus.visible = false
	combat_dialog.text += DAMAGE_DEALT.replace("{player1}", current_combatant.name).replace("{damage}", str(damage)).replace("{player2}", enemy.name)
	if was_crit:
		combat_dialog.text += CRIT_MSG
	remove_focus()
	remove_highlight(current_combatant)
	advance_turn()

func _award_battle_xp(survivors: Array) -> void:
	var xp_total: int = int(battle_xp_reward * RunModifiers.xp_multiplier(RunState.run_modifier_id))
	if xp_total <= 0:
		return
	for character in survivors:
		if character is Character:
			var before: int = character.level
			character.gain_xp(xp_total)
			if character.level > before:
				combat_dialog.text += LEVEL_UP_MSG.replace("{player1}", character.name).replace("{level}", str(character.level))

func _award_battle_gold(survivors: Array) -> void:
	if is_boss_battle:
		return
	var depth: int = RunState.get_run_depth()
	var gold: int = GameConstants.BATTLE_GOLD_BASE + depth * 2
	for foe in enemy_original_state.keys():
		if is_instance_valid(foe) and foe.get("is_elite") == true:
			gold += 14
	var before: int = RunState.run_gold
	RunState.add_run_gold(gold)
	var gained: int = RunState.run_gold - before
	if gained > 0:
		var shown: int = gained
		for ch in survivors:
			if ch is Character:
				shown = CharacterTraits.modify_run_gold_gain(shown, ch.character_id)
				break
		combat_dialog.text += "\n+%d run gold secured." % shown

func _on_defend_pressed():
	skill_panel.visible = false
	pending_skill = null
	var current_combatant = combatants[current_turn]
	if check_if_container_has_child(character_container,current_combatant):
		current_combatant.defend()
	combat_dialog.text += DEFEND_MSG.replace("{player1}", current_combatant.name)
	remove_highlight(current_combatant)
	advance_turn()


func _on_run_pressed():
	if is_boss_battle:
		combat_dialog.text += RUN_BOSS
	else:
		is_run_pressed = true
		end_battle()
	
func initialize_combatants(characters, enemies):
	combatants = characters + enemies

func sort_combatants_by_initiative():
	combatants.sort_custom(sort_by_initiative)

func sort_by_initiative(a, b):
	return a.initiative > b.initiative

func start_turn():
	if current_turn >= combatants.size():
		current_turn = 0
	skill_panel.visible = false
	pending_skill = null
	var current_combatant = combatants[current_turn]
	if check_if_container_has_child(character_container, current_combatant):
		battle_menu.visible = true
		highlight_character(current_combatant)
		if current_combatant is Character:
			var regen: int = current_combatant.regenerate_mp_this_turn()
			if regen > 0:
				combat_dialog.text += MP_REGEN_MSG.replace("{player1}", current_combatant.name).replace("{amount}", str(regen))
			var status_msg: String = current_combatant.tick_status_effects_start_of_turn()
			if status_msg != "":
				combat_dialog.text += "\n%s suffers%s." % [current_combatant.name, status_msg]
			var trait_msg: String = CharacterTraits.tick_combat_turn_start(current_combatant)
			if trait_msg != "":
				combat_dialog.text += "\n%s: %s." % [current_combatant.name, trait_msg]
			StressSystem.on_low_hp_turn(current_combatant)
			if current_combatant.current_hp <= 0:
				advance_turn()
				return
	else:
		if current_combatant is Boss:
			boss_take_turn(current_combatant)
		else:
			enemy_take_turn(current_combatant)

func boss_take_turn(boss: Boss) -> void:
	if boss.boss_kind == "warden" and (_boss_turn_counter + 1) % 3 == 0:
		combat_dialog.text += "\nTelegraph: Blood Cleave incoming!"
	if boss.boss_kind == "khorne" and (_boss_turn_counter + 1) % 4 == 0:
		combat_dialog.text += "\nTelegraph: Skull Throne rampage incoming!"
	_boss_turn_counter += 1
	battle_menu.visible = false
	var theme_id: String = ""
	var zone: ZoneDefinition = RunState.get_current_zone()
	if zone != null:
		theme_id = zone.map_theme_id
	if boss.boss_kind == "warden" and _boss_turn_counter % 3 == 0:
		_boss_cleave(boss, theme_id)
		return
	if boss.boss_kind == "khorne" and _boss_turn_counter % 4 == 0:
		_boss_rampage(boss, theme_id)
		return
	enemy_take_turn(boss)

func _boss_cleave(boss: Boss, theme_id: String) -> void:
	var targets: Array[Character] = []
	for t in character_container.get_children():
		if t is Character and t.current_hp > 0:
			targets.append(t)
	if targets.is_empty():
		advance_turn()
		return
	combat_dialog.text += "\n%s unleashes Blood Cleave!" % boss.name
	var damage: int = BiomeCombat.compute_enemy_damage(theme_id, boss, targets[0])
	damage = maxi(1, int(damage * 0.72))
	for target in targets:
		target.receive_damage(damage)
		combat_dialog.text += DAMAGE_DEALT.replace("{player1}", boss.name).replace("{damage}", str(damage)).replace("{player2}", target.name)
	advance_turn()

func _boss_rampage(boss: Boss, theme_id: String) -> void:
	var targets: Array = character_container.get_children()
	var target: Character = BiomeCombat.pick_target(theme_id, boss, targets)
	if target == null:
		advance_turn()
		return
	var damage: int = maxi(1, int(BiomeCombat.compute_enemy_damage(theme_id, boss, target) * 1.55))
	combat_dialog.text += "\n%s focuses Skull Throne wrath on %s!" % [boss.name, target.name]
	target.receive_damage(damage)
	combat_dialog.text += DAMAGE_DEALT.replace("{player1}", boss.name).replace("{damage}", str(damage)).replace("{player2}", target.name)
	advance_turn()

func _tick_all_skill_cooldowns() -> void:
	for ally in character_container.get_children():
		if ally is Character:
			ally.tick_skill_cooldowns()

func enemy_take_turn(enemy):
	battle_menu.visible = false
	var targets: Array = character_container.get_children()
	var theme_id: String = ""
	var zone: ZoneDefinition = RunState.get_current_zone()
	if zone != null:
		theme_id = zone.map_theme_id
	var random_target: Character = BiomeCombat.pick_target(theme_id, enemy, targets)
	if random_target == null:
		advance_turn()
		return
	var damage: int = BiomeCombat.compute_enemy_damage(theme_id, enemy, random_target)
	combat_dialog.text += ATTACK_MSG.replace("{player1}", enemy.name).replace("{player2}", random_target.name)
	await get_tree().create_timer(1.0).timeout
	random_target.receive_damage(damage)
	combat_dialog.text += DAMAGE_DEALT.replace("{player1}", enemy.name).replace("{damage}", str(damage)).replace("{player2}", random_target.name)
	var extra: String = BiomeCombat.apply_post_hit(theme_id, enemy, random_target, damage)
	if extra != "":
		combat_dialog.text += extra
	if enemy.get("combat_trait") == "skirmisher" and randf() < 0.22:
		random_target.apply_bleed(1)
		combat_dialog.text += "\n%s is bleeding." % random_target.name
	advance_turn()

func advance_turn():
	battle_menu.visible = false
	_tick_all_skill_cooldowns()
	await get_tree().create_timer(2.0).timeout
	if character_container.get_child_count() > 0 and enemy_container.get_child_count() > 0:
		current_turn += 1
		start_turn()

func check_if_container_has_child(container,child):
	for children in container.get_children():
		if children == child:
			return true
	return false 
	
func highlight_character(character):
	character.focus.visible = true

func remove_highlight(character):
	character.focus.visible = false

func _on_enemy_defeated(enemy):
	if character_container.get_child_count() > 0:
		var killer: Character = character_container.get_child(0) as Character
		if killer != null:
			CharacterTraits.on_first_enemy_kill_in_battle(killer)
	if enemy.get_parent() == enemy_container:
		enemy_container.remove_child(enemy)
	if _is_persistent_world_enemy(enemy):
		var state: Dictionary = enemy_original_state.get(enemy, {})
		if state.has("parent"):
			state["parent"].add_child(enemy)
		enemy.visible = false
		enemy.battle_started = false
		enemy.progress_bar.visible = false
	else:
		enemy.queue_free()
	combatants.erase(enemy)
	enemy_original_state.erase(enemy)
	if enemy_container.get_child_count() == 0:
		end_battle()

func _on_character_defeated(character):
	character_container.remove_child(character)
	original_parents.erase(character)
	combatants.erase(character)
	dead_players += 1
	if character_container.get_child_count() == 0:
		end_battle()

func remove_focus():
	for child in enemy_container.get_children():
		child.focus.visible = false

func _on_inventory_pressed():
	inventory_pressed.emit()

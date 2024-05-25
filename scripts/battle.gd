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
var original_positions = {}
var original_scales = {}
var original_parents = {}
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
var dead_players = 0
var is_boss_battle = false
var is_run_pressed = false
signal battle_ended
signal level_ended
signal game_over
# Called when the node enters the scene tree for the first time.
func _ready():
	battle_camera.enabled = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func start_battle(characters, enemies):
	fill_characters(characters)
	fill_enemies(enemies)
	battle_camera.make_current()
	initialize_combatants(characters,enemies)
	sort_combatants_by_initiative()
	combat_dialog.visible = true
	combat_dialog.text = BATTLE_STARTED
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
			character.character_defeated.connect(_on_character_defeated.bind(character))
			character_container.add_child(character)
		character.visible = true
		
func fill_enemies(enemies):
	var is_lonely_enemy = enemies.size() == 1
	for enemy in enemies:
		if enemy.name.contains("Boss"):
			is_boss_battle = true
	if is_boss_battle:
		background_boss.visible = true
		boss_music.play()
		
	else:
		background_enemy.visible = true
		enemy_music.play()
	var offset = 30
	var spacing_between_enemies = 250
	for enemy in enemies:
		if enemy.get_parent() != character_container:
			if enemy.get_parent() != null:
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
	else:
		win_music.play()
		if !is_run_pressed:
			combat_dialog.text += WIN_BATTLE
		else:
			is_run_pressed = false
		var enemies = enemy_container.get_children()
		for enemy in enemies:
			enemy.focus.visible = false
		
		var characters = character_container.get_children()
		for character in characters:
			character.focus.visible = false
			
		var remaining_characters = []
		# Restore original parents and positions
		for character in original_parents.keys():
			var parent = original_parents[character]
			if character.get_parent() == character_container:
				character_container.remove_child(character)
			character.position = original_positions[character]
			character.scale = original_scales[character]
			character.visible = false
			character.ap.play("RESET")
			parent.add_child(character)
			remaining_characters.append(character)
		await get_tree().create_timer(5.0).timeout
		clear_characters_and_enemies()
		combat_dialog.visible = false
		win_music.stop()
		if is_boss_battle:
			level_ended.emit(remaining_characters)
		else:
			battle_ended.emit(remaining_characters)

func _on_attack_pressed():
	battle_menu.visible = false
	show_enemy_options()

func show_enemy_options():
	combat_dialog.text += SELECT_ENEMY
	var enemies = enemy_container.get_children()
	for enemy in enemies:
		enemy.focus.visible = true
		enemy.enemy_selected.connect(_on_enemy_selected.bind(enemy))

func _on_enemy_selected(enemy):
	var current_combatant = combatants[current_turn]
	combat_dialog.text += ATTACK_MSG.replace("{player1}", current_combatant.name).replace("{player2}", enemy.name)
	if check_if_container_has_child(character_container,current_combatant):
		enemy.receive_damage(current_combatant.attack)
		enemy.focus.visible = false
	combat_dialog.text += DAMAGE_DEALT.replace("{player1}", current_combatant.name).replace("{damage}", str(current_combatant.attack)).replace("{player2}", enemy.name)
	remove_highlight(current_combatant)
	advance_turn()

func _on_defend_pressed():
	var current_combatant = combatants[current_turn]
	if check_if_container_has_child(character_container,current_combatant):
		current_combatant.defend()
	combat_dialog.text += DEFEND_MSG.replace("{player1}", current_combatant.name)
	remove_highlight(current_combatant)
	advance_turn()


func _on_run_pressed():
	if enemy_container.has_node("Evil Geanie Boss"):
		combat_dialog.text += RUN_BOSS
	else:
		combat_dialog.text += RUN
		is_run_pressed = true
		end_battle() # Replace with function body.
	
func initialize_combatants(characters, enemies):
	combatants = characters + enemies

func sort_combatants_by_initiative():
	combatants.sort_custom(sort_by_initiative)

func sort_by_initiative(a, b):
	return a.initiative > b.initiative

func start_turn():
	if current_turn >= combatants.size():
		current_turn = 0

	var current_combatant = combatants[current_turn]
	if check_if_container_has_child(character_container,current_combatant):
		battle_menu.visible = true
		highlight_character(current_combatant)
	else:
		enemy_take_turn(current_combatant)

func enemy_take_turn(enemy):
	battle_menu.visible = false
	var targets = character_container.get_children()
	var random_target = targets[randi() % targets.size()]
	combat_dialog.text += ATTACK_MSG.replace("{player1}", enemy.name).replace("{player2}", random_target.name)
	await get_tree().create_timer(1.0).timeout
	combat_dialog.text += DAMAGE_DEALT.replace("{player1}", enemy.name).replace("{damage}", str(enemy.attack)).replace("{player2}", random_target.name)
	random_target.receive_damage(enemy.attack)
	advance_turn()

func advance_turn():
	battle_menu.visible = false
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
	enemy_container.remove_child(enemy)
	combatants.erase(enemy)
	if enemy_container.get_child_count() == 0:
		end_battle()

func _on_character_defeated(character):
	character_container.remove_child(character)
	original_parents.erase(character)
	combatants.erase(character)
	dead_players += 1
	if character_container.get_child_count() == 0:
		end_battle()

func clear_characters_and_enemies():
	for child in character_container.get_children():
		character_container.remove_child(child)
	for child in enemy_container.get_children():
		enemy_container.remove_child(child)
	

extends Node2D


@onready var character_container = $CharacterContainer
@onready var enemy_container = $EnemyContainer
@onready var battle_menu = $UI/Options
@onready var battle_camera = $BattleCamera
@onready var combat_dialog = $UI/CombatDialog
var original_positions = {}
var original_parents = {}
var combatants = []
var current_turn = 0
var BATTLE_STARTED = "Battle started"
var ATTACK_MSG = "\n{player1} attacking: {player2}"
var SELECT_ENEMY = "\nSelect Enemy to attack"
var DAMAGE_DEALT = "\n{player1} dealt {damage} to {player2}"
signal battle_ended
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
	combat_dialog.text = true
	start_turn()
	
func fill_characters(characters):
	var offset = 30
	var spacing_between_characters = 150
	for character in characters:
		if character.get_parent() != character_container:
			if character.get_parent() != null:
				original_parents[character] = character.get_parent()
				original_positions[character] = character.position
				character.get_parent().remove_child(character)
			if character.has_node("Camera2D"):
				var camera = character.get_node("Camera2D")
				camera.enabled = false
			character.position = Vector2(0,offset)
			offset += spacing_between_characters
			character.collided_with_enemy()
			character_container.add_child(character)
		character.visible = true
		
func fill_enemies(enemies):
	var is_lonely_enemy = enemies.size() == 1
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
			enemy.progress_bar.visible = true
			enemy_container.add_child(enemy)
		enemy.visible = true

func end_battle():
	battle_camera.enabled = false
	# Restore original parents and positions
	for character in original_parents.keys():
		var parent = original_parents[character]
		if character.get_parent() == character_container:
			character_container.remove_child(character)
		character.position = original_positions[character]
		character.visible = false
		parent.add_child(character)
	battle_menu.visible = false
	battle_ended.emit()

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
	remove_highlight(current_combatant)
	advance_turn()


func _on_run_pressed():
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
		highlight_character(current_combatant)
		show_battle_menu(current_combatant)
	else:
		enemy_take_turn(current_combatant)

func show_battle_menu(character):
	battle_menu.visible = true
	# Set up the menu for the character to take an action
	# Connect the menu options to relevant functions

func enemy_take_turn(enemy):
	# Logic for enemy actions
	# After the enemy action, move to the next turn
	battle_menu.visible = false
	var targets = character_container.get_children()
	var random_target = targets[randi() % targets.size()]
	combat_dialog.text += ATTACK_MSG.replace("{player1}", enemy.name).replace("{player2}", random_target.name)
	await get_tree().create_timer(2.0).timeout
	random_target.receive_damage(enemy.attack)
	combat_dialog.text += DAMAGE_DEALT.replace("{player1}", enemy.name).replace("{damage}", str(enemy.attack)).replace("{player2}", random_target.name)
	advance_turn()

func advance_turn():
	await get_tree().create_timer(2.0).timeout
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

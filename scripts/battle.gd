extends Node2D


@onready var character_container = $CharacterContainer
@onready var enemy_container = $EnemyContainer
@onready var battle_menu = $UI/Options
@onready var battle_camera = $BattleCamera
var original_positions = {}
var original_parents = {}
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
	battle_menu.visible = true
	battle_camera.make_current()
	
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
			#enemy.position = Vector2(0,0)
			#enemy.position = enemy_container.get_rect().get_center()
			if is_lonely_enemy:
				var min_size = enemy_container.get_custom_minimum_size()
				enemy.position = Vector2(min_size.x,min_size.y/2)
			else:
				enemy.position = Vector2(0,offset)
				offset += spacing_between_enemies
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

func _on_run_pressed():
	end_battle() # Replace with function body.

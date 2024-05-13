extends Node2D


@onready var character_container = $CharacterGroup/CharacterContainer
@onready var enemy_container = $EnemyGroup/EnemyContainer
@onready var battle_menu = $UI/Options
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func start_battle(characters, enemies):
	fill_characters(characters)
	fill_enemies(enemies)
	battle_menu.visible = true
	
func fill_characters(characters):
	for character in characters:
		character_container.add_child(character)
		
func fill_enemies(enemies):
	for enemy in enemies:
		enemy_container.add_child(enemy)

extends CanvasLayer

signal game_started
signal character_added
signal character_removed
signal restart_game
@onready var main_menu = $"Main-menu"
@onready var character_menu = $"Character-menu"
@onready var game_over_menu = $"Game-Over"
@onready var end_game_menu = $"Level-Ended"
@onready var error_message = $"Character-menu/Error"
@onready var death_count_message = $"Game-Over/InfoDeathsLabel"
@onready var end_message = $"Level-Ended/ExplanationLabel"
var character_ids_toggled = []
# Called when the node enters the scene tree for the first time.

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_play_pressed():
	main_menu.visible = false
	character_menu.visible = true

func _on_world_map_generated():
	character_menu.visible = false

func character_toggle(toggled_on,id):
	if toggled_on:
		character_ids_toggled.append(id)
		character_added.emit(id)
	else:
		character_ids_toggled.erase(id)
		character_removed.emit(id)

func _on_start_run_pressed():
	if character_ids_toggled.size()>0:
		game_started.emit()
	else:
		error_message.visible = true

func _on_player_0_select_toggled(toggled_on):
	character_toggle(toggled_on,0)

func _on_player_1_select_toggled(toggled_on):
	character_toggle(toggled_on,1)

func _on_player_2_select_toggled(toggled_on):
	character_toggle(toggled_on,2)

func _on_player_3_select_toggled(toggled_on):
	character_toggle(toggled_on,3)

func _on_battle_game_over(dead_players):
	if dead_players > 1:
		death_count_message.text = death_count_message.text.replace("{COUNT}", str(dead_players))
	else:
		death_count_message.text = death_count_message.text.replace("{COUNT} skulls", str(dead_players)+" skull")
	if Global.total_deaths > 1:
		death_count_message.text = death_count_message.text.replace("{TOTAL_COUNT}", str(Global.total_deaths))
	else:
		death_count_message.text = death_count_message.text.replace("{TOTAL_COUNT} skulls", str(Global.total_deaths)+" skull")
	game_over_menu.visible = true

func _on_retry_pressed():
	game_over_menu.visible = false
	restart_game.emit()


func _on_battle_level_ended(remaining_characters):
	var character_names = []
	for character in remaining_characters:
		character_names.append(character.name)
	end_message.text = end_message.text.replace("{PARTY_MEMBERS}",",".join(character_names))
	end_game_menu.visible = true

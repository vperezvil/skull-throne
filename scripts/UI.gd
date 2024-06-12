extends CanvasLayer

signal game_started
signal character_added
signal character_removed
signal restart_game

@onready var main_menu = $"Main-menu"
@onready var character_menu = $"Character-menu"
@onready var game_over_menu = $"Game-Over"
@onready var end_game_menu = $"Level-Ended"
@onready var game_menu = $"Game-menu"
@onready var error_message = $"Character-menu/Error"
@onready var death_count_message = $"Game-Over/InfoDeathsLabel"
@onready var end_message = $"Level-Ended/ExplanationLabel"
@onready var main_theme = $"Main-menu/Main Theme"
@onready var game_won_music = $"Level-Ended/Game Won Theme"
@onready var game_over_music = $"Game-Over/Game Over Theme"
@onready var exit_dialog = $"Game-menu/ConfirmationDialog"
@onready var item_grid = $"Game-menu/ItemPanel/ItemGrid"
@onready var item_grid_panel = $"Game-menu/ItemPanel"
@onready var character_grid = $"Game-menu/CharacterPanel/CharacterGrid"
@onready var character_grid_panel = $"Game-menu/CharacterPanel"
@onready var options_menu = $"Game-menu/Options"
var character_ids_toggled = []
var characters = []
var in_battle = false
# Called when the node enters the scene tree for the first time.

func _ready():
	main_theme.play()


func _on_play_pressed():
	main_menu.visible = false
	character_menu.visible = true

func _on_world_map_generated():
	main_theme.stop()
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
	game_over_music.play()

func _on_retry_pressed():
	game_over_menu.visible = false
	game_won_music.stop()
	game_over_music.stop()
	restart_game.emit()

func _on_battle_level_ended(remaining_characters):
	var character_names = []
	for character in remaining_characters:
		character_names.append(character.name)
	end_message.text = end_message.text.replace("{PARTY_MEMBERS}",",".join(character_names))
	end_game_menu.visible = true
	game_won_music.play()

func _on_inventory_pressed():
	clear_item_grid()
	if in_battle:
		game_menu.visible = true
	if !item_grid_panel.visible:
		display_grid_items()
	else:
		item_grid_panel.visible = false

func _on_world_paused_game(is_paused, characters_in_party: Array = []):
	game_menu.visible = is_paused
	options_menu.visible = is_paused
	item_grid_panel.visible = false
	character_grid_panel.visible = false
	characters = characters_in_party

func _on_item_pressed(item):
	print("Item pressed:", item.item_name)
	clear_character_grid()
	display_grid_characters(item)

func _on_character_pressed(item, character):
	character_grid_panel.visible = false
	if item.type == "healing":
		character.current_hp += item.healing_amount
		character.update_progress_bar()
	#TODO: handle other item types
	clear_character_grid()
	Inventory.remove_item(item)
	if Inventory.get_item_count(item) == 0:
		clear_item_grid()
		display_grid_items()
	if in_battle:
		get_parent().resume_paused_game()

func _on_exit_pressed():
	exit_dialog.visible = true


func _on_confirmation_dialog_confirmed():
	get_tree().quit()

func clear_item_grid():
	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()

func clear_character_grid():
	for child in character_grid.get_children():
		if !(child is Label):
			character_grid.remove_child(child)
			child.queue_free()
		

func display_grid_items():
	for item in Inventory.items.keys():
		if (item.usable_outside_battle and !in_battle) or in_battle:
			var icon = item.icon.texture
			var item_button = Button.new()
			var style_box = StyleBoxFlat.new()
			style_box.bg_color = Color.html("#FF8D4D")
			item_button.add_theme_stylebox_override("normal", style_box)
			item_button.icon = icon
			item_button.text = "x"+str(Inventory.get_item_count(item))
			item_button.pressed.connect(_on_item_pressed.bind(item))
			item_grid.add_child(item_button)
	if item_grid.get_child_count() > 0:
		item_grid_panel.visible = true
	else:
		item_grid_panel.visible = false
		
func display_grid_characters(item):
	for character in characters:
		var character_button = Button.new()
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color.html("#FF8D4D")
		character_button.text = character.name
		character_button.add_theme_stylebox_override("normal", style_box)
		character_button.pressed.connect(_on_character_pressed.bind(item, character))
		character_grid.add_child(character_button)
	if character_grid.get_child_count() > 0:
		character_grid_panel.visible = true
	else:
		character_grid_panel.visible = false

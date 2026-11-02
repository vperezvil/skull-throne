extends CanvasLayer

signal game_started
signal character_added
signal character_removed
signal restart_game
signal continue_adventure

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
@onready var zone_title_label: RichTextLabel
@onready var continue_button: Button
var character_ids_toggled = []
var characters = []
var in_battle = false
const GAME_OVER_DEATHS_TEMPLATE := "{COUNT} skulls added to the Skull Throne.\nThere's currently {TOTAL_COUNT} skulls on the throne."
# Called when the node enters the scene tree for the first time.

func _ready():
	main_theme.play()
	zone_title_label = RichTextLabel.new()
	zone_title_label.name = "ZoneTitle"
	zone_title_label.offset_left = 32
	zone_title_label.offset_top = 24
	zone_title_label.offset_right = 520
	zone_title_label.offset_bottom = 72
	zone_title_label.visible = false
	add_child(zone_title_label)
	continue_button = Button.new()
	continue_button.name = "Continue"
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.offset_left = 873.0
	continue_button.offset_top = 480.0
	continue_button.offset_right = 993.0
	continue_button.offset_bottom = 534.0
	continue_button.pressed.connect(_on_continue_adventure_pressed)
	end_game_menu.add_child(continue_button)
	_refresh_character_select_locks()


func _on_play_pressed():
	main_menu.visible = false
	character_menu.visible = true
	_refresh_character_select_locks()

func _on_world_map_generated():
	main_theme.stop()
	character_menu.visible = false
	if zone_title_label:
		zone_title_label.visible = true

func set_zone_title(title: String) -> void:
	if zone_title_label:
		zone_title_label.text = "Zone: %s" % title

func show_zone_cleared(remaining_characters: Array, campaign_complete: bool) -> void:
	var character_names: PackedStringArray = []
	for character in remaining_characters:
		character_names.append(character.name)
	end_message.text = "You cleared %s with: %s." % [
		ContentRegistry.get_zone(RunState.current_zone_index).display_name,
		", ".join(character_names),
	]
	if campaign_complete:
		end_message.text += " The path to the Skull Throne is open — for now, replay and grow your roster."
		continue_button.visible = false
	else:
		end_message.text += " Press Continue to enter the next zone."
		continue_button.visible = true
	end_game_menu.visible = true
	game_won_music.play()

func _on_continue_adventure_pressed() -> void:
	end_game_menu.visible = false
	game_won_music.stop()
	continue_adventure.emit()

func _refresh_character_select_locks() -> void:
	var button_paths := [
		"Character-menu/CharacterSelection/HBoxContainer/TinyBones",
		"Character-menu/CharacterSelection/HBoxContainer/Beth",
		"Character-menu/CharacterSelection/HBoxContainer/Dalf",
		"Character-menu/CharacterSelection/HBoxContainer/Trece",
	]
	for i in button_paths.size():
		var button: TextureButton = get_node(button_paths[i])
		var definition := ContentRegistry.get_character_for_menu_index(i)
		var unlocked := definition == null or RunState.is_character_unlocked(definition)
		button.disabled = !unlocked
		button.modulate = Color.WHITE if unlocked else Color(0.45, 0.45, 0.45, 1.0)

func character_toggle(toggled_on, id):
	var definition := ContentRegistry.get_character_for_menu_index(id)
	if definition != null and !RunState.is_character_unlocked(definition):
		return
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
	var message := GAME_OVER_DEATHS_TEMPLATE
	if dead_players > 1:
		message = message.replace("{COUNT}", str(dead_players))
	else:
		message = message.replace("{COUNT} skulls", str(dead_players) + " skull")
	if Global.total_deaths > 1:
		message = message.replace("{TOTAL_COUNT}", str(Global.total_deaths))
	else:
		message = message.replace("{TOTAL_COUNT} skulls", str(Global.total_deaths) + " skull")
	message += "\nSkulls on the throne: %d" % Global.get_skull_count()
	death_count_message.text = message
	game_over_menu.visible = true
	game_over_music.play()

func _on_retry_pressed():
	game_over_menu.visible = false
	end_game_menu.visible = false
	continue_button.visible = false
	game_won_music.stop()
	game_over_music.stop()
	restart_game.emit()

func _on_battle_level_ended(_remaining_characters):
	pass

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
		character.apply_healing(item.healing_amount)
	elif item.type == "weapon":
		character.attack += item.attack_amount
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

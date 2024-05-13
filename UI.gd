extends CanvasLayer

signal game_started
signal character_added
signal character_removed
@onready var main_menu = $"Main-menu"
@onready var character_menu = $"Character-menu"
@onready var error_message = $"Character-menu/Error"
var character_ids_toggled = []
# Called when the node enters the scene tree for the first time.

func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_play_pressed():
	#game_started.emit()
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

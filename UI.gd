extends CanvasLayer

signal game_started
@onready var menu = $"main-menu"
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_play_pressed():
	game_started.emit()

func _on_world_map_generated():
	menu.visible = false

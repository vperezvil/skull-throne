extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if visible:
		for selectButtons in get_node("CharacterSelection/HBoxContainer").get_children():
			for character in selectButtons.get_children():
				if character is AnimatedSprite2D:
					character.play()

extends CharacterBody2D

var battle_started = false

var players
@onready var heal_sound = $HealSound
@onready var animated_sprite = $AnimatedSprite2D
func handle_collision():
	if !battle_started:
		heal_sound.play()
		for player in players:
			player.heal()

func spawn(spawn_position, tilemap, characters):
	position = tilemap.map_to_local(spawn_position.get_center())
	visible = true
	players = characters
	animated_sprite.play("default")

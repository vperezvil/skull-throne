extends StaticBody2D

var players
@onready var heal_sound = $HealSound
@onready var animated_sprite = $AnimatedSprite2D
func handle_collision():
	if visible:
		heal_sound.play()
		for player in players:
			player.heal()
		await get_tree().create_timer(1.0).timeout

func spawn(spawn_position, tilemap, characters):
	position = GameConstants.tile_map_cell_center(tilemap, Vector2i(spawn_position.get_center()))
	GameConstants.fit_animated_sprite_to_map_tile(animated_sprite)
	visible = true
	players = characters
	animated_sprite.play("default")

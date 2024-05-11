extends CharacterBody2D


const SPEED = 300.0
@onready var sprite = $BossSprite
	
func spawn(starting_room, tilemap):
	var center = tilemap.map_to_local(starting_room)
	position = center
	visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	pass

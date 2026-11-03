extends Item

@export var healing_amount: int = 50

func _ready(): 
	icon = $Icon
	item_name = "Potion"
	usable_outside_battle = true
	type = "healing"
	
func spawn(spawn_position, tilemap):
	position = tilemap.map_to_local(spawn_position)
	visible = true

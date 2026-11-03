extends Item

@export var attack_amount: int = 10

func _ready(): 
	icon = $Icon
	item_name = "Sword"
	usable_outside_battle = true
	type = "weapon"
	
func spawn(spawn_position, tilemap):
	position = tilemap.map_to_local(spawn_position)
	visible = true

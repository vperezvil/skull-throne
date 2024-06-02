extends Item

@export var healing_amount: int = 50

func _ready(): 
	icon = $Icon
	item_name = "Potion"
	
func spawn(spawn_position, tilemap):
	position = tilemap.map_to_local(spawn_position.get_center())
	visible = true

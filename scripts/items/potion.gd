extends Item

@export var healing_amount: int = 50

func _ready(): 
	icon = $Icon
	item_name = "Potion"
	usable_outside_battle = true
	type = "healing"
	
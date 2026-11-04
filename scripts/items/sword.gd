extends Item

@export var attack_amount: int = 10

func _ready(): 
	icon = $Icon
	item_name = "Sword"
	usable_outside_battle = true
	type = "weapon"
	
extends Character

func _init():
	attack = 15
	#TinyBones is fragile
	max_hp = 100
	#TinyBones is agile so it will be at least 60 initiative
	initiative = 60

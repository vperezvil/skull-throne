extends Character

func _init():
	#Highest attack means low life and low initiative to compensate
	attack = 20
	max_hp = 70
	# Lowest initiative in the party; clamped to 1–100 in spawn()
	initiative = 15

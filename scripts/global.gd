extends Node


var total_deaths: int = 0

func increment_death_count():
	total_deaths += 1

func reset_deaths():
	total_deaths = 0

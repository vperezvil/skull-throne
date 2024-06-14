extends Node
class_name InventoryManager

var items: Dictionary = {}

func add_item(item: Item, quantity: int = 1) -> void:
	if item.stackable:
		if items.has(item):
			items[item] += quantity
			if items[item] > item.max_stack_size:
				items[item] = item.max_stack_size
		else:
			items[item] = quantity
	else:
		for i in range(quantity):
			items[item.duplicate()] = 1

func remove_item(item: Item, quantity: int = 1) -> bool:
	if items.has(item):
		if item.stackable:
			items[item] -= quantity
			if items[item] <= 0:
				items.erase(item)
		else:
			for i in range(quantity):
				items.erase(item)
		return true
	return false

func get_item_count(item: Item) -> int:
	if items.has(item):
		return items[item]
	return 0

func has_item(item: Item, quantity: int = 1) -> bool:
	return get_item_count(item) >= quantity

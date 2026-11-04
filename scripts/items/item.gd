extends Node2D
class_name Item

var item_name
var stackable = true
var max_stack_size = 99
var icon
var usable_outside_battle = false
var type
@onready var collider = $CollisionShape2D

func spawn(spawn_position: Vector2i, tilemap: Node2D) -> void:
	position = GameConstants.tile_map_cell_center(tilemap, spawn_position)
	var icon_node := get_node_or_null("Icon") as Sprite2D
	if icon_node != null:
		GameConstants.fit_sprite_to_map_tile(icon_node)
	visible = true

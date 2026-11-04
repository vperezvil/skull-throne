extends Area2D
class_name MapEvent

signal triggered(event_id: String)

var event_id: String = "healing_spring"
var _fired: bool = false
var _sprite: Sprite2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_apply_visual()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = GameConstants.MAP_TILE_SIZE * 0.45
	shape.shape = circle
	add_child(shape)

func setup(tilemap: Node2D, cell: Vector2i, id: String) -> void:
	event_id = id
	_apply_visual()
	position = GameConstants.tile_map_cell_center(tilemap, cell)

func _apply_visual() -> void:
	if _sprite == null:
		return
	match event_id:
		"gamble":
			_sprite.texture = load("res://assets/items/ring/gold.png")
		"ambush":
			_sprite.texture = load("res://assets/monsters/undead/flying_skull.png")
		"gas_trap":
			_sprite.texture = load("res://assets/items/potion/i-blood.png")
		"wisdom":
			_sprite.texture = load("res://assets/items/book/gold.png")
		_:
			_sprite.texture = load("res://assets/map/dngn_sparkling_fountain.png")
	GameConstants.fit_sprite_to_map_tile(_sprite)

func _on_body_entered(body: Node2D) -> void:
	if _fired or !(body is Character):
		return
	var ch: Character = body
	if !ch.is_party_leader or ch.battle_started:
		return
	_fired = true
	collision_layer = 0
	visible = false
	triggered.emit(event_id)
	queue_free()

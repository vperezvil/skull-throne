extends Area2D
class_name MapEvent

signal triggered(event_id: String)

var event_id: String = "healing_spring"
var _fired := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)
	var sprite := Sprite2D.new()
	match event_id:
		"gamble":
			sprite.texture = load("res://assets/items/ring/gold.png")
		"ambush":
			sprite.texture = load("res://assets/monsters/undead/flying_skull.png")
		"gas_trap":
			sprite.texture = load("res://assets/items/potion/i-blood.png")
		"wisdom":
			sprite.texture = load("res://assets/items/book/gold.png")
		_:
			sprite.texture = load("res://assets/map/dngn_sparkling_fountain.png")
	sprite.scale = Vector2(2.2, 2.2)
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 32.0
	shape.shape = circle
	add_child(shape)

func setup(tilemap: TileMap, cell: Vector2i, id: String) -> void:
	event_id = id
	position = tilemap.map_to_local(cell)

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

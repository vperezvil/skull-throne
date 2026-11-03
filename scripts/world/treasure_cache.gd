extends Area2D
class_name TreasureCache

var gold_amount: int = 14
var _picked := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/items/misc/gold_pile.png")
	sprite.scale = Vector2(2.5, 2.5)
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 28.0
	shape.shape = circle
	add_child(shape)

func setup(tilemap: TileMap, cell: Vector2i, gold: int) -> void:
	gold_amount = gold
	position = tilemap.map_to_local(cell)

func _on_body_entered(body: Node2D) -> void:
	if _picked or !(body is Character):
		return
	var ch: Character = body
	if !ch.is_party_leader or ch.battle_started:
		return
	_picked = true
	RunState.add_run_gold(gold_amount)
	if randf() < 0.35:
		MetaProgress.grant_potion_to_inventory()
	collision_layer = 0
	visible = false
	queue_free()

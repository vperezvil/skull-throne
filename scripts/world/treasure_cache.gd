extends Area2D
class_name TreasureCache

var gold_amount: int = 14
var _picked: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/items/misc/gold_pile.png")
	GameConstants.fit_sprite_to_map_tile(sprite)
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = GameConstants.MAP_TILE_SIZE * 0.42
	shape.shape = circle
	add_child(shape)

func setup(tilemap: Node2D, cell: Vector2i, gold: int) -> void:
	gold_amount = gold
	position = GameConstants.tile_map_cell_center(tilemap, cell)

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

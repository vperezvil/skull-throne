extends Combatant
class_name Enemy

const CHASE_SPEED = 100.0
const SPEED = 50.0
const DETECTION_RANGE = 500.0
const RANDOM_MOVE_TIME = 2.0

@onready var sprite = $EnemySprite
@onready var timer = Timer.new()

var path = []
var current_path_index = 0
var random_direction = Vector2()
var is_chasing = false
var player

signal enemy_battle_start

func _ready():
	_ready_combatant()
	add_child(timer)
	timer.connect("timeout", _on_timer_timeout)
	timer.start(RANDOM_MOVE_TIME)
	random_direction = get_random_direction()

func spawn(spawn_position, tilemap, main_character):
	position = tilemap.map_to_local(spawn_position)
	spawn_initiative_clamp()
	visible = true
	player = main_character
	update_progress_bar()

func _physics_process(delta):
	if battle_started:
		sprite.flip_h = true
	else:
		if player != null:
			if is_chasing:
				chase_player(delta)
			else:
				random_move(delta)
				check_line_of_sight()

func random_move(delta):
	move_and_collide(random_direction * delta * SPEED)

func check_line_of_sight():
	if position.distance_to(player.position) <= DETECTION_RANGE:
		if has_clear_path_to_player():
			is_chasing = true

func chase_player(delta):
	velocity = Vector2.ZERO
	var delta_pos = player.position - position
	if abs(delta_pos.x) > abs(delta_pos.y):
		velocity.x = 1 if delta_pos.x > 0 else -1
	else:
		velocity.y = 1 if delta_pos.y > 0 else -1
	velocity = velocity.normalized() * CHASE_SPEED
	move_and_slide()
	if position.distance_to(player.position) > DETECTION_RANGE:
		is_chasing = false
	handle_collision()

func has_clear_path_to_player():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	query.from = position
	query.to = player.position
	var result = space_state.intersect_ray(query)
	return result.is_empty() or result.get("collider") == player

func _on_timer_timeout():
	random_direction = get_random_direction()
	timer.start(RANDOM_MOVE_TIME)

func get_random_direction():
	match randi() % 4:
		0: return Vector2(1, 0)
		1: return Vector2(-1, 0)
		2: return Vector2(0, 1)
		_: return Vector2(0, -1)

func handle_collision():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision == null:
			continue
		var collider = collision.get_collider()
		if collider == null:
			continue
		if collider == player and !battle_started and !collider.battle_started:
			collider.collided_with_enemy()
			enemy_battle_start.emit(self)

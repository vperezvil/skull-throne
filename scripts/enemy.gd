extends CharacterBody2D
class_name Enemy


const CHASE_SPEED = 100.0
const SPEED = 50.0
const DETECTION_RANGE = 500.0
const RANDOM_MOVE_TIME = 2.0
@onready var ap = $AnimationPlayer
@onready var sprite = $EnemySprite
@onready var damage_text = $DamageReceived
@onready var damage_sound = $DamageSound
@onready var death_sound = $DeathSound
var battle_started = false
var max_hp = 100
var current_hp
var initiative:int
var attack = 10
var path = []
var current_path_index = 0
var random_direction = Vector2()
var is_chasing = false
var player
@onready var progress_bar = $ProgressBar
@onready var focus = $Focus
@onready var ray_cast = RayCast2D.new()
@onready var timer = Timer.new()
signal enemy_selected
signal enemy_defeated
signal enemy_battle_start
func _ready():
	visible = false
	progress_bar.max_value = max_hp
	current_hp = max_hp
	add_child(timer)
	timer.connect("timeout", _on_timer_timeout)
	timer.start(RANDOM_MOVE_TIME)
	random_direction = get_random_direction()

func spawn(spawn_position, tilemap, main_character):
	position = tilemap.map_to_local(spawn_position)
	initiative = clamp(initiative, 1, 100)
	visible = true
	player = main_character
	update_progress_bar()

# Called every frame. 'delta' is the elapsed time since the previous frame.
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

func update_progress_bar():
	progress_bar.value = current_hp
	if current_hp == 0:
		ap.play("death")
		death_sound.play()
		await get_tree().create_timer(1.0).timeout
		progress_bar.visible = false
		death_sound.stop()
		enemy_defeated.emit()

func receive_damage(damage):
	current_hp -= damage
	damage_text.text = "-"+str(damage)
	damage_text.visible = true
	ap.play("hurt")
	damage_sound.play()
	# Ensure health doesn't go below 0
	current_hp = max(current_hp, 0)
	update_progress_bar()
	await get_tree().create_timer(1.0).timeout
	damage_text.visible = false
	damage_sound.stop()

func _on_focus_pressed():
	enemy_selected.emit()
	
func random_move(delta):
	move_and_collide(random_direction * delta * SPEED)
	
func check_line_of_sight():
	if position.distance_to(player.position) <= DETECTION_RANGE:
		if has_clear_path_to_player():
			is_chasing = true
	
func chase_player(delta):
	velocity = Vector2.ZERO
	
	# Calculate the difference in position
	var delta_pos = player.position - position

	# Determine the primary direction of movement
	if abs(delta_pos.x) > abs(delta_pos.y):
		if delta_pos.x > 0:
			velocity.x = 1  # Move right
		else:
			velocity.x = -1  # Move left
	else:
		if delta_pos.y > 0:
			velocity.y = 1  # Move down
		else:
			velocity.y = -1  # Move up

	velocity = velocity.normalized() * CHASE_SPEED

	# Move the enemy
	move_and_slide()
	# If the player is out of detection range, stop chasing
	if position.distance_to(player.position) > DETECTION_RANGE:
		is_chasing = false
	handle_collision()

func has_clear_path_to_player():
	var direction = (player.position - position).normalized()
	var ray_length = position.distance_to(player.position)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	query.from = position
	query.to = player.position
	var result = space_state.intersect_ray(query)
	return result.size() == 0 or result["collider"] == player
	
func _on_timer_timeout():
	random_direction = get_random_direction() 
	timer.start(RANDOM_MOVE_TIME)
	
func get_random_direction():
	# Generate a random integer between 0 and 3
	var direction_index = randi() % 4
	# Map the random integer to a cardinal direction
	match direction_index:
		0:
			return Vector2(1, 0)  # Right
		1:
			return Vector2(-1, 0)  # Left
		2:
			return Vector2(0, 1)  # Down
		3:
			return Vector2(0, -1)  # Up

func handle_collision():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision != null:
			var collider = collision.get_collider()
			if collider != null:
				if collider.name == player.name and !battle_started and !collider.battle_started:
					collider.collided_with_enemy()
					enemy_battle_start.emit(self)


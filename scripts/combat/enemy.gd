extends Combatant
class_name Enemy

const CHASE_SPEED = 100.0
const SPEED = 50.0
const DETECTION_RANGE = 500.0
const CLOSE_AGGRO_RANGE = 200.0
const RANDOM_MOVE_TIME = 2.0

@onready var sprite = $EnemySprite
@onready var timer = Timer.new()

var path = []
var current_path_index = 0
var random_direction = Vector2()
var is_chasing = false
var player: Character
var xp_reward: int = 25
var combat_trait: String = "standard"
var is_elite: bool = false
var _encounter_grace_until_msec: int = 0

signal enemy_battle_start

func _ready():
	_ready_combatant()
	add_child(timer)
	timer.connect("timeout", _on_timer_timeout)
	timer.start(RANDOM_MOVE_TIME)
	random_direction = get_random_direction()

func begin_encounter_grace(seconds: float = Character.ENCOUNTER_GRACE_SEC) -> void:
	_encounter_grace_until_msec = Time.get_ticks_msec() + int(seconds * 1000.0)

func _in_encounter_grace() -> bool:
	return Time.get_ticks_msec() < _encounter_grace_until_msec

func apply_battle_presentation_scale(factor: float) -> void:
	super.apply_battle_presentation_scale(factor)

func set_chase_target(target: Character) -> void:
	player = target
	if target == null:
		is_chasing = false

func spawn(spawn_position, tilemap, main_character: Character):
	position = tilemap.map_to_local(spawn_position)
	spawn_initiative_clamp()
	visible = true
	set_chase_target(main_character)
	update_progress_bar()

func _physics_process(delta):
	if battle_started:
		sprite.flip_h = true
		return
	var target: Character = _get_chase_target()
	if target == null:
		is_chasing = false
		return
	if is_chasing:
		chase_player(delta, target)
	else:
		random_move(delta)
		check_aggro(target)

func random_move(delta):
	move_and_collide(random_direction * delta * SPEED)

func check_aggro(target: Character) -> void:
	var dist: float = position.distance_to(target.position)
	if dist <= CLOSE_AGGRO_RANGE:
		is_chasing = true
		return
	if dist <= DETECTION_RANGE and has_clear_path_to(target):
		is_chasing = true

func chase_player(delta, target: Character):
	velocity = Vector2.ZERO
	var delta_pos: Vector2 = target.position - position
	if abs(delta_pos.x) > abs(delta_pos.y):
		velocity.x = 1.0 if delta_pos.x > 0.0 else -1.0
	else:
		velocity.y = 1.0 if delta_pos.y > 0.0 else -1.0
	velocity = velocity.normalized() * CHASE_SPEED
	if velocity.x != 0.0:
		sprite.flip_h = velocity.x < 0.0
	move_and_slide()
	if position.distance_to(target.position) > DETECTION_RANGE * 1.15:
		is_chasing = false
	handle_collision()

func has_clear_path_to(target: Character) -> bool:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(position, target.position)
	query.exclude = [get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return true
	return _collider_is_target(result.get("collider"), target)

func _collider_is_target(collider, target: Character) -> bool:
	if collider == null or target == null:
		return false
	if collider == target:
		return true
	if collider is Character:
		return collider == target
	return false

func _get_chase_target() -> Character:
	if player != null and is_instance_valid(player) and player.current_hp > 0 and player.is_party_leader:
		return player
	return null

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
		var target: Character = _get_chase_target()
		if collider == target and is_instance_valid(target) and !battle_started and !target.battle_started and !_in_encounter_grace() and !target._in_encounter_grace():
			target.collided_with_enemy()
			enemy_battle_start.emit(self)

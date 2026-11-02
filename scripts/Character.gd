extends CharacterBody2D
class_name Character

const SPEED = 300.0
@onready var ap = $AnimationPlayer
@onready var progress_bar = $ProgressBar
@onready var focus = $Focus
@onready var damage_text = $DamageReceived
@onready var damage_sound = $DamageSound
@onready var death_sound = $DeathSound
signal boss_battle_start
signal enemy_battle_start
signal character_defeated
signal item_picked
var battle_started = false
var max_hp = 150
var current_hp
var initiative:int
var attack = 10
var is_defending = false
var is_colliding = false
var is_party_leader := true
var follow_target: Character = null
var follow_offset := Vector2.ZERO

const PARTY_FOLLOW_SPEED := 8.0

var _spawn_collision_layer: int
var _spawn_collision_mask: int

# Called when the node enters the scene tree for the first time.
func _ready():
	_spawn_collision_layer = collision_layer
	_spawn_collision_mask = collision_mask
	visible = false
	progress_bar.max_value = max_hp
	current_hp = max_hp
	
func apply_definition(definition: CharacterDefinition) -> void:
	if definition == null:
		return
	max_hp = definition.max_hp
	attack = definition.attack
	initiative = definition.initiative
	if progress_bar:
		progress_bar.max_value = max_hp
	current_hp = max_hp

func spawn(starting_room, tilemap):
	var center = tilemap.map_to_local(starting_room.get_center())
	if is_party_leader:
		position = center
	else:
		position = center + follow_offset
	initiative = clampi(initiative, 1, 100)
	visible = true
	_configure_party_collision()

func spawn_as_follower(starting_room, tilemap, leader: Character, offset: Vector2) -> void:
	is_party_leader = false
	follow_target = leader
	follow_offset = offset
	spawn(starting_room, tilemap)

func _configure_party_collision() -> void:
	if is_party_leader:
		collision_layer = _spawn_collision_layer
		collision_mask = _spawn_collision_mask
	else:
		collision_layer = 0
		collision_mask = _spawn_collision_mask

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if visible and !battle_started:
		if is_party_leader:
			read_input()
		elif follow_target != null:
			_follow_leader(delta)

func _follow_leader(delta: float) -> void:
	var to_target := (follow_target.position + follow_offset) - position
	if to_target.length() < 8.0:
		ap.stop()
		return
	var direction := to_target.normalized()
	if abs(direction.x) > abs(direction.y):
		ap.play("walk_right" if direction.x > 0 else "walk_left")
	else:
		ap.play("walk_down" if direction.y > 0 else "walk_up")
	velocity = direction * SPEED
	move_and_slide()
		
func read_input():
	velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_down"):
		ap.play("walk_down")
		velocity.y += 1
	elif Input.is_action_pressed("ui_right"):
		ap.play("walk_right")
		velocity.x += 1
	elif Input.is_action_pressed("ui_left"):
		ap.play("walk_left")
		velocity.x -= 1
	elif Input.is_action_pressed("ui_up"):
		ap.play("walk_up")
		velocity.y -= 1
	else:
		ap.stop()
	velocity = velocity.normalized() * SPEED
	move_and_slide()
	handle_collision()

func handle_collision():
	if !is_party_leader:
		return
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision != null:
			var collider = collision.get_collider()
			if collider != null:
				if collider.name.contains("Boss") and !battle_started:
					collided_with_enemy()
					boss_battle_start.emit()
				elif collider.name.contains("Enemy") and !battle_started:
					collided_with_enemy()
					enemy_battle_start.emit(collider)
				elif collider.name.contains("Fountain") and !battle_started:
					if !is_colliding:
						collider.handle_collision()
						is_colliding = true
				elif collider is Item and !battle_started:
					if !is_colliding:
						is_colliding = true
						item_picked.emit(collider)
	if is_colliding and get_slide_collision_count() == 0:
		is_colliding = false

func collided_with_enemy():
	battle_started = true
	update_progress_bar()
	progress_bar.visible = true
	ap.play("walk_left")
	ap.stop()
	
func update_progress_bar():
	progress_bar.value = current_hp
	if current_hp == 0:
		ap.play("death")
		death_sound.play()
		await get_tree().create_timer(1.0).timeout
		progress_bar.visible = false
		death_sound.stop()
		Global.increment_death_count()
		character_defeated.emit()

func receive_damage(damage):
	var damage_received := damage
	if is_defending:
		damage_received = damage / 2
	current_hp -= damage_received
	damage_text.text = "-"+str(damage_received)
	damage_text.visible = true
	ap.play("hurt")
	damage_sound.play()
	is_defending = false
	# Ensure health doesn't go below 0
	current_hp = max(current_hp, 0)
	update_progress_bar()
	await get_tree().create_timer(1.0).timeout
	damage_text.visible = false
	damage_sound.stop()
	

func defend():
	is_defending = true
	ap.play("defend")
	
func heal():
	current_hp = max_hp
	update_progress_bar()

func apply_healing(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)
	update_progress_bar()

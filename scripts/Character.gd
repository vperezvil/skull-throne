extends CharacterBody2D


const SPEED = 300.0
@onready var ap = $AnimationPlayer
@onready var progress_bar = $ProgressBar
@onready var focus = $Focus
signal boss_battle_start
signal enemy_battle_start
var battle_started = false
var max_hp = 150
var current_hp
var initiative:int
var attack = 10
var is_defending = false

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	progress_bar.max_value = max_hp
	current_hp = max_hp
	
func spawn(starting_room, tilemap):
	var center = tilemap.map_to_local(starting_room.get_center())
	position = center
	initiative = clamp(initiative, 1, 100)
	visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if visible and !battle_started:
		read_input()
		
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
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.name == "Boss" and !battle_started:
			collided_with_enemy()
			boss_battle_start.emit()
		if collider.name.contains("Enemy") and !battle_started:
			collided_with_enemy()
			enemy_battle_start.emit()
			
func collided_with_enemy():
	battle_started = true
	update_progress_bar()
	progress_bar.visible = true
	ap.play("walk_left")
	ap.stop()
	
func update_progress_bar():
	progress_bar.value = current_hp

func receive_damage(damage):
	if is_defending:
		current_hp -= damage/2
	else:
		current_hp -= damage
	ap.play("hurt")
	is_defending = false
	# Ensure health doesn't go below 0
	current_hp = max(current_hp, 0)
	update_progress_bar()

func defend():
	is_defending = true
	ap.play("defend")

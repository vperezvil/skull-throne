extends CharacterBody2D


const SPEED = 300.0
@onready var ap = $AnimationPlayer
signal boss_battle_start
signal enemy_battle_start
var battle_started = false
# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	
func spawn(starting_room, tilemap):
	var center = tilemap.map_to_local(starting_room.get_center())
	position = center
	visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if visible and !battle_started:
		read_input()
	if battle_started:
		ap.play("walk_left")
		ap.stop()
		
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
			battle_started = true
			boss_battle_start.emit()
		if collider.name.contains("Enemy"):
			enemy_battle_start.emit()

extends CharacterBody2D


const SPEED = 300.0
@onready var ap = $AnimationPlayer
@onready var sprite = $BodySkeleton

# Called when the node enters the scene tree for the first time.
func _ready():
	ap.play("walk_down") # Replace with function body.
	
func spawn(starting_room, tilemap):
	var center = tilemap.map_to_local(starting_room.get_center())
	position = center
	visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	read_input()
func read_input():
	velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_down"):
		ap.play("walk_down")
		velocity.y += 1
		velocity = velocity.normalized() * SPEED
		move_and_slide()
	elif Input.is_action_pressed("ui_right"):
		ap.play("walk_right")
		velocity.x += 1
		velocity = velocity.normalized() * SPEED
		move_and_slide()
	elif Input.is_action_pressed("ui_left"):
		ap.play("walk_left")
		velocity.x -= 1
		velocity = velocity.normalized() * SPEED
		move_and_slide()
	elif Input.is_action_pressed("ui_up"):
		ap.play("walk_up")
		velocity.y -= 1
		velocity = velocity.normalized() * SPEED
		move_and_slide()
	else:
		ap.stop()

extends CharacterBody2D


const SPEED = 300.0
@onready var sprite = $BossSprite
var battle_started = false
var max_hp = 150
var current_hp
@onready var progress_bar = $ProgressBar

func _ready():
	visible = false

func spawn(starting_room, tilemap):
	var center = tilemap.map_to_local(starting_room)
	position = center
	visible = true
	current_hp = max_hp
	update_progress_bar()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if battle_started:
		sprite.flip_h = true

func update_progress_bar():
	progress_bar.value = (current_hp/max_hp) * 100

extends CharacterBody2D


const SPEED = 300.0
@onready var ap = $AnimationPlayer
@onready var sprite = $BossSprite
var battle_started = false
var max_hp = 150
var current_hp
var initiative:int
var attack = 10
var ENEMY_NAME = 'Evil Geanie'
@onready var progress_bar = $ProgressBar

func _ready():
	visible = false
	progress_bar.max_value = max_hp
	current_hp = max_hp

func spawn(starting_room, tilemap):
	var center = tilemap.map_to_local(starting_room)
	position = center
	initiative = clamp(initiative, 1, 100)
	visible = true
	update_progress_bar()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if battle_started:
		sprite.flip_h = true

func update_progress_bar():
	progress_bar.value = current_hp

func receive_damage(damage):
	current_hp -= damage
	ap.play("hurt")
	update_progress_bar()

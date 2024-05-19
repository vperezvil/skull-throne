extends CharacterBody2D


const SPEED = 300.0
@onready var ap = $AnimationPlayer
@onready var sprite = $BossSprite
var battle_started = false
var max_hp = 150
var current_hp
var initiative:int
var attack = 20
@onready var progress_bar = $ProgressBar
@onready var focus = $Focus
signal enemy_selected
signal enemy_defeated
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
	if current_hp == 0:
		ap.play("death")
		await get_tree().create_timer(1.0).timeout
		progress_bar.visible = false
		enemy_defeated.emit()

func receive_damage(damage):
	current_hp -= damage
	ap.play("hurt")
	# Ensure health doesn't go below 0
	current_hp = max(current_hp, 0)
	update_progress_bar()

func _on_focus_pressed():
	enemy_selected.emit()

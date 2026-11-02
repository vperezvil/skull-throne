extends Combatant
class_name Boss

@onready var sprite = $BossSprite

func _ready():
	_ready_combatant()

const BASE_BOSS_HP := 150

func spawn(room: Rect2, tilemap: TileMap) -> void:
	var center := tilemap.map_to_local(room.get_center())
	position = center
	spawn_initiative_clamp()
	max_hp = BASE_BOSS_HP + RunState.get_skull_throne_bonus_hp()
	current_hp = max_hp
	progress_bar.max_value = max_hp
	visible = true
	update_progress_bar()

func _physics_process(_delta):
	if battle_started:
		sprite.flip_h = true

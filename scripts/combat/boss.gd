extends Combatant
class_name Boss

@onready var sprite = $BossSprite

const BASE_WARDEN_HP := 140
const BASE_KHORNE_HP := 380

var boss_kind: String = "warden"
var display_title: String = "Zone Warden"

func _ready():
	_ready_combatant()

func configure_for_zone(zone: ZoneDefinition) -> void:
	if zone == null:
		return
	boss_kind = zone.boss_kind
	if zone.boss_kind == "khorne":
		configure_khorne()
	else:
		configure_warden(zone)

func configure_warden(zone: ZoneDefinition) -> void:
	display_title = "Blood Warden"
	name = "Blood Warden Boss"
	attack = 18 + RunState.get_run_depth() * 2
	initiative = 35
	if sprite:
		sprite.texture = load("res://assets/monsters/unique/azrael.png")
		sprite.scale = Vector2(5, 5)

func configure_khorne() -> void:
	display_title = "Khorne - Blood God"
	name = "Khorne Blood God Boss"
	attack = 32
	initiative = 45
	max_hp = int((BASE_KHORNE_HP + Global.total_deaths * 8) * RunModifiers.boss_hp_multiplier(RunState.run_modifier_id) * RunModifiers.ascended_boss_hp_multiplier(RunState.ascended_run))
	current_hp = max_hp
	if progress_bar:
		progress_bar.max_value = max_hp
	if sprite:
		sprite.texture = load("res://assets/monsters/unique/asmodeus.png")
		sprite.modulate = Color(1.0, 0.35, 0.25)
		sprite.scale = Vector2(4.5, 4.5)

func spawn(room: Rect2, tilemap: Node2D) -> void:
	var center: Vector2 = tilemap.map_to_local(room.get_center())
	position = center
	spawn_initiative_clamp()
	if boss_kind != "khorne":
		max_hp = int((BASE_WARDEN_HP + RunState.get_skull_throne_bonus_hp() + RunState.get_run_depth() * 25) * RunModifiers.boss_hp_multiplier(RunState.run_modifier_id) * RunModifiers.ascended_boss_hp_multiplier(RunState.ascended_run))
		current_hp = max_hp
		progress_bar.max_value = max_hp
	visible = true
	update_progress_bar()

func _physics_process(_delta):
	if battle_started:
		sprite.flip_h = true

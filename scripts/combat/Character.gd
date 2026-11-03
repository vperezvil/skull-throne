extends CharacterBody2D
class_name Character

const BASE_SPEED := 300.0

@onready var ap = $AnimationPlayer
@onready var progress_bar = $ProgressBar
@onready var focus = $Focus
@onready var damage_text = $DamageReceived
@onready var damage_sound = $DamageSound
@onready var death_sound = $DeathSound

var mp_bar: ProgressBar
var xp_bar: ProgressBar

signal boss_battle_start
signal enemy_battle_start
signal character_defeated
signal item_picked

var character_id: String = ""
var skills: Array[SkillDefinition] = []
var _base_attack: int = 10
var _base_max_hp: int = 150
var _base_crit_rate: float = 0.05
var _base_initiative: int = 50
var _veteran_bonus_hp: int = 0
var _veteran_bonus_atk: int = 0
var stress: int = 0
var _battle_first_kill_done := false
var _equip_attack: int = 0
var _equip_hp: int = 0
var _equip_crit: float = 0.0
var battle_started = false
var max_hp = 150
var current_hp
var max_mp: int = 0
var current_mp: int = 0
var level: int = 1
var xp: int = 0
var initiative: int
var attack = 10
var crit_rate: float = 0.05
var move_speed: float = BASE_SPEED
var mp_regen_per_turn: int = 2
var bleed_stacks: int = 0
var poison_stacks: int = 0
var _base_mp_regen: int = 2
var skill_cooldowns: Dictionary = {}
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
	if damage_sound:
		Global.assign_sfx_bus(damage_sound)
	if death_sound:
		Global.assign_sfx_bus(death_sound)
	visible = false
	progress_bar.max_value = max_hp
	current_hp = max_hp
	_setup_resource_bars()

func _setup_resource_bars() -> void:
	var theme := progress_bar.theme
	mp_bar = ProgressBar.new()
	mp_bar.name = "MpBar"
	mp_bar.visible = false
	mp_bar.show_percentage = false
	mp_bar.offset_left = progress_bar.offset_left
	mp_bar.offset_right = progress_bar.offset_right
	mp_bar.offset_top = progress_bar.offset_top + 18
	mp_bar.offset_bottom = progress_bar.offset_bottom + 18
	if theme:
		mp_bar.theme = theme
	mp_bar.modulate = Color(0.55, 0.75, 1.0)
	add_child(mp_bar)
	xp_bar = ProgressBar.new()
	xp_bar.name = "XpBar"
	xp_bar.visible = false
	xp_bar.show_percentage = false
	xp_bar.offset_left = progress_bar.offset_left
	xp_bar.offset_right = progress_bar.offset_right
	xp_bar.offset_top = progress_bar.offset_top + 36
	xp_bar.offset_bottom = progress_bar.offset_bottom + 36
	if theme:
		xp_bar.theme = theme
	add_child(xp_bar)
	_update_resource_bars()
	
func apply_definition(definition: CharacterDefinition) -> void:
	if definition == null:
		return
	character_id = definition.character_id
	var rolled := RunState.get_stat_variant(character_id) if RunState.campaign_active else {}
	var hp_base: int = int(rolled.get("max_hp", definition.max_hp))
	var atk_base: int = int(rolled.get("attack", definition.attack))
	var init_base: int = int(rolled.get("initiative", definition.initiative))
	var mp_base: int = int(rolled.get("max_mp", definition.max_mp))
	var crit_base: float = float(rolled.get("crit_rate", definition.crit_rate))
	_base_max_hp = hp_base
	_base_attack = atk_base
	max_hp = hp_base
	max_mp = mp_base
	attack = atk_base
	initiative = init_base
	_base_initiative = init_base
	crit_rate = crit_base
	_base_crit_rate = crit_base
	move_speed = definition.move_speed
	mp_regen_per_turn = definition.mp_regen_per_turn
	_base_mp_regen = definition.mp_regen_per_turn
	skills = SkillLibrary.get_skills_for_character(character_id)
	_equip_attack = 0
	_equip_hp = 0
	_equip_crit = 0.0
	if progress_bar:
		progress_bar.max_value = max_hp
	current_hp = max_hp
	current_mp = max_mp
	MetaProgress.apply_veteran_progress(self)
	apply_run_equipment()
	apply_blessing_bonuses()
	current_hp = max_hp
	current_mp = max_mp
	_update_resource_bars()

func refresh_skills_from_training() -> void:
	skills = SkillLibrary.get_skills_for_character(character_id)
	skill_cooldowns.clear()

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
	velocity = direction * move_speed
	move_and_slide()
		
func read_input():
	velocity = Vector2.ZERO
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length_squared() < 0.01:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction.length_squared() > 0.01:
		direction = direction.normalized()
		if abs(direction.x) > abs(direction.y):
			ap.play("walk_right" if direction.x > 0 else "walk_left")
		else:
			ap.play("walk_down" if direction.y > 0 else "walk_up")
		velocity = direction * move_speed
		move_and_slide()
	else:
		ap.stop()
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
	if mp_bar:
		mp_bar.visible = max_mp > 0
	if xp_bar:
		xp_bar.visible = true
	ap.play("walk_left")
	ap.stop()
	
func update_progress_bar():
	if Global.high_contrast_bars:
		progress_bar.modulate = Color(1.15, 1.15, 1.15)
	else:
		progress_bar.modulate = Color.WHITE
	progress_bar.value = current_hp
	_update_resource_bars()
	if current_hp == 0:
		ap.play("death")
		death_sound.play()
		await get_tree().create_timer(1.0).timeout
		progress_bar.visible = false
		death_sound.stop()
		Global.increment_death_count()
		character_defeated.emit()

func receive_damage(damage, is_crit: bool = false):
	var damage_received := damage
	if is_defending:
		damage_received = damage / 2
	damage_received = int(damage_received * CharacterTraits.get_incoming_damage_multiplier(character_id))
	current_hp -= damage_received
	_show_damage_number(damage_received, is_crit, false)
	ap.play("hurt")
	if Global.screen_shake_enabled:
		_flash_hit()
	damage_sound.play()
	is_defending = false
	current_hp = max(current_hp, 0)
	update_progress_bar()
	if RunState.campaign_active:
		StressSystem.on_damage_taken(self)
	await get_tree().create_timer(1.0).timeout
	damage_sound.stop()

func _show_damage_number(amount: int, is_crit: bool, is_heal: bool) -> void:
	damage_text.text = ("+" if is_heal else "-") + str(amount)
	if is_crit:
		damage_text.modulate = Color(1.0, 0.35, 0.35)
	elif is_heal:
		damage_text.modulate = Color(0.45, 1.0, 0.55)
	else:
		damage_text.modulate = Color(1.0, 0.85, 0.5)
	damage_text.visible = true
	await get_tree().create_timer(0.85).timeout
	damage_text.visible = false
	damage_text.modulate = Color.WHITE

func _flash_hit() -> void:
	var original := modulate
	modulate = Color(1.4, 0.6, 0.6)
	await get_tree().create_timer(0.12).timeout
	modulate = original

func reset_battle_state() -> void:
	_battle_first_kill_done = false
	remove_meta("oath_kill_bonus")
	

func defend():
	is_defending = true
	ap.play("defend")
	
func heal():
	current_hp = max_hp
	current_mp = max_mp
	update_progress_bar()

func hide_battle_bars() -> void:
	progress_bar.visible = false
	if mp_bar:
		mp_bar.visible = false
	if xp_bar:
		xp_bar.visible = false

func apply_healing(amount: int) -> void:
	var received := int(amount * CharacterTraits.get_healing_multiplier(character_id))
	if poison_stacks > 0:
		received = int(received * 0.75)
	current_hp = mini(current_hp + received, max_hp)
	_update_resource_bars()

func apply_bleed(stacks: int) -> void:
	bleed_stacks = maxi(0, bleed_stacks + stacks)

func apply_poison(stacks: int) -> void:
	poison_stacks = maxi(0, poison_stacks + stacks)

func clear_status_effects() -> void:
	bleed_stacks = 0
	poison_stacks = 0

func tick_status_effects_start_of_turn() -> String:
	var parts: PackedStringArray = []
	if bleed_stacks > 0:
		var bleed_damage := bleed_stacks * 3
		current_hp = maxi(0, current_hp - bleed_damage)
		parts.append("bleed %d" % bleed_damage)
	if poison_stacks > 0:
		var poison_damage := poison_stacks * 2
		current_hp = maxi(0, current_hp - poison_damage)
		parts.append("poison %d" % poison_damage)
	if parts.is_empty():
		return ""
	update_progress_bar()
	return " (%s)" % ", ".join(parts)

func apply_blessing_bonuses() -> void:
	recalculate_combat_stats()

func recalculate_combat_stats() -> void:
	var trait_mods := CharacterTraits.get_stat_modifiers(character_id)
	var sanctum_hp := MetaProgress.vitality_level * MetaProgress.VITALITY_HP_BONUS
	var sanctum_atk := MetaProgress.fury_level * MetaProgress.FURY_ATK_BONUS
	attack = (
		_base_attack
		+ _equip_attack
		+ RunState.get_blessing_attack_bonus()
		+ sanctum_atk
		+ _veteran_bonus_atk
		+ int(trait_mods.get("attack", 0))
	)
	max_hp = (
		_base_max_hp
		+ _equip_hp
		+ RunState.get_blessing_hp_bonus()
		+ sanctum_hp
		+ _veteran_bonus_hp
		+ int(trait_mods.get("max_hp", 0))
	)
	crit_rate = _base_crit_rate + _equip_crit + RunState.get_blessing_crit_bonus() + float(trait_mods.get("crit_rate", 0.0))
	mp_regen_per_turn = _base_mp_regen + RunState.get_blessing_mp_regen_bonus() + int(trait_mods.get("mp_regen", 0))
	initiative = clampi(_base_initiative + int(trait_mods.get("initiative", 0)), 1, 100)
	current_hp = mini(current_hp, max_hp)
	if progress_bar:
		progress_bar.max_value = max_hp
	_update_resource_bars()

func spend_mp(cost: int) -> bool:
	if cost <= 0:
		return true
	if current_mp < cost:
		return false
	current_mp -= cost
	_update_resource_bars()
	return true

func reset_battle_cooldowns() -> void:
	skill_cooldowns.clear()

func tick_skill_cooldowns() -> void:
	var expired: Array[String] = []
	for skill_id in skill_cooldowns.keys():
		skill_cooldowns[skill_id] = int(skill_cooldowns[skill_id]) - 1
		if skill_cooldowns[skill_id] <= 0:
			expired.append(skill_id)
	for skill_id in expired:
		skill_cooldowns.erase(skill_id)

func get_skill_cooldown_remaining(skill_id: String) -> int:
	return int(skill_cooldowns.get(skill_id, 0))

func start_skill_cooldown(skill: SkillDefinition) -> void:
	if skill == null or skill.cooldown_turns <= 0:
		return
	skill_cooldowns[skill.skill_id] = skill.cooldown_turns

func can_use_skill(skill: SkillDefinition) -> bool:
	if skill == null:
		return false
	if get_skill_cooldown_remaining(skill.skill_id) > 0:
		return false
	if skill.mp_cost > current_mp:
		return false
	return true

func regenerate_mp_this_turn() -> int:
	if max_mp <= 0:
		return 0
	var amount := mp_regen_per_turn + level / 4
	var before := current_mp
	restore_mp(amount)
	return current_mp - before

func restore_mp(amount: int) -> void:
	current_mp = mini(current_mp + amount, max_mp)
	_update_resource_bars()

func xp_to_next_level() -> int:
	return level * 40 + 40

func gain_xp(amount: int, track_for_run: bool = true) -> void:
	if amount <= 0:
		return
	if track_for_run and RunState.campaign_active:
		RunState.record_xp_gained(character_id, amount)
	xp += amount
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		_level_up()

func apply_level_up_bonus() -> void:
	_base_max_hp += 8
	_base_attack += 2
	max_mp += 5
	level += 1
	recalculate_combat_stats()
	current_hp = max_hp
	current_mp = max_mp
	if progress_bar:
		progress_bar.max_value = max_hp
	_update_resource_bars()

func _level_up() -> void:
	_base_max_hp += 8
	_base_attack += 2
	max_mp += 5
	level += 1
	recalculate_combat_stats()
	current_hp = max_hp
	current_mp = max_mp
	if progress_bar:
		progress_bar.max_value = max_hp
	_update_resource_bars()

func apply_run_equipment() -> void:
	_equip_attack = 0
	_equip_hp = 0
	_equip_crit = 0.0
	for slot in [EquipmentDefinition.Slot.WEAPON, EquipmentDefinition.Slot.HEAD, EquipmentDefinition.Slot.HANDS, EquipmentDefinition.Slot.BODY]:
		var eq_id := RunState.get_equipped_id(character_id, slot)
		if eq_id == "":
			continue
		var def := EquipmentRegistry.get_definition(eq_id)
		if def == null:
			continue
		_equip_attack += def.attack_bonus
		_equip_hp += def.hp_bonus
		_equip_crit += def.crit_bonus
	recalculate_combat_stats()

func get_crit_chance() -> float:
	return crit_rate

func roll_crit(skill: SkillDefinition = null) -> bool:
	var bonus := skill.crit_bonus if skill else 0.0
	return randf() < get_crit_chance() + bonus

func receive_damage_from_attack(damage: int, was_crit: bool) -> void:
	receive_damage(damage, was_crit)

func compute_skill_damage(skill: SkillDefinition, _target) -> int:
	var damage := 0
	match skill.damage_kind:
		SkillDefinition.DamageKind.PHYSICAL:
			damage = attack + skill.power
			if roll_crit(skill):
				damage *= 2
		SkillDefinition.DamageKind.MAGICAL:
			damage = skill.power + int(attack * 0.75)
	damage = int(damage * MetaProgress.get_skill_damage_multiplier(character_id))
	return maxi(damage, 1)

func compute_basic_attack_damage() -> int:
	var damage := attack
	if roll_crit():
		damage *= 2
	return damage

func _update_resource_bars() -> void:
	if mp_bar:
		mp_bar.max_value = maxi(max_mp, 1)
		mp_bar.value = current_mp
	if xp_bar:
		xp_bar.max_value = maxi(xp_to_next_level(), 1)
		xp_bar.value = xp

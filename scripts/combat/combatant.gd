extends CharacterBody2D
class_name Combatant

# Shared HP bar, damage numbers, and sounds for Enemy / Boss.

@onready var ap: AnimationPlayer = $AnimationPlayer
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var focus: Control = $Focus
@onready var damage_text: RichTextLabel = $DamageReceived
@onready var damage_sound: AudioStreamPlayer = $DamageSound
@onready var death_sound: AudioStreamPlayer = $DeathSound

signal enemy_selected
signal enemy_defeated

var battle_started: bool = false
var max_hp: int = 100
var current_hp: int
var initiative: int = 50
var attack: int = 10
var _bar_value_label: Label
var _battle_hud_active: bool = false

func _ready_combatant() -> void:
	progress_bar.max_value = max_hp
	current_hp = max_hp
	if damage_sound:
		Global.assign_sfx_bus(damage_sound)
	if death_sound:
		Global.assign_sfx_bus(death_sound)

func apply_combat_stats(hp: int, atk: int, init: int) -> void:
	max_hp = hp
	attack = atk
	initiative = init
	if progress_bar:
		progress_bar.max_value = max_hp
	current_hp = max_hp

func spawn_initiative_clamp() -> void:
	initiative = clampi(initiative, 1, 100)

func apply_battle_presentation_scale(factor: float) -> void:
	scale *= factor
	var inv := 1.0 / factor
	progress_bar.scale = Vector2(inv, inv)

func _visual_sprite_node() -> Node2D:
	if has_node("EnemySprite"):
		return $EnemySprite as Node2D
	if has_node("Body"):
		return $Body as Node2D
	for child in get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			return child as Node2D
	return null

func _sprite_top_local_y() -> float:
	var sprite := _visual_sprite_node()
	if sprite == null:
		return -56.0
	var height := 64.0
	if sprite is Sprite2D:
		var s: Sprite2D = sprite as Sprite2D
		if s.texture != null:
			var frame_h: float = s.texture.get_height() / maxf(float(maxi(s.vframes, 1)), 1.0)
			height = frame_h * absf(s.scale.y)
		else:
			height = 64.0 * absf(s.scale.y)
	elif sprite is AnimatedSprite2D:
		var a: AnimatedSprite2D = sprite as AnimatedSprite2D
		if a.sprite_frames != null and a.sprite_frames.has_animation(a.animation):
			var tex: Texture2D = a.sprite_frames.get_frame_texture(a.animation, 0)
			if tex != null:
				height = tex.get_height() * absf(a.scale.y)
	return sprite.position.y - height * 0.5

func _sprite_center_x() -> float:
	var sprite := _visual_sprite_node()
	return sprite.position.x if sprite != null else 0.0

func align_battle_hud_to_sprite() -> void:
	var cx := _sprite_center_x()
	var top_y := _sprite_top_local_y()
	var bar_h := 14.0
	var gap := 10.0
	var half_w := 56.0
	progress_bar.offset_left = cx - half_w
	progress_bar.offset_right = cx + half_w
	progress_bar.offset_top = top_y - bar_h - gap
	progress_bar.offset_bottom = top_y - gap

func prepare_battle_hud() -> void:
	_battle_hud_active = true
	_ensure_bar_value_label()
	_bar_value_label.visible = true
	progress_bar.show_percentage = false
	align_battle_hud_to_sprite()
	_sync_bar_value_label()

func _ensure_bar_value_label() -> void:
	if _bar_value_label != null:
		return
	_bar_value_label = Label.new()
	_bar_value_label.name = "BarValue"
	_bar_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bar_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bar_value_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bar_value_label.add_theme_font_size_override("font_size", Global.get_ui_font_size(11))
	_bar_value_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	progress_bar.add_child(_bar_value_label)

func _sync_bar_value_label() -> void:
	if _bar_value_label == null or !_battle_hud_active:
		return
	_bar_value_label.text = "%d/%d" % [current_hp, max_hp]

func reset_presentation_bars() -> void:
	_battle_hud_active = false
	if _bar_value_label:
		_bar_value_label.visible = false
	progress_bar.scale = Vector2.ONE
	progress_bar.offset_left = -52.0
	progress_bar.offset_right = 53.0
	progress_bar.offset_top = -42.0
	progress_bar.offset_bottom = -24.0

func update_progress_bar() -> void:
	progress_bar.value = current_hp
	_sync_bar_value_label()
	if current_hp <= 0:
		ap.play("death")
		death_sound.play()
		await get_tree().create_timer(1.0).timeout
		progress_bar.visible = false
		death_sound.stop()
		enemy_defeated.emit()

func receive_damage(damage: int) -> void:
	current_hp -= damage
	damage_text.text = "-" + str(damage)
	damage_text.visible = true
	ap.play("hurt")
	damage_sound.play()
	current_hp = maxi(current_hp, 0)
	update_progress_bar()
	await get_tree().create_timer(1.0).timeout
	damage_text.visible = false
	damage_sound.stop()

func _on_focus_pressed() -> void:
	enemy_selected.emit()

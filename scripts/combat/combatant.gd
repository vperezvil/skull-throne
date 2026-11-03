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
var _battle_bar_mount: Dictionary = {}

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

func align_battle_hud_to_sprite() -> void:
	BattleHudLayout.mount_bar(self, progress_bar)

func prepare_battle_hud() -> void:
	_battle_hud_active = true
	_bar_value_label = BattleHudLayout.ensure_bar_label(progress_bar)
	_bar_value_label.visible = true
	progress_bar.show_percentage = false
	align_battle_hud_to_sprite()
	_sync_bar_value_label()

func _ensure_bar_value_label() -> void:
	if _bar_value_label == null:
		_bar_value_label = BattleHudLayout.ensure_bar_label(progress_bar)

func _sync_bar_value_label() -> void:
	if _bar_value_label == null or !_battle_hud_active:
		return
	_bar_value_label.text = "%d/%d" % [current_hp, max_hp]

func reset_presentation_bars() -> void:
	_battle_hud_active = false
	if _bar_value_label:
		_bar_value_label.visible = false
	BattleHudLayout.unmount_bar(progress_bar, _battle_bar_mount)
	_battle_bar_mount.clear()
	progress_bar.scale = Vector2.ONE
	progress_bar.position = Vector2.ZERO
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

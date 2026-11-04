extends Resource
class_name SkillDefinition

enum TargetKind { ENEMY, ALLY, SELF }
enum DamageKind { PHYSICAL, MAGICAL, HEAL }

@export var skill_id: String = ""
@export var display_name: String = "Skill"
@export var description: String = ""
@export var mp_cost: int = 0
@export var power: int = 10
@export var target_kind: TargetKind = TargetKind.ENEMY
@export var damage_kind: DamageKind = DamageKind.PHYSICAL
@export var crit_bonus: float = 0.0
@export var initiative_bonus: int = 0
@export var cooldown_turns: int = 0
@export var icon_path: String = ""

extends Resource
class_name EquipmentDefinition

enum Slot { WEAPON, HEAD, HANDS, BODY }

@export var equipment_id: String = ""
@export var display_name: String = ""
@export var slot: Slot = Slot.WEAPON
@export var icon_path: String = ""
@export var attack_bonus: int = 0
@export var hp_bonus: int = 0
@export var crit_bonus: float = 0.0
@export var sanctum_price: int = 35
@export var waystation_price: int = 22

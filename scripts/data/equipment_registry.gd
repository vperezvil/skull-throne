extends Node

var catalog: Dictionary = {}

func _ready() -> void:
	_register_all()

func get_definition(id: String) -> EquipmentDefinition:
	return catalog.get(id)

func get_all_ids() -> Array:
	return catalog.keys()

func get_shop_ids(use_run_gold: bool) -> Array:
	var ids: Array = get_all_ids()
	ids.sort()
	if !use_run_gold:
		return ids
	var depth := RunState.floors_cleared_this_run
	var count := clampi(4 + depth / 2, 4, ids.size())
	return ids.slice(0, count)

func _register_all() -> void:
	_add("weapon_blessed_blade", "Blessed Blade", EquipmentDefinition.Slot.WEAPON,
		"res://assets/items/weapon/blessed_blade.png", 6, 0, 0.0, 45, 28)
	_add("weapon_quickblade", "Quickblade", EquipmentDefinition.Slot.WEAPON,
		"res://assets/items/weapon/quickblade.png", 4, 0, 0.03, 32, 20)
	_add("weapon_club", "Iron Club", EquipmentDefinition.Slot.WEAPON,
		"res://assets/items/weapon/club.png", 3, 4, 0.0, 25, 18)
	_add("head_chain_helm", "Chain Helm", EquipmentDefinition.Slot.HEAD,
		"res://assets/accessories/HEAD_chain_armor_helmet.png", 0, 12, 0.0, 30, 22)
	_add("head_leather_hat", "Leather Cap", EquipmentDefinition.Slot.HEAD,
		"res://assets/accessories/HEAD_leather_armor_hat.png", 1, 8, 0.0, 22, 15)
	_add("hands_plate_gloves", "Plate Gloves", EquipmentDefinition.Slot.HANDS,
		"res://assets/accessories/HANDS_plate_armor_gloves.png", 2, 6, 0.0, 28, 20)
	_add("body_leather_belt", "Leather Belt", EquipmentDefinition.Slot.BODY,
		"res://assets/accessories/BELT_leather.png", 0, 10, 0.02, 26, 18)
	_add("amulet_gold", "Celtic Amulet", EquipmentDefinition.Slot.BODY,
		"res://assets/items/amulet/celtic_red.png", 0, 5, 0.05, 40, 25)
	_add("ring_silver", "Silver Ring", EquipmentDefinition.Slot.HANDS,
		"res://assets/items/amulet/celtic_blue.png", 1, 0, 0.04, 35, 22)
	_add("cloak_traveler", "Traveler's Cloak", EquipmentDefinition.Slot.BODY,
		"res://assets/accessories/BELT_leather.png", 0, 14, 0.0, 38, 24)

func _add(
	id: String,
	display: String,
	slot: EquipmentDefinition.Slot,
	icon: String,
	atk: int,
	hp: int,
	crit: float,
	sanctum: int,
	way: int
) -> void:
	var def := EquipmentDefinition.new()
	def.equipment_id = id
	def.display_name = display
	def.slot = slot
	def.icon_path = icon
	def.attack_bonus = atk
	def.hp_bonus = hp
	def.crit_bonus = crit
	def.sanctum_price = sanctum
	def.waystation_price = way
	catalog[id] = def

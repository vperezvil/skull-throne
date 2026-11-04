extends SceneTree

# Run: godot --headless --path . --script res://scripts/tools/content_validator.gd

const EquipmentRegistryScript := preload("res://scripts/data/equipment_registry.gd")

func _init() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var errors: PackedStringArray = []
	errors.append_array(_validate_equipment())
	if errors.is_empty():
		print("Content validation OK")
		quit(0)
	for e in errors:
		push_error(e)
	quit(1)

func _validate_equipment() -> PackedStringArray:
	var out: PackedStringArray = []
	var registry: Node = EquipmentRegistryScript.new()
	registry.call("_register_all")
	for eq_id in registry.get_shop_ids(false):
		if registry.get_definition(eq_id) == null:
			out.append("Missing equipment def: %s" % eq_id)
	return out

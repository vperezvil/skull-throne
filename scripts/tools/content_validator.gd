extends SceneTree

# Run: godot --headless --path . --script res://scripts/tools/content_validator.gd

func _init() -> void:
	# Autoload _ready() runs after _init; defer so equipment catalog is registered.
	call_deferred("_run_validation")

func _run_validation() -> void:
	var errors: PackedStringArray = []
	errors.append_array(_validate_equipment())
	if errors.is_empty():
		print("Content validation OK")
		quit(0)
	else:
		for e in errors:
			push_error(e)
		quit(1)

func _validate_equipment() -> PackedStringArray:
	var out: PackedStringArray = []
	for eq_id in EquipmentRegistry.get_shop_ids(false):
		if EquipmentRegistry.get_definition(eq_id) == null:
			out.append("Missing equipment def: %s" % eq_id)
	return out

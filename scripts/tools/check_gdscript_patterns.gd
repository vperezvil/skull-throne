extends SceneTree

# Run: godot --headless --path . --script res://scripts/tools/check_gdscript_patterns.gd

const FORBIDDEN := [
	{"pattern": "Key\\.[A-Z]", "hint": "Use KEY_W-style globals, not Key dot W (Godot 4.7)."},
	{"pattern": "\\btrait:\\s*String", "hint": "Rename parameter; trait is reserved in GDScript 4.7."},
	{"pattern": "var trait :=", "hint": "Rename variable; trait is reserved."},
]

const SCAN_ROOT := "res://scripts"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var errors: PackedStringArray = []
	errors.append_array(_scan_directory(SCAN_ROOT))
	if errors.is_empty():
		print("GDScript pattern check OK")
		quit(0)
	for e in errors:
		push_error(e)
	quit(1)

func _scan_directory(dir_path: String) -> PackedStringArray:
	var out: PackedStringArray = []
	for file_name in DirAccess.get_files_at(dir_path):
		if file_name.ends_with(".gd"):
			out.append_array(_check_file(dir_path.path_join(file_name)))
	for subdir in DirAccess.get_directories_at(dir_path):
		if subdir.begins_with("."):
			continue
		out.append_array(_scan_directory(dir_path.path_join(subdir)))
	return out

func _check_file(path: String) -> PackedStringArray:
	if path.get_file() == "check_gdscript_patterns.gd":
		return PackedStringArray()
	var out: PackedStringArray = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	var line_no := 0
	while !f.eof_reached():
		var line := f.get_line()
		line_no += 1
		for rule in FORBIDDEN:
			var regex := RegEx.new()
			regex.compile(rule["pattern"])
			if regex.search(line):
				out.append("%s:%d: %s" % [path, line_no, rule["hint"]])
	f.close()
	return out

extends RefCounted
class_name PauseSettingsUi

static func add_accessibility_section(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "Accessibility"
	title.add_theme_font_size_override("font_size", 22)
	parent.add_child(title)
	_add_scale_row(parent, "UI text size", Global.ui_text_scale, Global.set_ui_text_scale)
	var contrast := CheckButton.new()
	contrast.text = "High contrast HP bars"
	contrast.button_pressed = Global.high_contrast_bars
	contrast.toggled.connect(func(on: bool): Global.set_high_contrast_bars(on))
	parent.add_child(contrast)
	var shake := CheckButton.new()
	shake.text = "Combat hit flash"
	shake.button_pressed = Global.screen_shake_enabled
	shake.toggled.connect(func(on: bool): Global.set_screen_shake_enabled(on))
	parent.add_child(shake)

static func add_controls_section(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "Movement (primary key)"
	title.add_theme_font_size_override("font_size", 22)
	parent.add_child(title)
	var hint := Label.new()
	hint.text = "WASD defaults. Rebind sets one key per direction."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(hint)
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		var btn := Button.new()
		btn.text = "Rebind %s" % action
		btn.pressed.connect(_on_rebind_pressed.bind(action))
		parent.add_child(btn)

static func _on_rebind_pressed(action: String) -> void:
	# Cycle common keys for quick rebind without a capture dialog.
	var cycle := [Key.W, Key.A, Key.S, Key.D, Key.UP, Key.DOWN, Key.LEFT, Key.RIGHT]
	var events := InputMap.action_get_events(action)
	var current := Key.W
	if events.size() > 0 and events[0] is InputEventKey:
		current = (events[0] as InputEventKey).physical_keycode
	var idx := cycle.find(current)
	var next_key: Key = cycle[(idx + 1) % cycle.size()] if idx >= 0 else Key.W
	Global.save_movement_binding(action, next_key)

static func _add_scale_row(parent: VBoxContainer, label_text: String, initial: float, apply_callable: Callable) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 120
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.85
	slider.max_value = 1.35
	slider.step = 0.05
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = initial
	slider.value_changed.connect(apply_callable)
	row.add_child(slider)

static func add_debug_section(parent: VBoxContainer, message_label: Label) -> void:
	if !Global.DEBUG:
		return
	var btn := Button.new()
	btn.text = "Reset meta progress (debug)"
	btn.pressed.connect(func():
		MetaProgress.reset_meta_progress()
		if message_label:
			message_label.text = "Meta progress reset."
	)
	parent.add_child(btn)

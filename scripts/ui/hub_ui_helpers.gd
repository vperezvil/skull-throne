extends RefCounted
class_name HubUiHelpers

const COLOR_ACCENT := Color(1.0, 0.552941, 0.301961, 1.0)
const COLOR_PANEL := Color(0.08, 0.04, 0.05, 0.92)
const COLOR_PANEL_BORDER := Color(0.35, 0.12, 0.1, 1.0)
const COLOR_MUTED := Color(0.82, 0.78, 0.74, 1.0)

static func flat_panel(bg: Color = COLOR_PANEL, border: Color = COLOR_PANEL_BORDER) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = 2
	box.border_color = border
	box.corner_radius_top_left = 6
	box.corner_radius_top_right = 6
	box.corner_radius_bottom_right = 6
	box.corner_radius_bottom_left = 6
	box.content_margin_left = 16.0
	box.content_margin_top = 14.0
	box.content_margin_right = 16.0
	box.content_margin_bottom = 14.0
	return box

static func style_section_title(label: Label, size: int = 20) -> void:
	label.add_theme_font_size_override("font_size", Global.get_ui_font_size(size))
	label.modulate = COLOR_ACCENT

static func style_body_label(label: Label, size: int = 16) -> void:
	label.add_theme_font_size_override("font_size", Global.get_ui_font_size(size))
	label.modulate = COLOR_MUTED

static func style_primary_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(0, 52)
	button.add_theme_font_size_override("font_size", Global.get_ui_font_size(20))
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_ACCENT
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_right = 4
	normal.corner_radius_bottom_left = 4
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.15, 0.12, 0.12, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", _disabled_box(normal))

static func style_secondary_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_font_size_override("font_size", Global.get_ui_font_size(17))
	var normal := flat_panel(Color(0.12, 0.06, 0.07, 0.95), COLOR_ACCENT)
	normal.content_margin_top = 10.0
	normal.content_margin_bottom = 10.0
	var hover := normal.duplicate()
	hover.bg_color = Color(0.18, 0.08, 0.09, 0.98)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", _disabled_box(normal))

static func style_ghost_button(button: Button) -> void:
	button.flat = true
	button.add_theme_font_size_override("font_size", Global.get_ui_font_size(16))
	button.add_theme_color_override("font_color", COLOR_MUTED)
	button.add_theme_color_override("font_hover_color", COLOR_ACCENT)

static func wrap_scroll(content: Control, min_height: float = 320.0) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, min_height)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return scroll

static func make_card(title: String, body: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", flat_panel())
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	if title != "":
		var heading := Label.new()
		heading.text = title
		style_section_title(heading, 18)
		vbox.add_child(heading)
	vbox.add_child(body)
	return panel

static func _disabled_box(base: StyleBoxFlat) -> StyleBoxFlat:
	var box := base.duplicate()
	box.bg_color = Color(box.bg_color.r, box.bg_color.g, box.bg_color.b, 0.35)
	return box

extends Control
class_name HubSanctumMap

signal service_picked(tab_index: int)

const SERVICE_DEFS: Array[Dictionary] = [
	{
		"tab": 0,
		"label": "Shop",
		"hint": "Grum",
		"anchor": Vector2(0.12, 0.28),
		"icon": "res://assets/monsters/unique/grum.png",
	},
	{
		"tab": 1,
		"label": "Train",
		"hint": "Skills",
		"anchor": Vector2(0.88, 0.28),
		"icon": "res://assets/monsters/unique/enchantress.png",
	},
	{
		"tab": 2,
		"label": "Boons",
		"hint": "Permanent",
		"anchor": Vector2(0.12, 0.52),
		"icon": "",
	},
	{
		"tab": 3,
		"label": "Stash",
		"hint": "Equip",
		"anchor": Vector2(0.88, 0.52),
		"icon": "",
	},
]

var _hint_label: Label
var _descent_nodes: HBoxContainer
var _service_layer: Control
var _sanctum_title: Label
var _sanctum_hint: Label
var _descent_plan: Array[String] = []
var _has_party: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(480, 440)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_service_layer = Control.new()
	_service_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_service_layer)
	_hint_label = Label.new()
	_hint_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_hint_label.offset_top = 8.0
	_hint_label.offset_bottom = 36.0
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HubUiHelpers.style_body_label(_hint_label, 16)
	add_child(_hint_label)
	var sanctum_box := PanelContainer.new()
	sanctum_box.name = "SanctumFrame"
	sanctum_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sanctum_box.offset_left = 8.0
	sanctum_box.offset_top = 44.0
	sanctum_box.offset_right = -8.0
	sanctum_box.offset_bottom = 244.0
	sanctum_box.add_theme_stylebox_override("panel", HubUiHelpers.flat_panel(Color(0.12, 0.06, 0.07, 0.55), HubUiHelpers.COLOR_ACCENT))
	add_child(sanctum_box)
	var sanctum_v := VBoxContainer.new()
	sanctum_v.set_anchors_preset(Control.PRESET_FULL_RECT)
	sanctum_v.alignment = BoxContainer.ALIGNMENT_CENTER
	sanctum_box.add_child(sanctum_v)
	_sanctum_title = Label.new()
	_sanctum_title.text = "Blood Sanctum"
	_sanctum_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HubUiHelpers.style_section_title(_sanctum_title, 20)
	sanctum_v.add_child(_sanctum_title)
	_sanctum_hint = Label.new()
	_sanctum_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sanctum_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HubUiHelpers.style_body_label(_sanctum_hint, 14)
	sanctum_v.add_child(_sanctum_hint)
	var descent_title := Label.new()
	descent_title.text = "Descent route (this run)"
	descent_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	descent_title.offset_top = 248.0
	descent_title.offset_bottom = 276.0
	descent_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HubUiHelpers.style_section_title(descent_title, 17)
	add_child(descent_title)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 280.0
	scroll.offset_bottom = -8.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_descent_nodes = HBoxContainer.new()
	_descent_nodes.add_theme_constant_override("separation", 10)
	_descent_nodes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	scroll.add_child(_descent_nodes)
	_build_service_buttons()
	resized.connect(_layout_services)
	call_deferred("_layout_services")

func _build_service_buttons() -> void:
	for def in SERVICE_DEFS:
		var btn := Button.new()
		btn.name = "Service_%s" % def["label"]
		btn.text = def["label"]
		btn.tooltip_text = String(def["hint"])
		btn.add_theme_font_size_override("font_size", Global.get_ui_font_size(14))
		HubUiHelpers.style_secondary_button(btn)
		btn.custom_minimum_size = Vector2(108, 72)
		var tab_index: int = int(def["tab"])
		btn.pressed.connect(func() -> void: service_picked.emit(tab_index))
		var icon_path: String = String(def.get("icon", ""))
		if icon_path != "" and ResourceLoader.exists(icon_path):
			btn.icon = load(icon_path)
			btn.expand_icon = true
		btn.set_meta("anchor", def["anchor"])
		_service_layer.add_child(btn)

func _layout_services() -> void:
	if _service_layer == null:
		return
	for child in _service_layer.get_children():
		if child is Button and child.has_meta("anchor"):
			var anchor: Vector2 = child.get_meta("anchor")
			var btn_size: Vector2 = child.custom_minimum_size
			child.position = Vector2(
				clampf(anchor.x * _service_layer.size.x - btn_size.x * 0.5, 4.0, _service_layer.size.x - btn_size.x - 4.0),
				clampf(anchor.y * _service_layer.size.y - btn_size.y * 0.5, 48.0, _service_layer.size.y - btn_size.y - 4.0)
			)

func set_hub_state(has_party: bool, hint_text: String) -> void:
	_has_party = has_party
	_hint_label.text = hint_text
	if _sanctum_hint != null:
		if !has_party:
			_sanctum_hint.text = "Choose your party, then tap Shop, Train, Boons, or Stash."
		else:
			_sanctum_hint.text = "Visit a marker on the map, then Begin descent when ready."

func set_descent_plan(zone_ids: Array[String]) -> void:
	_descent_plan = zone_ids.duplicate()
	for child in _descent_nodes.get_children():
		child.queue_free()
	if zone_ids.is_empty():
		var empty := Label.new()
		empty.text = "Begin descent to roll your path."
		HubUiHelpers.style_body_label(empty, 14)
		_descent_nodes.add_child(empty)
		return
	for i in zone_ids.size():
		var zone_id: String = zone_ids[i]
		var zone: ZoneDefinition = ContentRegistry.get_zone_by_id(zone_id)
		var title: String = zone.display_name if zone != null else zone_id
		if zone != null and zone.is_final_zone:
			title = "Skull Throne"
		var chip := _make_route_node(title, zone != null and zone.is_final_zone, i + 1)
		_descent_nodes.add_child(chip)
		if i + 1 < zone_ids.size() and (i + 1) % GameConstants.FLOORS_BETWEEN_WAYSTATIONS == 0:
			_descent_nodes.add_child(_make_waystation_marker())

func _make_route_node(title: String, is_finale: bool, floor_num: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var bg := HubUiHelpers.flat_panel(
		Color(0.14, 0.07, 0.08, 0.95) if !is_finale else Color(0.22, 0.08, 0.06, 0.98),
		HubUiHelpers.COLOR_ACCENT if is_finale else HubUiHelpers.COLOR_PANEL_BORDER
	)
	panel.add_theme_stylebox_override("panel", bg)
	panel.custom_minimum_size = Vector2(96, 88)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	var num_lbl := Label.new()
	num_lbl.text = str(floor_num)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num_lbl.add_theme_font_size_override("font_size", Global.get_ui_font_size(12))
	num_lbl.modulate = HubUiHelpers.COLOR_MUTED
	v.add_child(num_lbl)
	var name_lbl := Label.new()
	name_lbl.text = title if title.length() <= 12 else title.substr(0, 11) + "..."
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.custom_minimum_size = Vector2(88, 0)
	name_lbl.add_theme_font_size_override("font_size", Global.get_ui_font_size(13))
	v.add_child(name_lbl)
	return panel

func _make_waystation_marker() -> Label:
	var lbl := Label.new()
	lbl.text = "⌂"
	lbl.tooltip_text = "Caravan waystation"
	lbl.add_theme_font_size_override("font_size", Global.get_ui_font_size(22))
	lbl.modulate = Color(0.85, 0.7, 0.45)
	return lbl

extends Control
class_name HubSanctumMap

signal service_picked(tab_index: int)

const SERVICE_DEFS: Array[Dictionary] = [
	{"tab": 0, "label": "Shop", "anchor": Vector2(0.18, 0.38), "icon": "res://assets/monsters/unique/grum.png"},
	{"tab": 1, "label": "Train", "anchor": Vector2(0.82, 0.38), "icon": "res://assets/monsters/unique/enchantress.png"},
	{"tab": 2, "label": "Boons", "anchor": Vector2(0.18, 0.72), "icon": ""},
	{"tab": 3, "label": "Stash", "anchor": Vector2(0.82, 0.72), "icon": ""},
]

var _service_layer: Control
var _service_buttons: Array[Button] = []
var _has_party: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(720, 480)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_PASS
	_service_layer = Control.new()
	_service_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_service_layer)
	_build_service_buttons()
	resized.connect(_layout_services)
	call_deferred("_layout_services")

func _build_service_buttons() -> void:
	for def in SERVICE_DEFS:
		var btn := Button.new()
		btn.name = "Service_%s" % def["label"]
		btn.text = def["label"]
		btn.tooltip_text = def["label"]
		btn.add_theme_font_size_override("font_size", Global.get_ui_font_size(15))
		HubUiHelpers.style_secondary_button(btn)
		btn.custom_minimum_size = Vector2(96, 40)
		var tab_index: int = int(def["tab"])
		btn.pressed.connect(func() -> void: service_picked.emit(tab_index))
		var icon_path: String = String(def.get("icon", ""))
		if icon_path != "" and ResourceLoader.exists(icon_path):
			btn.icon = load(icon_path)
			btn.expand_icon = true
		btn.set_meta("anchor", def["anchor"])
		_service_layer.add_child(btn)
		_service_buttons.append(btn)

func _layout_services() -> void:
	if _service_layer == null:
		return
	for child in _service_layer.get_children():
		if child is Button and child.has_meta("anchor"):
			var anchor: Vector2 = child.get_meta("anchor")
			var btn_size: Vector2 = child.custom_minimum_size
			child.position = Vector2(
				anchor.x * _service_layer.size.x - btn_size.x * 0.5,
				anchor.y * _service_layer.size.y - btn_size.y * 0.5
			)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.07, 0.04, 0.05, 0.92))
	draw_rect(rect.grow(-6), Color(0.1, 0.05, 0.06, 0.55), false, 2.0)
	var hub := rect.get_center()
	draw_circle(hub, 36.0, Color(0.16, 0.08, 0.09, 0.95))
	draw_arc(hub, 36.0, 0.0, TAU, 32, Color(1.0, 0.55, 0.3, 0.85), 2.0, true)
	for btn in _service_buttons:
		if !is_instance_valid(btn):
			continue
		var target := btn.position + btn.size * 0.5
		draw_line(hub, target, Color(0.45, 0.22, 0.18, 0.65), 3.0, true)
		draw_circle(target, 8.0, Color(1.0, 0.55, 0.3, 0.9))

func set_hub_state(has_party: bool, _hint_text: String) -> void:
	_has_party = has_party
	for btn in _service_buttons:
		btn.disabled = !has_party
	queue_redraw()

func set_descent_plan(_zone_ids: Array[String]) -> void:
	queue_redraw()

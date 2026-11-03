extends RefCounted
class_name BattleHudLayout

const BAR_HALF_W := 80.0
const BAR_H := 18.0
const BAR_XP_H := 4.0
const BAR_STACK_GAP := 1.0
const BAR_XP_GAP := 0.0
const GAP_ABOVE_CROWN := 4.0
const CROWN_FRAC := 0.36
const BAR_FONT_SIZE := 13

static var _hp_theme: Theme
static var _mp_theme: Theme
static var _xp_theme: Theme

static func find_sprite(host: Node) -> Node2D:
	if host.has_node("EnemySprite"):
		return host.get_node("EnemySprite") as Node2D
	if host.has_node("BossSprite"):
		return host.get_node("BossSprite") as Node2D
	if host.has_node("Body"):
		return host.get_node("Body") as Node2D
	if host.has_node("BodySkeleton"):
		return host.get_node("BodySkeleton") as Node2D
	for child in host.get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			return child as Node2D
	return null

static func frame_height(sprite: Node2D) -> float:
	if sprite is Sprite2D:
		var s: Sprite2D = sprite as Sprite2D
		if s.texture != null:
			var frame_h: float = s.texture.get_height() / maxf(float(maxi(s.vframes, 1)), 1.0)
			return frame_h * absf(s.scale.y)
		return 64.0 * absf(s.scale.y)
	if sprite is AnimatedSprite2D:
		var a: AnimatedSprite2D = sprite as AnimatedSprite2D
		if a.sprite_frames != null and a.sprite_frames.has_animation(a.animation):
			var tex: Texture2D = a.sprite_frames.get_frame_texture(a.animation, 0)
			if tex != null:
				return tex.get_height() * absf(a.scale.y)
	return 64.0

static func _battle_stack_height(show_mp: bool, show_xp: bool) -> float:
	var stack_h := BAR_H
	if show_mp:
		stack_h += BAR_STACK_GAP + BAR_H
	if show_xp:
		stack_h += BAR_XP_GAP + BAR_XP_H
	return stack_h

static func _crown_top_y(sprite: Node2D, stack_height: float) -> float:
	var h := frame_height(sprite)
	var crown_y: float = sprite.position.y - h * CROWN_FRAC
	return crown_y - GAP_ABOVE_CROWN - stack_height

static func _ensure_on_host(host: Node2D, bar: ProgressBar) -> void:
	if bar.get_parent() != host:
		if bar.get_parent() != null:
			bar.get_parent().remove_child(bar)
		host.add_child(bar)

static func _place_bar(host: Node2D, bar: ProgressBar, cx: float, top_y: float, bar_h: float = BAR_H) -> void:
	_ensure_on_host(host, bar)
	var bar_w := BAR_HALF_W * 2.0
	bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bar.set_offsets_preset(Control.PRESET_TOP_LEFT)
	bar.offset_left = 0
	bar.offset_top = 0
	bar.offset_right = int(bar_w)
	bar.offset_bottom = int(bar_h)
	bar.custom_minimum_size = Vector2(bar_w, bar_h)
	bar.size = bar.custom_minimum_size
	bar.pivot_offset = Vector2.ZERO
	bar.position = Vector2(cx - bar_w * 0.5, top_y)
	bar.z_index = 100

static func _hp_theme_ref() -> Theme:
	if _hp_theme != null:
		return _hp_theme
	_hp_theme = Theme.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.06, 0.06, 0.88)
	bg.border_color = Color(0.35, 0.12, 0.1, 1.0)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.82, 0.22, 0.18, 1.0)
	fill.set_corner_radius_all(2)
	_hp_theme.set_stylebox("background", "ProgressBar", bg)
	_hp_theme.set_stylebox("fill", "ProgressBar", fill)
	return _hp_theme

static func _mp_theme_ref() -> Theme:
	if _mp_theme != null:
		return _mp_theme
	_mp_theme = Theme.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.07, 0.12, 0.88)
	bg.border_color = Color(0.2, 0.35, 0.65, 1.0)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.28, 0.48, 0.95, 1.0)
	fill.set_corner_radius_all(2)
	_mp_theme.set_stylebox("background", "ProgressBar", bg)
	_mp_theme.set_stylebox("fill", "ProgressBar", fill)
	return _mp_theme

static func _xp_theme_ref() -> Theme:
	if _xp_theme != null:
		return _xp_theme
	_xp_theme = Theme.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.05, 0.04, 0.45)
	bg.set_border_width_all(0)
	bg.set_corner_radius_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.45, 0.72, 0.38, 0.72)
	fill.set_corner_radius_all(1)
	_xp_theme.set_stylebox("background", "ProgressBar", bg)
	_xp_theme.set_stylebox("fill", "ProgressBar", fill)
	return _xp_theme

static func style_value_label(label: Label) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", Global.get_ui_font_size(BAR_FONT_SIZE))
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.98))
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))

static func ensure_bar_label(bar: ProgressBar) -> Label:
	var existing := bar.get_node_or_null("BarValue") as Label
	if existing != null:
		style_value_label(existing)
		return existing
	var label := Label.new()
	label.name = "BarValue"
	style_value_label(label)
	bar.add_child(label)
	return label

static func mount_bar(host: Node2D, bar: ProgressBar) -> Dictionary:
	bar.theme = _hp_theme_ref()
	bar.show_percentage = false
	var sprite := find_sprite(host)
	if sprite == null:
		_layout_fallback(host, bar)
		return {}
	_place_bar(host, bar, sprite.position.x, _crown_top_y(sprite, BAR_H))
	return {}

static func mount_party_bars(
	host: Node2D,
	hp_bar: ProgressBar,
	mp_bar: ProgressBar,
	show_mp: bool,
	xp_bar: ProgressBar = null,
	show_xp: bool = false,
) -> void:
	hp_bar.theme = _hp_theme_ref()
	hp_bar.show_percentage = false
	var sprite := find_sprite(host)
	if sprite == null:
		_layout_fallback(host, hp_bar)
		return
	var cx := sprite.position.x
	var show_mp_bar := show_mp and mp_bar != null
	var stack_h := _battle_stack_height(show_mp_bar, show_xp and xp_bar != null)
	var hp_top := _crown_top_y(sprite, stack_h)
	_place_bar(host, hp_bar, cx, hp_top)
	var next_y := hp_top + BAR_H
	if show_mp_bar:
		mp_bar.theme = _mp_theme_ref()
		mp_bar.show_percentage = false
		mp_bar.modulate = Color.WHITE
		next_y += BAR_STACK_GAP
		_place_bar(host, mp_bar, cx, next_y)
		mp_bar.visible = true
		next_y += BAR_H
	elif mp_bar != null:
		mp_bar.visible = false
	if show_xp and xp_bar != null:
		xp_bar.theme = _xp_theme_ref()
		xp_bar.show_percentage = false
		xp_bar.modulate = Color(1.0, 1.0, 1.0, 0.88)
		next_y += BAR_XP_GAP
		_place_bar(host, xp_bar, cx, next_y, BAR_XP_H)
		xp_bar.visible = true
	elif xp_bar != null:
		xp_bar.visible = false

static func unmount_bar(bar: ProgressBar, saved: Dictionary) -> void:
	if saved.is_empty() or bar == null:
		return
	var home: Node = saved.get("parent")
	if home == null or !is_instance_valid(home):
		return
	if bar.get_parent() != null:
		bar.get_parent().remove_child(bar)
	home.add_child(bar)
	var idx: int = clampi(int(saved.get("index", -1)), 0, home.get_child_count() - 1)
	home.move_child(bar, idx)

static func _layout_fallback(host: Node2D, bar: ProgressBar) -> void:
	bar.theme = _hp_theme_ref()
	_place_bar(host, bar, 0.0, -74.0)

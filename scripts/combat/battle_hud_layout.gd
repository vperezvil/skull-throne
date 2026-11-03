extends RefCounted
class_name BattleHudLayout

const BAR_HALF_W := 76.0
const BAR_H := 17.0
const BAR_STACK_GAP := 3.0
const GAP_ABOVE_CROWN := 3.0
const CROWN_FRAC := 0.36
const BAR_FONT_SIZE := 13

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

static func _crown_top_y(sprite: Node2D, stack_rows: int) -> float:
	var h := frame_height(sprite)
	var crown_y: float = sprite.position.y - h * CROWN_FRAC
	var stack_h: float = float(stack_rows) * BAR_H + float(maxi(stack_rows - 1, 0)) * BAR_STACK_GAP
	return crown_y - GAP_ABOVE_CROWN - stack_h

static func _ensure_on_host(host: Node2D, bar: ProgressBar) -> void:
	if bar.get_parent() != host:
		if bar.get_parent() != null:
			bar.get_parent().remove_child(bar)
		host.add_child(bar)

static func _place_bar(host: Node2D, bar: ProgressBar, cx: float, top_y: float) -> void:
	_ensure_on_host(host, bar)
	bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bar.anchor_left = 0.0
	bar.anchor_top = 0.0
	bar.anchor_right = 0.0
	bar.anchor_bottom = 0.0
	bar.offset_left = 0
	bar.offset_top = 0
	bar.offset_right = int(BAR_HALF_W * 2.0)
	bar.offset_bottom = int(BAR_H)
	bar.custom_minimum_size = Vector2(BAR_HALF_W * 2.0, BAR_H)
	bar.size = bar.custom_minimum_size
	bar.position = Vector2(cx - BAR_HALF_W, top_y)

static func style_value_label(label: Label) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", Global.get_ui_font_size(BAR_FONT_SIZE))
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))

static func ensure_bar_label(bar: ProgressBar) -> Label:
	var existing := bar.get_node_or_null("BarValue") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "BarValue"
	style_value_label(label)
	bar.add_child(label)
	return label

static func mount_bar(host: Node2D, bar: ProgressBar) -> Dictionary:
	var sprite := find_sprite(host)
	if sprite == null:
		_layout_fallback(host, bar)
		return {}
	_place_bar(host, bar, sprite.position.x, _crown_top_y(sprite, 1))
	return {}

static func mount_party_bars(host: Node2D, hp_bar: ProgressBar, mp_bar: ProgressBar, show_mp: bool) -> void:
	var sprite := find_sprite(host)
	if sprite == null:
		_layout_fallback(host, hp_bar)
		return
	var cx := sprite.position.x
	var rows := 2 if show_mp and mp_bar != null else 1
	var hp_top := _crown_top_y(sprite, rows)
	_place_bar(host, hp_bar, cx, hp_top)
	if show_mp and mp_bar != null:
		var mp_top := hp_top + BAR_H + BAR_STACK_GAP
		_place_bar(host, mp_bar, cx, mp_top)
		mp_bar.visible = true
	elif mp_bar != null:
		mp_bar.visible = false

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
	_ensure_on_host(host, bar)
	_place_bar(host, bar, 0.0, -72.0)

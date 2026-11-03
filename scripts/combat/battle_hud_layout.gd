extends RefCounted
class_name BattleHudLayout

const BAR_HALF_W := 54.0
const BAR_H := 13.0
const GAP_ABOVE_CROWN := 2.0
## Most RPG frames are feet-heavy; the visible head sits above center, not at the texture edge.
const CROWN_FRAC := 0.38

static func find_sprite(host: Node) -> Node2D:
	if host.has_node("EnemySprite"):
		return host.get_node("EnemySprite") as Node2D
	if host.has_node("Body"):
		return host.get_node("Body") as Node2D
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

static func mount_bar(host: Node2D, bar: ProgressBar) -> Dictionary:
	var sprite := find_sprite(host)
	if sprite == null:
		_layout_on_host(host, bar)
		return {}
	if bar.get_parent() == sprite:
		_apply_bar_on_sprite(sprite, bar)
		return {}
	var home_parent: Node = bar.get_parent()
	var home_index: int = bar.get_index()
	home_parent.remove_child(bar)
	sprite.add_child(bar)
	_apply_bar_on_sprite(sprite, bar)
	return {"parent": home_parent, "index": home_index}

static func _apply_bar_on_sprite(sprite: Node2D, bar: ProgressBar) -> void:
	bar.position = Vector2.ZERO
	var h := frame_height(sprite)
	var crown_y: float = -h * CROWN_FRAC
	bar.offset_left = -BAR_HALF_W
	bar.offset_right = BAR_HALF_W
	bar.offset_bottom = crown_y - GAP_ABOVE_CROWN
	bar.offset_top = crown_y - GAP_ABOVE_CROWN - BAR_H

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

static func _layout_on_host(host: Node2D, bar: ProgressBar) -> void:
	bar.position = Vector2.ZERO
	bar.offset_left = -BAR_HALF_W
	bar.offset_right = BAR_HALF_W
	bar.offset_top = -72.0
	bar.offset_bottom = -72.0 + BAR_H

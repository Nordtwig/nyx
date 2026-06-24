@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

# Shared base for the two particle sink nodes (Start / Process).
# Slate styling matching OutputNode; no per-node preview (a "preview of the
# Velocity sink" is meaningless, same rationale as the screen-space nodes).


func _add_preview_controls() -> void:
	pass


func _apply_style() -> void:
	var color := Color("#3C4655")
	var border := Color(1, 1, 1, 0.1)

	var body := StyleBoxFlat.new()
	body.bg_color = color
	body.corner_radius_top_left = 0
	body.corner_radius_top_right = 0
	body.corner_radius_bottom_left = 12
	body.corner_radius_bottom_right = 6
	body.expand_margin_top = 2
	body.border_width_left = 1
	body.border_width_right = 1
	body.border_width_bottom = 1
	body.border_color = border
	body.content_margin_left = 2
	body.content_margin_right = 2
	body.content_margin_bottom = 6
	add_theme_stylebox_override("panel", body)
	add_theme_constant_override("separation", 4)

	var titlebar := StyleBoxFlat.new()
	titlebar.bg_color = color
	titlebar.corner_radius_top_left = 6
	titlebar.corner_radius_top_right = 12
	titlebar.corner_radius_bottom_left = 0
	titlebar.corner_radius_bottom_right = 0
	titlebar.border_width_left = 1
	titlebar.border_width_right = 1
	titlebar.border_width_top = 1
	titlebar.border_color = border
	titlebar.content_margin_left = 7
	titlebar.content_margin_top = 3
	titlebar.content_margin_bottom = -1
	add_theme_stylebox_override("titlebar", titlebar)

	_apply_selection_style(body, titlebar)
	add_theme_icon_override("port", _create_port_texture(10, 1))
	call_deferred("_center_title")

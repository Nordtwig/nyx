@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

# Sink node for the spatial vertex stage. Separate from Fragment Output so
# users get a clear separation of concerns (matches ShaderGraph's two-sink model).
# Only visible when shader_type == 0 (Spatial).

func _add_preview_controls() -> void:
	pass


func _ready() -> void:
	super._ready()
	title = "Vertex Output"
	var vec3_color := _type_color(0)

	set_slot(0, true, 0, vec3_color, false, -1, vec3_color)
	set_slot(1, true, 0, vec3_color, false, -1, vec3_color)
	set_slot(2, true, 0, vec3_color, false, -1, vec3_color)

	for label_text in ["Offset", "Normal", "Tangent"]:
		var label := Label.new()
		label.text = label_text
		add_child(label)


func get_shader_snippet(inputs: Array = []) -> String:
	return ""


func get_default_inputs() -> Array:
	return []


func _on_hover_exit() -> void:
	if selected:
		return
	_body_style.border_color = Color("#1A1A26")
	_titlebar_style.border_color = Color("#1A1A26")


func _on_deselected() -> void:
	var hovered := get_global_rect().has_point(get_global_mouse_position())
	var c := Color("#31614F") if hovered else Color("#1A1A26")
	_body_style.border_color = c
	_titlebar_style.border_color = c
	queue_redraw()


func _apply_style() -> void:
	var color := Color(0.14, 0.14, 0.18, 0.95)
	var border := Color("#1A1A26")

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
	if not mouse_entered.is_connected(_on_hover_enter):
		mouse_entered.connect(_on_hover_enter)
		mouse_exited.connect(_on_hover_exit)
	call_deferred("_center_title")

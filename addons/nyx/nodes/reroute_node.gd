@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = ""

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(24, 0)
	add_child(spacer)

	var vec3_color := _type_color(0)
	set_slot(0, true, 0, vec3_color, true, 0, vec3_color)


func _add_preview_controls() -> void:
	pass


func _center_title() -> void:
	var hbox := get_titlebar_hbox()
	for child in hbox.get_children():
		if child is Label:
			child.text = ""
			child.custom_minimum_size = Vector2.ZERO
			child.add_theme_font_size_override("font_size", 1)
			break


func _apply_style() -> void:
	var color := Color("#3C4655")
	var radius := 10

	var body := StyleBoxFlat.new()
	body.bg_color = color
	body.corner_radius_top_left = radius
	body.corner_radius_top_right = radius
	body.corner_radius_bottom_left = radius
	body.corner_radius_bottom_right = radius
	body.expand_margin_top = 8
	body.content_margin_left = 4
	body.content_margin_right = 4
	body.content_margin_top = 0
	body.content_margin_bottom = 2
	add_theme_stylebox_override("panel", body)

	var titlebar := StyleBoxFlat.new()
	titlebar.bg_color = color
	titlebar.corner_radius_top_left = radius
	titlebar.corner_radius_top_right = radius
	titlebar.corner_radius_bottom_left = 0
	titlebar.corner_radius_bottom_right = 0
	titlebar.content_margin_top = 0
	titlebar.content_margin_bottom = 0
	titlebar.content_margin_left = 0
	titlebar.content_margin_right = 0
	add_theme_stylebox_override("titlebar", titlebar)

	_apply_selection_style(body, titlebar)
	add_theme_icon_override("port", _create_port_texture(10, 1))


func is_polymorphic() -> bool:
	return true


func get_output_type(from_port: int, input_types: Array) -> int:
	return input_types[0] if not input_types.is_empty() else 0


func get_default_input_types() -> Array:
	return [0]


func get_shader_snippet(inputs: Array = []) -> String:
	return inputs[0] if not inputs.is_empty() else "vec3(0.0)"


func get_default_inputs() -> Array:
	return ["vec3(0.0)"]

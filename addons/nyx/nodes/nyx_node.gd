@tool
extends GraphNode

signal value_changed
signal edit_started


func _ready() -> void:
	_apply_style()


func _apply_style() -> void:
	var color := Color("#269b5b")

	var body := StyleBoxFlat.new()
	body.bg_color = color
	body.corner_radius_top_left = 0
	body.corner_radius_top_right = 0
	body.corner_radius_bottom_left = 12
	body.corner_radius_bottom_right = 6
	body.expand_margin_top = 2
	add_theme_stylebox_override("panel", body)

	var titlebar := StyleBoxFlat.new()
	titlebar.bg_color = color
	titlebar.corner_radius_top_left = 6
	titlebar.corner_radius_top_right = 12
	titlebar.corner_radius_bottom_left = 0
	titlebar.corner_radius_bottom_right = 0
	titlebar.content_margin_bottom = -1
	add_theme_stylebox_override("titlebar", titlebar)

	_apply_selection_style(body, titlebar)
	add_theme_icon_override("port", _create_port_texture(10, 1))
	call_deferred("_center_title")


func _apply_selection_style(body: StyleBoxFlat, titlebar: StyleBoxFlat) -> void:
	var sel := Color(1, 1, 1, 0.4)

	var body_sel := body.duplicate() as StyleBoxFlat
	body_sel.border_width_left = 2
	body_sel.border_width_right = 2
	body_sel.border_width_bottom = 2
	body_sel.border_color = sel
	body_sel.expand_margin_left = 5
	body_sel.expand_margin_right = 5
	body_sel.expand_margin_bottom = 5
	add_theme_stylebox_override("panel_selected", body_sel)

	var title_sel := titlebar.duplicate() as StyleBoxFlat
	title_sel.border_width_top = 2
	title_sel.border_width_left = 2
	title_sel.border_width_right = 2
	title_sel.border_color = sel
	title_sel.expand_margin_top = 5
	title_sel.expand_margin_left = 5
	title_sel.expand_margin_right = 5
	add_theme_stylebox_override("titlebar_selected", title_sel)


func _center_title() -> void:
	var hbox := get_titlebar_hbox()
	for child in hbox.get_children():
		if child is Label:
			child.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			child.add_theme_color_override("font_color", Color.WHITE)
			child.add_theme_constant_override("outline_size", 0)
			child.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
			child.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
			child.add_theme_constant_override("shadow_offset_x", 0)
			child.add_theme_constant_override("shadow_offset_y", 0)
			return


func _create_port_texture(size: int, outline: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var outer_radius := size / 2.0
	var inner_radius := outer_radius - outline
	var aa := 1.2

	for x in range(size):
		for y in range(size):
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var outer_alpha := clamp((outer_radius - dist) / aa, 0.0, 1.0)
			var inner_blend := clamp((dist - inner_radius) / aa, 0.0, 1.0)
			if outer_alpha <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var fill := Color.WHITE
				var ring := Color(0.1, 0.1, 0.1, 1.0)
				var pixel := fill.lerp(ring, inner_blend)
				pixel.a = outer_alpha
				img.set_pixel(x, y, pixel)

	return ImageTexture.create_from_image(img)


func get_shader_snippet(inputs: Array = []) -> String:
	return ""


func get_output_snippet(port: int, inputs: Array = []) -> String:
	return get_shader_snippet(inputs)


func get_shader_functions() -> Dictionary:
	return {}


func get_default_inputs() -> Array:
	return []


func get_state() -> Dictionary:
	return {}


func set_state(_state: Dictionary) -> void:
	pass

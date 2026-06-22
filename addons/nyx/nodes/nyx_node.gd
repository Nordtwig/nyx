@tool
extends GraphNode

signal value_changed
signal edit_started
signal preview_toggled

var _preview_open: bool = false
var _preview_slot: TextureRect
var _preview_wrapper: Panel
var _preview_spacer: Control
var _body_style: StyleBoxFlat


func _ready() -> void:
	_apply_style()
	call_deferred("_add_preview_controls")
	resized.connect(_update_body_for_preview)


func _add_preview_controls() -> void:
	var chevron := Button.new()
	chevron.text = "▾"
	chevron.flat = true
	chevron.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chevron.pressed.connect(_on_preview_chevron_pressed.bind(chevron))
	add_child(chevron)

	_preview_spacer = Control.new()
	_preview_spacer.custom_minimum_size = Vector2(0, 8)
	_preview_spacer.visible = false
	add_child(_preview_spacer)

	_preview_wrapper = Panel.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0)
	_preview_wrapper.add_theme_stylebox_override("panel", bg)
	_preview_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_wrapper.custom_minimum_size = Vector2(0, 100)
	_preview_wrapper.visible = false
	add_child(_preview_wrapper)

	_preview_slot = TextureRect.new()
	_preview_slot.stretch_mode = TextureRect.STRETCH_SCALE
	_preview_slot.set_anchor(SIDE_LEFT, 0.5)
	_preview_slot.set_anchor(SIDE_RIGHT, 0.5)
	_preview_slot.set_offset(SIDE_LEFT, -50)
	_preview_slot.set_offset(SIDE_RIGHT, 50)
	_preview_slot.set_offset(SIDE_TOP, 0)
	_preview_slot.set_offset(SIDE_BOTTOM, 100)

	var corner_shader := Shader.new()
	corner_shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec2 size = 1.0 / TEXTURE_PIXEL_SIZE;\n\tvec2 pos = UV * size;\n\tfloat r = 5.0;\n\tvec2 d = max(abs(pos - size * 0.5) - (size * 0.5 - r), vec2(0.0));\n\tCOLOR = texture(TEXTURE, UV);\n\tCOLOR.a *= clamp(-(length(d) - r), 0.0, 1.0);\n}"
	var corner_mat := ShaderMaterial.new()
	corner_mat.shader = corner_shader
	_preview_slot.material = corner_mat

	_preview_wrapper.add_child(_preview_slot)


func _on_preview_chevron_pressed(chevron: Button) -> void:
	_preview_open = not _preview_open
	chevron.text = "▴" if _preview_open else "▾"
	_preview_spacer.visible = _preview_open
	_preview_wrapper.visible = _preview_open
	if _preview_open:
		_update_body_for_preview()
	else:
		call_deferred("reset_size")
	emit_signal("preview_toggled")


func _update_body_for_preview() -> void:
	var body := get_theme_stylebox("panel") as StyleBoxFlat
	if body:
		body.expand_margin_bottom = -108 if _preview_open else 0
		body.corner_radius_bottom_left = 12
		body.corner_radius_bottom_right = 6

	var body_sel := get_theme_stylebox("panel_selected") as StyleBoxFlat
	if body_sel:
		body_sel.expand_margin_bottom = -108 if _preview_open else 5


func get_preview_slot() -> TextureRect:
	return _preview_slot


func _apply_style() -> void:
	var color := Color("#269b5b")

	_body_style = StyleBoxFlat.new()
	_body_style.bg_color = color
	_body_style.corner_radius_top_left = 0
	_body_style.corner_radius_top_right = 0
	_body_style.corner_radius_bottom_left = 12
	_body_style.corner_radius_bottom_right = 6
	_body_style.expand_margin_top = 2
	add_theme_stylebox_override("panel", _body_style)

	var titlebar := StyleBoxFlat.new()
	titlebar.bg_color = color
	titlebar.corner_radius_top_left = 6
	titlebar.corner_radius_top_right = 12
	titlebar.corner_radius_bottom_left = 0
	titlebar.corner_radius_bottom_right = 0
	titlebar.content_margin_bottom = -1
	add_theme_stylebox_override("titlebar", titlebar)

	_apply_selection_style(_body_style, titlebar)
	add_theme_icon_override("port", _create_port_texture(10, 1))
	call_deferred("_center_title")


func _apply_selection_style(body: StyleBoxFlat, titlebar: StyleBoxFlat) -> void:
	var sel := Color(1, 1, 1, 0.95)

	var body_sel := body.duplicate() as StyleBoxFlat
	body_sel.border_width_left = 1
	body_sel.border_width_right = 1
	body_sel.border_width_bottom = 1
	body_sel.border_color = sel
	add_theme_stylebox_override("panel_selected", body_sel)

	var title_sel := titlebar.duplicate() as StyleBoxFlat
	title_sel.border_width_top = 1
	title_sel.border_width_left = 1
	title_sel.border_width_right = 1
	title_sel.border_color = sel
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


func get_default_input_types() -> Array:
	return []


func is_polymorphic() -> bool:
	return false


func get_output_type(from_port: int, input_types: Array) -> int:
	return get_output_port_type(from_port)


func get_state() -> Dictionary:
	return {}


func set_state(_state: Dictionary) -> void:
	pass

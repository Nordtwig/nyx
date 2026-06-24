@tool
extends GraphNode

signal value_changed
signal edit_started
signal preview_toggled

var _node_color: Color = Color("#2E8266")
var _preview_open: bool = false
var _preview_slot: TextureRect
var _preview_wrapper: Panel
var _preview_spacer: Control
var _preview_chevron: Button
var _body_style: StyleBoxFlat


func _ready() -> void:
	_apply_style()
	call_deferred("_add_preview_controls")
	call_deferred("_apply_input_styles")
	resized.connect(_update_body_for_preview)


func _add_preview_controls() -> void:
	var chevron := Button.new()
	chevron.text = "▾"
	chevron.flat = true
	chevron.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chevron.pressed.connect(_on_preview_chevron_pressed.bind(chevron))
	add_child(chevron)
	_preview_chevron = chevron

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


# Hide/show the per-node preview chevron. Particle mode disables previews
# (per-particle values have no per-pixel meaning); force any open one closed.
func set_preview_chevron_visible(v: bool) -> void:
	if _preview_chevron == null:
		return
	_preview_chevron.visible = v
	if not v and _preview_open:
		# Reset the open-state visuals; the viewport/material meta teardown is
		# handled by nyx_main when the shader mode changes.
		_preview_open = false
		_preview_chevron.text = "▾"
		if _preview_spacer:
			_preview_spacer.visible = false
		if _preview_wrapper:
			_preview_wrapper.visible = false
		call_deferred("reset_size")


func _apply_style() -> void:
	var color := _node_color

	_body_style = StyleBoxFlat.new()
	_body_style.bg_color = color
	_body_style.corner_radius_top_left = 0
	_body_style.corner_radius_top_right = 0
	_body_style.corner_radius_bottom_left = 12
	_body_style.corner_radius_bottom_right = 6
	_body_style.expand_margin_top = 2
	_body_style.content_margin_left = 2
	_body_style.content_margin_right = 2
	_body_style.content_margin_bottom = 6
	add_theme_stylebox_override("panel", _body_style)
	add_theme_constant_override("separation", 4)

	var titlebar := StyleBoxFlat.new()
	titlebar.bg_color = color
	titlebar.corner_radius_top_left = 6
	titlebar.corner_radius_top_right = 12
	titlebar.corner_radius_bottom_left = 0
	titlebar.corner_radius_bottom_right = 0
	titlebar.content_margin_bottom = -1
	titlebar.content_margin_left = 6
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
			child.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
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


func _apply_input_styles() -> void:
	_style_inputs_recursive(self)


func _style_inputs_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Popup:
			continue
		if child is SpinBox:
			_style_spinbox(child)
			continue
		if child is LineEdit:
			_style_lineedit(child)
		elif child is TextEdit:
			_style_textedit(child)
		_style_inputs_recursive(child)


func _make_input_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#3C4655")
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func _style_spinbox(sb: SpinBox) -> void:
	var style := _make_input_style()
	var le := sb.get_line_edit()
	le.add_theme_stylebox_override("normal", style)
	le.add_theme_stylebox_override("focus", style)


func _style_lineedit(le: LineEdit) -> void:
	var style := _make_input_style()
	le.add_theme_stylebox_override("normal", style)
	le.add_theme_stylebox_override("focus", style)


func _style_textedit(te: TextEdit) -> void:
	var style := _make_input_style()
	te.add_theme_stylebox_override("normal", style)
	te.add_theme_stylebox_override("focus", style)


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
	if is_polymorphic():
		return _dominant_type(input_types)
	return get_output_port_type(from_port)


# Resolve the widest type among inputs. Rank: float < vec2 < vec3 < vec4.
# Type IDs: 0 = vec3, 1 = float, 2 = vec2, 3 = vec4. Float inputs promote up to
# whatever vec type is present; an all-float set stays float.
func _dominant_type(input_types: Array) -> int:
	var rank := {1: 0, 2: 1, 0: 2, 3: 3}
	var best := 1
	var best_rank := 0
	for t in input_types:
		var r: int = rank.get(t, 0)
		if r > best_rank:
			best_rank = r
			best = t
	return best


func get_state() -> Dictionary:
	return {}


func set_state(_state: Dictionary) -> void:
	pass


func get_param_export_line() -> String:
	return ""


func apply_shader_params(_material: ShaderMaterial) -> void:
	pass

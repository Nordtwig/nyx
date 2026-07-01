@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _gradient: Gradient
var _gradient_texture: GradientTexture1D
var _gradient_rect: TextureRect


func _ready() -> void:
	super._ready()
	title = "Gradient"

	var float_color := _type_color(1)

	_gradient = Gradient.new()
	_gradient_texture = GradientTexture1D.new()
	_gradient_texture.gradient = _gradient
	_gradient_texture.width = 256
	_gradient.changed.connect(_on_gradient_changed)

	var row0 := HBoxContainer.new()
	var t_lbl := Label.new()
	t_lbl.text = "T"
	t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row0.add_child(t_lbl)
	var col_lbl := Label.new()
	col_lbl.text = "Color"
	row0.add_child(col_lbl)
	add_child(row0)

	_gradient_rect = TextureRect.new()
	_gradient_rect.texture = _gradient_texture
	_gradient_rect.custom_minimum_size = Vector2(0, _s(24))
	_gradient_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gradient_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_gradient_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_gradient_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_gradient_rect.gui_input.connect(_on_gradient_rect_input)
	add_child(_gradient_rect)

	set_slot(0, true, 1, float_color, true, 0, _type_color(0))


func _on_gradient_rect_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		EditorInterface.inspect_object(_gradient)


func _on_gradient_changed() -> void:
	emit_signal("value_changed")


func get_uniform_name() -> String:
	return "grad_" + str(name).to_lower()


func get_uniform_declaration() -> String:
	return "uniform sampler2D %s : source_color, hint_default_white;" % get_uniform_name()


func get_texture() -> Texture2D:
	return _gradient_texture


func get_shader_snippet(inputs: Array = []) -> String:
	return "texture(%s, vec2(clamp(%s, 0.0, 1.0), 0.5)).rgb" % [get_uniform_name(), inputs[0]]


func get_default_inputs() -> Array:
	return ["0.5"]


func export_as_sub_resource(start_id: int) -> Dictionary:
	var grad_id := "Gradient_%d" % start_id
	var tex_id := "GradientTexture1D_%d" % (start_id + 1)
	var lines := PackedStringArray()
	lines.append('[sub_resource type="Gradient" id="%s"]' % grad_id)
	lines.append("colors = %s" % var_to_str(_gradient.colors))
	lines.append("offsets = %s" % var_to_str(PackedFloat32Array(_gradient.offsets)))
	lines.append("")
	lines.append('[sub_resource type="GradientTexture1D" id="%s"]' % tex_id)
	lines.append('gradient = SubResource("%s")' % grad_id)
	lines.append("width = 256")
	lines.append("")
	return {
		"lines": lines,
		"param_line": 'shader_parameter/%s = SubResource("%s")' % [get_uniform_name(), tex_id],
		"count": 2
	}


func get_state() -> Dictionary:
	var colors := []
	for c in _gradient.colors:
		colors.append(c.to_html())
	return {"colors": colors, "offsets": Array(_gradient.offsets)}


func set_state(state: Dictionary) -> void:
	var colors_html: Array = state.get("colors", [])
	var offsets: Array = state.get("offsets", [])
	if colors_html.is_empty():
		return
	var packed_colors := PackedColorArray()
	for ch in colors_html:
		packed_colors.append(Color.html(ch))
	_gradient.colors = packed_colors
	_gradient.offsets = PackedFloat32Array(offsets)

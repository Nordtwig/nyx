@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _custom_name: String = "Preview"
var _color: Color = Color("#3C4655")

var _name_label: Label
var _name_edit_field: LineEdit
var _settings_toggle: Button
var _settings_popup: PopupPanel
var _color_picker: ColorPicker
var _embedded_preview: TextureRect


func _ready() -> void:
	_node_color = _color
	super._ready()
	title = _custom_name

	var port_row := Control.new()
	port_row.custom_minimum_size = Vector2(140, 0)
	add_child(port_row)

	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)

	var bottom_row := HBoxContainer.new()
	var bottom_spacer := Control.new()
	bottom_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_child(bottom_spacer)
	_settings_toggle = Button.new()
	_settings_toggle.text = "⚙"
	_settings_toggle.flat = true
	_settings_toggle.pressed.connect(_on_settings_toggled)
	bottom_row.add_child(_settings_toggle)
	add_child(bottom_row)

	_settings_popup = PopupPanel.new()
	_settings_popup.size = Vector2(220, 260)
	_color_picker = ColorPicker.new()
	_color_picker.color = _color
	_color_picker.edit_alpha = false
	_color_picker.color_changed.connect(_on_color_changed)
	_settings_popup.add_child(_color_picker)
	add_child(_settings_popup)

	_apply_node_color()


func _add_preview_controls() -> void:
	_embedded_preview = TextureRect.new()
	_embedded_preview.custom_minimum_size = Vector2(0, 100)
	_embedded_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_embedded_preview.stretch_mode = TextureRect.STRETCH_SCALE
	_embedded_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	var corner_shader := Shader.new()
	corner_shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tvec2 size = 1.0 / TEXTURE_PIXEL_SIZE;\n\tvec2 pos = UV * size;\n\tfloat r = 5.0;\n\tvec2 d = max(abs(pos - size * 0.5) - (size * 0.5 - r), vec2(0.0));\n\tCOLOR = texture(TEXTURE, UV);\n\tCOLOR.a *= clamp(-(length(d) - r), 0.0, 1.0);\n}"
	var corner_mat := ShaderMaterial.new()
	corner_mat.shader = corner_shader
	_embedded_preview.material = corner_mat

	add_child(_embedded_preview)
	_preview_slot = _embedded_preview

	var bottom_row: Node = _settings_toggle.get_parent()
	if bottom_row and bottom_row.get_parent() == self:
		move_child(bottom_row, get_child_count() - 1)

	set_slot(get_children().find(_embedded_preview), false, -1, Color.WHITE, false, -1, Color.WHITE)

	call_deferred("_request_preview_open")


func _request_preview_open() -> void:
	emit_signal("preview_toggled")


func get_preview_slot() -> TextureRect:
	return _embedded_preview


func _on_settings_toggled() -> void:
	if _settings_popup.visible:
		_settings_popup.hide()
	else:
		var btn_pos := _settings_toggle.get_screen_position()
		_settings_popup.popup(Rect2(btn_pos + Vector2(-180, _settings_toggle.size.y), _settings_popup.size))


func _center_title() -> void:
	var hbox := get_titlebar_hbox()
	for child in hbox.get_children():
		if child is Label:
			child.hide()
			break

	var lbl := Label.new()
	lbl.text = _custom_name
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 0)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", 0)
	lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	hbox.add_child(lbl)
	_name_label = lbl

	var name_edit := LineEdit.new()
	name_edit.text = _custom_name
	name_edit.custom_minimum_size = Vector2(80, 0)
	name_edit.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_edit.add_theme_color_override("font_color", Color.WHITE)
	name_edit.visible = false
	_name_edit_field = name_edit
	name_edit.text_submitted.connect(_on_name_submitted.bind(name_edit, lbl))
	name_edit.focus_exited.connect(func(): _on_name_submitted(name_edit.text, name_edit, lbl))
	hbox.add_child(name_edit)

	lbl.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			lbl.hide()
			name_edit.text = _custom_name
			name_edit.show()
			name_edit.grab_focus()
			name_edit.select_all()
	)


func _on_name_submitted(new_name: String, name_edit: LineEdit, lbl: Label) -> void:
	_custom_name = new_name if new_name.strip_edges() != "" else _custom_name
	title = _custom_name
	if _name_label: _name_label.text = _custom_name
	lbl.show()
	name_edit.hide()
	call_deferred("reset_size")
	emit_signal("value_changed")


func _on_color_changed(color: Color) -> void:
	_color = color
	_node_color = color
	_apply_node_color()
	emit_signal("value_changed")


func _apply_node_color() -> void:
	var body := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	body.bg_color = _color
	add_theme_stylebox_override("panel", body)
	var titlebar := get_theme_stylebox("titlebar").duplicate() as StyleBoxFlat
	titlebar.bg_color = _color
	add_theme_stylebox_override("titlebar", titlebar)
	_apply_selection_style(body, titlebar)
	call_deferred("_update_title_color")


func _update_title_color() -> void:
	var luminance := _color.r * 0.299 + _color.g * 0.587 + _color.b * 0.114
	var text_color := Color.BLACK if luminance > 0.5 else Color.WHITE
	if _name_label: _name_label.add_theme_color_override("font_color", text_color)


func is_polymorphic() -> bool:
	return true


func get_output_type(from_port: int, input_types: Array) -> int:
	return input_types[0] if not input_types.is_empty() else 0


func get_default_input_types() -> Array:
	return [0]


func get_output_snippet(port: int, inputs: Array = []) -> String:
	return inputs[0] if not inputs.is_empty() else "vec3(0.0)"


func get_shader_snippet(inputs: Array = []) -> String:
	return inputs[0] if not inputs.is_empty() else "vec3(0.0)"


func get_default_inputs() -> Array:
	return ["vec3(0.0)"]


func get_state() -> Dictionary:
	return {
		"custom_name": _custom_name,
		"color": [_color.r, _color.g, _color.b, _color.a],
	}


func set_state(state: Dictionary) -> void:
	_custom_name = state.get("custom_name", "Preview")
	var c = state.get("color")
	if c is Array and c.size() >= 4:
		_color = Color(c[0], c[1], c[2], c[3])
		_node_color = _color
		if _color_picker: _color_picker.color = _color
	title = _custom_name
	if _name_label: _name_label.text = _custom_name
	if _name_edit_field: _name_edit_field.text = _custom_name
	_apply_node_color()

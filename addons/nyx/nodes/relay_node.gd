@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

signal pair_removed(index: int)

var _pair_count: int = 1
var _custom_name: String = "Relay"
var _color: Color = Color("#3C4655")

var _pair_rows: Array = []
var _add_btn: Button
var _settings_toggle: Button
var _settings_popup: PopupPanel
var _color_picker: ColorPicker
var _name_label: Label
var _name_edit_field: LineEdit


func _ready() -> void:
	_node_color = _color
	super._ready()
	title = _custom_name

	_add_pair_row_internal()

	var bottom_row := HBoxContainer.new()
	_add_btn = Button.new()
	_add_btn.text = "+"
	_add_btn.flat = true
	_add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_btn.pressed.connect(_on_add_pressed)
	bottom_row.add_child(_add_btn)
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

	_update_slots()
	_apply_node_color()


func _add_preview_controls() -> void:
	pass


func _on_settings_toggled() -> void:
	if _settings_popup.visible:
		_settings_popup.hide()
	else:
		var btn_pos := _settings_toggle.get_screen_position()
		_settings_popup.popup(Rect2(btn_pos + Vector2(-180, _settings_toggle.size.y), _settings_popup.size))


func _add_pair_row_internal() -> HBoxContainer:
	var row := HBoxContainer.new()
	var left_spacer := Control.new()
	left_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left_spacer)
	var remove_btn := Button.new()
	remove_btn.text = "×"
	remove_btn.flat = true
	remove_btn.pressed.connect(func(): _on_remove_pair(_pair_rows.find(row)))
	row.add_child(remove_btn)
	var right_spacer := Control.new()
	right_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right_spacer)
	_pair_rows.append(row)
	add_child(row)
	return row


func _on_add_pressed() -> void:
	emit_signal("edit_started")
	var bottom_row: Node = _add_btn.get_parent()
	remove_child(bottom_row)
	_add_pair_row_internal()
	add_child(bottom_row)
	_pair_count += 1
	_update_slots()
	emit_signal("value_changed")


func _add_pair_silently() -> void:
	var bottom_row: Node = _add_btn.get_parent()
	remove_child(bottom_row)
	_add_pair_row_internal()
	add_child(bottom_row)
	_pair_count += 1
	_update_slots()


func _on_remove_pair(idx: int) -> void:
	if _pair_count <= 1 or idx < 0:
		return
	emit_signal("edit_started")
	var row: Node = _pair_rows[idx]
	_pair_rows.remove_at(idx)
	remove_child(row)
	row.queue_free()
	_pair_count -= 1
	_update_slots()
	call_deferred("reset_size")
	emit_signal("pair_removed", idx)
	emit_signal("value_changed")


func _update_slots() -> void:
	var vec3_color := _type_color(0)
	for i in range(_pair_rows.size()):
		set_slot(i, true, 0, vec3_color, true, 0, vec3_color)
	var n := _pair_rows.size()
	set_slot(n, false, -1, _type_color(0), false, -1, _type_color(0))


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
	name_edit.custom_minimum_size = Vector2(_s(80), 0)
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
	return input_types[from_port] if from_port < input_types.size() else 0


func get_default_input_types() -> Array:
	var types := []
	for i in range(_pair_count):
		types.append(0)
	return types


func get_output_snippet(port: int, inputs: Array = []) -> String:
	return inputs[port] if port < inputs.size() else "vec3(0.0)"


func get_shader_snippet(inputs: Array = []) -> String:
	return inputs[0] if not inputs.is_empty() else "vec3(0.0)"


func get_default_inputs() -> Array:
	var defaults := []
	for i in range(_pair_count):
		defaults.append("vec3(0.0)")
	return defaults


func get_state() -> Dictionary:
	return {
		"pair_count": _pair_count,
		"custom_name": _custom_name,
		"color": [_color.r, _color.g, _color.b, _color.a],
	}


func set_state(state: Dictionary) -> void:
	_custom_name = state.get("custom_name", "Relay")
	var c = state.get("color")
	if c is Array and c.size() >= 4:
		_color = Color(c[0], c[1], c[2], c[3])
		_node_color = _color
		if _color_picker: _color_picker.color = _color
	var target: int = state.get("pair_count", 1)
	while _pair_count < target:
		_add_pair_silently()
	title = _custom_name
	if _name_label: _name_label.text = _custom_name
	if _name_edit_field: _name_edit_field.text = _custom_name
	_apply_node_color()

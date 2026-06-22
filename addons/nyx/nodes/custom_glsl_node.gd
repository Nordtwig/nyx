@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _input_count: int = 1
var _code: String = "return in0;"
var _code_open: bool = true
var _custom_name: String = "Custom Function"

var _input_labels: Array = []
var _count_spin: SpinBox
var _chevron: Button
var _code_spacer: Control
var _code_edit: TextEdit
var _name_label: Label
var _name_edit_field: LineEdit


func _ready() -> void:
	super._ready()
	title = _custom_name

	for i in range(4):
		var label := Label.new()
		label.text = "in%d" % i
		_input_labels.append(label)
		add_child(label)

	_update_slots()


func _add_preview_controls() -> void:
	var count_row := HBoxContainer.new()
	var count_label := Label.new()
	count_label.text = "Inputs"
	count_row.add_child(count_label)
	_count_spin = SpinBox.new()
	_count_spin.min_value = 1
	_count_spin.max_value = 4
	_count_spin.value = _input_count
	_count_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count_spin.value_changed.connect(_on_count_changed)
	count_row.add_child(_count_spin)
	add_child(count_row)

	_chevron = Button.new()
	_chevron.text = "▴ Code" if _code_open else "▸ Code"
	_chevron.flat = true
	_chevron.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_chevron.pressed.connect(_on_chevron_pressed)
	add_child(_chevron)

	_code_spacer = Control.new()
	_code_spacer.custom_minimum_size = Vector2(0, 4)
	add_child(_code_spacer)

	_code_edit = TextEdit.new()
	_code_edit.text = _code
	_code_edit.custom_minimum_size = Vector2(200, 120)
	_code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_code_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE
	_code_edit.text_changed.connect(_on_code_changed)
	add_child(_code_edit)

	_code_spacer.visible = _code_open
	_code_edit.visible = _code_open
	_update_slots()
	super._add_preview_controls()


func _on_count_changed(val: float) -> void:
	emit_signal("edit_started")
	_input_count = int(val)
	_update_slots()
	emit_signal("value_changed")


func _on_chevron_pressed() -> void:
	_code_open = not _code_open
	_chevron.text = "▴ Code" if _code_open else "▸ Code"
	_code_spacer.visible = _code_open
	_code_edit.visible = _code_open
	if not _code_open:
		call_deferred("reset_size")
	emit_signal("preview_toggled")


func _on_code_changed() -> void:
	_code = _code_edit.get_text()
	emit_signal("value_changed")


func _center_title() -> void:
	var hbox := get_titlebar_hbox()
	for child in hbox.get_children():
		if child is Label:
			child.hide()
			break

	var lbl := Label.new()
	lbl.text = _custom_name
	lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_constant_override("outline_size", 0)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", 0)
	lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	hbox.add_child(lbl)
	_name_label = lbl

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(spacer)

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
			_on_pen_pressed(name_edit, lbl)
	)


func _on_pen_pressed(name_edit: LineEdit, lbl: Label) -> void:
	lbl.hide()
	name_edit.text = _custom_name
	name_edit.show()
	name_edit.grab_focus()
	name_edit.select_all()


func _on_name_submitted(new_name: String, name_edit: LineEdit, lbl: Label) -> void:
	_custom_name = new_name if new_name.strip_edges() != "" else _custom_name
	title = _custom_name
	if _name_label:
		_name_label.text = _custom_name
	lbl.show()
	name_edit.hide()
	emit_signal("value_changed")


func _update_slots() -> void:
	var vec3_color := Color.WHITE
	for i in range(4):
		var has_input := i < _input_count
		if i < _input_labels.size():
			_input_labels[i].visible = has_input
		if i == 0:
			set_slot(0, has_input, 0, vec3_color, true, 0, vec3_color)
		else:
			set_slot(i, has_input, 0, vec3_color, false, -1, vec3_color)


func _get_func_name() -> String:
	var sanitized := _custom_name.strip_edges()
	if sanitized.is_empty():
		sanitized = str(name)
	return "nyx_custom_%s" % sanitized.replace(" ", "_").replace("-", "_").replace("@", "_")


func get_shader_functions() -> Dictionary:
	if _code.strip_edges().is_empty():
		return {}
	var params := PackedStringArray()
	for i in range(_input_count):
		params.append("vec3 in%d" % i)
	var fn := "vec3 %s(%s) {\n%s\n}\n\n" % [_get_func_name(), ", ".join(params), _code]
	return {_get_func_name(): fn}


func get_shader_snippet(inputs: Array = []) -> String:
	if _code.strip_edges().is_empty():
		return "vec3(0.0)"
	return "%s(%s)" % [_get_func_name(), ", ".join(inputs.slice(0, _input_count))]


func get_default_inputs() -> Array:
	var defaults := []
	for i in range(_input_count):
		defaults.append("vec3(0.0)")
	return defaults


func get_state() -> Dictionary:
	return {"code": _code, "input_count": _input_count, "code_open": _code_open, "custom_name": _custom_name}


func set_state(state: Dictionary) -> void:
	var v = state.get("input_count")
	if v is float or v is int:
		_input_count = int(v)
	_code = state.get("code", "return in0;")
	_code_open = state.get("code_open", true)
	_custom_name = state.get("custom_name", "Custom Function")
	title = _custom_name
	if _name_label:
		_name_label.text = _custom_name
	if _name_edit_field:
		_name_edit_field.text = _custom_name
	if _count_spin:
		_count_spin.value = _input_count
	if _code_edit:
		_code_edit.text = _code
	if _chevron:
		_chevron.text = "▴ Code" if _code_open else "▸ Code"
	if _code_spacer:
		_code_spacer.visible = _code_open
	if _code_edit:
		_code_edit.visible = _code_open
	_update_slots()

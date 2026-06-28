@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _value: float = 1.0
var _param_mode: bool = false
var _param_name: String = ""
var _spinbox: SpinBox
var _param_btn: Button
var _param_name_edit: LineEdit


func _ready() -> void:
	super._ready()
	title = "Float"

	var float_color := _type_color(1)

	_spinbox = SpinBox.new()
	_spinbox.min_value = -1e9
	_spinbox.max_value = 1e9
	_spinbox.step = 0.001
	_spinbox.value = _value
	_spinbox.custom_minimum_size = Vector2(80, 0)
	_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_spinbox.value_changed.connect(_on_value_changed)
	add_child(_spinbox)

	_param_name_edit = LineEdit.new()
	_param_name_edit.placeholder_text = "param name"
	_param_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_param_name_edit.visible = false
	_param_name_edit.text_changed.connect(_on_param_name_changed)
	add_child(_param_name_edit)

	set_slot(0, false, -1, _type_color(0), true, 1, float_color)

	call_deferred("_init_default_param_name")
	call_deferred("_setup_param_button")


func _init_default_param_name() -> void:
	if _param_name == "":
		_param_name = "param_" + str(name).to_lower()
		_param_name_edit.text = _param_name


func _setup_param_button() -> void:
	var hbox := get_titlebar_hbox()
	_param_btn = Button.new()
	_param_btn.text = "$"
	_param_btn.flat = true
	_param_btn.custom_minimum_size = Vector2(20, 0)
	_param_btn.pressed.connect(_on_param_btn_pressed)
	hbox.add_child(_param_btn)
	_update_param_button()


func _on_param_btn_pressed() -> void:
	_param_mode = not _param_mode
	_param_name_edit.visible = _param_mode
	if not _param_mode:
		call_deferred("reset_size")
	_update_param_button()
	_update_param_tooltip()
	value_changed.emit()


func _update_param_button() -> void:
	if not _param_btn:
		return
	if _param_mode:
		_param_btn.add_theme_color_override("font_color", _type_color(1))
	else:
		_param_btn.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))


func _on_value_changed(val: float) -> void:
	_value = val
	value_changed.emit()


func _on_param_name_changed(new_name: String) -> void:
	_param_name = new_name
	_update_param_tooltip()
	value_changed.emit()


func _update_param_tooltip() -> void:
	if _param_mode:
		_param_name_edit.tooltip_text = 'material.set_shader_parameter("%s", value)' % _param_name
	else:
		_param_name_edit.tooltip_text = ""


func _add_preview_controls() -> void:
	pass


func get_uniform_declaration() -> String:
	if not _param_mode:
		return ""
	return "uniform float %s = %.4f;" % [_param_name, _value]


func get_param_export_line() -> String:
	if not _param_mode:
		return ""
	return "shader_parameter/%s = %.4f" % [_param_name, _value]


func get_shader_snippet(inputs: Array = []) -> String:
	if _param_mode:
		return _param_name
	return "%.4f" % _value


func get_default_inputs() -> Array:
	return []


func get_state() -> Dictionary:
	return {"value": _value, "param_mode": _param_mode, "param_name": _param_name}


func set_state(state: Dictionary) -> void:
	var v = state.get("value")
	if v is float:
		_value = v
	_spinbox.value = _value
	var pname = state.get("param_name", "")
	if pname != "":
		_param_name = pname
		_param_name_edit.text = _param_name
	_param_mode = state.get("param_mode", false)
	_param_name_edit.visible = _param_mode
	_update_param_button()
	_update_param_tooltip()


func is_param_mode() -> bool:
	return _param_mode


func get_param_name() -> String:
	return _param_name


func set_value_external(v: float) -> void:
	_value = v
	_spinbox.value = v
	emit_signal("value_changed")


func get_blackboard_control() -> Control:
	var sb := SpinBox.new()
	sb.min_value = -1e9
	sb.max_value = 1e9
	sb.step = 0.001
	sb.value = _value
	sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sb.value_changed.connect(func(v: float) -> void: set_value_external(v))
	value_changed.connect(func() -> void:
		if sb.value != _value:
			sb.set_value_no_signal(_value)
	)
	return sb

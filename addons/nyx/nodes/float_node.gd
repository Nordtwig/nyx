@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _value: float = 1.0
var _param_mode: bool = false
var _param_name: String = ""
var _spinbox: SpinBox


func _ready() -> void:
	super._ready()
	title = "Float"

	var float_color := _type_color(1)

	_spinbox = SpinBox.new()
	_spinbox.min_value = -1e9
	_spinbox.max_value = 1e9
	_spinbox.step = 0.001
	_spinbox.value = _value
	_spinbox.custom_minimum_size = Vector2(_s(80), 0)
	_spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_spinbox.value_changed.connect(_on_value_changed)
	add_child(_spinbox)

	set_slot(0, false, -1, _type_color(0), true, 1, float_color)

	call_deferred("_init_default_param_name")


func _init_default_param_name() -> void:
	if _param_name == "":
		_param_name = "param_" + str(name).to_lower()


func _on_value_changed(val: float) -> void:
	_value = val
	value_changed.emit()


func set_param_mode(v: bool) -> void:
	_param_mode = v
	value_changed.emit()


func set_param_name(n: String) -> void:
	_param_name = n
	value_changed.emit()


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
	_param_mode = state.get("param_mode", false)


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

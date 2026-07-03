@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _x: float = 0.0
var _y: float = 0.0
var _z: float = 0.0
var _param_mode: bool = false
var _param_name: String = ""
var _spin_x: SpinBox
var _spin_y: SpinBox
var _spin_z: SpinBox


func _ready() -> void:
	super._ready()
	title = "Vector3"

	var vec3_color := _type_color(0)

	for axis in [["X", "_spin_x"], ["Y", "_spin_y"], ["Z", "_spin_z"]]:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = axis[0]
		lbl.custom_minimum_size = Vector2(_s(12), 0)
		row.add_child(lbl)
		var spin := SpinBox.new()
		spin.min_value = -1e9
		spin.max_value = 1e9
		spin.step = 0.001
		spin.value = 0.0
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spin)
		add_child(row)
		set(axis[1], spin)

	_spin_x.value_changed.connect(func(v): _on_axis_changed(v, 0))
	_spin_y.value_changed.connect(func(v): _on_axis_changed(v, 1))
	_spin_z.value_changed.connect(func(v): _on_axis_changed(v, 2))

	set_slot(0, false, -1, vec3_color, true, 0, vec3_color)

	call_deferred("_init_default_param_name")


func _init_default_param_name() -> void:
	if _param_name == "":
		_param_name = "vec3_" + str(name).to_lower()


func _on_axis_changed(val: float, axis: int) -> void:
	match axis:
		0: _x = val
		1: _y = val
		2: _z = val
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
	return "uniform vec3 %s = vec3(%.4f, %.4f, %.4f);" % [_param_name, _x, _y, _z]


func get_shader_snippet(inputs: Array = []) -> String:
	if _param_mode:
		return _param_name
	return "vec3(%.4f, %.4f, %.4f)" % [_x, _y, _z]


func apply_shader_params(material: ShaderMaterial) -> void:
	if _param_mode:
		material.set_shader_parameter(_param_name, Vector3(_x, _y, _z))


func get_param_export_line() -> String:
	if not _param_mode:
		return ""
	return "shader_parameter/%s = Vector3(%.4f, %.4f, %.4f)" % [_param_name, _x, _y, _z]


func get_default_inputs() -> Array:
	return []


func get_state() -> Dictionary:
	return {"x": _x, "y": _y, "z": _z, "param_mode": _param_mode, "param_name": _param_name}


func set_state(state: Dictionary) -> void:
	var vx = state.get("x"); if vx is float: _x = vx
	var vy = state.get("y"); if vy is float: _y = vy
	var vz = state.get("z"); if vz is float: _z = vz
	_spin_x.value = _x
	_spin_y.value = _y
	_spin_z.value = _z
	var pname = state.get("param_name", "")
	if pname != "":
		_param_name = pname
	_param_mode = state.get("param_mode", false)


func is_param_mode() -> bool:
	return _param_mode


func get_param_name() -> String:
	return _param_name


func get_blackboard_control() -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	for axis in ["X", "Y", "Z"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var lbl := Label.new()
		lbl.text = axis
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.65, 0.68, 0.72))
		lbl.custom_minimum_size = Vector2(_s(12), 0)
		row.add_child(lbl)
		var sb := SpinBox.new()
		sb.min_value = -1e9
		sb.max_value = 1e9
		sb.step = 0.001
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var prop: String = "_" + axis.to_lower()
		sb.value = get(prop)
		sb.value_changed.connect(func(v: float) -> void:
			set(prop, v)
			emit_signal("value_changed")
		)
		value_changed.connect(func() -> void:
			if sb.value != get(prop):
				sb.set_value_no_signal(get(prop))
		)
		row.add_child(sb)
		vbox.add_child(row)
	return vbox

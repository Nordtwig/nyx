@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _value: float = 0.5
var _param_mode: bool = false
var _param_name: String = ""
var _slider: EditorSpinSlider
var _param_check: CheckBox
var _param_name_edit: LineEdit


func _ready() -> void:
	super._ready()
	title = "Float"

	var float_color := Color(0.35, 0.9, 0.85)

	_slider = EditorSpinSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.01
	_slider.allow_lesser = true
	_slider.allow_greater = true
	_slider.value = _value
	_slider.custom_minimum_size = Vector2(80, 0)
	_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider.value_changed.connect(_on_value_changed)
	add_child(_slider)

	var param_row := HBoxContainer.new()
	_param_check = CheckBox.new()
	_param_check.text = "Param"
	_param_check.toggled.connect(_on_param_toggled)
	param_row.add_child(_param_check)
	_param_name = "param_" + str(name).to_lower()
	_param_name_edit = LineEdit.new()
	_param_name_edit.text = _param_name
	_param_name_edit.editable = false
	_param_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_param_name_edit.text_changed.connect(_on_param_name_changed)
	param_row.add_child(_param_name_edit)
	add_child(param_row)

	set_slot(0, false, -1, Color.WHITE, true, 1, float_color)


func _on_value_changed(val: float) -> void:
	_value = val
	value_changed.emit()


func _on_param_toggled(enabled: bool) -> void:
	_param_mode = enabled
	_param_name_edit.editable = enabled
	_update_param_tooltip()
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


func get_shader_snippet(inputs: Array = []) -> String:
	if _param_mode:
		return _param_name
	return "%.4f" % _value


func get_default_inputs() -> Array:
	return []


func get_state() -> Dictionary:
	return {"value": _value, "param_mode": _param_mode, "param_name": _param_name}


func set_state(state: Dictionary) -> void:
	_value = state.get("value", 0.5)
	_slider.value = _value
	_param_name = state.get("param_name", _param_name)
	_param_name_edit.text = _param_name
	_param_mode = state.get("param_mode", false)
	_param_check.button_pressed = _param_mode
	_param_name_edit.editable = _param_mode
	_update_param_tooltip()

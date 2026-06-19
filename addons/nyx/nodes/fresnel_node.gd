@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _power: float = 3.0
var _spinbox: SpinBox


func _ready() -> void:
	super._ready()
	title = "Fresnel"

	var float_color := Color(0.35, 0.9, 0.85)

	_spinbox = SpinBox.new()
	_spinbox.min_value = 0.1
	_spinbox.max_value = 20.0
	_spinbox.step = 0.1
	_spinbox.value = _power
	_spinbox.custom_minimum_size = Vector2(120, 0)
	_spinbox.value_changed.connect(_on_value_changed)
	add_child(_spinbox)

	set_slot(0, true, 1, float_color, true, 1, float_color)


func _on_value_changed(val: float) -> void:
	_power = val
	value_changed.emit()


func get_shader_snippet(inputs: Array = []) -> String:
	return "pow(clamp(1.0 - dot(NORMAL, VIEW), 0.0, 1.0), %s)" % [inputs[0]]


func get_default_inputs() -> Array:
	return ["%.4f" % _power]


func get_state() -> Dictionary:
	return {"power": _power}


func set_state(state: Dictionary) -> void:
	_power = state["power"]
	_spinbox.value = _power

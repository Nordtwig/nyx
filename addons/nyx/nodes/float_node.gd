@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _value: float = 0.5
var _spinbox: SpinBox


func _ready() -> void:
	super._ready()
	title = "Float"

	_spinbox = SpinBox.new()
	_spinbox.min_value = 0.0
	_spinbox.max_value = 1.0
	_spinbox.step = 0.01
	_spinbox.value = _value
	_spinbox.custom_minimum_size = Vector2(120, 0)
	_spinbox.value_changed.connect(_on_value_changed)
	add_child(_spinbox)

	set_slot(0, false, -1, Color.WHITE, true, 1, Color(0.35, 0.9, 0.85))


func _on_value_changed(val: float) -> void:
	_value = val
	value_changed.emit()


func get_shader_snippet(inputs: Array = []) -> String:
	return "%.4f" % _value


func get_default_inputs() -> Array:
	return []


func get_state() -> Dictionary:
	return {"value": _value}


func set_state(state: Dictionary) -> void:
	_value = state["value"]
	_spinbox.value = _value

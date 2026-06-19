@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _value: float = 0.5
var _slider: EditorSpinSlider


func _ready() -> void:
	super._ready()
	title = "Float"

	_slider = EditorSpinSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 1.0
	_slider.step = 0.01
	_slider.value = _value
	_slider.custom_minimum_size = Vector2(80, 0)
	_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider.value_changed.connect(_on_value_changed)
	add_child(_slider)

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
	_slider.value = _value

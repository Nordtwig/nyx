@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _power: float = 3.0
var _slider: EditorSpinSlider


func _ready() -> void:
	super._ready()
	title = "Fresnel"

	var float_color := _type_color(1)

	_slider = EditorSpinSlider.new()
	_slider.label = "Power"
	_slider.min_value = 0.1
	_slider.max_value = 20.0
	_slider.step = 0.1
	_slider.value = _power
	_slider.custom_minimum_size = Vector2(_s(80), 0)
	_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider.value_changed.connect(_on_value_changed)
	add_child(_slider)

	set_slot(0, true, 1, float_color, true, 1, float_color)


func _on_value_changed(val: float) -> void:
	_power = val
	value_changed.emit()


func get_shader_snippet(inputs: Array = []) -> String:
	return "pow(clamp(1.0 - dot(NORMAL, VIEW), 0.0, 1.0), %s)" % [inputs[0]]


func get_param_range_hint(_port: int) -> Array:
	return [0.1, 20.0, 0.1]  # Power (the only input port)


func get_default_inputs() -> Array:
	return ["%.4f" % _power]


func get_state() -> Dictionary:
	return {"power": _power}


func set_state(state: Dictionary) -> void:
	_power = state["power"]
	_slider.value = _power

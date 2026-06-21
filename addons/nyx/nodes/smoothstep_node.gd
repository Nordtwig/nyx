@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _edge0: float = 0.0
var _edge1: float = 1.0
var _edge0_slider: EditorSpinSlider
var _edge1_slider: EditorSpinSlider


func _ready() -> void:
	super._ready()
	title = "Smoothstep"

	var float_color := Color(0.35, 0.9, 0.85)

	_edge0_slider = EditorSpinSlider.new()
	_edge0_slider.label = "Edge0"
	_edge0_slider.min_value = -10.0
	_edge0_slider.max_value = 10.0
	_edge0_slider.step = 0.01
	_edge0_slider.value = _edge0
	_edge0_slider.custom_minimum_size = Vector2(80, 0)
	_edge0_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edge0_slider.value_changed.connect(func(v: float): _edge0 = v; emit_signal("value_changed"))
	add_child(_edge0_slider)

	_edge1_slider = EditorSpinSlider.new()
	_edge1_slider.label = "Edge1"
	_edge1_slider.min_value = -10.0
	_edge1_slider.max_value = 10.0
	_edge1_slider.step = 0.01
	_edge1_slider.value = _edge1
	_edge1_slider.custom_minimum_size = Vector2(80, 0)
	_edge1_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edge1_slider.value_changed.connect(func(v: float): _edge1 = v; emit_signal("value_changed"))
	add_child(_edge1_slider)

	var label_x := Label.new()
	label_x.text = "X"
	add_child(label_x)

	set_slot(0, true, 1, float_color, true, 1, float_color)
	set_slot(1, true, 1, float_color, false, -1, float_color)
	set_slot(2, true, 1, float_color, false, -1, float_color)


func get_shader_snippet(inputs: Array = []) -> String:
	return "smoothstep(%s, %s, %s)" % [inputs[0], inputs[1], inputs[2]]


func get_default_inputs() -> Array:
	return ["%.4f" % _edge0, "%.4f" % _edge1, "0.5"]


func get_state() -> Dictionary:
	return {"edge0": _edge0, "edge1": _edge1}


func set_state(state: Dictionary) -> void:
	var e0 = state.get("edge0")
	var e1 = state.get("edge1")
	if e0 is float:
		_edge0 = e0
	if e1 is float:
		_edge1 = e1
	_edge0_slider.value = _edge0
	_edge1_slider.value = _edge1

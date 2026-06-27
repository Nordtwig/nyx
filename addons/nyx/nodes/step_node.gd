@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

var _edge: float = 0.5
var _edge_slider: EditorSpinSlider


func _ready() -> void:
	super._ready()
	title = "Step"

	var float_color := _type_color(1)

	_edge_slider = EditorSpinSlider.new()
	_edge_slider.label = "Edge"
	_edge_slider.min_value = -10.0
	_edge_slider.max_value = 10.0
	_edge_slider.step = 0.01
	_edge_slider.value = _edge
	_edge_slider.custom_minimum_size = Vector2(80, 0)
	_edge_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edge_slider.value_changed.connect(func(v: float): _edge = v; emit_signal("value_changed"))
	add_child(_edge_slider)

	var label_x := Label.new()
	label_x.text = "X"
	add_child(label_x)

	set_slot(0, true, 1, float_color, true, 1, float_color)
	set_slot(1, true, 1, float_color, false, -1, float_color)


func get_shader_snippet(inputs: Array = []) -> String:
	return "step(%s, %s)" % [inputs[0], inputs[1]]


func get_default_inputs() -> Array:
	return ["%.4f" % _edge, "0.0"]


func get_state() -> Dictionary:
	return {"edge": _edge}


func set_state(state: Dictionary) -> void:
	var e = state.get("edge")
	if e is float:
		_edge = e
	_edge_slider.value = _edge

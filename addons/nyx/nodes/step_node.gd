@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Step"

	var float_color := Color(0.35, 0.9, 0.85)

	var label_edge := Label.new()
	label_edge.text = "Edge"
	add_child(label_edge)

	var label_x := Label.new()
	label_x.text = "X"
	add_child(label_x)

	set_slot(0, true, 1, float_color, true, 1, float_color)
	set_slot(1, true, 1, float_color, false, -1, float_color)


func get_shader_snippet(inputs: Array = []) -> String:
	return "step(%s, %s)" % [inputs[0], inputs[1]]


func get_default_inputs() -> Array:
	return ["0.5", "0.0"]

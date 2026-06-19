@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Smoothstep"

	var float_color := Color(0.35, 0.9, 0.85)

	var label_edge0 := Label.new()
	label_edge0.text = "Edge0"
	add_child(label_edge0)

	var label_edge1 := Label.new()
	label_edge1.text = "Edge1"
	add_child(label_edge1)

	var label_x := Label.new()
	label_x.text = "X"
	add_child(label_x)

	set_slot(0, true, 1, float_color, true, 1, float_color)
	set_slot(1, true, 1, float_color, false, -1, float_color)
	set_slot(2, true, 1, float_color, false, -1, float_color)


func get_shader_snippet(inputs: Array = []) -> String:
	return "smoothstep(%s, %s, %s)" % [inputs[0], inputs[1], inputs[2]]


func get_default_inputs() -> Array:
	return ["0.0", "1.0", "0.5"]

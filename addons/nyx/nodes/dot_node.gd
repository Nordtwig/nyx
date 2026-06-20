@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Dot"

	var label_a := Label.new()
	label_a.text = "A"
	add_child(label_a)

	var label_b := Label.new()
	label_b.text = "B"
	add_child(label_b)

	var float_color := Color(0.35, 0.9, 0.85)
	set_slot(0, true, 0, Color.WHITE, true, 1, float_color)
	set_slot(1, true, 0, Color.WHITE, false, -1, Color.WHITE)


func get_shader_snippet(inputs: Array = []) -> String:
	return "dot(%s, %s)" % [inputs[0], inputs[1]]


func get_default_inputs() -> Array:
	return ["vec3(0.0)", "vec3(0.0)"]

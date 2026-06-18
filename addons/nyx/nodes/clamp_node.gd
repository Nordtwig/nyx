@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Clamp"

	var label_a := Label.new()
	label_a.text = "A"
	add_child(label_a)

	var label_min := Label.new()
	label_min.text = "Min"
	add_child(label_min)

	var label_max := Label.new()
	label_max.text = "Max"
	add_child(label_max)

	var float_color := Color(0.35, 0.9, 0.85)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, true, 1, float_color, false, -1, Color.WHITE)
	set_slot(2, true, 1, float_color, false, -1, Color.WHITE)


func get_shader_snippet(inputs: Array = []) -> String:
	return "clamp(%s, %s, %s)" % [inputs[0], inputs[1], inputs[2]]


func get_default_inputs() -> Array:
	return ["vec3(0.5)", "0.0", "1.0"]

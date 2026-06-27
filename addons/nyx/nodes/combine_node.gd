@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Combine"

	var float_color := _type_color(1)

	var label_r := Label.new()
	label_r.text = "R"
	add_child(label_r)

	var label_g := Label.new()
	label_g.text = "G"
	add_child(label_g)

	var label_b := Label.new()
	label_b.text = "B"
	add_child(label_b)

	set_slot(0, true, 1, float_color, true, 0, _type_color(0))
	set_slot(1, true, 1, float_color, false, -1, _type_color(0))
	set_slot(2, true, 1, float_color, false, -1, _type_color(0))


func get_shader_snippet(inputs: Array = []) -> String:
	return "vec3(%s, %s, %s)" % [inputs[0], inputs[1], inputs[2]]


func get_default_inputs() -> Array:
	return ["0.0", "0.0", "0.0"]

@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Scale"

	var float_color := Color(0.35, 0.9, 0.85)

	var label_v := Label.new()
	label_v.text = "V"
	add_child(label_v)

	var label_t := Label.new()
	label_t.text = "T"
	add_child(label_t)

	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, true, 1, float_color, false, -1, Color.WHITE)


func get_shader_snippet(inputs: Array = []) -> String:
	return "(%s * %s)" % [inputs[0], inputs[1]]


func get_default_inputs() -> Array:
	return ["vec3(1.0)", "1.0"]

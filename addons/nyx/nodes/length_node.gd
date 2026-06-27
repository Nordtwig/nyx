@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Length"

	var label := Label.new()
	label.text = "V"
	add_child(label)

	var float_color := _type_color(1)
	set_slot(0, true, 0, _type_color(0), true, 1, float_color)


func get_shader_snippet(inputs: Array = []) -> String:
	return "length(%s)" % inputs[0]


func get_default_inputs() -> Array:
	return ["vec3(0.0)"]

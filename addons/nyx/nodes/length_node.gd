@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Length"

	var label := Label.new()
	label.text = "V"
	add_child(label)

	var float_color := Color(0.35, 0.9, 0.85)
	set_slot(0, true, 0, Color.WHITE, true, 1, float_color)


func get_shader_snippet(inputs: Array = []) -> String:
	return "length(%s)" % inputs[0]


func get_default_inputs() -> Array:
	return ["vec3(0.0)"]

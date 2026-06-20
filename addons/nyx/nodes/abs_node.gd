@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Abs"
	var label := Label.new()
	label.text = "V"
	add_child(label)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)


func get_shader_snippet(inputs: Array = []) -> String:
	return "abs(%s)" % inputs[0]


func get_default_inputs() -> Array:
	return ["vec3(0.0)"]

@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Sin"

	var label := Label.new()
	label.text = "A"
	add_child(label)

	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)


func get_shader_snippet(inputs: Array = []) -> String:
	return "sin(%s)" % inputs[0]


func get_default_inputs() -> Array:
	return ["vec3(0.0)"]

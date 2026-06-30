@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Object Position"

	var label := Label.new()
	label.text = "World"
	add_child(label)

	set_slot(0, false, -1, _type_color(0), true, 0, _type_color(0))


func get_shader_snippet(inputs: Array = []) -> String:
	return "NODE_POSITION_WORLD"


func get_default_inputs() -> Array:
	return []

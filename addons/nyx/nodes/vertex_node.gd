@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Vertex"

	var label := Label.new()
	label.text = "Position"
	add_child(label)

	set_slot(0, false, -1, Color.WHITE, true, 0, Color.WHITE)


func get_shader_snippet(inputs: Array = []) -> String:
	return "VERTEX"


func get_default_inputs() -> Array:
	return []

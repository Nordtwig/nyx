@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Instance Custom Data"

	var label := Label.new()
	label.text = "Per-Instance"
	add_child(label)

	set_slot(0, false, -1, _type_color(3), true, 3, _type_color(3))


func get_shader_snippet(inputs: Array = []) -> String:
	return "INSTANCE_CUSTOM"


func get_default_inputs() -> Array:
	return []

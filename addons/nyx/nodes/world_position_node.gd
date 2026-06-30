@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "World Position"

	var label := Label.new()
	label.text = "Surface"
	add_child(label)

	set_slot(0, false, -1, _type_color(0), true, 0, _type_color(0))


func get_shader_snippet(inputs: Array = []) -> String:
	return "(MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz"


func get_default_inputs() -> Array:
	return []

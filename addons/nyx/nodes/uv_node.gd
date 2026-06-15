@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "UV"

	var label := Label.new()
	label.text = "UV"
	add_child(label)

	set_slot(0, false, -1, Color.WHITE, true, 0, Color.WHITE)


func get_shader_snippet(inputs: Array = []) -> String:
	return "vec3(UV, 0.0)"

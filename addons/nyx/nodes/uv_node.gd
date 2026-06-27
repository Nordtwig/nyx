@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "UV"

	var label := Label.new()
	label.text = "UV"
	add_child(label)

	set_slot(0, false, -1, _type_color(0), true, 2, _type_color(2))


func get_shader_snippet(inputs: Array = []) -> String:
	return "UV"

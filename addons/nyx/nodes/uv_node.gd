@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "UV"

	var label := Label.new()
	label.text = "UV"
	add_child(label)

	set_slot(0, false, -1, Color.WHITE, true, 2, Color("#A99BFF"))


func get_shader_snippet(inputs: Array = []) -> String:
	return "UV"

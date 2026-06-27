@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

# Delta — seconds since the last process frame. Multiply forces by Delta to make
# them frame-rate independent. (Default velocity integration already uses DELTA.)


func _add_preview_controls() -> void:
	pass


func _ready() -> void:
	super._ready()
	title = "Delta"

	var float_color := _type_color(1)
	var label := Label.new()
	label.text = "Delta"
	add_child(label)

	set_slot(0, false, -1, _type_color(0), true, 1, float_color)


func get_shader_snippet(inputs: Array = []) -> String:
	return "DELTA"

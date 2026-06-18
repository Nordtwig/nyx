@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Power"

	var label_base := Label.new()
	label_base.text = "Base"
	add_child(label_base)

	var label_exp := Label.new()
	label_exp.text = "Exp"
	add_child(label_exp)

	var float_color := Color(0.35, 0.9, 0.85)
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, true, 1, float_color, false, -1, Color.WHITE)


func get_shader_snippet(inputs: Array = []) -> String:
	return "pow(%s, vec3(%s))" % [inputs[0], inputs[1]]


func get_default_inputs() -> Array:
	return ["vec3(0.5)", "2.0"]

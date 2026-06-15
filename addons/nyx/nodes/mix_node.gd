@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Mix"

	var label_a := Label.new()
	label_a.text = "A"
	add_child(label_a)

	var label_b := Label.new()
	label_b.text = "B"
	add_child(label_b)

	var label_t := Label.new()
	label_t.text = "T"
	add_child(label_t)

	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, true, 0, Color.WHITE, false, -1, Color.WHITE)
	set_slot(2, true, 1, Color.GRAY, false, -1, Color.WHITE)


func get_shader_snippet(inputs: Array = []) -> String:
	return "mix(%s, %s, %s)" % [inputs[0], inputs[1], inputs[2]]


func get_default_inputs() -> Array:
	return ["vec3(0.0)", "vec3(1.0)", "0.5"]

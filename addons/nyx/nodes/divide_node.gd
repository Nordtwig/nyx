@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Divide"

	var label_a := Label.new()
	label_a.text = "A"
	add_child(label_a)

	var label_b := Label.new()
	label_b.text = "B"
	add_child(label_b)

	set_slot(0, true, 0, _type_color(0), true, 0, _type_color(0))
	set_slot(1, true, 0, _type_color(0), false, -1, _type_color(0))


func is_polymorphic() -> bool:
	return true

func get_shader_snippet(inputs: Array = []) -> String:
	return "(%s / %s)" % [inputs[0], inputs[1]]

func get_default_inputs() -> Array:
	return ["1.0", "1.0"]

func get_default_input_types() -> Array:
	return [1, 1]

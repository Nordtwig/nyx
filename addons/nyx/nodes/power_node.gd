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

	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, true, 0, Color.WHITE, false, -1, Color.WHITE)


func is_polymorphic() -> bool:
	return true

func get_output_type(from_port: int, input_types: Array) -> int:
	return input_types[0] if not input_types.is_empty() else 1

func get_shader_snippet(inputs: Array = []) -> String:
	return "pow(%s, %s)" % [inputs[0], inputs[1]]

func get_default_inputs() -> Array:
	return ["0.5", "2.0"]

func get_default_input_types() -> Array:
	return [1, 1]

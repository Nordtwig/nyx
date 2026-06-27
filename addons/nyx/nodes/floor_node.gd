@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Floor"
	var label := Label.new()
	label.text = "V"
	add_child(label)
	set_slot(0, true, 0, _type_color(0), true, 0, _type_color(0))


func is_polymorphic() -> bool:
	return true

func get_output_type(from_port: int, input_types: Array) -> int:
	return input_types[0] if not input_types.is_empty() else 1

func get_shader_snippet(inputs: Array = []) -> String:
	return "floor(%s)" % inputs[0]


func get_default_inputs() -> Array:
	return ["0.0"]

func get_default_input_types() -> Array:
	return [1]

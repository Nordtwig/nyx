@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Subtract"

	var label_a := Label.new()
	label_a.text = "A"
	add_child(label_a)

	var label_b := Label.new()
	label_b.text = "B"
	add_child(label_b)

	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, true, 0, Color.WHITE, false, -1, Color.WHITE)


func is_polymorphic() -> bool:
	return true

func get_shader_snippet(inputs: Array = []) -> String:
	return "(%s - %s)" % [inputs[0], inputs[1]]

func get_default_inputs() -> Array:
	return ["0.0", "0.0"]

func get_default_input_types() -> Array:
	return [1, 1]

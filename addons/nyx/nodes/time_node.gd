@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Time"

	var float_color := _type_color(1)

	var label_time := Label.new()
	label_time.text = "Time"
	add_child(label_time)

	var label_sin := Label.new()
	label_sin.text = "Sin"
	add_child(label_sin)

	var label_cos := Label.new()
	label_cos.text = "Cos"
	add_child(label_cos)

	set_slot(0, false, -1, _type_color(0), true, 1, float_color)
	set_slot(1, false, -1, _type_color(0), true, 1, float_color)
	set_slot(2, false, -1, _type_color(0), true, 1, float_color)


func _add_preview_controls() -> void:
	pass


func get_output_snippet(port: int, _inputs: Array = []) -> String:
	match port:
		1: return "sin(TIME)"
		2: return "cos(TIME)"
		_: return "TIME"


func get_default_inputs() -> Array:
	return []

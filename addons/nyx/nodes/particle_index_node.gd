@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

# Index — this particle's index as a float. Use it to stagger or stripe particles
# deterministically (e.g. drive a gradient by Index for a per-particle colour ramp).


func _add_preview_controls() -> void:
	pass


func _ready() -> void:
	super._ready()
	title = "Index"

	var float_color := _type_color(1)
	var label := Label.new()
	label.text = "Index"
	add_child(label)

	set_slot(0, false, -1, _type_color(0), true, 1, float_color)


func get_shader_snippet(inputs: Array = []) -> String:
	return "float(INDEX)"

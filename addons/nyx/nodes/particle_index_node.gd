@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

# Index — this particle's index as a float. Use it to stagger or stripe particles
# deterministically (e.g. drive a gradient by Index for a per-particle colour ramp).


func _add_preview_controls() -> void:
	pass


func _ready() -> void:
	super._ready()
	title = "Index"

	var float_color := Color(0.35, 0.9, 0.85)
	var label := Label.new()
	label.text = "Index"
	add_child(label)

	set_slot(0, false, -1, Color.WHITE, true, 1, float_color)


func get_shader_snippet(inputs: Array = []) -> String:
	return "float(INDEX)"

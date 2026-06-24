@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

# Age Ratio — 0 at spawn, 1 at the end of the particle's life. Reads the
# compiler-reserved CUSTOM.y channel (set 0 in start, += DELTA/LIFETIME each
# frame in process). The plumbing is hidden; the user just gets a clean 0→1 float.


func _add_preview_controls() -> void:
	pass


func _ready() -> void:
	super._ready()
	title = "Age Ratio"

	var float_color := Color(0.35, 0.9, 0.85)
	var label := Label.new()
	label.text = "Age"
	add_child(label)

	set_slot(0, false, -1, Color.WHITE, true, 1, float_color)


func get_shader_snippet(inputs: Array = []) -> String:
	return "CUSTOM.y"

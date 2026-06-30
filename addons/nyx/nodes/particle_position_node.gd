@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

# Position (read) — the particle's current world position (TRANSFORM[3].xyz).
# Useful for position-dependent forces (radial attraction, bounds) in Process.


func _add_preview_controls() -> void:
	pass


func _ready() -> void:
	super._ready()
	title = "Position"

	var label := Label.new()
	label.text = "Position"
	add_child(label)

	set_slot(0, false, -1, _type_color(0), true, 0, _type_color(0))


func get_shader_snippet(inputs: Array = []) -> String:
	return "TRANSFORM[3].xyz"


func get_vector_semantic() -> String:
	return "vector"

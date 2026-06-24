@tool
extends "res://addons/nyx/nodes/nyx_node.gd"

# Velocity (read) — the particle's current velocity vector. Read it to build
# forces relative to motion (drag, steering) in the Process stage.


func _add_preview_controls() -> void:
	pass


func _ready() -> void:
	super._ready()
	title = "Velocity"

	var label := Label.new()
	label.text = "Velocity"
	add_child(label)

	set_slot(0, false, -1, Color.WHITE, true, 0, Color.WHITE)


func get_shader_snippet(inputs: Array = []) -> String:
	return "VELOCITY"

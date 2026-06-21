@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Screen UV"

	var out_lbl := Label.new()
	out_lbl.text = "Screen UV"
	add_child(out_lbl)

	set_slot(0, false, -1, Color.WHITE, true, 0, Color.WHITE)


func _add_preview_controls() -> void:
	pass


func get_shader_snippet(inputs: Array = []) -> String:
	return "vec3(SCREEN_UV, 0.0)"


func get_default_inputs() -> Array:
	return []

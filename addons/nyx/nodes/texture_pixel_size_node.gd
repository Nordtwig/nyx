@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Pixel Size"

	var label := Label.new()
	label.text = "Size"
	add_child(label)

	set_slot(0, false, -1, Color.WHITE, true, 0, Color.WHITE)


func _add_preview_controls() -> void:
	pass


func get_shader_snippet(inputs: Array = []) -> String:
	return "vec3(TEXTURE_PIXEL_SIZE, 0.0)"


func get_default_inputs() -> Array:
	return []

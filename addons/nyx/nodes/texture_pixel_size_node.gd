@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Pixel Size"

	var label := Label.new()
	label.text = "Size"
	add_child(label)

	set_slot(0, false, -1, _type_color(0), true, 0, _type_color(0))


func _add_preview_controls() -> void:
	pass


func get_shader_snippet(inputs: Array = []) -> String:
	return "vec3(TEXTURE_PIXEL_SIZE, 0.0)"


func get_default_inputs() -> Array:
	return []

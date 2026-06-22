@tool
extends "res://addons/nyx/nodes/nyx_node.gd"


func _ready() -> void:
	super._ready()
	title = "Sprite Texture"

	var uv_label := Label.new()
	uv_label.text = "UV"
	add_child(uv_label)

	var color_label := Label.new()
	color_label.text = "Color"
	add_child(color_label)

	set_slot(0, true, 0, Color.WHITE, false, -1, Color.WHITE)
	set_slot(1, false, -1, Color.WHITE, true, 0, Color.WHITE)


func _add_preview_controls() -> void:
	pass


func get_shader_snippet(inputs: Array = []) -> String:
	return "texture(TEXTURE, (%s).xy).rgb" % inputs[0]


func get_default_inputs() -> Array:
	return ["vec3(UV, 0.0)"]
